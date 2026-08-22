class_name OutfitAboveCasualGirlRequirement
extends GirlAccessRequirement

const FAIL_REASON: String = "Для этого свидания нужен образ интереснее повседневного."
const REQUIRED_TIER: int = 1


func is_met(_girl_id: StringName) -> bool:
	var equipment: Variant = _equipment_service()
	if equipment == null:
		return false
	return int(equipment.get_current_outfit_tier()) >= REQUIRED_TIER


func get_description(_girl_id: StringName) -> String:
	return "Одежда: выше «Повседневной»"


func get_progress_text(_girl_id: StringName) -> String:
	if is_met(_girl_id):
		return "Выше повседневного"
	return "Повседневный"


func _equipment_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("EquipmentService")
	if not is_instance_valid(node):
		return null
	return node
