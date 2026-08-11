extends Interactable
class_name ApartmentWardrobeInteractable
## Apartment wardrobe clothing shop (buy + equip outfits).

const MENU_SCENE: String = "res://world/locations/apartment/apartment_wardrobe_menu.tscn"

var _menu: CanvasLayer = null


func _ready() -> void:
	prompt_action = "Открыть гардероб"
	monitoring = false
	monitorable = true
	collision_layer = 4
	collision_mask = 0


func get_interaction_prompt(_player: Node) -> String:
	return "[E] Открыть гардероб"


func _on_interact(player: Node) -> void:
	if _menu != null and is_instance_valid(_menu):
		return
	var packed: PackedScene = load(MENU_SCENE) as PackedScene
	if packed == null:
		push_error("[ApartmentWardrobe] menu scene missing")
		return
	_menu = packed.instantiate() as CanvasLayer
	if _menu == null:
		push_error("[ApartmentWardrobe] menu instantiate failed")
		return
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		_menu.free()
		_menu = null
		return
	tree.root.add_child(_menu)
	_menu.connect("outfit_selected", _on_outfit_selected)
	_menu.connect("closed", _on_menu_closed)
	_menu.call("open", player)


func _on_outfit_selected(item_id: StringName) -> void:
	var catalog: GDScript = load(
		"res://world/locations/apartment/apartment_wardrobe_catalog.gd"
	) as GDScript
	if catalog == null:
		return
	var definition: Dictionary = catalog.call("get_definition", item_id)
	_notify("Надето: %s" % str(definition.get("name", "образ")))


func _on_menu_closed() -> void:
	_menu = null


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
