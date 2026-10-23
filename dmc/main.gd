extends CharacterBody2D

signal enemy_judged(action_type: String, enemy_value: float)

@export var speed: float = 100.0

var player: Node2D = null
var decimal_value: float = 0.0


func setup(target_player: Node2D, decimal_val: float, speed_multiplier: float = 1.0) -> void:
	player = target_player
	decimal_value = decimal_val
	speed *= speed_multiplier
	$ValueLabel.text = str(decimal_value)


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		return

	var direction := global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()


func receive_attack(action_type: String) -> void:
	enemy_judged.emit(action_type, decimal_value)
	queue_free()
