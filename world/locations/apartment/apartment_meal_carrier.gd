extends Node3D
class_name ApartmentMealCarrier
## First-person holder for a free apartment meal selected at the fridge.

const DISHES: Dictionary = {
	&"pizza": {
		"name": "Пицца",
		"scene": "res://assets/props/food/meshes/Pizza.fbx",
	},
	&"burger": {
		"name": "Бургер",
		"scene": "res://assets/props/food/meshes/Cheeseburger.fbx",
	},
	&"pancakes": {
		"name": "Блинчики",
		"scene": "res://assets/props/food/meshes/Pancakes_Stack.fbx",
	},
	&"steak": {
		"name": "Стейк",
		"scene": "res://assets/props/food/meshes/Steak.fbx",
	},
}

var _dish_id: StringName = &""
var _visual: Node3D = null


func _ready() -> void:
	add_to_group("apartment_meal_carrier")


func has_meal() -> bool:
	return _dish_id != &""


func get_meal_id() -> StringName:
	return _dish_id


func get_meal_name() -> String:
	var definition: Dictionary = DISHES.get(_dish_id, {})
	return str(definition.get("name", ""))


func set_meal(dish_id: StringName) -> bool:
	var definition: Dictionary = DISHES.get(dish_id, {})
	if definition.is_empty():
		return false
	var scene_path: String = str(definition.get("scene", ""))
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		push_error("[ApartmentMealCarrier] dish scene missing: %s" % scene_path)
		return false
	var instance: Node = packed.instantiate()
	if not (instance is Node3D):
		instance.free()
		push_error("[ApartmentMealCarrier] dish scene root is not Node3D: %s" % scene_path)
		return false
	_clear_visual()
	_dish_id = dish_id
	_visual = instance as Node3D
	add_child(_visual)
	_visual.position = Vector3.ZERO
	_visual.rotation_degrees = Vector3(-18.0, 20.0, 8.0)
	_visual.scale = Vector3.ONE
	return true


func take_meal() -> Dictionary:
	if not has_meal():
		return {}
	var definition: Dictionary = DISHES.get(_dish_id, {}).duplicate(true)
	definition["id"] = _dish_id
	_dish_id = &""
	_clear_visual()
	return definition


func clear_meal() -> void:
	_dish_id = &""
	_clear_visual()


func _clear_visual() -> void:
	if _visual != null and is_instance_valid(_visual):
		_visual.queue_free()
	_visual = null
