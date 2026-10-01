extends CharacterBody2D

const SPEED = 300.0

func _physics_process(_delta):
	# 基础的上下左右移动
	var direction_x = Input.get_axis("ui_left", "ui_right")
	var direction_y = Input.get_axis("ui_up", "ui_down")
	
	velocity = Vector2(direction_x, direction_y).normalized() * SPEED
	move_and_slide()
	
	# --- 修改后的四方向攻击范围逻辑 ---
	if direction_x > 0:
		# 往右走
		$Sprite2D.flip_h = false
		$Hitbox.rotation_degrees = 0    # 攻击圆圈转到右边 (0度)
	elif direction_x < 0:
		# 往左走
		$Sprite2D.flip_h = true
		$Hitbox.rotation_degrees = 180  # 攻击圆圈转到左边 (180度)
	elif direction_y > 0:
		# 往下走
		$Hitbox.rotation_degrees = 90   # 攻击圆圈转到下边 (90度)
	elif direction_y < 0:
		# 往上走
		$Hitbox.rotation_degrees = -90  # 攻击圆圈转到上边 (-90度)
	# -------------------------
	
	# 攻击输入检测
	if Input.is_action_just_pressed("attack_correct"):
		_attack("correct")
	elif Input.is_action_just_pressed("attack_wrong"):
		_attack("wrong")

func _attack(action_type: String):
	# 获取 Hitbox 圆圈内的所有物理体
	var enemies_in_range = $Hitbox.get_overlapping_bodies()
	var nearest_enemy = null
	var min_dist = INF
	
	# 遍历寻找距离最近的敌人
	for body in enemies_in_range:
		if body.is_in_group("enemies"): # 确保打中的是怪物
			var dist = global_position.distance_to(body.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest_enemy = body
				
	# 如果范围内有敌人，向最近的敌人发送判定请求
	if nearest_enemy != null:
		nearest_enemy.receive_attack(action_type)
