extends CanvasLayer

signal confirmed

const MENU_FONT: Font = preload("res://assets/ttf/TiejiliSC-Regular.ttf")

var title: String = ""
var dialog_text: String = ""
var confirm_text: String = "ACEPTAR"

var _title_label: Label
var _body_label: Label
var _dialog_panel: PanelContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	_build_dialog()
	hide()


func _build_dialog() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.002, 0.008, 0.025, 0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(center)

	_dialog_panel = PanelContainer.new()
	_dialog_panel.custom_minimum_size = Vector2(600.0, 280.0)
	_dialog_panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(_dialog_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	_dialog_panel.add_child(content)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_override("font", MENU_FONT)
	_title_label.add_theme_font_size_override("font_size", 30)
	_title_label.add_theme_color_override("font_color", Color(0.91, 0.94, 1.0))
	content.add_child(_title_label)

	var body_scroll := ScrollContainer.new()
	body_scroll.custom_minimum_size = Vector2(490.0, 150.0)
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(body_scroll)
	_body_label = Label.new()
	_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.custom_minimum_size.x = 470.0
	_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_label.add_theme_font_override("font", MENU_FONT)
	_body_label.add_theme_font_size_override("font_size", 20)
	_body_label.add_theme_color_override("font_color", Color(0.80, 0.86, 0.95))
	body_scroll.add_child(_body_label)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(button_row)
	var accept_button := Button.new()
	accept_button.text = confirm_text
	accept_button.custom_minimum_size = Vector2(180.0, 48.0)
	_style_button(accept_button)
	accept_button.pressed.connect(_on_confirm_pressed)
	button_row.add_child(accept_button)

	_sync_text()


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.028, 0.075, 0.97)
	style.border_color = Color(0.69, 0.78, 0.92, 0.96)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 34.0
	style.content_margin_right = 34.0
	style.content_margin_top = 28.0
	style.content_margin_bottom = 26.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	return style


func _style_button(button: Button) -> void:
	button.add_theme_font_override("font", MENU_FONT)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color(0.80, 0.86, 0.95))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _sync_text() -> void:
	if is_instance_valid(_title_label):
		_title_label.text = title
		_body_label.text = dialog_text


func popup_centered(_minimum_size: Vector2 = Vector2.ZERO) -> void:
	_sync_text()
	show()
	_dialog_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_dialog_panel, "modulate:a", 1.0, 0.18)


func _on_confirm_pressed() -> void:
	hide()
	confirmed.emit()
