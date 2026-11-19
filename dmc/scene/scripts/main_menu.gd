extends Control

const STYLED_DIALOG_SCRIPT: Script = preload("res://scene/scripts/styled_dialog.gd")
const RANKING_SCENE: String = "res://scene/Ranking.tscn"
const TUTORIAL_SCENE: String = "res://scene/Tutorial.tscn"

@onready var main_buttons: Control = $MenuCenter/MainButtons
@onready var progress_center: Control = $ProgressCenter
@onready var name_center: Control = $NameCenter

@onready var name_line_edit: LineEdit = \
	$NameCenter/NamePanel/VBoxContainer/NameLineEdit

var info_dialog
var transition_busy: bool = false
var fade_rect: ColorRect


func _ready() -> void:
	info_dialog = STYLED_DIALOG_SCRIPT.new()
	info_dialog.name = "StyledNotice"
	add_child(info_dialog)
	_create_fade_layer()
	progress_center.hide()
	name_center.hide()

	_connect_button(
		$MenuCenter/MainButtons/StartButton,
		_on_start_button_pressed
	)
	_connect_button(
		$MenuCenter/MainButtons/TutorialButton,
		_on_tutorial_button_pressed
	)
	_connect_button(
		$MenuCenter/MainButtons/LeaderboardButton,
		_on_leaderboard_button_pressed
	)
	_connect_button(
		$MenuCenter/MainButtons/QuitButton,
		_on_quit_button_pressed
	)

	_connect_button(
		$ProgressCenter/ProgressPanel/VBoxContainer/ContinueButton,
		_on_continue_button_pressed
	)
	_connect_button(
		$ProgressCenter/ProgressPanel/VBoxContainer/NewGameButton,
		_on_new_game_button_pressed
	)
	_connect_button(
		$ProgressCenter/ProgressPanel/VBoxContainer/BackProgressButton,
		_on_back_progress_button_pressed
	)

	_connect_button(
		$NameCenter/NamePanel/VBoxContainer/HBoxContainer/ConfirmNameButton,
		_on_confirm_name_button_pressed
	)
	_connect_button(
		$NameCenter/NamePanel/VBoxContainer/HBoxContainer/BackNameButton,
		_on_back_name_button_pressed
	)

	_show_campaign_complete_notice_if_needed()
	await _fade_in_from_black()


func _show_campaign_complete_notice_if_needed() -> void:
	if not GameManager.show_campaign_complete_notice:
		return

	GameManager.show_campaign_complete_notice = false

	var notice = STYLED_DIALOG_SCRIPT.new()
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


func _create_fade_layer() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	fade_rect = ColorRect.new()
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color.BLACK
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(fade_rect)


func _fade_in_from_black() -> void:
	var tween := create_tween()
	tween.tween_property(
		fade_rect,
		"color:a",
		0.0,
		0.8
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _connect_button(button: Button, callback: Callable) -> void:
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func _on_start_button_pressed() -> void:
	main_buttons.hide()

	if GameManager.has_saved_progress():
		progress_center.show()
	else:
		name_center.show()


func _on_continue_button_pressed() -> void:
	GameManager.continue_game()


func _on_new_game_button_pressed() -> void:
	progress_center.hide()
	name_center.show()


func _on_confirm_name_button_pressed() -> void:
	var player_name: String = name_line_edit.text.strip_edges()

	if player_name.is_empty():
		info_dialog.dialog_text = "Escribe tu nombre para continuar."
		info_dialog.popup_centered()
		return

	GameManager.start_new_game(player_name)


func _on_leaderboard_button_pressed() -> void:
	if transition_busy:
		return
	transition_busy = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.38).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	var error := get_tree().change_scene_to_file(RANKING_SCENE)
	if error != OK:
		transition_busy = false
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		push_error("No se pudo abrir el ranking.")


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_back_progress_button_pressed() -> void:
	progress_center.hide()
	main_buttons.show()


func _on_back_name_button_pressed() -> void:
	name_center.hide()
	main_buttons.show()


func _on_tutorial_button_pressed() -> void:
	if transition_busy:
		return
	transition_busy = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.38).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	var error := get_tree().change_scene_to_file(TUTORIAL_SCENE)
	if error != OK:
		transition_busy = false
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		push_error("No se pudo abrir el tutorial.")
