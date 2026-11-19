extends Node2D

const STYLED_DIALOG_SCRIPT: Script = preload("res://scene/scripts/styled_dialog.gd")

const BATTLE_SCENE: String = "res://scene/BattleCastle.tscn"

@onready var dialogue_panel: Control = $CanvasLayer/DialoguePanel
@onready var dialogue_label: Label = \
	$CanvasLayer/DialoguePanel/DialogueLabel

var dialogue_open: bool = false
var dialogue_action: String = ""


func _ready() -> void:
	GameManager.save_lobby_checkpoint(1)
	if has_node("Spawn") and has_node("Player2"):
		$Player2.global_position = $Spawn.global_position

	dialogue_panel.hide()
	_style_dialogue_panel()

	$King.interacted.connect(_on_king_interacted)
	if has_node("Princesa"):
		$Princesa.interacted.connect(_on_princess_interacted)
	$ForestPortal.interacted.connect(_on_forest_portal_interacted)

	# Mostrar una sola vez al volver tras completar el castillo
	if GameManager.consume_forest_notice():
		var notice = STYLED_DIALOG_SCRIPT.new()
		notice.title = "Nuevo destino desbloqueado"
		notice.dialog_text = \
			"¡Has completado el desafío del castillo! Acércate a la puerta superior y pulsa J para ir al bosque."
		add_child(notice)
		notice.popup_centered()


func _style_dialogue_panel() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.028, 0.075, 0.96)
	style.border_color = Color(0.69, 0.78, 0.92, 0.96)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	dialogue_panel.add_theme_stylebox_override("panel", style)
	dialogue_label.add_theme_font_override("font", preload("res://assets/ttf/TiejiliSC-Regular.ttf"))
	dialogue_label.add_theme_color_override("font_color", Color(0.88, 0.92, 0.98))


func _on_king_interacted() -> void:
	if dialogue_open:
		return

	dialogue_open = true
	dialogue_action = "battle"
	dialogue_label.text = \
		"Rey: Valiente, ve al campo de batalla y supera el desafío. Pulsa J para continuar."
	dialogue_panel.show()


func _on_forest_portal_interacted() -> void:
	if GameManager.is_lobby_unlocked(2):
		GameManager.go_to_lobby(2)
		return

	if dialogue_open:
		return

	dialogue_open = true
	dialogue_action = "close"
	dialogue_label.text = \
		"El camino al bosque está cerrado. Completa primero el desafío del castillo."
	dialogue_panel.show()


func _on_princess_interacted() -> void:
	if dialogue_open:
		return

	dialogue_open = true
	dialogue_action = "close"

	var unlocked_lobby: int = int(
		GameManager.current_progress.get("unlocked_lobby", 1)
	)
	if unlocked_lobby >= 3:
		dialogue_label.text = "Princesa: Has superado los desafíos del castillo y del bosque. Solo queda la cueva; completa esa última prueba y nuestra promesa seguirá en pie."
	elif unlocked_lobby >= 2:
		dialogue_label.text = "Princesa: Has vencido a los 20 monstruos del castillo. El bosque aún te espera; supera también su desafío y nuestra promesa seguirá en pie."
	else:
		dialogue_label.text = "Princesa: Si derrotas a los 20 monstruos del castillo, me casaré contigo. ¡Demuestra tu valor!"

	dialogue_panel.show()


func _unhandled_input(event: InputEvent) -> void:
	if not dialogue_open or not event.is_action_pressed("interact"):
		return

	dialogue_panel.hide()
	dialogue_open = false

	if dialogue_action == "battle":
		get_tree().change_scene_to_file(BATTLE_SCENE)

	dialogue_action = ""
