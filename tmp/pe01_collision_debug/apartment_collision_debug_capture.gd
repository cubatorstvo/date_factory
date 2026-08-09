extends Node
## Development-only PE01 apartment collision-debug capture.
## Instances production apartment read-only; overlays collider volumes; writes six PNGs.
## Does NOT mutate GameState/Story/saves or edit production scenes.

const ABS_OUT: String = "C:/Users/User/Documents/GodotProjects/date_factory/tmp/pe01_collision_debug/evidence"

var _failed: int = 0
var _passed: int = 0
var _overlay_root: Node3D
var _cam: Camera3D
var _collider_count: int = 0
var _overlays: Array[MeshInstance3D] = []


func _ready() -> void:
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ABS_OUT)
	print("PE01_COL_DBG: start out=%s" % ABS_OUT)

	var packed: PackedScene = load("res://world/locations/apartment/apartment.tscn") as PackedScene
	_ok(packed != null, "load production apartment.tscn")
	if packed == null:
		_finish()
		return

	var loc: Node3D = packed.instantiate() as Node3D
	_ok(loc != null, "instantiate apartment")
	if loc == null:
		_finish()
		return
	add_child(loc)
	await get_tree().process_frame
	await get_tree().process_frame

	_overlay_root = Node3D.new()
	_overlay_root.name = "DevCollisionOverlay"
	add_child(_overlay_root)

	_build_overlays_from_static_bodies(loc)
	_build_overlays_from_csg(loc)
	_ok(_collider_count > 0, "overlay volumes created count=%s" % _collider_count)
	print("PE01_COL_DBG: overlay_count=%s" % _collider_count)

	_cam = Camera3D.new()
	_cam.name = "DevCollisionCamera"
	_cam.current = true
	_cam.fov = 62.0
	_cam.near = 0.05
	_cam.far = 40.0
	add_child(_cam)

	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	# Room is ~5x5 (walls at ±2.5). Keep cameras inside so we never clip wall CSG fills.
	await _capture_shot(
		"apartment_collision_overview.png",
		Vector3(-0.15, 3.05, 1.45),
		Vector3(0.1, 0.45, -0.65),
		"all",
		"overview room + all essential collider volumes"
	)
	await _capture_shot(
		"apartment_collision_bed.png",
		Vector3(0.15, 1.65, 0.05),
		Vector3(1.55, 0.35, -1.55),
		"bed",
		"bed + nightstand meshes with BedBody/NightStandBody boxes"
	)
	await _capture_shot(
		"apartment_collision_table.png",
		Vector3(-0.55, 1.55, 1.55),
		Vector3(0.4, 0.45, 0.61),
		"table",
		"dining table + chairs with DiningTable/Chair boxes"
	)
	await _capture_shot(
		"apartment_collision_kitchen.png",
		Vector3(0.55, 1.55, -0.35),
		Vector3(-1.0, 0.75, -2.15),
		"kitchen",
		"kitchen run fridge/oven/sink/drawers + counter boxes"
	)
	await _capture_shot(
		"apartment_collision_storage.png",
		Vector3(0.45, 1.6, 1.35),
		Vector3(2.15, 0.8, 0.95),
		"storage",
		"wardrobe/storage mesh + WardrobeBody box"
	)
	await _capture_shot(
		"apartment_collision_exit.png",
		Vector3(-1.15, 1.45, 0.7),
		Vector3(-2.42, 1.05, 0.25),
		"exit",
		"city exit door mesh + ExitDoorBody box"
	)

	_finish()


func _build_overlays_from_static_bodies(root: Node) -> void:
	var bodies: Array[Node] = []
	_collect_by_class(root, "StaticBody3D", bodies)
	for body_n in bodies:
		var body: StaticBody3D = body_n as StaticBody3D
		if body == null:
			continue
		for child in body.get_children():
			var cs: CollisionShape3D = child as CollisionShape3D
			if cs == null or cs.disabled or cs.shape == null:
				continue
			var path_l: String = str(body.get_path()).to_lower()
			var color: Color = _color_for_path(path_l)
			var tags: PackedStringArray = _tags_for_path(path_l)
			if _add_shape_overlay(cs, color, tags, str(body.name)):
				_collider_count += 1


func _build_overlays_from_csg(root: Node) -> void:
	var nodes: Array[Node] = []
	_collect_by_class(root, "CSGShape3D", nodes)
	for n in nodes:
		var csg: CSGShape3D = n as CSGShape3D
		if csg == null or not csg.use_collision:
			continue
		var box: CSGBox3D = csg as CSGBox3D
		if box == null:
			continue
		var mi := MeshInstance3D.new()
		mi.name = "OverlayCSG_%s" % box.name
		var mesh := BoxMesh.new()
		mesh.size = box.size
		mi.mesh = mesh
		mi.material_override = _make_overlay_material(Color(1.0, 0.85, 0.2, 0.07))
		mi.set_meta("focus_tags", PackedStringArray(["all", "arch"]))
		mi.set_meta("base_color", Color(1.0, 0.85, 0.2, 0.07))
		_overlay_root.add_child(mi)
		mi.global_transform = box.global_transform
		_overlays.append(mi)
		_collider_count += 1


func _add_shape_overlay(cs: CollisionShape3D, color: Color, tags: PackedStringArray, body_name: String) -> bool:
	var shape: Shape3D = cs.shape
	var mesh: Mesh = null
	if shape is BoxShape3D:
		var box_shape: BoxShape3D = shape as BoxShape3D
		var box_mesh := BoxMesh.new()
		box_mesh.size = box_shape.size
		mesh = box_mesh
	elif shape is SphereShape3D:
		var sphere_shape: SphereShape3D = shape as SphereShape3D
		var sphere_mesh := SphereMesh.new()
		sphere_mesh.radius = sphere_shape.radius
		sphere_mesh.height = sphere_shape.radius * 2.0
		mesh = sphere_mesh
	elif shape is CapsuleShape3D:
		var cap_shape: CapsuleShape3D = shape as CapsuleShape3D
		var cap_mesh := CapsuleMesh.new()
		cap_mesh.radius = cap_shape.radius
		cap_mesh.height = cap_shape.height
		mesh = cap_mesh
	elif shape is CylinderShape3D:
		var cyl_shape: CylinderShape3D = shape as CylinderShape3D
		var cyl_mesh := CylinderMesh.new()
		cyl_mesh.top_radius = cyl_shape.radius
		cyl_mesh.bottom_radius = cyl_shape.radius
		cyl_mesh.height = cyl_shape.height
		mesh = cyl_mesh
	else:
		print("PE01_COL_DBG: skip unsupported shape %s at %s" % [shape.get_class(), cs.get_path()])
		return false

	var fill := MeshInstance3D.new()
	fill.name = "OverlayFill_%s" % body_name
	fill.mesh = mesh
	fill.material_override = _make_overlay_material(color)
	fill.set_meta("focus_tags", tags)
	fill.set_meta("base_color", color)
	_overlay_root.add_child(fill)
	fill.global_transform = cs.global_transform
	_overlays.append(fill)

	var outline := MeshInstance3D.new()
	outline.name = "OverlayWire_%s" % body_name
	if mesh is BoxMesh:
		var om := BoxMesh.new()
		var src: BoxMesh = mesh as BoxMesh
		om.size = src.size * 1.015
		outline.mesh = om
	else:
		outline.mesh = mesh.duplicate()
	var wire_col: Color = color
	wire_col.a = minf(0.9, color.a + 0.4)
	outline.material_override = _make_overlay_material(wire_col)
	outline.set_meta("focus_tags", tags)
	outline.set_meta("base_color", wire_col)
	_overlay_root.add_child(outline)
	outline.global_transform = cs.global_transform
	_overlays.append(outline)
	return true


func _make_overlay_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Draw over meshes so in-volume colliders remain readable diagnostics.
	mat.no_depth_test = true
	mat.render_priority = 10
	mat.disable_receive_shadows = true
	return mat


func _color_for_path(path_l: String) -> Color:
	# Keep alpha modest: no_depth_test overlays must not hide production meshes.
	if path_l.find("bed") >= 0 or path_l.find("nightstand") >= 0:
		return Color(0.15, 0.95, 1.0, 0.28)
	if path_l.find("dining") >= 0 or path_l.find("table") >= 0 or path_l.find("chair") >= 0:
		return Color(0.2, 1.0, 0.35, 0.28)
	if (
		path_l.find("fridge") >= 0
		or path_l.find("oven") >= 0
		or path_l.find("kitchen") >= 0
		or path_l.find("sink") >= 0
		or path_l.find("drawer") >= 0
	):
		return Color(1.0, 0.5, 0.12, 0.3)
	if path_l.find("wardrobe") >= 0 or path_l.find("bookshelf") >= 0:
		return Color(0.95, 0.3, 1.0, 0.3)
	if path_l.find("exit") >= 0:
		return Color(1.0, 0.12, 0.35, 0.38)
	if path_l.find("neighbor") >= 0 or path_l.find("door") >= 0:
		return Color(1.0, 0.35, 0.55, 0.22)
	if path_l.find("trash") >= 0:
		return Color(0.75, 0.75, 0.75, 0.22)
	return Color(0.2, 0.95, 0.95, 0.25)


func _tags_for_path(path_l: String) -> PackedStringArray:
	var tags: PackedStringArray = PackedStringArray(["all"])
	if path_l.find("bed") >= 0 or path_l.find("nightstand") >= 0:
		tags.append("bed")
	if path_l.find("dining") >= 0 or path_l.find("table") >= 0 or path_l.find("chair") >= 0:
		tags.append("table")
	if (
		path_l.find("fridge") >= 0
		or path_l.find("oven") >= 0
		or path_l.find("kitchen") >= 0
		or path_l.find("sink") >= 0
		or path_l.find("drawer") >= 0
		or path_l.find("trash") >= 0
	):
		tags.append("kitchen")
	if path_l.find("wardrobe") >= 0 or path_l.find("bookshelf") >= 0:
		tags.append("storage")
	if path_l.find("exit") >= 0:
		tags.append("exit")
	if path_l.find("neighbor") >= 0:
		tags.append("neighbor")
	return tags


func _apply_focus(focus: String) -> void:
	for mi in _overlays:
		var tags: PackedStringArray = mi.get_meta("focus_tags", PackedStringArray(["all"])) as PackedStringArray
		var base: Color = mi.get_meta("base_color", Color(1, 1, 1, 0.3)) as Color
		var mat: StandardMaterial3D = mi.material_override as StandardMaterial3D
		if mat == null:
			continue
		# Non-overview shots boost focused volumes and dim the rest for readability.
		if focus == "all":
			mat.albedo_color = base
			mi.visible = true
		elif tags.has(focus):
			var hot: Color = base
			hot.a = minf(0.4, base.a + 0.12)
			mat.albedo_color = hot
			mi.visible = true
		else:
			var cool: Color = base
			cool.a = 0.04
			mat.albedo_color = cool
			mi.visible = true


func _collect_by_class(node: Node, class_name_str: String, out: Array[Node]) -> void:
	if node.is_class(class_name_str):
		out.append(node)
	for child in node.get_children():
		_collect_by_class(child, class_name_str, out)


func _capture_shot(
	filename: String,
	cam_pos: Vector3,
	look_at: Vector3,
	focus: String,
	label: String
) -> void:
	_apply_focus(focus)
	_cam.global_position = cam_pos
	_cam.look_at(look_at, Vector3.UP)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var ok: bool = _save_shot(filename)
	_ok(ok, "shot %s (%s)" % [filename, label])
	print("PE01_COL_DBG: captured %s focus=%s -> %s" % [filename, focus, label])


func _save_shot(filename: String) -> bool:
	var tex: ViewportTexture = get_viewport().get_texture()
	if tex == null:
		return false
	var img: Image = tex.get_image()
	if img == null:
		return false
	var abs_path: String = ABS_OUT.path_join(filename)
	var err: Error = img.save_png(abs_path)
	print(
		"CAPTURE %s err=%s path=%s size=%sx%s"
		% [filename, err, abs_path, img.get_width(), img.get_height()]
	)
	return err == OK


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("PE01_COL_DBG PASS: %s" % label)
	else:
		_failed += 1
		push_error("PE01_COL_DBG FAIL: %s" % label)
		print("PE01_COL_DBG FAIL: %s" % label)


func _finish() -> void:
	if _failed == 0:
		print("PE01_COL_DBG: ALL PASS (%s)" % _passed)
	else:
		print("PE01_COL_DBG: FAIL passed=%s failed=%s" % [_passed, _failed])
	get_tree().create_timer(0.25).timeout.connect(
		func() -> void:
			get_tree().quit(0 if _failed == 0 else 1)
	)
