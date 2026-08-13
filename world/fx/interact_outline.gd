class_name InteractOutline
extends Node
## Focus rim on the current interact target (additive fresnel next_pass).
## Buildings: doors only. People: body meshes, not face details.

const SHADER_PATH: String = "res://world/fx/interact_outline.gdshader"
const RIM_COLOR: Color = Color(1.0, 0.88, 0.62, 1.0)
const RIM_POWER: float = 2.4
const RIM_INTENSITY: float = 1.35
const NEARBY_DOOR_RADIUS: float = 6.0
const SKIP_BRANCHES: PackedStringArray = [
	"LotBounds",
	"ReservedLot",
	"DebugLot",
	"CollisionRoot",
]
const DETAIL_MESH_NAMES: PackedStringArray = [
	"EyeL", "EyeR", "PupilL", "PupilR", "BrowL", "BrowR", "Nose", "Mouth",
]

var _rim: ShaderMaterial = null
var _bases: Array[Material] = []
var _hovered: bool = false


func _ready() -> void:
	_apply()
	if _bases.is_empty():
		call_deferred("_apply")


func _exit_tree() -> void:
	_detach()


func refresh() -> void:
	_detach()
	_bases.clear()
	_rim = null
	_apply()
	_sync_pass()


func set_hovered(on: bool) -> void:
	_hovered = on
	_sync_pass()


func _apply() -> void:
	if not _bases.is_empty():
		return
	var host: Node = get_parent()
	if host == null or not is_instance_valid(host):
		return
	var meshes: Array[MeshInstance3D] = _collect_meshes(host)
	if meshes.is_empty():
		return
	var shader: Shader = load(SHADER_PATH) as Shader
	if shader == null:
		return
	_rim = _make_rim(shader)
	for mi in meshes:
		_bind_mesh(mi)


func _make_rim(shader: Shader) -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("rim_color", RIM_COLOR)
	mat.set_shader_parameter("rim_power", RIM_POWER)
	mat.set_shader_parameter("rim_intensity", RIM_INTENSITY)
	mat.set_shader_parameter("highlight_on", 1.0 if _hovered else 0.0)
	return mat


func _bind_mesh(mi: MeshInstance3D) -> void:
	if mi == null or not is_instance_valid(mi) or _rim == null:
		return
	var bases: Array[Material] = _ensure_base_materials(mi)
	for base in bases:
		_remember_base(base)
	_sync_pass()


func _sync_pass() -> void:
	if _rim != null:
		_rim.set_shader_parameter("highlight_on", 1.0 if _hovered else 0.0)
	for base in _bases:
		if base == null:
			continue
		if _hovered:
			if base.next_pass != _rim:
				base.next_pass = _rim
		elif base.next_pass == _rim:
			base.next_pass = null


func _detach() -> void:
	for base in _bases:
		if base != null and base.next_pass == _rim:
			base.next_pass = null


func _remember_base(base: Material) -> void:
	if base == null:
		return
	for existing in _bases:
		if existing == base:
			return
	_bases.append(base)


func _ensure_base_materials(mi: MeshInstance3D) -> Array[Material]:
	var result: Array[Material] = []
	if mi.material_override != null:
		var dup: Material = mi.material_override.duplicate() as Material
		mi.material_override = dup
		result.append(dup)
		return result
	var surface_count: int = 1
	if mi.mesh != null:
		surface_count = maxi(mi.mesh.get_surface_count(), 1)
	var had_any: bool = false
	for i in range(surface_count):
		var src: Material = mi.get_surface_override_material(i)
		if src == null and mi.mesh != null and i < mi.mesh.get_surface_count():
			src = mi.mesh.surface_get_material(i)
		var dup: Material
		if src != null:
			dup = src.duplicate() as Material
		else:
			dup = StandardMaterial3D.new()
		mi.set_surface_override_material(i, dup)
		result.append(dup)
		had_any = true
	if not had_any:
		var fallback: StandardMaterial3D = StandardMaterial3D.new()
		mi.material_override = fallback
		result.append(fallback)
	return result


func _collect_meshes(host: Node) -> Array[MeshInstance3D]:
	var building: Node = _find_building_ancestor(host)
	if building != null:
		var doors: Array[MeshInstance3D] = _collect_door_meshes(building)
		if not doors.is_empty():
			return doors
	if host is WorldTransition:
		var nearby: Array[MeshInstance3D] = _collect_nearby_doors(host)
		if not nearby.is_empty():
			return nearby
	var visual_root: Node = _resolve_item_root(host)
	return _collect_all_meshes(visual_root)


func _resolve_item_root(host: Node) -> Node:
	var packed: Node = _find_packed_ancestor(host)
	if packed != null:
		return packed
	var item_parent: Node = host.get_parent()
	if item_parent != null and not _is_location_root(item_parent) and _has_mesh_descendant(item_parent):
		return item_parent
	return host


func _find_building_ancestor(start: Node) -> Node:
	var n: Node = start
	for _i in range(8):
		if n == null:
			return null
		if _is_location_root(n):
			return null
		if n is CityPOIBuilding:
			return n
		var visual: Node = n.get_node_or_null("VisualRoot")
		if visual != null and String(n.scene_file_path) != "":
			return n
		n = n.get_parent()
	return null


func _find_packed_ancestor(start: Node) -> Node:
	var n: Node = start
	for _i in range(8):
		if n == null:
			return null
		if _is_location_root(n):
			return null
		if String(n.scene_file_path) != "" and n.get_node_or_null("VisualRoot") == null:
			return n
		n = n.get_parent()
	return null


func _is_location_root(n: Node) -> bool:
	if n is WorldLocation:
		return true
	var loc_id: Variant = n.get("location_id")
	return loc_id != null and String(loc_id) != ""


func _collect_nearby_doors(host: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if not (host is Node3D):
		return found
	var origin: Vector3 = (host as Node3D).global_position
	var search_root: Node = _find_location_ancestor(host)
	if search_root == null:
		var tree: SceneTree = host.get_tree()
		search_root = tree.current_scene if tree != null else host
	_walk_doors(search_root, origin, found)
	if found.is_empty():
		return found
	var closest: MeshInstance3D = found[0]
	var best_d: float = origin.distance_to(closest.global_position)
	for mi in found:
		var d: float = origin.distance_to(mi.global_position)
		if d < best_d:
			best_d = d
			closest = mi
	var building: Node = _find_building_ancestor(closest)
	if building != null:
		return _collect_door_meshes(building)
	var only: Array[MeshInstance3D] = [closest]
	return only


func _find_location_ancestor(start: Node) -> Node:
	var n: Node = start
	while n != null:
		if _is_location_root(n):
			return n
		n = n.get_parent()
	return null


func _walk_doors(node: Node, origin: Vector3, out: Array[MeshInstance3D]) -> void:
	if node == null or SKIP_BRANCHES.has(node.name):
		return
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.visible and _is_door_mesh(mi) and mi.global_position.distance_to(origin) <= NEARBY_DOOR_RADIUS:
			out.append(mi)
	for child in node.get_children():
		_walk_doors(child, origin, out)


func _collect_door_meshes(root: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	_walk_collect(root, true, result)
	return result


func _collect_all_meshes(root: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	_walk_collect(root, false, result)
	return result


func _walk_collect(node: Node, doors_only: bool, out: Array[MeshInstance3D]) -> void:
	if node == null or SKIP_BRANCHES.has(node.name):
		return
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.visible and not DETAIL_MESH_NAMES.has(mi.name) and (not doors_only or _is_door_mesh(mi)):
			out.append(mi)
	for child in node.get_children():
		_walk_collect(child, doors_only, out)


func _is_door_mesh(mi: MeshInstance3D) -> bool:
	var n: String = mi.name.to_lower()
	if n == "portal" or n == "door" or n.contains("portal") or n.contains("door"):
		return true
	if not _is_under_visual_root(mi):
		return false
	var mesh: Mesh = mi.mesh
	if mesh is BoxMesh:
		var sz: Vector3 = (mesh as BoxMesh).size
		var thin: float = minf(sz.x, sz.z)
		var wide: float = maxf(sz.x, sz.z)
		if sz.y >= 1.55 and sz.y <= 2.7 and thin <= 0.4 and wide <= 1.7:
			return true
	return false


func _is_under_visual_root(mi: Node) -> bool:
	var n: Node = mi.get_parent()
	for _i in range(6):
		if n == null:
			return false
		if n.name == "VisualRoot":
			return true
		n = n.get_parent()
	return false


func _has_mesh_descendant(root: Node) -> bool:
	if root is MeshInstance3D:
		return true
	for child in root.get_children():
		if _has_mesh_descendant(child):
			return true
	return false
