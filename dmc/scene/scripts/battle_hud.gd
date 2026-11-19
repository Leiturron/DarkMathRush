extends RefCounted

const HEART_TEXTURE: Texture2D = preload("res://assets/heart.png")
const MAX_HEALTH: int = 3


static func install(ui: CanvasLayer) -> void:
	if ui.get_node_or_null("LivesDisplay") == null:
		var lives := HBoxContainer.new()
		lives.name = "LivesDisplay"
		lives.position = Vector2(18.0, 582.0)
		lives.size = Vector2(240.0, 72.0)
		lives.add_theme_constant_override("separation", 8)
		ui.add_child(lives)

		for index in MAX_HEALTH:
			var heart := TextureRect.new()
			heart.name = "Heart%d" % index
			heart.texture = HEART_TEXTURE
			heart.custom_minimum_size = Vector2(68.0, 68.0)
			heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			lives.add_child(heart)

	var health_label := ui.get_node_or_null("HealthLabel")
	if health_label is CanvasItem:
		health_label.hide()

	if ui.get_node_or_null("ScoreLabel") is Label:
		var score_label := ui.get_node("ScoreLabel") as Label
		score_label.position = Vector2(900.0, 578.0)
		score_label.size = Vector2(360.0, 80.0)
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	if ui.get_node_or_null("QuestionExpression") == null:
		var expression := HBoxContainer.new()
		expression.name = "QuestionExpression"
		expression.position = Vector2(36.0, 18.0)
		expression.size = Vector2(1208.0, 112.0)
		expression.alignment = BoxContainer.ALIGNMENT_CENTER
		expression.add_theme_constant_override("separation", 5)
		ui.add_child(expression)
		expression.hide()


static func update_health(ui: CanvasLayer, health: int) -> void:
	install(ui)
	var lives := ui.get_node("LivesDisplay") as HBoxContainer
	for index in MAX_HEALTH:
		var heart := lives.get_node("Heart%d" % index) as TextureRect
		heart.modulate = Color.WHITE if index < health else Color(0.32, 0.32, 0.38, 0.65)


static func display_question(ui: CanvasLayer, question_text: String) -> void:
	install(ui)
	var question_label := ui.get_node("QuestionLabel") as Label
	var expression := ui.get_node("QuestionExpression") as HBoxContainer
	question_label.position = Vector2(36.0, 18.0)
	question_label.size = Vector2(1208.0, 112.0)
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	question_label.add_theme_font_size_override(
		"font_size",
		38 if question_text.length() > 24 else 52
	)
	var regex := RegEx.new()
	# Keep every symbol in the original question; render only numeric a/b tokens
	# as stacked fractions instead of dropping unrecognized operators.
	regex.compile("\\d+(?:\\.\\d+)?\\s*/\\s*\\d+(?:\\.\\d+)?|\\d+(?:\\.\\d+)?|.")
	var tokens := regex.search_all(question_text)

	var has_fraction := false
	for token in tokens:
		if token.get_string().contains("/"):
			has_fraction = true
			break

	if not has_fraction:
		question_label.show()
		expression.hide()
		return

	question_label.hide()
	for child in expression.get_children():
		expression.remove_child(child)
		child.queue_free()

	for token_match in tokens:
		var token := token_match.get_string()
		if token.strip_edges().is_empty():
			var word_space := Control.new()
			word_space.custom_minimum_size = Vector2(9.0, 1.0)
			expression.add_child(word_space)
			continue

		if token.contains("/"):
			var parts := token.split("/")
			var fraction := VBoxContainer.new()
			fraction.custom_minimum_size = Vector2(68.0, 90.0)
			fraction.alignment = BoxContainer.ALIGNMENT_CENTER
			fraction.add_theme_constant_override("separation", -5)
			fraction.add_child(_make_expression_label(parts[0].strip_edges(), 30))

			var line := ColorRect.new()
			line.color = Color.WHITE
			line.custom_minimum_size = Vector2(62.0, 3.0)
			fraction.add_child(line)
			fraction.add_child(_make_expression_label(parts[1].strip_edges(), 30))
			expression.add_child(fraction)
		else:
			expression.add_child(_make_expression_label(token, 36))

	expression.show()


static func _make_expression_label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label
