extends Control

const MENU_SCENE: String = "res://uitest.tscn"
const MENU_FONT: Font = preload("res://assets/ttf/TiejiliSC-Regular.ttf")

@onready var page_one: Control = $MainPanelCenter/MainPanel/MainMargin/MainContent/TutorialBody/PageStack/PageOne
@onready var page_two: Control = $MainPanelCenter/MainPanel/MainMargin/MainContent/TutorialBody/PageStack/PageTwo
@onready var previous_page_button: Button = $MainPanelCenter/MainPanel/MainMargin/MainContent/TutorialBody/LeftArrowSlot/PreviousPageButton
@onready var next_page_button: Button = $MainPanelCenter/MainPanel/MainMargin/MainContent/TutorialBody/RightArrowSlot/NextPageButton
@onready var page_indicator: Label = $MainPanelCenter/MainPanel/MainMargin/MainContent/PageIndicator
@onready var fade_rect: ColorRect = $TransitionLayer/FadeRect

var current_page: int = 1
var transition_busy: bool = false


func _ready() -> void:
	$BackButton.pressed.connect(_return_to_menu)
	previous_page_button.pressed.connect(_switch_page)
	next_page_button.pressed.connect(_switch_page)
	_style_button($BackButton, 22)
	_update_page()
	fade_rect.color = Color(0.0, 0.0, 0.0, 1.0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 0.4).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


@warning_ignore("shadowed_variable_base_class")
func _style_button(button: Button, size: int) -> void:
	button.add_theme_font_override("font", MENU_FONT)
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", Color(0.78, 0.86, 0.97))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.mouse_filter = Control.MOUSE_FILTER_STOP


func _switch_page() -> void:
	if transition_busy:
		return
	transition_busy = true
	var old_page := page_one if current_page == 1 else page_two
	var new_page := page_two if current_page == 1 else page_one
	var fade_out := create_tween()
	fade_out.tween_property(old_page, "modulate:a", 0.0, 0.14)
	await fade_out.finished
	current_page = 2 if current_page == 1 else 1
	_update_page()
	new_page.modulate.a = 0.0
	var fade_in := create_tween()
	fade_in.tween_property(new_page, "modulate:a", 1.0, 0.2)
	await fade_in.finished
	transition_busy = false


func _update_page() -> void:
	page_one.visible = current_page == 1
	page_two.visible = current_page == 2
	page_one.modulate.a = 1.0
	page_two.modulate.a = 1.0
	previous_page_button.visible = current_page == 2
	next_page_button.visible = current_page == 1
	previous_page_button.mouse_filter = Control.MOUSE_FILTER_STOP
	next_page_button.mouse_filter = Control.MOUSE_FILTER_STOP
	previous_page_button.tooltip_text = "Página anterior"
	next_page_button.tooltip_text = "Siguiente página"
	page_indicator.text = "PÁGINA %d / 2" % current_page
	_update_image_hint(
		NodePath("MainPanelCenter/MainPanel/MainMargin/MainContent/TutorialBody/PageStack/PageOne/Cards/PlayerCard/CardContent/ImageFrame/PlayerImage"),
		NodePath("MainPanelCenter/MainPanel/MainMargin/MainContent/TutorialBody/PageStack/PageOne/Cards/PlayerCard/CardContent/ImageFrame/ImageHint")
	)
	_update_image_hint(
		NodePath("MainPanelCenter/MainPanel/MainMargin/MainContent/TutorialBody/PageStack/PageOne/Cards/KingCard/CardContent/ImageFrame/KingImage"),
		NodePath("MainPanelCenter/MainPanel/MainMargin/MainContent/TutorialBody/PageStack/PageOne/Cards/KingCard/CardContent/ImageFrame/ImageHint")
	)
	_update_image_hint(
		NodePath("MainPanelCenter/MainPanel/MainMargin/MainContent/TutorialBody/PageStack/PageTwo/Cards/CorrectCard/CardContent/ImageFrame/QuestionImage"),
		NodePath("MainPanelCenter/MainPanel/MainMargin/MainContent/TutorialBody/PageStack/PageTwo/Cards/CorrectCard/CardContent/ImageFrame/ImageHint")
	)
	_update_image_hint(
		NodePath("MainPanelCenter/MainPanel/MainMargin/MainContent/TutorialBody/PageStack/PageTwo/Cards/WrongCard/CardContent/ImageFrame/WrongEnemyImage"),
		NodePath("MainPanelCenter/MainPanel/MainMargin/MainContent/TutorialBody/PageStack/PageTwo/Cards/WrongCard/CardContent/ImageFrame/ImageHint")
	)
	_update_image_hint(
		NodePath("MainPanelCenter/MainPanel/MainMargin/MainContent/TutorialBody/PageStack/PageTwo/Cards/PortalCard/CardContent/ImageFrame/PortalImage"),
		NodePath("MainPanelCenter/MainPanel/MainMargin/MainContent/TutorialBody/PageStack/PageTwo/Cards/PortalCard/CardContent/ImageFrame/ImageHint")
	)


@warning_ignore("unused_parameter")
func _update_image_hint(image_path: NodePath, hint_path: NodePath) -> void:
	@warning_ignore("unused_variable")
	var image := get_node(image_path) as TextureRect

func _return_to_menu() -> void:
	if transition_busy:
		return
	transition_busy = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.38).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	var error := get_tree().change_scene_to_file(MENU_SCENE)
	if error != OK:
		transition_busy = false
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		push_error("No se pudo volver al menú principal.")
