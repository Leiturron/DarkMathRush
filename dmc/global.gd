extends Node

const PROGRESS_PATH: String = "user://progress.json"
const LEADERBOARD_PATH: String = "user://leaderboard.json"

const LOBBY_SCENES: Dictionary = {
	1: "res://scene/LobbyCastle.tscn",
	2: "res://scene/LobbyForest.tscn",
	3: "res://scene/LobbyCave.tscn"
}

var current_progress: Dictionary = {}
var show_campaign_complete_notice: bool = false


func _ready() -> void:
	var saved_data: Variant = _read_json(PROGRESS_PATH, {})

	if saved_data is Dictionary:
		current_progress = saved_data
	else:
		current_progress = {}


func has_saved_progress() -> bool:
	var progress: Variant = _read_json(PROGRESS_PATH, {})

	return (
		progress is Dictionary
		and progress.get("active", false) == true
	)


func start_new_game(player_name: String) -> void:
	if has_saved_progress():
		var old_progress: Variant = _read_json(PROGRESS_PATH, {})

		if old_progress is Dictionary:
			_archive_progress(old_progress)

	current_progress = {
		"active": true,
		"player_name": player_name,
		"last_lobby": 1,
		"unlocked_lobby": 1,
		"show_forest_notice": false,
		"show_cave_notice": false,
		"total_score": 0,
		"correct_answers": 0,
		"wrong_answers": 0,
		"kills": 0
	}

	_write_json(PROGRESS_PATH, current_progress)
	_go_to_lobby(1)


func continue_game() -> void:
	var saved_data: Variant = _read_json(PROGRESS_PATH, {})

	if not saved_data is Dictionary:
		push_error("No hay una partida guardada válida.")
		return

	current_progress = saved_data
	var lobby_number: int = int(current_progress.get("last_lobby", 1))
	_go_to_lobby(lobby_number)


func save_lobby_checkpoint(lobby_number: int) -> void:
	if current_progress.is_empty():
		return

	current_progress["last_lobby"] = lobby_number
	_write_json(PROGRESS_PATH, current_progress)


func save_run_stats(score: int, kills: int) -> void:
	if current_progress.is_empty():
		return

	current_progress["score"] = score
	current_progress["kills"] = int(current_progress.get("kills", 0)) + kills
	_write_json(PROGRESS_PATH, current_progress)


func record_answer_result(was_correct: bool, points: int = 10) -> void:
	if current_progress.is_empty():
		var saved_data: Variant = _read_json(PROGRESS_PATH, {})
		if saved_data is Dictionary:
			current_progress = saved_data

	if current_progress.is_empty():
		push_error("No hay una partida activa para guardar el resultado.")
		return

	if was_correct:
		current_progress["correct_answers"] = \
			int(current_progress.get("correct_answers", 0)) + 1
		current_progress["total_score"] = \
			int(current_progress.get("total_score", 0)) + points
	else:
		current_progress["wrong_answers"] = \
			int(current_progress.get("wrong_answers", 0)) + 1

	_write_json(PROGRESS_PATH, current_progress)


func unlock_forest() -> void:
	_unlock_lobby(2, "show_forest_notice")


func unlock_cave() -> void:
	_unlock_lobby(3, "show_cave_notice")


func _unlock_lobby(lobby_number: int, notice_key: String) -> void:
	if current_progress.is_empty():
		var saved_data: Variant = _read_json(PROGRESS_PATH, {})
		if saved_data is Dictionary:
			current_progress = saved_data

	if current_progress.is_empty():
		push_error("No hay una partida activa para desbloquear el lobby.")
		return

	var unlocked_lobby: int = int(
		current_progress.get("unlocked_lobby", 1)
	)

	current_progress["unlocked_lobby"] = maxi(
		unlocked_lobby,
		lobby_number
	)
	current_progress[notice_key] = true
	_write_json(PROGRESS_PATH, current_progress)


func consume_forest_notice() -> bool:
	return _consume_notice("show_forest_notice")


func consume_cave_notice() -> bool:
	return _consume_notice("show_cave_notice")


func _consume_notice(notice_key: String) -> bool:
	if current_progress.get(notice_key, false) != true:
		return false

	current_progress[notice_key] = false
	_write_json(PROGRESS_PATH, current_progress)
	return true


func is_lobby_unlocked(lobby_number: int) -> bool:
	var unlocked_lobby: int = int(
		current_progress.get("unlocked_lobby", 1)
	)

	return lobby_number <= unlocked_lobby


func go_to_lobby(lobby_number: int) -> void:
	_go_to_lobby(lobby_number)


func _go_to_lobby(lobby_number: int) -> void:
	if not LOBBY_SCENES.has(lobby_number):
		push_error("No existe la escena del lobby solicitado.")
		return

	if not is_lobby_unlocked(lobby_number):
		push_error("El lobby solicitado todavía está bloqueado.")
		return

	var scene_path: String = LOBBY_SCENES[lobby_number]
	var error: Error = get_tree().change_scene_to_file(scene_path)

	if error != OK:
		push_error("No se pudo abrir la escena: " + scene_path)


func complete_game() -> bool:
	if current_progress.is_empty():
		var saved_data: Variant = _read_json(PROGRESS_PATH, {})
		if saved_data is Dictionary:
			current_progress = saved_data

	if current_progress.is_empty():
		push_error("No hay una partida activa para guardar en el ranking.")
		return false

	var loaded_records: Variant = _read_json(LEADERBOARD_PATH, [])
	var records: Array = []

	if loaded_records is Array:
		records = loaded_records

	var completion_record: Dictionary = {
		"player_name": str(current_progress.get("player_name", "Jugador")),
		"total_score": int(current_progress.get("total_score", 0)),
		"correct_answers": int(current_progress.get("correct_answers", 0)),
		"wrong_answers": int(current_progress.get("wrong_answers", 0)),
		"completed": true,
		"completed_at": Time.get_datetime_string_from_system()
	}

	records.append(completion_record)

	if not _write_json(LEADERBOARD_PATH, records):
		return false

	if FileAccess.file_exists(PROGRESS_PATH):
		var absolute_path: String = \
			ProjectSettings.globalize_path(PROGRESS_PATH)
		var error: Error = DirAccess.remove_absolute(absolute_path)

		if error != OK:
			push_error("No se pudo eliminar el archivo de progreso.")
			return false

	current_progress = {}
	show_campaign_complete_notice = true
	return true


func get_leaderboard_text() -> String:
	var loaded_records: Variant = _read_json(LEADERBOARD_PATH, [])

	if not loaded_records is Array or loaded_records.is_empty():
		return "Todavía no hay registros."

	var records: Array = loaded_records

	# Ordenar por puntuación, de mayor a menor
	for i in range(records.size()):
		for j in range(i + 1, records.size()):
			var score_i: int = int(
				records[i].get("total_score", records[i].get("score", 0))
			)
			var score_j: int = int(
				records[j].get("total_score", records[j].get("score", 0))
			)

			if score_j > score_i:
				var temporary: Variant = records[i]
				records[i] = records[j]
				records[j] = temporary

	var lines: PackedStringArray = [
		"Nombre | Puntos | Correctas | Errores"
	]

	for i in range(records.size()):
		var record: Variant = records[i]

		if not record is Dictionary:
			continue

		var player_name: String = str(
			record.get("player_name", "Jugador")
		)
		var total_score: int = int(
			record.get("total_score", record.get("score", 0))
		)
		var correct_answers: int = int(
			record.get("correct_answers", 0)
		)
		var wrong_answers: int = int(
			record.get("wrong_answers", 0)
		)

		lines.append(
			"%d. %s | %d | %d | %d"
			% [
				i + 1,
				player_name,
				total_score,
				correct_answers,
				wrong_answers
			]
		)

	return "\n".join(lines)


func _archive_progress(progress: Dictionary) -> void:
	var loaded_records: Variant = _read_json(LEADERBOARD_PATH, [])
	var records: Array = []

	if loaded_records is Array:
		records = loaded_records

	records.append({
		"player_name": str(progress.get("player_name", "Jugador")),
		"total_score": int(
			progress.get("total_score", progress.get("score", 0))
		),
		"correct_answers": int(progress.get("correct_answers", 0)),
		"wrong_answers": int(progress.get("wrong_answers", 0)),
		"completed": false,
		"completed_at": ""
	})

	_write_json(LEADERBOARD_PATH, records)


func _read_json(file_path: String, default_value: Variant) -> Variant:
	if not FileAccess.file_exists(file_path):
		return default_value

	var file := FileAccess.open(file_path, FileAccess.READ)

	if file == null:
		push_error("No se pudo abrir el archivo: " + file_path)
		return default_value

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if parsed == null:
		push_error("El archivo JSON no tiene un formato válido: " + file_path)
		return default_value

	return parsed


func _write_json(file_path: String, data: Variant) -> bool:
	var file := FileAccess.open(file_path, FileAccess.WRITE)

	if file == null:
		push_error("No se pudo guardar el archivo: " + file_path)
		return false

	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true
