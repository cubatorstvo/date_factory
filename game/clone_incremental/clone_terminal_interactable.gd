class_name CloneTerminalInteractable
extends Interactable
## Physical Clone Terminal entry in laboratory (MODULE 18).
## Scene worker attaches this at story_point_clone_terminal.

const MODAL_SCRIPT: String = "res://game/clone_incremental/clone_terminal_ui.gd"

var _modal: CanvasLayer = null


func _ready() -> void:
	prompt_action = CloneIncrementalTypes.TERMINAL_PROMPT
	monitoring = false
	monitorable = true
	collision_layer = 4
	collision_mask = 0
	_ensure_collision()


func can_interact(player: Node) -> bool:
	if not super.can_interact(player):
		return false
	if _modal != null and is_instance_valid(_modal):
		return false
	if player == null or not player.has_method("get_control_mode"):
		return true
	var mode: Variant = player.call("get_control_mode")
	return int(mode) == int(PlayerController.ControlMode.GAMEPLAY)


func get_interaction_prompt(_player: Node) -> String:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null or int(gs.call("get_total_clones")) < 1:
		return CloneIncrementalTypes.TERMINAL_LOCKED_PROMPT
	return "[E] %s" % CloneIncrementalTypes.TERMINAL_PROMPT


func _on_interact(player: Node) -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null or int(gs.call("get_total_clones")) < 1:
		return
	if not can_interact(player):
		return
	_open_modal(player)


func _open_modal(player: Node) -> void:
	_close_modal(player)
	var script: Script = load(MODAL_SCRIPT) as Script
	if script == null:
		push_error("[CloneTerminalInteractable] modal script missing")
		return
	var layer := CanvasLayer.new()
	layer.set_script(script)
	layer.name = "CloneTerminalUI"
	add_child(layer)
	_modal = layer
	if layer.has_method("open"):
		layer.call("open", player, Callable(self, "_on_modal_closed"))
	else:
		if player != null and player.has_method("enter_modal_ui"):
			player.call("enter_modal_ui")


func _on_modal_closed(player: Node) -> void:
	_modal = null
	if player != null and player.has_method("enter_gameplay"):
		player.call("enter_gameplay")


func _close_modal(player: Node) -> void:
	if _modal != null and is_instance_valid(_modal):
		if _modal.has_method("close"):
			_modal.call("close")
		else:
			_modal.queue_free()
	_modal = null
	if player != null and player.has_method("enter_gameplay"):
		player.call("enter_gameplay")


func _ensure_collision() -> void:
	var shape_node: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null:
		shape_node = get_node_or_null("Collision") as CollisionShape3D
	if shape_node != null:
		return
	shape_node = CollisionShape3D.new()
	shape_node.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 2.0, 1.4)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 1.0, 0.0)
	add_child(shape_node)
