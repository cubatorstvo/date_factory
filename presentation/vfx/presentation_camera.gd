class_name PresentationCamera
extends RefCounted
## Narrow CameraFeedback FOV helpers for first clone / final signal (MODULE 23 §24).

const FIRST_CLONE_FOV_DEG: float = 2.0
const FIRST_CLONE_FOV_SEC: float = 0.18
const FINAL_SIGNAL_FOV_DEG: float = 1.5
const FINAL_SIGNAL_FOV_SEC: float = 0.18


static func resolve_feedback(from_node: Node = null, player: Node = null) -> CameraFeedback:
	if player != null and is_instance_valid(player) and player.has_method("get_camera_feedback"):
		return player.call("get_camera_feedback") as CameraFeedback
	var tree: SceneTree = null
	if from_node != null and is_instance_valid(from_node):
		tree = from_node.get_tree()
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var group_player: Node = tree.get_first_node_in_group("player")
	if group_player != null and group_player.has_method("get_camera_feedback"):
		return group_player.call("get_camera_feedback") as CameraFeedback
	return null


static func fov_pulse(from_node: Node, degrees: float, duration: float, player: Node = null) -> void:
	var fb: CameraFeedback = resolve_feedback(from_node, player)
	if fb == null:
		return
	fb.fov_pulse(degrees, duration)


static func first_clone_reveal(from_node: Node, player: Node = null) -> void:
	fov_pulse(from_node, FIRST_CLONE_FOV_DEG, FIRST_CLONE_FOV_SEC, player)


static func final_signal(from_node: Node, player: Node = null) -> void:
	fov_pulse(from_node, FINAL_SIGNAL_FOV_DEG, FINAL_SIGNAL_FOV_SEC, player)
