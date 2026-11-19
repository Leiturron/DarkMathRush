extends Control

const STYLED_DIALOG_SCRIPT: Script = preload("res://scene/scripts/styled_dialog.gd")
const RANKING_SCENE: String = "res://scene/Ranking.tscn"
const TUTORIAL_SCENE: String = "res://scene/Tutorial.tscn"

@onready var title_art: Control = $Title
@onready var main_menu_layer: Control = $MenuLayer
@onready var main_buttons: VBoxContainer = $MenuLayer/MenuContainer
@onready var dimmer: ColorRect = $SubmenuDimmer
@onready var progress_center: CenterContainer = $ProgressCenter
@onready var name_center: CenterContainer = $NameCenter
@onready var name_line_edit: LineEdit = \
	$NameCenter/NamePanel/VBoxContainer/NameLineEdit
@onready var fade_rect: ColorRect = $TransitionLayer/FadeRect

@onready var click_sound: AudioStreamPlayer = $ClickSound
@onready var hold_sound: AudioStreamPlayer = $EnteredSound
@onready var jugar_sound: AudioStreamPlayer = $PlaySound

var transition_busy: bool = false
var name_back_screen: String = "main"
var info_dialog


func _ready() -> void:
	info_dialog = STYLED_DIALOG_SCRIPT.new()
	info_dialog.name = "StyledNotice"
	add_child(info_dialog)
	dimmer.hide()
	progress_center.hide()
	name_center.hide()

	var fade_color := fade_rect.color
	fade_color.a = 0.0
	fade_rect.color = fade_color
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	$MenuLayer/MenuContainer/StartButton.pressed.connect(
		_on_start_pressed
	)
	$MenuLayer/MenuContainer/TutorialButton.pressed.connect(
		_on_tutorial_pressed
	)
	$MenuLayer/MenuContainer/RankingButton.pressed.connect(
		_on_ranking_pressed
	)
	$MenuLayer/MenuContainer/ExitButton.pressed.connect(
		_on_exit_pressed
	)

	$ProgressCenter/ProgressPanel/VBoxContainer/ContinueButton.pressed.connect(
		_on_continue_pressed
	)
	$ProgressCenter/ProgressPanel/VBoxContainer/NewGameButton.pressed.connect(
		_on_new_game_pressed
	)
	$ProgressCenter/ProgressPanel/VBoxContainer/BackProgressButton.pressed.connect(
		_on_progress_back_pressed
	)

	$NameCenter/NamePanel/VBoxContainer/NameButtons/BackNameButton.pressed.connect(
		_on_name_back_pressed
	)
	$NameCenter/NamePanel/VBoxContainer/NameButtons/ConfirmNameButton.pressed.connect(
		_on_name_confirm_pressed
	)
	
	var hover_buttons: Array[Button] = [
	$MenuLayer/MenuContainer/StartButton,
	$MenuLayer/MenuContainer/TutorialButton,
	$MenuLayer/MenuContainer/RankingButton,
	$MenuLayer/MenuContainer/ExitButton,
	$ProgressCenter/ProgressPanel/VBoxContainer/ContinueButton,
	$ProgressCenter/ProgressPanel/VBoxContainer/NewGameButton,
	$ProgressCenter/ProgressPanel/VBoxContainer/BackProgressButton,
	$NameCenter/NamePanel/VBoxContainer/NameButtons/BackNameButton,
	$NameCenter/NamePanel/VBoxContainer/NameButtons/ConfirmNameButton,
	]

	for button in hover_buttons:
		button.mouse_entered.connect(_play_hold_sound)

	_show_campaign_complete_notice_if_needed()


func _show_campaign_complete_notice_if_needed() -> void:
	if not GameManager.show_campaign_complete_notice:
		return

	GameManager.show_campaign_complete_notice = false
	var notice = STYLED_DIALOG_SCRIPT.new()
	notice.process_mode = Node.PROCESS_MODE_ALWAYS
	notice.title = "¡Felicidades!"
	var record: Dictionary = GameManager.last_completion_record
	if record.is_empty():
		notice.dialog_text = "¡Has completado Dark Math Rush!"
	else:
		var player_summary := "Jugador: %s\nPuntuación total: %d" % [
			str(record.get("player_name", "Jugador")),
			int(record.get("total_score", 0))
		]
		notice.dialog_text = (
			"¡Has completado Dark Math Rush!\n\n" + player_summary
		)
	add_child(notice)
	notice.popup_centered()


func _fade_to(alpha: float) -> void:
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(
		fade_rect,
		"color:a",
		alpha,
		0.38
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	if is_zero_approx(alpha):
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _show_screen(screen_name: String) -> void:
	if transition_busy:
		return

	transition_busy = true
	await _fade_to(1.0)

	var show_main := screen_name == "main"
	main_menu_layer.visible = show_main
	title_art.visible = show_main
	dimmer.visible = not show_main
	progress_center.visible = screen_name == "progress"
	name_center.visible = screen_name == "name"

	await _fade_to(0.0)
	transition_busy = false


func _on_start_pressed() -> void:
	jugar_sound.play()
	await _show_screen("progress")


func _on_continue_pressed() -> void:
	click_sound.play()
	if transition_busy:
		return
	if not GameManager.has_saved_progress():
		info_dialog.title = "No hay partida guardada"
		info_dialog.dialog_text = \
			"Todavía no existe una partida para continuar. Elige Juego nuevo para crear una."
		info_dialog.popup_centered()
		return

	transition_busy = true
	await _fade_to(1.0)
	GameManager.continue_game()


func _on_new_game_pressed() -> void:
	click_sound.play()
	name_back_screen = "progress"
	name_line_edit.text = ""
	await _show_screen("name")


func _on_progress_back_pressed() -> void:
	click_sound.play()
	await _show_screen("main")


func _on_name_back_pressed() -> void:
	click_sound.play()
	await _show_screen(name_back_screen)


func _on_name_confirm_pressed() -> void:
	click_sound.play()
	var player_name := name_line_edit.text.strip_edges()

	if player_name.is_empty():
		info_dialog.title = "Falta tu nombre"
		info_dialog.dialog_text = "Escribe tu nombre para comenzar."
		info_dialog.popup_centered()
		return

	if transition_busy:
		return

	transition_busy = true
	await _fade_to(1.0)
	GameManager.start_new_game(player_name)


func _on_tutorial_pressed() -> void:
	click_sound.play()
	if transition_busy:
		return
	transition_busy = true
	await _fade_to(1.0)
	var error := get_tree().change_scene_to_file(TUTORIAL_SCENE)
	if error != OK:
		transition_busy = false
		push_error("No se pudo abrir el tutorial.")


func _on_ranking_pressed() -> void:
	click_sound.play()
	if transition_busy:
		return
	transition_busy = true
	await _fade_to(1.0)
	var error := get_tree().change_scene_to_file(RANKING_SCENE)
	if error != OK:
		transition_busy = false
		push_error("No se pudo abrir el ranking.")


func _on_exit_pressed() -> void:
	get_tree().quit()
	
func _play_hold_sound() -> void:
	hold_sound.stop()
	hold_sound.play()
