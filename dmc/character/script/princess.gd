extends Area2D

signal interacted

@onready var prompt: TextureRect = $TextureRect

func _ready() -> void:
	add_to_group("lobby_interactable")
	prompt.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		prompt.hide()
