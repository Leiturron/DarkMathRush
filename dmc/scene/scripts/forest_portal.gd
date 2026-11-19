extends Area2D

signal interacted

@onready var prompt: TextureRect = get_node_or_null("TextureRect") as TextureRect


func _ready() -> void:
	add_to_group("lobby_interactable")
	if prompt != null:
		prompt.hide()
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if prompt != null and body.is_in_group("player"):
		prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if prompt != null and body.is_in_group("player"):
		prompt.hide()
