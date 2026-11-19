
extends Button

@onready var left_decoration: TextureRect = $LeftDecoration
@onready var right_decoration: TextureRect = $RightDecoration

var mouse_is_over: bool = false
var has_keyboard_focus: bool = false


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)

	add_theme_color_override("font_color", Color("#C7D5E8"))
	add_theme_color_override("font_hover_color", Color("#FFFFFF"))
	add_theme_color_override("font_focus_color", Color("#FFFFFF"))
	add_theme_color_override("font_pressed_color", Color("#FFFFFF"))

	_update_decoration()


func _on_mouse_entered() -> void:
	mouse_is_over = true
	_update_decoration()


func _on_mouse_exited() -> void:
	mouse_is_over = false
	_update_decoration()


func _on_focus_entered() -> void:
	has_keyboard_focus = true
	_update_decoration()


func _on_focus_exited() -> void:
	has_keyboard_focus = false
	_update_decoration()


func _update_decoration() -> void:
	var is_selected := mouse_is_over or has_keyboard_focus

	left_decoration.visible = is_selected
	right_decoration.visible = is_selected
