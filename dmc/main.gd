extends Node2D

@export var enemy_scene: PackedScene # 我们将在编辑器里把enemy.tscn拖到这里

var health = 3
var score = 0
var kills = 0
var current_phase = 1
var speed_multiplier = 1.0
var current_correct_decimal: float = 0.0
var last_question_text = ""

# 现在变成了空字典，等待从 txt 导入
var questions_oa1 = {}
var questions_oa2 = {}
var questions_oa3 = {}
var current_question_set = []

func _ready():
	# 游戏启动时，分别读取三个 txt 文件
	questions_oa1 = load_questions_from_txt("res://preguntaFase1.txt")
	#questions_oa2 = load_questions_from_txt("res://oa2.txt")
	#questions_oa3 = load_questions_from_txt("res://oa3.txt")
	
	load_phase_questions()
	update_ui()
	generate_new_question()

# --- 新增的核心读取函数 ---
func load_questions_from_txt(file_path: String) -> Dictionary:
	var loaded_dict = {}
	
	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		print("找不到文件: ", file_path)
		return loaded_dict
		
	# 以只读模式打开文件 (Godot 4.x 的写法)
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	# 循环读取每一行，直到文件末尾
	while not file.eof_reached():
		var line = file.get_line().strip_edges() # 读取一行并去掉首尾空格
		
		# 跳过空行或者用 # 开头的注释行
		if line.is_empty() or line.begins_with("#"):
			continue 
			
		# 用 "|" 分割这一行数据
		var parts = line.split("|")
		
		# 确保这行正好有 4 个部分 (题目|正答|错1|错2)
		if parts.size() >= 4:
			var q_text = parts[0]
			# 把后面的字符串转换成浮点数 (float)
			var correct_ans = parts[1].to_float()
			var wrong1 = parts[2].to_float()
			var wrong2 = parts[3].to_float()
			
			# 存入字典
			loaded_dict[q_text] = [correct_ans, wrong1, wrong2]
			
	file.close() # 养成好习惯，读完关掉文件
	return loaded_dict
# -----------------------------

# 根据阶段加载题库
func load_phase_questions():
	if current_phase == 1:
		current_question_set = questions_oa1.keys()
	elif current_phase == 2:
		current_question_set = questions_oa2.keys()
	elif current_phase == 3:
		current_question_set = questions_oa3.keys()

# 抽取新题
func generate_new_question():
	var q_text = current_question_set.pick_random()
	$UI/QuestionLabel.text = q_text
	
	# 根据阶段找到对应的字典提取答案
	if current_phase == 1: current_correct_decimal = questions_oa1[q_text][0]
	elif current_phase == 2: current_correct_decimal = questions_oa2[q_text][0]
	elif current_phase == 3: current_correct_decimal = questions_oa3[q_text][0]

# 刷怪定时器触发
func _on_spawn_timer_timeout():
	var enemy = enemy_scene.instantiate()
	
	# 在玩家周围随机生成坐标
	var spawn_radius = 600
	var random_angle = randf() * PI * 2
	enemy.global_position = $Player.global_position + Vector2(cos(random_angle), sin(random_angle)) * spawn_radius
	
	# 30%概率刷出正确答案怪物，70%概率刷错误答案怪物
	var is_correct = randf() < 0.3
	var val_to_show = 0.0
	
	var q_text = $UI/QuestionLabel.text
	var dict_ref = questions_oa1
	if current_phase == 2: dict_ref = questions_oa2
	elif current_phase == 3: dict_ref = questions_oa3
	
	if is_correct:
		val_to_show = current_correct_decimal
	else:
		# 从题库的错误选项中随机挑一个
		val_to_show = dict_ref[q_text].pick_random()
		while val_to_show == current_correct_decimal: # 确保不是正确答案
			val_to_show = dict_ref[q_text].pick_random()
			
	# 初始化怪物，并连接判定信号
	enemy.setup($Player, val_to_show, is_correct, speed_multiplier)
	enemy.enemy_judged.connect(_on_enemy_judged)
	add_child(enemy)

# 接收怪物的判定请求 (Main作为唯一裁判)
func _on_enemy_judged(action_type: String, enemy_value: float):
	var is_successful = false
	
	# 核心改动：在挨打的这一瞬间，拿怪物的数值和【当前的正确答案】做对比
	var is_this_correct_answer = (enemy_value == current_correct_decimal)
	
	# 逻辑判断：(按J且数值对上了) 或 (按K且数值没对上)
	if action_type == "correct" and is_this_correct_answer:
		is_successful = true
	elif action_type == "wrong" and not is_this_correct_answer:
		is_successful = true

	# 结算结果
	if is_successful:
		kills += 1
		score += 10
		check_progression()
		
		# 只有用J键打中了真正符合当前题目的怪物，才换题
		if action_type == "correct" and is_this_correct_answer:
			generate_new_question()
			
	else:
		health -= 1
		if health <= 0:
			print("Derrota! (游戏结束)")
			get_tree().paused = true # 暂停游戏
			
	update_ui()

# 检查是否需要增加难度阶段
func check_progression():
	if kills == 60:
		print("Victoria! ")
		get_tree().paused = true
		
	#elif kills == 20 and current_phase == 1:
		#current_phase = 2
		#speed_multiplier *= 1.2
		#$SpawnTimer.wait_time *= 0.8 # 加快刷怪频率
		#load_phase_questions()
		#generate_new_question() # 进阶时换题
	#elif kills == 40 and current_phase == 2:
		#current_phase = 3
		#speed_multiplier *= 1.2
		#$SpawnTimer.wait_time *= 0.8
		#load_phase_questions()
		#generate_new_question()

func update_ui():
	$UI/HealthLabel.text = "Vidas: " + str(health)
	$UI/ScoreLabel.text = "Puntaje: %d | Kills: %d" % [score, kills]
