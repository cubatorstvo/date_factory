extends Interactable
class_name ApartmentFridgeInteractable
## Free apartment meal selection. The selected dish is shown in first person.

const MENU_SCENE: String = "res://world/locations/apartment/apartment_fridge_menu.tscn"
const CARRIER_SCRIPT: String = "res://world/locations/apartment/apartment_meal_carrier.gd"

var _menu: CanvasLayer = null


func _ready() -> void:
	prompt_action = "Открыть холодильник"
	monitoring = false
	monitorable = true
	collision_layer = 4
	collision_mask = 0


func get_interaction_prompt(_player: Node) -> String:
	return "[E] Открыть холодильник"


func _on_interact(player: Node) -> void:
	if _menu != null and is_instance_valid(_menu):
		return
	var packed: PackedScene = load(MENU_SCENE) as PackedScene
	if packed == null:
		push_error("[ApartmentFridge] menu scene missing")
		return
	_menu = packed.instantiate() as CanvasLayer
	if _menu == null:
		push_error("[ApartmentFridge] menu instantiate failed")
		return
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		_menu.free()
		_menu = null
		return
	tree.root.add_child(_menu)
	_menu.connect("dish_selected", _on_dish_selected.bind(player))
	_menu.connect("closed", _on_menu_closed)
	_menu.call("open", player)


func _on_dish_selected(dish_id: StringName, player: Node) -> void:
	var carrier: Node = _get_or_create_carrier(player)
	if carrier == null or not carrier.has_method("set_meal"):
		return
	if not bool(carrier.call("set_meal", dish_id)):
		return
	var dish_name: String = str(carrier.call("get_meal_name"))
	_notify("В руках: %s. Отнеси блюдо на стол." % dish_name)


func _on_menu_closed() -> void:
	_menu = null


func _get_or_create_carrier(player: Node) -> Node:
	if player == null or not player.has_method("get_camera"):
		return null
	var camera: Camera3D = player.call("get_camera") as Camera3D
	if camera == null:
		return null
	var existing: Node = camera.get_node_or_null("ApartmentMealCarrier")
	if existing != null:
		return existing
	var script_resource: Resource = load(CARRIER_SCRIPT)
	if not (script_resource is GDScript):
		push_error("[ApartmentFridge] meal carrier script missing")
		return null
	var carrier: Node = (script_resource as GDScript).new()
	if not (carrier is Node3D):
		carrier.free()
		return null
	carrier.name = "ApartmentMealCarrier"
	camera.add_child(carrier)
	var carrier_3d: Node3D = carrier as Node3D
	carrier_3d.position = Vector3(0.38, -0.28, -0.72)
	carrier_3d.rotation_degrees = Vector3.ZERO
	return carrier


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
