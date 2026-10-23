extends Control

@onready var main_buttons: Control = $MenuCenter/MainButtons
@onready var progress_center: Control = $ProgressCenter
@onready var name_center: Control = $NameCenter

@onready var name_line_edit: LineEdit = \
	$NameCenter/NamePanel/VBoxContainer/NameLineEdit

@onready var info_dialog: AcceptDialog = $InfoDialog


func _ready() -> void:
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


func _show_campaign_complete_notice_if_needed() -> void:
	if not GameManager.show_campaign_complete_notice:
		return

	GameManager.show_campaign_complete_notice = false

	var notice := AcceptDialog.new()
	notice.title = "¡Felicidades!"
	notice.dialog_text = "¡Has completado Dark Math Rush!"
	add_child(notice)
	notice.popup_centered()


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
	info_dialog.title = "Ranking"
	info_dialog.dialog_text = GameManager.get_leaderboard_text()
	info_dialog.popup_centered()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_back_progress_button_pressed() -> void:
	progress_center.hide()
	main_buttons.show()


func _on_back_name_button_pressed() -> void:
	name_center.hide()
	main_buttons.show()


func _on_tutorial_button_pressed() -> void:
	info_dialog.title = "Tutorial"
	info_dialog.dialog_text = (
		"WASD: mover al personaje.\n"
		+ "J: interactuar en el lobby y atacar a los enemigos con la respuesta correcta.\n"
		+ "K: atacar a los enemigos con una respuesta incorrecta."
	)
	info_dialog.popup_centered()
