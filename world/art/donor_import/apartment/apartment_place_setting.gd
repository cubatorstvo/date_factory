class_name ApartmentPlaceSetting
extends Node3D
## Visual-bootstrap stub: legacy Game/EventBus place-setting disabled.
## Keeps Decor node script attachment safe without wiring old dating APIs.

const GLASS_A: String = "DateGlassA"
const GLASS_B: String = "DateGlassB"


func _ready() -> void:
	# Always hide date place-setting glass props in v2 (no legacy Game.dating).
	_set_glasses_visible(false)


func _set_glasses_visible(show: bool) -> void:
	var names: PackedStringArray = PackedStringArray([GLASS_A, GLASS_B])
	for i in names.size():
		var node: Node3D = get_node_or_null(names[i]) as Node3D
		if is_instance_valid(node):
			node.visible = show
