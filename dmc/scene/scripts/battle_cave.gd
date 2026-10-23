extends Node2D

@export var enemy_scene: PackedScene
const HEART_SCENE: PackedScene = preload("res://character/tscn/heart.tscn")
const MAX_HEALTH: int = 3

var battle_finished: bool = false
var campaign_completed: bool = false
var result_dialog: AcceptDialog
var wrong_questions: Array[Dictionary] = []

var health: int = 3
var score: int = 0
var kills: int = 0

var questions_oa3: Dictionary = {}
var current_question_set: Array = []
var current_correct_decimal: float = 0.0


func _ready() -> void:
	# Colocar al jugador en su punto de aparición
	if has_node("spawn"):
		$Player.global_position = $spawn.global_position

	# Cargar las preguntas del nivel 3
	questions_oa3 = load_questions_from_txt(
		"res://quiz/preguntaFase3.txt"
	)

	if questions_oa3.is_empty():
		push_error("No se pudieron cargar preguntas del nivel 3.")
		return

	result_dialog = AcceptDialog.new()
	result_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	result_dialog.confirmed.connect(_on_result_confirmed)
	add_child(result_dialog)

	generate_new_question()
	update_ui()

	$SpawnTimer.wait_time = 2.5

	if not $SpawnTimer.timeout.is_connected(_on_spawn_timer_timeout):
		$SpawnTimer.timeout.connect(_on_spawn_timer_timeout)

	$SpawnTimer.start()


func load_questions_from_txt(file_path: String) -> Dictionary:
	var loaded_questions: Dictionary = {}

	if not FileAccess.file_exists(file_path):
		push_error("No se encontró el archivo de preguntas: " + file_path)
		return loaded_questions

	var file := FileAccess.open(file_path, FileAccess.READ)

	if file == null:
		push_error("No se pudo abrir el archivo de preguntas: " + file_path)
		return loaded_questions

	while not file.eof_reached():
		var line := file.get_line().strip_edges()

		if line.is_empty() or line.begins_with("#"):
			continue

		var parts := line.split("|")

		if parts.size() != 4:
			push_warning("Formato de pregunta incorrecto: " + line)
			continue

		var question_text: String = parts[0]
		var correct_answer: float = parts[1].to_float()
		var wrong_answer_1: float = parts[2].to_float()
		var wrong_answer_2: float = parts[3].to_float()

		loaded_questions[question_text] = [
			correct_answer,
			wrong_answer_1,
			wrong_answer_2
		]

	file.close()
	return loaded_questions


func generate_new_question() -> void:
	current_question_set = questions_oa3.keys()

	if current_question_set.is_empty():
		push_error("No hay preguntas disponibles.")
		return

	var question_text: String = current_question_set.pick_random()
	current_correct_decimal = questions_oa3[question_text][0]

	# Mostrar solo la pregunta
	$UI/QuestionLabel.text = question_text


func get_enemy_value() -> float:
	var question_text: String = $UI/QuestionLabel.text
	var answers: Array = questions_oa3[question_text]

	# El 30 % de los enemigos muestra la respuesta correcta
	if randf() < 0.3:
		return current_correct_decimal

	# Los demás muestran una respuesta incorrecta
	var wrong_answers: Array = [answers[1], answers[2]]
	return float(wrong_answers.pick_random())


func _on_enemy_judged(
	action_type: String,
	enemy_value: float,
	enemy_position: Vector2
) -> void:
	if battle_finished:
		return

	var is_correct_answer: bool = is_equal_approx(
		enemy_value,
		current_correct_decimal
	)

	var is_successful: bool = (
		(action_type == "correct" and is_correct_answer)
		or
		(action_type == "wrong" and not is_correct_answer)
	)

	GameManager.record_answer_result(is_successful, 10)

	if is_successful:
		kills += 1
		score += 10
		print("Respuesta correcta.")
		_try_spawn_heart(enemy_position)

		update_ui()
		check_progression()

		if battle_finished:
			return

		# Cambiar la pregunta al acertar con J al enemigo correcto
		if action_type == "correct" and is_correct_answer:
			generate_new_question()
	else:
		_record_wrong_question()
		health -= 1
		$Player.play_damage_flash()
		print("Respuesta incorrecta.")

		update_ui()

		if health <= 0:
			_finish_battle(false)


func _record_wrong_question() -> void:
	var question_text: String = $UI/QuestionLabel.text

	for entry in wrong_questions:
		if str(entry.get("question", "")) == question_text:
			return

	wrong_questions.append({
		"question": question_text,
		"correct_answer": current_correct_decimal
	})

func _get_wrong_questions_report() -> String:
	if wrong_questions.is_empty():
		return "\n\n¡Muy bien! No cometiste errores."

	var report: String = "\n\nPreguntas incorrectas y su respuesta correcta:\n"
	for index in range(wrong_questions.size()):
		var entry: Dictionary = wrong_questions[index]
		report += "%d. %s = %s\n" % [
			index + 1,
			str(entry.get("question", "")),
			str(entry.get("correct_answer", ""))
		]

	return report.strip_edges()

func _try_spawn_heart(drop_position: Vector2) -> void:
	if randf() >= 0.25:
		return

	var heart: Area2D = HEART_SCENE.instantiate() as Area2D
	add_child(heart)
	heart.global_position = drop_position
	heart.connect("collected", _on_heart_collected)


func _on_heart_collected() -> void:
	if health >= MAX_HEALTH:
		return

	health = mini(health + 1, MAX_HEALTH)
	update_ui()


func update_ui() -> void:
	$UI/HealthLabel.text = "Vidas: %d" % health
	$UI/ScoreLabel.text = "Puntaje: %d" % score


func _on_spawn_timer_timeout() -> void:
	if battle_finished:
		return

	# Mantener un máximo de tres enemigos en escena
	var current_enemy_count: int = \
		get_tree().get_nodes_in_group("enemies").size()

	if current_enemy_count >= 3:
		return

	if enemy_scene == null:
		push_error("No se asignó la escena del enemigo.")
		return

	var spawn_points: Array[Node] = $SpawnPoints.get_children()

	if spawn_points.is_empty():
		push_error("No hay puntos de aparición configurados en SpawnPoints.")
		return

	var spawn_point: Node2D = spawn_points.pick_random() as Node2D
	var enemy = enemy_scene.instantiate()

	add_child(enemy)
	enemy.global_position = spawn_point.global_position

	enemy.call("setup", $Player, get_enemy_value(), false, 1.0)
	enemy.connect("enemy_judged", _on_enemy_judged)
	enemy.connect("player_contacted", _on_enemy_player_contacted)


func _on_enemy_player_contacted() -> void:
	if battle_finished or health <= 0:
		return

	health -= 1
	$Player.play_damage_flash()
	update_ui()

	if health <= 0:
		_finish_battle(false)


func check_progression() -> void:
	if kills >= 20:
		_finish_battle(true)


func _finish_battle(victory: bool) -> void:
	if battle_finished:
		return

	battle_finished = true
	$SpawnTimer.stop()
	GameManager.save_run_stats(score, kills)

	if victory:
		if not GameManager.complete_game():
			battle_finished = false
			return

		campaign_completed = true
		result_dialog.title = "Victoria"
		result_dialog.dialog_text = "¡Has completado Dark Math Rush!"
	else:
		result_dialog.title = "Derrota"
		result_dialog.dialog_text = "Te has quedado sin vidas."

	result_dialog.dialog_text += _get_wrong_questions_report()
	get_tree().paused = true
	result_dialog.popup_centered()


func _on_result_confirmed() -> void:
	get_tree().paused = false

	if campaign_completed:
		get_tree().change_scene_to_file("res://scene/MainMenu.tscn")
	else:
		get_tree().change_scene_to_file("res://scene/LobbyCave.tscn")
