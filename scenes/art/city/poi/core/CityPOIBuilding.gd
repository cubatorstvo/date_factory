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


func _apply_lot_bounds_visibility() -> void:
	var lot: Node = get_node_or_null("LotBounds")
	if lot == null:
		return
	var show_debug: bool = Engine.is_editor_hint() or OS.is_debug_build()
	if lot is CanvasItem:
		(lot as CanvasItem).visible = show_debug
	elif lot is Node3D:
		(lot as Node3D).visible = show_debug
	## Hide mesh/CSG children of LotBounds in normal play (non-debug, non-editor).
	if not show_debug:
		_hide_visual_recursive(lot)


func _hide_visual_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).visible = false
	elif node is CSGShape3D:
		(node as CSGShape3D).visible = false
	for child in node.get_children():
		_hide_visual_recursive(child)
