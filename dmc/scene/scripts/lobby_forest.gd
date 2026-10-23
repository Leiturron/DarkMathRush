extends Node2D

const BATTLE_SCENE: String = "res://scene/BattleForest.tscn"

@onready var dialogue_panel: Control = $CanvasLayer/DialoguePanel
@onready var dialogue_label: Label = $CanvasLayer/DialoguePanel/DialogueLabel

var dialogue_open: bool = false
var dialogue_action: String = ""


func _ready() -> void:
	GameManager.save_lobby_checkpoint(2)

	dialogue_panel.hide()

	$King.interacted.connect(_on_king_interacted)
	if has_node("Princesa"):
		$Princesa.interacted.connect(_on_princess_interacted)
	$CastlePortal.interacted.connect(_on_castle_portal_interacted)
	$CavePortal.interacted.connect(_on_cave_portal_interacted)

	# Mostrar una sola vez al volver tras completar el bosque
	if GameManager.consume_cave_notice():
		var notice := AcceptDialog.new()
		notice.title = "Nuevo destino desbloqueado"
		notice.dialog_text = "¡Has completado el desafío del bosque! Acércate a la salida de la cueva y pulsa J para continuar."
		add_child(notice)
		notice.popup_centered()


func _on_king_interacted() -> void:
	if dialogue_open:
		return

	dialogue_open = true
	dialogue_action = "battle"
	dialogue_label.text = "Rey: Ahora te espera el desafío del bosque. Pulsa J para continuar."
	dialogue_panel.show()


func _on_castle_portal_interacted() -> void:
	GameManager.go_to_lobby(1)


func _on_cave_portal_interacted() -> void:
	if GameManager.is_lobby_unlocked(3):
		GameManager.go_to_lobby(3)
		return

	if dialogue_open:
		return

	dialogue_open = true
	dialogue_action = "close"
	dialogue_label.text = "El camino a la cueva está cerrado. Completa primero el desafío del bosque."
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
		dialogue_label.text = "Princesa: Has superado el desafío del bosque. Solo queda la cueva; completa la última prueba y nuestra promesa seguirá en pie."
	else:
		dialogue_label.text = "Princesa: Ya venciste a los monstruos del castillo. Si derrotas a los 20 monstruos del bosque, estarás un paso más cerca de nuestra promesa."

	dialogue_panel.show()


func _unhandled_input(event: InputEvent) -> void:
	if not dialogue_open or not event.is_action_pressed("interact"):
		return

	dialogue_panel.hide()
	dialogue_open = false

	if dialogue_action == "battle":
		get_tree().change_scene_to_file(BATTLE_SCENE)

	dialogue_action = ""
