class_name FlavorInteractable
extends Interactable
## Presentation-only scenic flavor prop (MODULE 25).
## Shows a short HUD notification; never mutates GameState / save.

const LAYER_INTERACTABLE: int = 4
const FALLBACK_HIDE_SECONDS: float = 2.2

@export_multiline var text: String = ""
@export var prompt: String = ""
@export var hide_seconds: float = FALLBACK_HIDE_SECONDS

var _fallback_layer: CanvasLayer = null
var _fallback_timer: Timer = null


func _ready() -> void:
	# Prefer explicit `prompt`; otherwise keep Interactable.prompt_action from the scene.
	if prompt.strip_edges() == "" and prompt_action.strip_edges() != "":
		prompt = prompt_action
	elif prompt.strip_edges() != "":
		prompt_action = prompt
	elif prompt_action.strip_edges() == "":
		prompt_action = "Осмотреть"
		prompt = prompt_action
	monitoring = false
	monitorable = true
	collision_layer = LAYER_INTERACTABLE
	collision_mask = 0
	_ensure_collision()


func get_interaction_prompt(_player: Node) -> String:
	var action: String = prompt.strip_edges()
	if action == "":
		action = prompt_action
	if action.strip_edges() == "":
		action = "Осмотреть"
	return "[E] %s" % action


func _on_interact(_player: Node) -> void:
	var message: String = text.strip_edges()
	if message == "":
		return
	if _try_hud_notify(message):
		return
	_show_fallback_label(message)


func _try_hud_notify(message: String) -> bool:
	var hud: Node = _find_game_hud()
	if hud != null and hud.has_method("show_notification"):
		hud.call("show_notification", message)
		return true
	return false


func _find_game_hud() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var existing: Node = tree.get_first_node_in_group("game_hud")
	if existing != null:
		return existing
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_method("get_game_hud"):
		var via_world: Variant = world.call("get_game_hud")
		if via_world is Node:
			return via_world as Node
	var root: Node = tree.root
	if root == null:
		return null
	return root.find_child("GameHUD", true, false)


func _show_fallback_label(message: String) -> void:
	if _fallback_layer == null or not is_instance_valid(_fallback_layer):
		_fallback_layer = CanvasLayer.new()
		_fallback_layer.name = "FlavorFallbackToast"
		_fallback_layer.layer = 60
		var label := Label.new()
		label.name = "Message"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		label.offset_left = -280.0
		label.offset_right = 280.0
		label.offset_top = -120.0
		label.offset_bottom = -48.0
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.92))
		_fallback_layer.add_child(label)
		_fallback_timer = Timer.new()
		_fallback_timer.name = "HideTimer"
		_fallback_timer.one_shot = true
		_fallback_timer.timeout.connect(_hide_fallback_label)
		_fallback_layer.add_child(_fallback_timer)
		add_child(_fallback_layer)
	var msg_label: Label = _fallback_layer.get_node_or_null("Message") as Label
	if msg_label != null:
		msg_label.text = message
	_fallback_layer.visible = true
	if _fallback_timer != null:
		var seconds: float = hide_seconds if hide_seconds > 0.0 else FALLBACK_HIDE_SECONDS
		_fallback_timer.start(seconds)


func _hide_fallback_label() -> void:
	if _fallback_layer != null and is_instance_valid(_fallback_layer):
		_fallback_layer.visible = false


func _ensure_collision() -> void:
	var shape_node: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null:
		shape_node = get_node_or_null("Collision") as CollisionShape3D
	if shape_node != null:
		return
	shape_node = CollisionShape3D.new()
	shape_node.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(1.0, 1.6, 1.0)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 0.8, 0.0)
	add_child(shape_node)
