class_name CityPOIBuilding
extends Node3D
## City POI building shell — lot + shared structure for one or more tenants.
##
## Expected children (soft; document for authors, do not hard-crash if missing):
##   VisualRoot, CollisionRoot, LotBounds, SharedLighting, TenantSlots
##
## REPLACEMENT RULE
## ---------------
## MAY replace later:
##   - VisualRoot contents (meshes / GLB)
##   - CollisionRoot contents (static colliders)
##   - EntranceAnchor local pose inside tenants
## MUST NOT change:
##   - building root transform in city.tscn
##   - building_id / district_id
##   - tenant poi_id / action_id contracts
##   - save schema / interaction routing

@export var building_id: String = ""
@export var district_id: String = ""
## e.g. "VenueEntrance", "Storefront", "MultiTenant", "Landmark"
@export var building_mode: String = "VenueEntrance"
## Reserved lot size in meters on XZ.
@export var reserved_lot_size: Vector2 = Vector2(8.0, 8.0)


func _ready() -> void:
	add_to_group("city_poi_building")
	if building_id != "":
		set_meta("building_id", building_id)
	if district_id != "":
		set_meta("district_id", district_id)
	if building_mode != "":
		set_meta("building_mode", building_mode)
	_apply_lot_bounds_visibility()
	call_deferred("_ensure_interact_outline")


func _ensure_interact_outline() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	if get_node_or_null("InteractOutline") != null:
		return
	var script: GDScript = load("res://world/fx/interact_outline.gd") as GDScript
	if script == null:
		return
	var outline: Node = script.new() as Node
	outline.name = "InteractOutline"
	add_child(outline)


func _apply_lot_bounds_visibility() -> void:
	## Editor-only by default. Opt-in play debug via meta debug_show_lot_bounds=true.
	var show_debug: bool = Engine.is_editor_hint() or bool(get_meta("debug_show_lot_bounds", false))
	for lot_name in ["LotBounds", "ReservedLot", "DebugLot"]:
		var lot: Node = get_node_or_null(lot_name)
		if lot == null:
			continue
		if lot is CanvasItem:
			(lot as CanvasItem).visible = show_debug
		elif lot is Node3D:
			(lot as Node3D).visible = show_debug
		## Hide mesh/CSG children of lot debug visuals in normal play.
		if not show_debug:
			_hide_visual_recursive(lot)


func _hide_visual_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).visible = false
	elif node is CSGShape3D:
		(node as CSGShape3D).visible = false
	for child in node.get_children():
		_hide_visual_recursive(child)
