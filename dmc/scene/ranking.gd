extends Control

const MENU_BG: Texture2D = preload("res://assets/newresource/mainBG.png")
const MENU_LEFT: Texture2D = preload("res://assets/newresource/menu_left.png")
const MENU_RIGHT: Texture2D = preload("res://assets/newresource/menu_right.png")
const MENU_FONT: Font = preload("res://assets/ttf/TiejiliSC-Regular.ttf")
const MENU_SCENE: String = "res://uitest.tscn"

var _fade_rect: ColorRect


func _ready() -> void:
	_build_page()
	_fade_rect.color = Color(0.0, 0.0, 0.0, 1.0)
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 0.0, 0.45).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _build_page() -> void:
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = MENU_BG
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.008, 0.035, 0.42)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1060.0, 600.0)
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(content)

	var heading := HBoxContainer.new()
	heading.alignment = BoxContainer.ALIGNMENT_CENTER
	heading.add_theme_constant_override("separation", 18)
	content.add_child(heading)
	heading.add_child(_ornament(MENU_LEFT, Vector2(145, 52)))
	var title := Label.new()
	title.text = "GRAN RANKING"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", MENU_FONT)
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	title.custom_minimum_size.x = 420
	heading.add_child(title)
	heading.add_child(_ornament(MENU_RIGHT, Vector2(145, 52)))

	var subtitle := Label.new()
	subtitle.text = "CAMPAÑAS COMPLETADAS · PUNTUACIÓN TOTAL"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font", MENU_FONT)
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.62, 0.73, 0.89))
	content.add_child(subtitle)

	var table := VBoxContainer.new()
	table.add_theme_constant_override("separation", 6)
	content.add_child(table)
	var header := _make_row("PUESTO", "JUGADOR", "PUNTOS", true)
	table.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(970.0, 350.0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	table.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 5)
	scroll.add_child(rows)

	var records: Array[Dictionary] = GameManager.get_leaderboard_records()
	if records.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Todavía no hay campañas completadas."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_override("font", MENU_FONT)
		empty_label.add_theme_font_size_override("font_size", 22)
		empty_label.add_theme_color_override("font_color", Color(0.8, 0.86, 0.95))
		empty_label.custom_minimum_size.y = 100
		rows.add_child(empty_label)
	else:
		for index in range(records.size()):
			var record := records[index]
			var score := int(record.get("total_score", record.get("score", 0)))
			var player_name := str(record.get("player_name", "Jugador"))
			rows.add_child(_make_row("%02d" % (index + 1), player_name, "%d" % score, false, index))

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 16)
	content.add_child(bottom)
	bottom.add_child(_ornament(MENU_LEFT, Vector2(130, 40)))
	var back_button := Button.new()
	back_button.text = "VOLVER AL MENÚ"
	back_button.custom_minimum_size = Vector2(260.0, 52.0)
	_style_button(back_button, 24)
	back_button.pressed.connect(_return_to_menu)
	bottom.add_child(back_button)
	bottom.add_child(_ornament(MENU_RIGHT, Vector2(130, 40)))

	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade_rect.z_index = 100
	add_child(_fade_rect)


func _make_row(rank: String, player_name: String, points: String, header: bool, index: int = 0) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 44.0 if header else 42.0
	row.add_theme_constant_override("separation", 12)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.12, 0.22, 0.39, 0.88) if header else (
		Color(0.08, 0.15, 0.29, 0.82) if index % 2 == 0 else Color(0.045, 0.10, 0.22, 0.82)
	)
	background.border_color = Color(0.40, 0.53, 0.72, 0.65)
	background.set_border_width_all(1)
	background.set_corner_radius_all(4)
	row.add_theme_stylebox_override("panel", background)
	# Use a background panel behind each row while preserving the HBox layout.
	var shell := PanelContainer.new()
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.add_theme_stylebox_override("panel", background)
	var padded := MarginContainer.new()
	padded.add_theme_constant_override("margin_left", 16)
	padded.add_theme_constant_override("margin_right", 16)
	shell.add_child(padded)
	padded.add_child(row)
	_add_cell(row, rank, 180, header)
	_add_cell(row, player_name, 520, header, true)
	_add_cell(row, points, 180, header)
	return _row_shell(shell)


func _row_shell(shell: PanelContainer) -> HBoxContainer:
	# Return a layout container so the scroll list can accept each shell as a row.
	var wrapper := HBoxContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.add_child(shell)
	return wrapper


func _add_cell(row: HBoxContainer, value: String, width: float, header: bool, expand: bool = false) -> void:
	var cell := Label.new()
	cell.text = value
	cell.custom_minimum_size.x = width
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL if expand else Control.SIZE_SHRINK_BEGIN
	cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if not expand else HORIZONTAL_ALIGNMENT_LEFT
	cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cell.add_theme_font_override("font", MENU_FONT)
	cell.add_theme_font_size_override("font_size", 19 if header else 20)
	cell.add_theme_color_override("font_color", Color(0.91, 0.94, 1.0) if header else Color(0.78, 0.86, 0.97))
	row.add_child(cell)


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.008, 0.025, 0.07, 0.95)
	style.border_color = Color(0.69, 0.78, 0.91, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
	style.shadow_size = 22
	style.shadow_offset = Vector2(0, 8)
	return style


func _ornament(texture: Texture2D, size: Vector2) -> TextureRect:
	var ornament := TextureRect.new()
	ornament.texture = texture
	ornament.custom_minimum_size = size
	ornament.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ornament.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ornament


func _style_button(button: Button, font_size: int) -> void:
	button.add_theme_font_override("font", MENU_FONT)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(0.78, 0.86, 0.97))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _return_to_menu() -> void:
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, 0.4).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	var error := get_tree().change_scene_to_file(MENU_SCENE)
	if error != OK:
		push_error("No se pudo volver al menú principal.")
