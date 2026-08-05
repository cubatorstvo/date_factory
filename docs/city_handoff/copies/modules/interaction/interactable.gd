## NOTE: class_name removed from handoff copy to avoid global class clash.
extends Area3D
## World interactable: shared screen-space 2D silhouette outline on focus.
## Scene-component contract: display_name, action_label, action_id, payload are the
## settings for this subordinate Area3D; parent furniture owns placement/meshes.

const OUTLINE_SHADER: Shader = preload("res://shaders/interact_outline.gdshader")
## outline_width is in screen pixels (see interact_outline.gdshader).
const IDLE_WIDTH: float = 0.0
const FOCUS_WIDTH: float = 3.0
const IDLE_COLOR := Color(1.0, 0.35, 0.58, 0.0)
const FOCUS_COLOR := Color(1.0, 0.35, 0.58, 1.0)
const DETAIL_MESH_NAMES: Array[String] = [
	"EyeL", "EyeR", "PupilL", "PupilR", "BrowL", "BrowR", "Nose", "Mouth",
]

@export var display_name: String = "РћР±СЉРµРєС‚"
@export var action_label: String = "РСЃРїРѕР»СЊР·РѕРІР°С‚СЊ"
@export var action_id: StringName = &""
@export var payload: Dictionary = {}
## When true, _ready deferred-fits BoxShape3D to mesh AABB under this node / parent.
@export var auto_fit_mesh_aabb: bool = false
## Extra half-extents added after mesh AABB union (meters in Interactable local space).
## Keep small: adjacent kitchen units (Fridge/Drawers) are ~0.04 m apart on mesh AABB.
@export var aabb_padding: Vector3 = Vector3(0.015, 0.03, 0.015)

signal interacted(by: Node)

var _focused: bool = false
var _punch_time: float = 0.0
var _base_scale := Vector3.ONE
var _outline_mats: Array[ShaderMaterial] = []
var _external_outline_roots: Array[Node] = []
var _outlines_ready: bool = false


func _ready() -> void:
	_base_scale = scale
	if auto_fit_mesh_aabb:
		call_deferred("fit_collision_to_meshes")
	call_deferred("_setup_outlines")


## Reparent under host at local_offset without inheriting host non-uniform FBX scale.
## Keeps this Area's global scale at ~Vector3.ONE so BoxShape sizes stay in meters.
func attach_to_host(host: Node3D, local_offset: Vector3 = Vector3.ZERO) -> void:
	if host == null or not is_instance_valid(host):
		return
	var old_parent: Node = get_parent()
	if old_parent == host:
		position = local_offset
		rotation = Vector3.ZERO
		_force_unit_global_scale()
		return
	if old_parent != null:
		old_parent.remove_child(self)
	host.add_child(self)
	transform = Transform3D(Basis.IDENTITY, local_offset)
	_force_unit_global_scale()


## Union MeshInstance3D AABBs under mesh_root into the local BoxShape3D + CollisionShape3D.
## mesh_root defaults to first outline root, else parent, else self.
func fit_collision_to_meshes(mesh_root: Node = null) -> void:
	var root: Node = mesh_root
	if root == null:
		if not _external_outline_roots.is_empty():
			root = _external_outline_roots[0]
		elif get_parent() != null:
			root = get_parent()
		else:
			root = self
	if root == null or not is_instance_valid(root):
		return
	var meshes: Array[MeshInstance3D] = []
	if root is MeshInstance3D:
		var root_mi: MeshInstance3D = root as MeshInstance3D
		if not _is_detail_mesh(root_mi) and not _is_legacy_outline_mesh(root_mi):
			meshes.append(root_mi)
	_collect_meshes(root, meshes)
	if meshes.is_empty():
		push_warning("Interactable.fit_collision_to_meshes: no meshes under %s" % str(root.name))
		return
	var union_aabb: AABB
	var has_aabb: bool = false
	for mi in meshes:
		if mi.mesh == null:
			continue
		var local_aabb: AABB = _mesh_aabb_in_self_space(mi)
		if not has_aabb:
			union_aabb = local_aabb
			has_aabb = true
		else:
			union_aabb = union_aabb.merge(local_aabb)
	if not has_aabb:
		return
	var pad: Vector3 = aabb_padding
	union_aabb = AABB(union_aabb.position - pad, union_aabb.size + pad * 2.0)
	var cs: CollisionShape3D = _ensure_box_collision()
	var box: BoxShape3D = cs.shape as BoxShape3D
	box.size = union_aabb.size
	cs.position = union_aabb.get_center()


func get_collision_world_aabb() -> AABB:
	var cs: CollisionShape3D = _find_box_collision()
	if cs == null:
		return AABB()
	var box: BoxShape3D = cs.shape as BoxShape3D
	if box == null:
		return AABB()
	var half: Vector3 = box.size * 0.5
	var local_aabb: AABB = AABB(-half, box.size)
	var xf: Transform3D = cs.global_transform
	var result: AABB
	var first: bool = true
	for i in 8:
		var corner: Vector3 = xf * local_aabb.get_endpoint(i)
		if first:
			result = AABB(corner, Vector3.ZERO)
			first = false
		else:
			result = result.expand(corner)
	return result


func bind_outline_root(root: Node) -> void:
	## Attach outline passes to meshes under an external art node (apartment furniture, etc.).
	if root == null or not is_instance_valid(root):
		return
	if _external_outline_roots.has(root):
		return
	_external_outline_roots.append(root)
	if _outlines_ready:
		_setup_outlines()


func _process(delta: float) -> void:
	if _punch_time <= 0.0:
		return
	_punch_time = maxf(_punch_time - delta, 0.0)
	var pulse := 1.0 + sin(_punch_time * PI * 12.0) * 0.12 * (_punch_time / 0.16)
	scale = _base_scale * pulse
	if _punch_time <= 0.0:
		scale = _base_scale


func set_focused(focused: bool) -> void:
	if _focused == focused:
		return
	_focused = focused
	_apply_outline_state()


func get_prompt() -> String:
	return "%s [%s]" % [display_name, action_label]


func on_interact(by: Node) -> void:
	_punch_time = 0.16
	Sfx.play(&"click")
	interacted.emit(by)
	if action_id != &"":
		InteractionRouter.route(action_id, self, by, payload)


func _setup_outlines() -> void:
	_outline_mats.clear()
	_strip_legacy_outline_nodes(self)
	var meshes: Array[MeshInstance3D] = []
	# When furniture/art roots are bound, skip Area-local proxy meshes entirely.
	if _external_outline_roots.is_empty():
		_collect_meshes(self, meshes)
	for root in _external_outline_roots:
		if root == null or not is_instance_valid(root):
			continue
		if root is MeshInstance3D:
			var root_mi := root as MeshInstance3D
			if not _is_detail_mesh(root_mi) and not _is_legacy_outline_mesh(root_mi) and not meshes.has(root_mi):
				meshes.append(root_mi)
		_collect_meshes(root, meshes)
	for mi in meshes:
		var outline := _attach_outline(mi)
		if outline:
			_outline_mats.append(outline)
	_outlines_ready = true
	_apply_outline_state()


func _apply_outline_state() -> void:
	var width := FOCUS_WIDTH if _focused else IDLE_WIDTH
	var color := FOCUS_COLOR if _focused else IDLE_COLOR
	for mat in _outline_mats:
		if mat == null:
			continue
		mat.set_shader_parameter("outline_width", width)
		mat.set_shader_parameter("outline_color", color)


func _attach_outline(mi: MeshInstance3D) -> ShaderMaterial:
	var base: Material = mi.material_override
	if base == null:
		base = mi.get_active_material(0)
	if base == null:
		base = StandardMaterial3D.new()
	# Reuse prior outline pass if we rebuild after bind_outline_root.
	var existing_next: Material = null
	if base is BaseMaterial3D:
		existing_next = (base as BaseMaterial3D).next_pass
	elif base is ShaderMaterial:
		existing_next = (base as ShaderMaterial).next_pass
	if existing_next is ShaderMaterial and (existing_next as ShaderMaterial).shader == OUTLINE_SHADER:
		return existing_next as ShaderMaterial
	# Duplicate so shared girl/prop materials don't fight each other.
	var owned: Material = base.duplicate()
	mi.material_override = owned
	var outline := ShaderMaterial.new()
	outline.shader = OUTLINE_SHADER
	outline.set_shader_parameter("outline_width", IDLE_WIDTH)
	outline.set_shader_parameter("outline_color", IDLE_COLOR)
	if owned is BaseMaterial3D:
		(owned as BaseMaterial3D).next_pass = outline
	elif owned is ShaderMaterial:
		(owned as ShaderMaterial).next_pass = outline
	else:
		return null
	return outline


func _collect_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	for child in node.get_children():
		if child is Label3D:
			continue
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			if not _is_detail_mesh(mi) and not _is_legacy_outline_mesh(mi):
				out.append(mi)
		_collect_meshes(child, out)


func _is_detail_mesh(mi: MeshInstance3D) -> bool:
	return DETAIL_MESH_NAMES.has(str(mi.name))


func _is_legacy_outline_mesh(mi: MeshInstance3D) -> bool:
	var n := str(mi.name)
	return n == "FocusProxy" or n.begins_with("FocusMarker") or n.begins_with("OutlinePlane") or n.begins_with("OutlineExtrude")


func _strip_legacy_outline_nodes(node: Node) -> void:
	for child in node.get_children():
		var n := str(child.name)
		if n == "FocusProxy" or n.begins_with("FocusMarker") or n.begins_with("OutlinePlane") or n.begins_with("OutlineExtrude"):
			child.queue_free()
			continue
		_strip_legacy_outline_nodes(child)


func _force_unit_global_scale() -> void:
	var gs: Vector3 = global_transform.basis.get_scale()
	var sx: float = maxf(absf(gs.x), 0.0001)
	var sy: float = maxf(absf(gs.y), 0.0001)
	var sz: float = maxf(absf(gs.z), 0.0001)
	scale = Vector3(scale.x / sx, scale.y / sy, scale.z / sz)
	_base_scale = scale


func _mesh_aabb_in_self_space(mi: MeshInstance3D) -> AABB:
	var mesh_aabb: AABB = mi.get_aabb()
	var to_self: Transform3D = global_transform.affine_inverse() * mi.global_transform
	var result: AABB
	var first: bool = true
	for i in 8:
		var corner: Vector3 = to_self * mesh_aabb.get_endpoint(i)
		if first:
			result = AABB(corner, Vector3.ZERO)
			first = false
		else:
			result = result.expand(corner)
	return result


func _find_box_collision() -> CollisionShape3D:
	for child in get_children():
		if child is CollisionShape3D:
			var cs: CollisionShape3D = child as CollisionShape3D
			if cs.shape is BoxShape3D:
				return cs
	return null


func _ensure_box_collision() -> CollisionShape3D:
	var cs: CollisionShape3D = _find_box_collision()
	if cs != null:
		return cs
	cs = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(1.2, 1.8, 1.2)
	cs.shape = box
	cs.position = Vector3(0.0, 0.9, 0.0)
	add_child(cs)
	return cs
