class_name ApartmentPlaceSetting
extends Node3D
## Apartment table place setting: glasses stay hidden; cutlery appears with food.

const GLASS_NAMES: Array[String] = [
	"DateGlassA",
	"DateGlassB",
]

const CUTLERY_NAMES: Array[String] = [
	"DateFork",
	"DateSpoon",
	"DateForkB",
	"DateSpoonB",
]


func _ready() -> void:
	add_to_group("apartment_place_setting")
	_set_nodes_visible(GLASS_NAMES, false)
	_set_nodes_visible(CUTLERY_NAMES, false)


func set_cutlery_for_food(show: bool) -> void:
	_set_nodes_visible(CUTLERY_NAMES, show)


func _set_nodes_visible(node_names: Array[String], show: bool) -> void:
	for node_name: String in node_names:
		var node: Node3D = get_node_or_null(node_name) as Node3D
		if is_instance_valid(node):
			node.visible = show
