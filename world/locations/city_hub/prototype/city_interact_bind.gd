extends Node
## Places city_hub interactables onto prototype city art:
## buildings → door AABB, activities → object collision (or visual bounds).

const FLAVOR_SCRIPT: String = "res://world/flavor/flavor_interactable.gd"
const DOOR_MIN_SIZE: Vector3 = Vector3(0.95, 1.85, 0.55)
const TRAVEL_POI_TO_TRANSITION: Dictionary = {
	"player_home": "ToApartment",
	"cafe_two_hearts": "ToCafe",
	"gym": "ToGym",
	"photo_studio": "ToAppearance",
}
const LEGACY_FLAVOR_TO_POI: Dictionary = {
	"FlavorBench": "main_bench",
	"FlavorPublicSign": "karaoke",
	"FlavorMap": "bus_stop_candy",
	"FlavorSideDoor": "internet_cafe",
	"FlavorTrashBin": "park_bench",
}
const LEFTOVER_TRANSITION_TO_BG: Dictionary = {
	"ToMine": "BG_08",
	"ToLab": "BG_07",
	"ToProduction": "BG_06",
	"ToFinal": "BG_09",
}

var _claimed_areas: Dictionary = {}


func _ready() -> void:
	call_deferred("_bind_later")


func _bind_later() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_bind()


func _bind() -> void:
	var loc: Node = _find_world_location()
	if loc == null:
		return
	var transitions: Dictionary = _index_transitions(loc)
	var tenant_list: Array[CityPOITenant] = _tenants()
	for tenant in tenant_list:
		call_deferred("_bind_tenant", tenant, transitions)
	call_deferred("_finish_bind", transitions, loc)


func _bind_tenant(tenant: CityPOITenant, transitions: Dictionary) -> void:
	if tenant == null:
		return
	var areas: Array[Area3D] = _tenant_areas(tenant)
	if areas.is_empty():
		return
	var building: CityPOIBuilding = _building_of(tenant)
	var doors: Array[MeshInstance3D] = []
	if building != null:
		doors = _collect_doors(building)
	var travel_name: String = str(TRAVEL_POI_TO_TRANSITION.get(tenant.poi_id, ""))
	var travel: WorldTransition = transitions.get(travel_name) as WorldTransition
	for i in range(areas.size()):
		var area: Area3D = areas[i]
		if area == null or not is_instance_valid(area):
			continue
		if building != null:
			var door: MeshInstance3D = _nearest_door(area, doors) if not doors.is_empty() else null
			if i == 0 and travel != null:
				if door != null:
					_snap_transition_to_door(travel, door)
				else:
					_snap_transition_to_anchor(travel, tenant)
				_disable_area(area)
				_claimed_areas[area] = true
				continue
			var live: Area3D = _ensure_gameplay_area(area, tenant, i == 0)
			if door != null:
				_fit_area_to_door(live, door, i)
			else:
				_fit_area_to_anchor(live, tenant, i)
			_claimed_areas[live] = true
		else:
			call_deferred("_bind_activity_area", tenant, area)


func _finish_bind(transitions: Dictionary, loc: Node) -> void:
	await get_tree().process_frame
	_snap_leftover_transitions(transitions)
	_rehome_legacy_flavor(loc)
	_disable_unclaimed_legacy_flavor(loc)


func _bind_activity_area(tenant: CityPOITenant, area: Area3D) -> void:
	if tenant == null or area == null or not is_instance_valid(area):
		return
	var live_act: Area3D = _ensure_gameplay_area(area, tenant, area.name == "InteractionArea")
	_fit_area_to_host_collision(live_act, tenant)
	_claimed_areas[live_act] = true


func _ensure_gameplay_area(area: Area3D, tenant: CityPOITenant, primary: bool) -> Area3D:
	var script_path: String = ""
	if area.get_script() != null:
		script_path = String(area.get_script().resource_path)
	if area is Interactable and not script_path.ends_with("donor_interactable_stub.gd"):
		_arm_area(area)
		return area
	var flavor_script: GDScript = load(FLAVOR_SCRIPT) as GDScript
	if flavor_script == null:
		return area
	var prompt: String = tenant.action_label if primary and tenant.action_label != "" else tenant.prompt_text
	if prompt.strip_edges() == "":
		prompt = tenant.display_name
	if prompt.strip_edges() == "":
		prompt = "Осмотреть"
	var title: String = tenant.display_name if tenant.display_name != "" else prompt
	var body: String = tenant.prompt_text if tenant.prompt_text != "" else prompt
	var flavor: Area3D = flavor_script.new() as Area3D
	if flavor == null:
		return area
	flavor.name = area.name + "_Live"
	flavor.set("prompt", prompt)
	flavor.set("prompt_action", prompt)
	flavor.set("text", "%s\n%s" % [title, body])
	var parent: Node = area.get_parent()
	if parent == null:
		return area
	parent.add_child(flavor)
	flavor.global_transform = area.global_transform
	_disable_area(area)
	_arm_area(flavor)
	return flavor


func _snap_transition_to_door(travel: WorldTransition, door: MeshInstance3D) -> void:
	_fit_area_to_door(travel, door, 0)
	_hide_transition_debug(travel)
	_refresh_outline(travel)


func _snap_transition_to_anchor(travel: WorldTransition, tenant: CityPOITenant) -> void:
	_fit_area_to_anchor(travel, tenant, 0)
	_hide_transition_debug(travel)
	_refresh_outline(travel)


func _hide_transition_debug(travel: WorldTransition) -> void:
	var mesh: MeshInstance3D = travel.get_node_or_null("Mesh") as MeshInstance3D
	if mesh != null:
		mesh.visible = false
	for child in travel.get_children():
		if child is Label3D:
			(child as Label3D).visible = false


func _fit_area_to_door(area: Area3D, door: MeshInstance3D, extra_index: int) -> void:
	if area == null or door == null:
		return
	area.global_transform = door.global_transform
	var aabb: AABB = door.get_aabb()
	var size: Vector3 = aabb.size
	size.x = maxf(size.x, DOOR_MIN_SIZE.x)
	size.y = maxf(size.y, DOOR_MIN_SIZE.y)
	size.z = maxf(size.z, DOOR_MIN_SIZE.z)
	var cs: CollisionShape3D = _ensure_box_shape(area)
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	cs.shape = box
	var local_center: Vector3 = aabb.get_center()
	local_center.z += (size.z - aabb.size.z) * 0.5
	local_center.x += float(extra_index) * (size.x + 0.15)
	cs.position = local_center
	cs.rotation = Vector3.ZERO
	_arm_area(area)


func _fit_area_to_anchor(area: Area3D, tenant: Node, extra_index: int) -> void:
	var anchor: Node3D = tenant.get_node_or_null("EntranceAnchor") as Node3D
	if anchor == null:
		return
	area.global_transform = anchor.global_transform
	var size: Vector3 = DOOR_MIN_SIZE
	var cs: CollisionShape3D = _ensure_box_shape(area)
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.position = Vector3(float(extra_index) * (size.x + 0.15), size.y * 0.5, size.z * 0.5)
	cs.rotation = Vector3.ZERO
	_arm_area(area)


func _fit_area_to_host_collision(area: Area3D, host: Node) -> void:
	var src: CollisionShape3D = _find_static_shape(host)
	if src != null and src.shape != null:
		area.global_transform = src.global_transform
		var cs: CollisionShape3D = _ensure_box_shape(area)
		cs.shape = _copy_shape(src.shape)
		cs.position = Vector3.ZERO
		cs.rotation = Vector3.ZERO
		_arm_area(area)
		return
	var named: MeshInstance3D = _named_prop_mesh(host, area)
	if named != null:
		_fit_area_to_mesh(area, named)
		return
	var props: Node = host.get_node_or_null("IdentityProps")
	var visual: Node = props if props != null else host
	_fit_area_to_visual_bounds(area, visual)


func _fit_area_to_mesh(area: Area3D, mi: MeshInstance3D) -> void:
	if area == null or mi == null:
		return
	area.global_transform = mi.global_transform
	var aabb: AABB = mi.get_aabb()
	var cs: CollisionShape3D = _ensure_box_shape(area)
	var box: BoxShape3D = BoxShape3D.new()
	box.size = aabb.size
	cs.shape = box
	cs.position = aabb.get_center()
	cs.rotation = Vector3.ZERO
	_arm_area(area)


func _fit_area_to_visual_bounds(area: Area3D, root: Node) -> void:
	if area == null or root == null:
		return
	var merged: AABB = _merged_mesh_aabb(root)
	if merged.size == Vector3.ZERO:
		return
	var xf: Transform3D = (root as Node3D).global_transform if root is Node3D else area.global_transform
	area.global_transform = xf
	var cs: CollisionShape3D = _ensure_box_shape(area)
	var box: BoxShape3D = BoxShape3D.new()
	box.size = merged.size
	cs.shape = box
	cs.position = merged.get_center()
	cs.rotation = Vector3.ZERO
	_arm_area(area)


func _merged_mesh_aabb(root: Node) -> AABB:
	var merged: AABB = AABB()
	var started: bool = false
	var inv: Transform3D = (root as Node3D).global_transform.affine_inverse() if root is Node3D else Transform3D.IDENTITY
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi == null or not mi.visible or mi.mesh == null:
			continue
		var local_xf: Transform3D = inv * mi.global_transform
		var aabb: AABB = local_xf * mi.get_aabb()
		if not started:
			merged = aabb
			started = true
		else:
			merged = merged.merge(aabb)
	return merged


func _named_prop_mesh(host: Node, area: Area3D) -> MeshInstance3D:
	var hint: String = area.name.to_lower()
	var props: Node = host.get_node_or_null("IdentityProps")
	if props == null:
		return null
	var names: PackedStringArray = PackedStringArray()
	if hint.contains("candy"):
		names.append("Candy")
	if names.is_empty():
		return null
	for mesh_name in names:
		var found: Node = props.find_child(mesh_name, true, false)
		if found is MeshInstance3D:
			return found as MeshInstance3D
	return null


func _snap_leftover_transitions(transitions: Dictionary) -> void:
	var city: Node = get_parent()
	if city == null:
		return
	for tr_name in LEFTOVER_TRANSITION_TO_BG.keys():
		var travel: WorldTransition = transitions.get(str(tr_name)) as WorldTransition
		if travel == null:
			continue
		var bg: Node = city.find_child(str(LEFTOVER_TRANSITION_TO_BG[tr_name]), true, false)
		if bg == null:
			continue
		var doors: Array[MeshInstance3D] = _collect_doors(bg)
		if not doors.is_empty():
			_snap_transition_to_door(travel, doors[0])
			continue
		var body: MeshInstance3D = bg.find_child("Body", true, false) as MeshInstance3D
		if body == null:
			continue
		_fit_area_to_building_front(travel, body)
		_hide_transition_debug(travel)
		_refresh_outline(travel)


func _fit_area_to_building_front(area: Area3D, body: MeshInstance3D) -> void:
	area.global_transform = body.global_transform
	var aabb: AABB = body.get_aabb()
	var size: Vector3 = DOOR_MIN_SIZE
	var cs: CollisionShape3D = _ensure_box_shape(area)
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	cs.shape = box
	var center: Vector3 = aabb.get_center()
	center.y = aabb.position.y + size.y * 0.5
	center.z = aabb.position.z + aabb.size.z * 0.5 + size.z * 0.5
	cs.position = center
	cs.rotation = Vector3.ZERO
	_arm_area(area)


func _copy_shape(src: Shape3D) -> Shape3D:
	if src is BoxShape3D:
		var box: BoxShape3D = BoxShape3D.new()
		box.size = (src as BoxShape3D).size
		return box
	if src is SphereShape3D:
		var sphere: SphereShape3D = SphereShape3D.new()
		sphere.radius = (src as SphereShape3D).radius
		return sphere
	if src is CapsuleShape3D:
		var cap: CapsuleShape3D = CapsuleShape3D.new()
		var src_cap: CapsuleShape3D = src as CapsuleShape3D
		cap.radius = src_cap.radius
		cap.height = src_cap.height
		return cap
	return src.duplicate() as Shape3D


func _arm_area(area: Area3D) -> void:
	area.collision_layer = 4
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true


func _refresh_outline(area: Area3D) -> void:
	var outline: Node = area.get_node_or_null("InteractOutline")
	if outline != null and outline.has_method("refresh"):
		outline.call("refresh")


func _rehome_legacy_flavor(loc: Node) -> void:
	var folder: Node = loc.get_node_or_null("Interactables")
	if folder == null:
		return
	for flavor_name in LEGACY_FLAVOR_TO_POI.keys():
		var flavor: Node = folder.get_node_or_null(str(flavor_name))
		var poi_id: String = str(LEGACY_FLAVOR_TO_POI[flavor_name])
		var tenant: CityPOITenant = _tenant_by_poi(poi_id)
		if flavor == null or tenant == null:
			continue
		var areas: Array[Area3D] = _tenant_areas(tenant)
		var area: Area3D = null
		for candidate in areas:
			if candidate is FlavorInteractable and candidate.collision_layer == 4:
				area = candidate
				break
		if area == null:
			continue
		var text: String = str(flavor.get("text"))
		if text.strip_edges() != "":
			area.set("text", text)
		_disable_area(flavor as Area3D)


func _disable_unclaimed_legacy_flavor(loc: Node) -> void:
	var folder: Node = loc.get_node_or_null("Interactables")
	if folder == null:
		return
	for child in folder.get_children():
		if child is Area3D:
			_disable_area(child as Area3D)


func _disable_area(area: Area3D) -> void:
	if area == null:
		return
	area.collision_layer = 0
	area.monitorable = false
	area.monitoring = false
	if "interaction_enabled" in area:
		area.set("interaction_enabled", false)


func _tenants() -> Array[CityPOITenant]:
	var out: Array[CityPOITenant] = []
	var tree: SceneTree = get_tree()
	if tree == null:
		return out
	var root: Node = get_parent()
	if root == null:
		root = self
	for node in tree.get_nodes_in_group("city_poi_tenant"):
		if node is CityPOITenant and (root == node or root.is_ancestor_of(node)):
			out.append(node as CityPOITenant)
	return out


func _tenant_by_poi(poi_id: String) -> CityPOITenant:
	for tenant in _tenants():
		if tenant.poi_id == poi_id:
			return tenant
	return null


func _tenant_areas(tenant: Node) -> Array[Area3D]:
	var out: Array[Area3D] = []
	_collect_areas(tenant, out, 0)
	var primary: Array[Area3D] = []
	var extra: Array[Area3D] = []
	for area in out:
		if area.name == "InteractionArea":
			primary.append(area)
		else:
			extra.append(area)
	for area in extra:
		primary.append(area)
	return primary


func _collect_areas(node: Node, out: Array[Area3D], depth: int) -> void:
	if node == null or depth > 6:
		return
	if node.name == "InteractOutline" or node.name == "VisualRoot" or node.name == "CollisionRoot":
		return
	for child in node.get_children():
		if child is Area3D:
			out.append(child as Area3D)
		_collect_areas(child, out, depth + 1)


func _building_of(tenant: Node) -> CityPOIBuilding:
	var n: Node = tenant
	for _i in range(8):
		if n == null:
			return null
		if n is CityPOIBuilding:
			return n as CityPOIBuilding
		n = n.get_parent()
	return null


func _collect_doors(building: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if building == null:
		return out
	var visual: Node = building.get_node_or_null("VisualRoot")
	var root: Node = visual if visual != null else building
	_walk_doors(root, out)
	return out


func _walk_doors(node: Node, out: Array[MeshInstance3D]) -> void:
	if node == null:
		return
	if node is MeshInstance3D and _is_door_mesh(node as MeshInstance3D):
		out.append(node as MeshInstance3D)
	for child in node.get_children():
		_walk_doors(child, out)


func _is_door_mesh(mi: MeshInstance3D) -> bool:
	var n: String = mi.name.to_lower()
	if n == "portal" or n == "door" or n.contains("portal") or n.contains("door"):
		return true
	var mesh: Mesh = mi.mesh
	if mesh is BoxMesh:
		var sz: Vector3 = (mesh as BoxMesh).size
		var thin: float = minf(sz.x, sz.z)
		var wide: float = maxf(sz.x, sz.z)
		if sz.y >= 1.55 and sz.y <= 2.7 and thin <= 0.4 and wide <= 1.7:
			return true
	return false


func _nearest_door(area: Area3D, doors: Array[MeshInstance3D]) -> MeshInstance3D:
	var best: MeshInstance3D = doors[0]
	var best_d: float = area.global_position.distance_to(best.global_position)
	for door in doors:
		var d: float = area.global_position.distance_to(door.global_position)
		if d < best_d:
			best_d = d
			best = door
	return best


func _find_static_shape(host: Node) -> CollisionShape3D:
	for body in host.find_children("*", "StaticBody3D", true, false):
		for child in body.get_children():
			if child is CollisionShape3D:
				var cs: CollisionShape3D = child as CollisionShape3D
				if cs.shape != null:
					return cs
	return null


func _ensure_box_shape(area: Area3D) -> CollisionShape3D:
	var cs: CollisionShape3D = area.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if cs == null:
		cs = area.get_node_or_null("Collision") as CollisionShape3D
	if cs == null:
		cs = CollisionShape3D.new()
		cs.name = "CollisionShape3D"
		area.add_child(cs)
	return cs


func _index_transitions(loc: Node) -> Dictionary:
	var out: Dictionary = {}
	var nodes: Array[Node] = loc.find_children("*", "WorldTransition", true, false)
	for n in nodes:
		out[n.name] = n
	return out


func _find_world_location() -> Node:
	var n: Node = self
	while n != null:
		if n is WorldLocation:
			return n
		n = n.get_parent()
	return null
