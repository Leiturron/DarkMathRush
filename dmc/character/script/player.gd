extends CharacterBody2D

const SPEED = 500.0

@onready var player_sprite: AnimatedSprite2D = $VisualRoot/Sprite2D
@onready var visual_root: Node2D = $VisualRoot
@onready var interaction_area: Area2D = $InteractionArea

@export var damage_flash_duration: float = 0.50

var damage_tween: Tween
var is_attacking: bool = false
var current_attack_type: String = ""
var has_hit_enemy: bool = false
var nearby_interactables: Array[Area2D] = []


func _ready() -> void:
	player_sprite.animation_finished.connect(_on_sprite_animation_finished)
	player_sprite.play("idle")

	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)


func _physics_process(_delta: float) -> void:
	var direction_x := Input.get_axis("ui_left", "ui_right")
	var direction_y := Input.get_axis("ui_up", "ui_down")
	var direction := Vector2(direction_x, direction_y).normalized()

	velocity = direction * SPEED
	move_and_slide()

	# Actualizar la orientación del personaje y del área de ataque
	if direction_x > 0:
		visual_root.scale.x = 1.0
		$Hitbox.rotation_degrees = 0
	elif direction_x < 0:
		visual_root.scale.x = -1.0
		$Hitbox.rotation_degrees = 180
	elif direction_y > 0:
		$Hitbox.rotation_degrees = 90
	elif direction_y < 0:
		$Hitbox.rotation_degrees = -90

	if _is_lobby_scene():
		# En el lobby, J sirve para interactuar
		if Input.is_action_just_pressed("interact"):
			_interact()
	else:
		# En combate se mantienen los controles de ataque
		if Input.is_action_just_pressed("attack_correct"):
			_start_attack("correct")
		elif Input.is_action_just_pressed("attack_wrong"):
			_start_attack("wrong")

	if is_attacking:
		_check_attack_hits()
	else:
		if direction != Vector2.ZERO:
			player_sprite.play("move")
		else:
			player_sprite.play("idle")


func _is_lobby_scene() -> bool:
	var scene_name := get_tree().current_scene.name.to_lower()
	return scene_name.begins_with("lobby")


func _on_interaction_area_entered(area: Area2D) -> void:
	if area.is_in_group("lobby_interactable"):
		nearby_interactables.append(area)


func _on_interaction_area_exited(area: Area2D) -> void:
	nearby_interactables.erase(area)


func _interact() -> void:
	if nearby_interactables.is_empty():
		return

	var target := nearby_interactables[0]
	if is_instance_valid(target) and target.has_signal("interacted"):
		target.emit_signal("interacted")


func _start_attack(action_type: String) -> void:
	if is_attacking:
		return

	is_attacking = true
	current_attack_type = action_type
	has_hit_enemy = false
	player_sprite.play("attack")


func _check_attack_hits() -> void:
	if has_hit_enemy:
		return

	var enemies_in_range: Array = $Hitbox.get_overlapping_bodies()
	var nearest_enemy: Node2D = null
	var min_dist: float = INF

	# Buscar al enemigo más cercano dentro del área de ataque
	for body in enemies_in_range:
		if not body.is_in_group("enemies"):
			continue

		var distance: float = global_position.distance_to(body.global_position)
		if distance < min_dist:
			min_dist = distance
			nearest_enemy = body

	if nearest_enemy != null:
		# Limitar cada ataque a un solo enemigo
		has_hit_enemy = true
		nearest_enemy.receive_attack(current_attack_type)


func _on_sprite_animation_finished() -> void:
	if player_sprite.animation == "attack":
		is_attacking = false
		current_attack_type = ""
		has_hit_enemy = false


func play_damage_flash() -> void:
	if damage_tween and damage_tween.is_running():
		damage_tween.kill()

	player_sprite.modulate = Color(1.0, 0.25, 0.25, 1.0)

	damage_tween = create_tween()
	damage_tween.tween_property(
		player_sprite,
		"modulate",
		Color.WHITE,
		damage_flash_duration
	)
