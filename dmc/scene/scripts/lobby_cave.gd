extends Node2D

const BATTLE_SCENE: String = "res://scene/BattleCave.tscn"

@onready var dialogue_panel: Control = $CanvasLayer/DialoguePanel
@onready var dialogue_label: Label = $CanvasLayer/DialoguePanel/DialogueLabel

var dialogue_open: bool = false
var dialogue_action: String = ""


func _ready() -> void:
	GameManager.save_lobby_checkpoint(3)

	dialogue_panel.hide()

	$King.interacted.connect(_on_king_interacted)
	if has_node("Princesa"):
		$Princesa.interacted.connect(_on_princess_interacted)
	$ForestPortal.interacted.connect(_on_forest_portal_interacted)


func _on_king_interacted() -> void:
	if dialogue_open:
		return

	dialogue_open = true
	dialogue_action = "battle"
	dialogue_label.text = \
		"Rey: Has llegado a la cueva. Prepárate para el desafío final. Pulsa J para continuar."
	dialogue_panel.show()


func _on_forest_portal_interacted() -> void:
	GameManager.go_to_lobby(2)


func _on_princess_interacted() -> void:
	if dialogue_open:
		return

	dialogue_open = true
	dialogue_action = "close"
	dialogue_label.text = "Princesa: Esta es la última prueba. Si derrotas a los 20 monstruos de la cueva, cumpliré mi promesa. ¡Buena suerte!"
	dialogue_panel.show()


func _unhandled_input(event: InputEvent) -> void:
	if not dialogue_open or not event.is_action_pressed("interact"):
		return

	dialogue_panel.hide()
	dialogue_open = false

	if dialogue_action == "battle":
		get_tree().change_scene_to_file(BATTLE_SCENE)

	dialogue_action = ""
