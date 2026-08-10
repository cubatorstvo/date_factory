extends Node
## MODULE 00/24 entry bootstrap. Boots title menu first; World starts after New/Continue/Load.

const TITLE_MENU_SCENE: String = "res://ui/frontend/title_menu.tscn"


func _ready() -> void:
	call_deferred("_boot")


func _boot() -> void:
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_method("prepare_for_title"):
		world.call("prepare_for_title")
		DfLog.info("MODULE_24", "Boot -> title menu (World deferred)")
	else:
		DfLog.warn("MODULE_24", "World.prepare_for_title missing; title still shown")
	var existing: Node = get_tree().get_first_node_in_group("title_menu") if get_tree() != null else null
	if existing != null:
		if existing.has_method("show_menu"):
			existing.call("show_menu")
		return
	var packed: PackedScene = load(TITLE_MENU_SCENE) as PackedScene
	if packed == null:
		DfLog.error("MODULE_24", "TitleMenu scene missing; fallback World.boot_from_main")
		_fallback_boot_world()
		return
	var title: Node = packed.instantiate()
	add_child(title)


func _fallback_boot_world() -> void:
	var world: Node = get_node_or_null("/root/World")
	if world == null or not world.has_method("boot_from_main"):
		DfLog.error("MODULE_12", "World autoload missing; cannot boot apartment")
		return
	var result: Variant = world.call("boot_from_main")
	if int(result) != int(WorldTypes.WorldTravelResult.SUCCESS):
		DfLog.error("MODULE_12", "boot_from_main failed: %s" % result)
