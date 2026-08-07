extends Node
## MODULE 00/12 entry bootstrap. Boots playable apartment via World.


func _ready() -> void:
	call_deferred("_boot")


func _boot() -> void:
	var world: Node = get_node_or_null("/root/World")
	if world == null or not world.has_method("boot_from_main"):
		DfLog.error("MODULE_12", "World autoload missing; cannot boot apartment")
		return
	DfLog.info("MODULE_12", "Boot -> apartment via World")
	var result: Variant = world.call("boot_from_main")
	if int(result) != int(WorldTypes.WorldTravelResult.SUCCESS):
		DfLog.error("MODULE_12", "boot_from_main failed: %s" % result)
