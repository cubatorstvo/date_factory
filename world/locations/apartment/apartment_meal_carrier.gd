extends Node3D
class_name ApartmentMealCarrier
## Camera-mounted pair of servings currently carried from the apartment fridge.

const CATALOG_SCRIPT: String = (
	"res://world/locations/apartment/apartment_fridge_catalog.gd"
)
const SERVING_PAIR_SCENE: String = (
	"res://world/locations/apartment/apartment_serving_pair.tscn"
)

var _serving_id: StringName = &""
var _visual: Node3D = null


func _ready() -> void:
	add_to_group("apartment_meal_carrier")


func has_serving() -> bool:
	return _serving_id != &""


func get_serving_id() -> StringName:
	return _serving_id


func get_serving_name() -> String:
	var definition: Dictionary = _get_definition(_serving_id)
	return str(definition.get("name", ""))


func get_serving_category() -> StringName:
	var definition: Dictionary = _get_definition(_serving_id)
	return definition.get("category", &"")


func set_serving(item_id: StringName) -> bool:
	var definition: Dictionary = _get_definition(item_id)
	if definition.is_empty():
		return false
	var packed: PackedScene = load(SERVING_PAIR_SCENE) as PackedScene
	if packed == null:
		push_error("[ApartmentMealCarrier] serving pair scene missing")
		return false
	var instance: Node = packed.instantiate()
	if not (instance is Node3D):
		instance.free()
		push_error("[ApartmentMealCarrier] serving pair root is not Node3D")
		return false
	_clear_visual()
	_serving_id = item_id
	_visual = instance as Node3D
	add_child(_visual)
	_visual.position = Vector3.ZERO
	if not _visual.has_method("configure"):
		clear_serving()
		return false
	if not bool(_visual.call("configure", definition, true)):
		clear_serving()
		return false
	return true


func take_serving() -> Dictionary:
	if not has_serving():
		return {}
	var definition: Dictionary = _get_definition(_serving_id)
	definition["id"] = _serving_id
	_serving_id = &""
	_clear_visual()
	return definition


func clear_serving() -> void:
	_serving_id = &""
	_clear_visual()


## Compatibility aliases for code that still uses the original meal-specific API.
func has_meal() -> bool:
	return has_serving()


func get_meal_name() -> String:
	return get_serving_name()


func set_meal(item_id: StringName) -> bool:
	return set_serving(item_id)


func take_meal() -> Dictionary:
	return take_serving()


func clear_meal() -> void:
	clear_serving()


func _get_definition(item_id: StringName) -> Dictionary:
	if item_id == &"":
		return {}
	var catalog: GDScript = load(CATALOG_SCRIPT) as GDScript
	if catalog == null:
		return {}
	return catalog.call("get_definition", item_id) as Dictionary


func _clear_visual() -> void:
	if _visual != null and is_instance_valid(_visual):
		_visual.queue_free()
	_visual = null
