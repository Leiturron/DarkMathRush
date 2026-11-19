extends CharacterBody2D

const SPEED: float = 500.0
const PAUSE_MENU_SCRIPT: Script = preload("res://scene/scripts/pause_menu.gd")

@export var damage_flash_duration: float = 0.5

@onready var player_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var interaction_area: Area2D = $InteractionArea


@onready var attack1_sound: AudioStreamPlayer2D = $Attack1Sound
@onready var attack2_sound: AudioStreamPlayer2D = $Attack2Sound
@onready var take_damage_sound: AudioStreamPlayer2D = $TakeDamageSound
@onready var run_sound: AudioStreamPlayer2D = $RunSound

var is_attacking: bool = false
var is_taking_damage: bool = false
var current_attack_type: String = ""
var has_hit_enemy: bool = false
var nearby_interactables: Array[Area2D] = []
var damage_tween: Tween


func _ready() -> void:
	add_to_group("player")
	player_sprite.animation_finished.connect(_on_animation_finished)
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	player_sprite.play("Idle")
	call_deferred("_install_pause_menu")


func _install_pause_menu() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return

	var is_battle_scene: bool = false
	var lobby_path: String = ""

	match current_scene.name:
		"LobbyCastle", "LobbyForest", "LobbyCave":
			pass
		"BattleCastle":
			is_battle_scene = true
			lobby_path = "res://scene/LobbyCastle.tscn"
		"BattleForest":
			is_battle_scene = true
			lobby_path = "res://scene/LobbyForest.tscn"
		"BattleCave":
			is_battle_scene = true
			lobby_path = "res://scene/LobbyCave.tscn"
		_:
			return

	if current_scene.has_node("PauseMenu"):
		return

	var pause_menu := CanvasLayer.new()
	pause_menu.name = "PauseMenu"
	pause_menu.set_script(PAUSE_MENU_SCRIPT)
	pause_menu.call("configure", is_battle_scene, lobby_path)
	current_scene.add_child(pause_menu)


func _physics_process(_delta: float) -> void:
	var direction_x := Input.get_axis("move_left", "move_right")
	var direction_y := Input.get_axis("move_up", "move_down")
	var direction := Vector2(direction_x, direction_y).normalized()

	if direction != Vector2.ZERO:
		if not run_sound.playing:
			run_sound.play()
	else:
		run_sound.stop()
	
	velocity = direction * SPEED
	move_and_slide()

	if direction_x > 0:
		player_sprite.flip_h = false
		hitbox.rotation_degrees = 0
	elif direction_x < 0:
		player_sprite.flip_h = true
		hitbox.rotation_degrees = 180
	elif direction_y > 0:
		hitbox.rotation_degrees = 90
	elif direction_y < 0:
		hitbox.rotation_degrees = -90

	if Input.is_action_just_pressed("interact") and _is_lobby_scene():
		_interact()
	elif not _is_lobby_scene() and not is_taking_damage:
		if Input.is_action_just_pressed("attack_correct"):
			_start_attack("correct")
		elif Input.is_action_just_pressed("attack_wrong"):
			_start_attack("wrong")

	if is_taking_damage:
		return

	if is_attacking:
		_check_attack_hits()
	else:
		if direction != Vector2.ZERO:
			player_sprite.play("Run")
		else:
			player_sprite.play("Idle")


func _start_attack(action_type: String) -> void:
	if is_attacking or is_taking_damage:
		return

	is_attacking = true
	current_attack_type = action_type
	has_hit_enemy = false

	if action_type == "correct":
		attack1_sound.play()
		player_sprite.play("Attack1")
	else:
		attack2_sound.play()
		player_sprite.play("Attack2")


func _check_attack_hits() -> void:
	# This attack can only judge one enemy, even if others enter the hitbox
	# while the attack animation is still playing.
	if has_hit_enemy:
		return

	var enemies_in_range: Array[Node2D] = []

	for body in hitbox.get_overlapping_bodies():
		if body is Node2D and body.is_in_group("enemies"):
			enemies_in_range.append(body as Node2D)

	var nearest_enemy: Node2D = null
	var nearest_distance: float = INF

	for enemy in enemies_in_range:
		var distance := global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy

	if nearest_enemy != null:
		has_hit_enemy = true

		if nearest_enemy.has_method("receive_attack"):
			nearest_enemy.receive_attack(current_attack_type)


func _on_animation_finished() -> void:
	if player_sprite.animation == "Attack1" \
	or player_sprite.animation == "Attack2":
		is_attacking = false
		current_attack_type = ""
		has_hit_enemy = false

	elif player_sprite.animation == "Recive":
		is_taking_damage = false
		player_sprite.modulate = Color.WHITE
		_play_movement_animation()


func _play_movement_animation() -> void:
	var direction := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	if direction.length_squared() > 0.0:
		player_sprite.play("Run")
	else:
		player_sprite.play("Idle")


func _on_interaction_area_entered(area: Area2D) -> void:
	if area.is_in_group("lobby_interactable"):
		nearby_interactables.append(area)


func _on_interaction_area_exited(area: Area2D) -> void:
	nearby_interactables.erase(area)


func _interact() -> void:
	var closest: Area2D = null
	var closest_distance: float = INF

	for target in nearby_interactables:
		if not is_instance_valid(target):
			continue

		var distance := global_position.distance_to(target.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = target

	if closest != null and closest.has_signal("interacted"):
		closest.emit_signal("interacted")


func _is_lobby_scene() -> bool:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false

	return current_scene.name.to_lower().begins_with("lobby")


func play_damage_flash() -> void:
	if damage_tween and damage_tween.is_running():
		damage_tween.kill()

	is_taking_damage = true
	is_attacking = false
	current_attack_type = ""
	has_hit_enemy = false

	player_sprite.modulate = Color(1.0, 0.25, 0.25, 1.0)
	player_sprite.play("Recive")

	damage_tween = create_tween()
	damage_tween.tween_property(
		player_sprite,
		"modulate",
		Color.WHITE,
		damage_flash_duration
	)
	attack1_sound.stop()
	attack2_sound.stop()

	take_damage_sound.stop()
	take_damage_sound.play()
