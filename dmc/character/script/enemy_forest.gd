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
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var dead_sound: AudioStreamPlayer2D = $DeadSound
@onready var value_label: Label = $ValueLabel

var player: Node2D = null
var decimal_value: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var contact_timer: float = 0.0
var enemy_bump_timer: float = 0.0
var is_dead: bool = false
var fraction_value_display: VBoxContainer


func _ready() -> void:
	add_to_group("enemies")
	enemy_sprite.animation_finished.connect(_on_animation_finished)
	enemy_sprite.play("move")
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 8.0


func setup(
	target_player: Node2D,
	decimal_val: float,
	_is_correct: bool,
	speed_multiplier: float,
	answer_display: String = ""
) -> void:
	player = target_player
	decimal_value = decimal_val
	speed *= speed_multiplier
	_set_value_display(answer_display if not answer_display.is_empty() else str(decimal_value))


func _set_value_display(display_text: String) -> void:
	if not display_text.contains("/"):
		value_label.text = display_text
		value_label.show()
		if is_instance_valid(fraction_value_display):
			fraction_value_display.queue_free()
		return

	var fraction_parts := display_text.split("/")
	if fraction_parts.size() != 2:
		value_label.text = display_text
		value_label.show()
		return

	value_label.hide()
	if is_instance_valid(fraction_value_display):
		fraction_value_display.queue_free()

	fraction_value_display = VBoxContainer.new()
	fraction_value_display.name = "FractionValueDisplay"
	fraction_value_display.anchors_preset = Control.PRESET_CENTER
	fraction_value_display.anchor_left = 0.5
	fraction_value_display.anchor_top = 0.5
	fraction_value_display.anchor_right = 0.5
	fraction_value_display.anchor_bottom = 0.5
	fraction_value_display.offset_left = -285.714
	fraction_value_display.offset_top = -700.0
	fraction_value_display.offset_right = 284.286
	fraction_value_display.offset_bottom = -248.0
	fraction_value_display.grow_horizontal = Control.GROW_DIRECTION_BOTH
	fraction_value_display.grow_vertical = Control.GROW_DIRECTION_BOTH
	fraction_value_display.alignment = BoxContainer.ALIGNMENT_CENTER
	fraction_value_display.add_theme_constant_override("separation", -12)

	var numerator := _make_fraction_part(fraction_parts[0].strip_edges())
	fraction_value_display.add_child(numerator)

	var line := ColorRect.new()
	line.color = Color.WHITE
	line.custom_minimum_size = Vector2(220.0, 7.0)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	fraction_value_display.add_child(line)

	var denominator := _make_fraction_part(fraction_parts[1].strip_edges())
	fraction_value_display.add_child(denominator)
	add_child(fraction_value_display)


func _make_fraction_part(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 180)
	return label


func _physics_process(delta: float) -> void:
	if is_dead:
		return

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
		navigation_agent.target_position = player.global_position

		if not navigation_agent.is_navigation_finished():
			var next_position: Vector2 = navigation_agent.get_next_path_position()
			var direction: Vector2 = global_position.direction_to(next_position)
			velocity = direction * speed
		else:
			velocity = Vector2.ZERO

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
	dead_sound.play()
	if is_dead:
		return

	is_dead = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	enemy_judged.emit(action_type, decimal_value, global_position)
	remove_from_group("enemies")
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	$CollisionShape2D.set_deferred("disabled", true)

	if enemy_sprite.sprite_frames != null \
	and enemy_sprite.sprite_frames.has_animation("Dead"):
		enemy_sprite.sprite_frames.set_animation_loop("Dead", false)
		enemy_sprite.play("Dead")
	else:
		queue_free()


func _on_animation_finished() -> void:
	if is_dead and enemy_sprite.animation == "Dead":
		queue_free()
