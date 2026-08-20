class_name GameTermTooltipLayer
extends CanvasLayer

const LAYER_NAME := "GameTermTooltipLayer"

static var _instance: GameTermTooltipLayer

var _panel: PanelContainer
var _title: Label
var _body: Label


static func ensure(from: Node) -> GameTermTooltipLayer:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null and from != null and from.is_inside_tree():
		tree = from.get_tree()
	if tree == null or tree.root == null:
		return null
	var existing: Node = tree.root.get_node_or_null(LAYER_NAME)
	if existing is GameTermTooltipLayer:
		_instance = existing
		return existing
	if _instance != null and is_instance_valid(_instance):
		return _instance
	var layer := GameTermTooltipLayer.new()
	layer.name = LAYER_NAME
	layer.layer = 128
	_instance = layer
	tree.root.add_child.call_deferred(layer)
	return layer


func _ready() -> void:
	layer = 128
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.self_modulate = Color.WHITE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(LabUi.PANEL, 1.0)
	style.draw_center = true
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = LabUi.PANEL_ALT
	_panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 18)
	_title.add_theme_color_override("font_color", LabUi.ACCENT)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(280, 0)
	_body.add_theme_color_override("font_color", LabUi.TEXT)
	box.add_child(_title)
	box.add_child(_body)
	_panel.add_child(box)
	add_child(_panel)


func show_term(term: GameTerm) -> void:
	if term == null or _panel == null:
		hide_tooltip()
		return
	_title.text = term.display_name
	_body.text = term.description
	_panel.visible = true
	_follow_mouse()


func hide_tooltip() -> void:
	if _panel != null:
		_panel.visible = false


func _process(_delta: float) -> void:
	if _panel != null and _panel.visible:
		_follow_mouse()


func _follow_mouse() -> void:
	var pos: Vector2 = get_viewport().get_mouse_position() + Vector2(16, 16)
	var size: Vector2 = _panel.get_combined_minimum_size()
	var view: Vector2 = get_viewport().get_visible_rect().size
	pos.x = minf(pos.x, view.x - size.x - 8.0)
	pos.y = minf(pos.y, view.y - size.y - 8.0)
	_panel.position = pos
