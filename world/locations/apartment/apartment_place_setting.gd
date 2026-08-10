class_name ApartmentPlaceSetting
extends Node3D
## Visual-bootstrap stub: legacy Game/EventBus place-setting disabled.
## Keeps Decor node script attachment safe without wiring old dating APIs.

const PLACE_SETTING_NAMES: PackedStringArray = PackedStringArray([
	"DatePlateA",
	"DatePlateB",
	"DateFork",
	"DateSpoon",
	"DateForkB",
	"DateSpoonB",
	"DateGlassA",
	"DateGlassB",
])


func _ready() -> void:
	_set_place_setting_visible(false)


func _set_place_setting_visible(show: bool) -> void:
	for node_name: String in PLACE_SETTING_NAMES:
		var node: Node3D = get_node_or_null(node_name) as Node3D
		if is_instance_valid(node):
			node.visible = show
