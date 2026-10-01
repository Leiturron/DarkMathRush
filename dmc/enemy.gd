extends CharacterBody2D

# 现在的信号直接发送：玩家按了什么键(action_type) 和 怪物的数值(enemy_value)
signal enemy_judged(action_type: String, enemy_value: float)

var speed = 100.0
var player: Node2D = null
var decimal_value: float = 0.0 # 怪物要把自己的数值记下来

func setup(target_player: Node2D, decimal_val: float, is_correct: bool, speed_multiplier: float):
	player = target_player
	decimal_value = decimal_val # 记录数值
	speed *= speed_multiplier
	$ValueLabel.text = str(decimal_val)

func _physics_process(_delta):
	if player:
		# 自动追踪玩家
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * speed
		move_and_slide()

# 接收玩家的攻击判定
func receive_attack(action_type: String):
	# 怪物自己不做判断了，直接把按键类型和自己的数值扔给 Main 去裁决！
	enemy_judged.emit(action_type, decimal_value)
	queue_free()
