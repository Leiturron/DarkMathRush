extends CanvasLayer

const MENU_SCENE_PATH: String = "res://uitest.tscn"
const MENU_FONT: Font = preload("res://assets/ttf/TiejiliSC-Regular.ttf")

var is_battle_scene: bool = false
var return_lobby_path: String = ""
var menu_open: bool = false


func configure(battle_scene: bool, lobby_path: String) -> void:
	is_battle_scene = battle_scene
	return_lobby_path = lobby_path


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_menu()
	hide()


func _build_menu() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.002, 0.008, 0.025, 0.84)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560.0, 0.0)
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(panel)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(buttons)

	var title := Label.new()
	title.text = "PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", MENU_FONT)
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	buttons.add_child(title)

	_add_button(buttons, "CONTINUAR", _resume_game)
	if is_battle_scene:
		_add_button(buttons, "VOLVER AL ESCENARIO PRINCIPAL", _return_to_lobby)
	_add_button(buttons, "VOLVER AL MENÚ", _return_to_menu)


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.028, 0.075, 0.97)
	style.border_color = Color(0.69, 0.78, 0.92, 0.96)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	return style


func _add_button(container: VBoxContainer, button_text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(330.0, 52.0)
	button.add_theme_font_override("font", MENU_FONT)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color(0.78, 0.86, 0.95))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(callback)
	container.add_child(button)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if menu_open:
		_resume_game()
		get_viewport().set_input_as_handled()
		return

	if get_tree().paused:
		return

	menu_open = true
	show()
	get_tree().paused = true
	get_viewport().set_input_as_handled()


func _resume_game() -> void:
	menu_open = false
	hide()
	get_tree().paused = false


func _return_to_lobby() -> void:
	if return_lobby_path.is_empty():
		return
	_change_scene(return_lobby_path)


func _return_to_menu() -> void:
	_change_scene(MENU_SCENE_PATH)


func _change_scene(scene_path: String) -> void:
	menu_open = false
	get_tree().paused = false
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("No se pudo abrir la escena: " + scene_path)
