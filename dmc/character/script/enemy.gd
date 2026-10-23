extends CharacterBody2D

signal enemy_judged(action_type: String, enemy_value: float, enemy_position: Vector2)
signal player_contacted

@export var speed: float = 100.0
@export var contact_distance: float = 32.0
@export var contact_cooldown: float = 0.8
@export var knockback_force: float = 1000.0
@export var knockback_deceleration: float = 1800.0

@export var enemy_bump_distance: float = 50.0
@export var enemy_bump_force: float = 350.0
@export var enemy_bump_cooldown: float = 0.25

@onready var visual_root: Node2D = $VisualRoot
@onready var enemy_sprite: AnimatedSprite2D = $VisualRoot/Sprite2D

var player: Node2D = null
var decimal_value: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var contact_timer: float = 0.0
var enemy_bump_timer: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	enemy_sprite.play("move")


func setup(
	target_player: Node2D,
	decimal_val: float,
	_is_correct: bool,
	speed_multiplier: float
) -> void:
	player = target_player
	decimal_value = decimal_val
	speed *= speed_multiplier
	$ValueLabel.text = str(decimal_value)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	contact_timer = maxf(0.0, contact_timer - delta)
	enemy_bump_timer = maxf(0.0, enemy_bump_timer - delta)

	if knockback_velocity.length() > 10.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(
			Vector2.ZERO,
			knockback_deceleration * delta
		)
	else:
		# Perseguir al jugador en línea directa
		var direction: Vector2 = global_position.direction_to(
			player.global_position
		)
		velocity = direction * speed

	_update_facing()
	move_and_slide()
	_check_enemy_bump()
	_check_player_contact()


func _update_facing() -> void:
	if velocity.x > 0.1:
		visual_root.scale.x = 1.0
	elif velocity.x < -0.1:
		visual_root.scale.x = -1.0


func _check_enemy_bump() -> void:
	if enemy_bump_timer > 0.0:
		return

	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self or not other.has_method("apply_enemy_bump"):
			continue

		var other_node := other as Node2D
		if other_node == null:
			continue

		var offset: Vector2 = global_position - other_node.global_position
		var distance: float = offset.length()

		if distance >= enemy_bump_distance:
			continue

		var direction_away: Vector2

		if distance > 0.001:
			direction_away = offset / distance
		elif get_instance_id() < other.get_instance_id():
			direction_away = Vector2.LEFT
		else:
			direction_away = Vector2.RIGHT

		# Empujar a ambos enemigos en direcciones opuestas
		apply_enemy_bump(direction_away, enemy_bump_force, enemy_bump_cooldown)
		other.call(
			"apply_enemy_bump",
			-direction_away,
			enemy_bump_force,
			enemy_bump_cooldown
		)
		return


func apply_enemy_bump(
	direction: Vector2,
	force: float,
	cooldown: float
) -> void:
	knockback_velocity = direction.normalized() * force
	enemy_bump_timer = cooldown


func _check_player_contact() -> void:
	if contact_timer > 0.0:
		return

	if global_position.distance_to(player.global_position) > contact_distance:
		return

	var direction_away: Vector2 = global_position - player.global_position

	if direction_away.length_squared() == 0.0:
		direction_away = Vector2.UP
	else:
		direction_away = direction_away.normalized()

	knockback_velocity = direction_away * knockback_force
	contact_timer = contact_cooldown
	player_contacted.emit()


func receive_attack(action_type: String) -> void:
	enemy_judged.emit(action_type, decimal_value, global_position)
	queue_free()
