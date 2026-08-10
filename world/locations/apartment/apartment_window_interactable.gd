extends Interactable
class_name ApartmentWindowInteractable
## Openable apartment window. Opening it reveals the neighboring brick wall.

@export var curtains_path: NodePath = NodePath("../../Geometry/ApartmentArt/Furniture/Curtains")

var _opened: bool = false
var _curtains: Node3D = null


func _ready() -> void:
	monitoring = false
	monitorable = true
	collision_layer = 4
	collision_mask = 0
	_curtains = get_node_or_null(curtains_path) as Node3D
	_apply_visual_state()


func get_interaction_prompt(_player: Node) -> String:
	return "[E] Закрыть окно" if _opened else "[E] Открыть окно"


func _on_interact(_player: Node) -> void:
	_opened = not _opened
	_apply_visual_state()
	if _opened:
		_notify("Окно открыто. За ним — стена соседнего дома.")
	else:
		_notify("Окно закрыто.")


func _apply_visual_state() -> void:
	prompt_action = "Закрыть окно" if _opened else "Открыть окно"
	if _curtains != null and is_instance_valid(_curtains):
		_curtains.visible = not _opened


func _notify(message: String) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var hud: Node = tree.get_first_node_in_group("game_hud")
	if hud == null:
		var world: Node = get_node_or_null("/root/World")
		if world != null and world.has_method("get_game_hud"):
			hud = world.call("get_game_hud") as Node
	if hud != null and hud.has_method("show_notification"):
		hud.call("show_notification", message)
