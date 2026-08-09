extends Node
## AP1-CHARS presentation self-test: real hair, dual shoes, materials, slot exclusivity.

var _failed: int = 0
var _passed: int = 0
var _spawn_root: Node3D = null


func _ready() -> void:
	await get_tree().process_frame
	_spawn_root = get_node_or_null("SpawnRoot") as Node3D
	if _spawn_root == null:
		_spawn_root = Node3D.new()
		_spawn_root.name = "SpawnRoot"
		add_child(_spawn_root)
	await _run_all()
	var summary: String = ""
	if _failed == 0:
		summary = "VC_CHARS_PRESENTATION_TEST: ALL PASS (%s)" % _passed
	else:
		summary = "VC_CHARS_PRESENTATION_TEST: FAIL passed=%s failed=%s" % [_passed, _failed]
	print(summary)
	var dir_path: String = "res://docs/agent/qa/evidence/ap1_chars_fix3"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	var result_file: FileAccess = FileAccess.open("%s/last_result.txt" % dir_path, FileAccess.WRITE)
	if result_file != null:
		result_file.store_string(summary + "\n")
		result_file.close()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[VC_CHARS_PRESENTATION_TEST] FAIL: %s" % label)
		print("VC_CHARS_PRESENTATION_TEST FAIL: %s" % label)


func _run_all() -> void:
	_test_idle_walk_bind()
	await _test_walk_top_stays_on_chest()
	await _test_hair_and_shoes_rules()
	await _test_slot_bone_heights()
	var ids: PackedStringArray = _list_appearance_ids()
	_ok(ids.size() == 45, "appearance count == 45 (got %s)" % ids.size())
	var snapshots: Dictionary = {}
	for appearance_id in ids:
		var id_name: StringName = StringName(appearance_id)
		var actor: CharacterActor = CharacterFactory.create(id_name, id_name, _spawn_root)
		_ok(actor != null, "%s factory create" % appearance_id)
		if actor == null:
			continue
		var controller: CharacterVariantController = _find_controller(actor)
		_ok(controller != null, "%s has CharacterVariantController" % appearance_id)
		if controller == null:
			continue
		_ok(controller.ensure_slot_bindings(), "%s slot bindings" % appearance_id)
		_ok(_body_is_expected_pack(controller, appearance_id), "%s PACK_021 body" % appearance_id)
		_ok(controller.count_visible_slot_children("HairRoot") == 1, "%s exactly one Hair" % appearance_id)
		_ok(not controller.has_active_primitive_hair(), "%s no primitive hair" % appearance_id)
		_ok(_hair_selection_valid(controller), "%s real hairstyle or bald" % appearance_id)
		_ok(controller.count_visible_slot_children("TopRoot") <= 1, "%s <=1 Top" % appearance_id)
		_ok(controller.count_visible_slot_children("BottomRoot") <= 1, "%s <=1 Bottom" % appearance_id)
		_ok(controller.count_visible_slot_children("ShoesRoot") <= 1, "%s <=1 Shoes pair" % appearance_id)
		_ok(controller.count_visible_shoe_foot_meshes() == 2, "%s left+right shoes" % appearance_id)
		_ok(controller.count_visible_slot_children("HeadAccessoryRoot") <= 1, "%s <=1 HeadAcc" % appearance_id)
		_ok(controller.count_visible_slot_children("NeckAccessoryRoot") <= 1, "%s <=1 NeckAcc" % appearance_id)
		_ok(controller.count_visible_slot_children("HandAccessoryRoot") <= 1, "%s <=1 HandAcc" % appearance_id)
		_ok(_materials_valid(controller), "%s materials valid" % appearance_id)
		await get_tree().process_frame
		_ok(_slot_heights_sane(controller, appearance_id), "%s slot heights on body" % appearance_id)
		snapshots[appearance_id] = _snapshot(controller)
		actor.queue_free()
	for appearance_id in snapshots.keys():
		var id_name2: StringName = StringName(appearance_id)
		var actor2: CharacterActor = CharacterFactory.create(id_name2, id_name2, _spawn_root)
		_ok(actor2 != null, "%s recreate" % appearance_id)
		if actor2 == null:
			continue
		var controller2: CharacterVariantController = _find_controller(actor2)
		_ok(controller2 != null, "%s recreate controller" % appearance_id)
		if controller2 != null:
			var again: Dictionary = _snapshot(controller2)
			_ok(again.hash() == (snapshots[appearance_id] as Dictionary).hash(), "%s deterministic snapshot" % appearance_id)
			_ok(_dicts_equal(again, snapshots[appearance_id] as Dictionary), "%s deterministic fields" % appearance_id)
		actor2.queue_free()


func _test_idle_walk_bind() -> void:
	var male: CharacterActor = CharacterFactory.create(&"appearance_male_base", &"anim_male", _spawn_root)
	var female: CharacterActor = CharacterFactory.create(&"appearance_female_base", &"anim_female", _spawn_root)
	_ok(male != null and female != null, "idle/walk actors")
	if male == null or female == null:
		return
	for actor in [male, female]:
		var typed: CharacterActor = actor as CharacterActor
		var anim: CharacterAnimationController = typed.get_animation_controller()
		_ok(anim != null, "%s anim controller" % String(typed.content_id))
		if anim == null:
			continue
		_ok(anim.has_animation(&"idle"), "%s has idle" % String(typed.content_id))
		_ok(anim.has_animation(&"walk"), "%s has walk" % String(typed.content_id))
		_ok(anim.play_loop(&"idle"), "%s play idle" % String(typed.content_id))
		_ok(anim.get_current_animation_alias() == &"idle", "%s current idle" % String(typed.content_id))
		_ok(anim.play_loop(&"walk"), "%s play walk" % String(typed.content_id))
		_ok(anim.get_current_animation_alias() == &"walk", "%s current walk" % String(typed.content_id))
	male.queue_free()
	female.queue_free()


func _test_walk_top_stays_on_chest() -> void:
	## After 0.4s of walk, top shell centroid must stay on/in front of Chest (not a back plate).
	var sample_ids: PackedStringArray = PackedStringArray([
		"appearance_male_base",
		"appearance_female_base",
		"appearance_male_city_thermos",
		"appearance_female_neighbor",
	])
	for appearance_id in sample_ids:
		var actor: CharacterActor = CharacterFactory.create(
			StringName(appearance_id), StringName("walk_%s" % appearance_id), _spawn_root
		)
		_ok(actor != null, "walk-top create %s" % appearance_id)
		if actor == null:
			continue
		var controller: CharacterVariantController = _find_controller(actor)
		_ok(controller != null, "walk-top controller %s" % appearance_id)
		if controller == null:
			actor.queue_free()
			continue
		controller.ensure_slot_bindings()
		var anim: CharacterAnimationController = actor.get_animation_controller()
		_ok(anim != null and anim.play_loop(&"walk"), "walk-top play walk %s" % appearance_id)
		await get_tree().create_timer(0.4).timeout
		_ok(_top_on_chest_during_pose(controller, appearance_id), "walk-top on chest %s" % appearance_id)
		actor.queue_free()
		await get_tree().process_frame


func _top_on_chest_during_pose(controller: CharacterVariantController, appearance_id: String) -> bool:
	var skel: Skeleton3D = controller.get_body_skeleton()
	if skel == null:
		push_error("%s missing skeleton for walk-top" % appearance_id)
		return false
	var chest_idx: int = skel.find_bone("Chest")
	if chest_idx < 0:
		chest_idx = skel.find_bone("UpperChest")
	if chest_idx < 0:
		push_error("%s missing Chest bone" % appearance_id)
		return false
	var chest_xf: Transform3D = skel.global_transform * skel.get_bone_global_pose(chest_idx)
	var top_center: Vector3 = _visible_slot_aabb_center(controller, "TopRoot")
	if top_center == Vector3.ZERO:
		push_error("%s empty top center during walk" % appearance_id)
		return false
	var local: Vector3 = chest_xf.affine_inverse() * top_center
	# Rest basis: +Z forward. Thin front shell must sit clearly on/in front of chest.
	if local.z < 0.06:
		push_error("%s top not on chest front localZ=%s" % [appearance_id, snappedf(local.z, 0.001)])
		return false
	if absf(local.x) > 0.25:
		push_error("%s top off midline localX=%s" % [appearance_id, snappedf(local.x, 0.001)])
		return false
	return true


func _test_hair_and_shoes_rules() -> void:
	var actor_a: CharacterActor = CharacterFactory.create(&"appearance_male_base", &"hair_iso_a", _spawn_root)
	var actor_b: CharacterActor = CharacterFactory.create(&"appearance_male_base", &"hair_iso_b", _spawn_root)
	_ok(actor_a != null and actor_b != null, "hair isolation actors")
	if actor_a == null or actor_b == null:
		return
	var ctrl_a: CharacterVariantController = _find_controller(actor_a)
	var ctrl_b: CharacterVariantController = _find_controller(actor_b)
	_ok(ctrl_a != null and ctrl_b != null, "hair isolation controllers")
	if ctrl_a == null or ctrl_b == null:
		return
	# Force same style, different colors — instance materials must not leak.
	ctrl_a.apply_variants(&"2", &"blond", &"0", &"gray", &"0", &"navy", &"0", &"none", &"none", &"none")
	ctrl_b.apply_variants(&"2", &"black", &"0", &"gray", &"0", &"navy", &"0", &"none", &"none", &"none")
	await get_tree().process_frame
	var color_a: Color = ctrl_a.sample_visible_hair_albedo()
	var color_b: Color = ctrl_b.sample_visible_hair_albedo()
	_ok(color_a.a > 0.0 and color_b.a > 0.0, "hair colors sampled")
	_ok(not color_a.is_equal_approx(color_b), "hair material instance isolation (A != B)")
	_ok(not ctrl_a.has_active_primitive_hair(), "isolation A no primitive hair")
	_ok(ctrl_a.count_visible_shoe_foot_meshes() == 2, "isolation A dual shoes")
	# Index accept forms: "0"/"00"/0 and "4"/"04".
	ctrl_a.apply_variants(&"00", &"brown", &"0", &"gray", &"0", &"navy", &"0", &"none", &"none", &"none")
	_ok(String(ctrl_a.get_visible_slot_child_name("HairRoot")) == "Hair_00", "accept hair 00")
	ctrl_a.apply_variants(&"04", &"brown", &"0", &"gray", &"0", &"navy", &"0", &"none", &"none", &"none")
	_ok(String(ctrl_a.get_visible_slot_child_name("HairRoot")) == "Hair_04", "accept hair 04")
	ctrl_a.apply_variants(&"05", &"brown", &"0", &"gray", &"0", &"navy", &"0", &"none", &"none", &"none")
	_ok(String(ctrl_a.get_visible_slot_child_name("HairRoot")) == "Hair_04", "migrate legacy hair 05 -> 4")
	actor_a.queue_free()
	actor_b.queue_free()


func _test_slot_bone_heights() -> void:
	var sample_ids: PackedStringArray = PackedStringArray([
		"appearance_male_base",
		"appearance_female_base",
		"appearance_male_city_thermos",
		"appearance_male_city_headphones",
		"appearance_male_gym_mirror",
		"appearance_male_first_clone",
		"appearance_male_public_watch",
		"appearance_female_neighbor",
		"appearance_female_cafe_laptop",
		"appearance_female_gym_timer",
		"appearance_female_city_umbrella",
		"appearance_female_actress",
	])
	var hair_ys: Array[float] = []
	var top_colors: Array[Color] = []
	var kept: Array[CharacterActor] = []
	for i in sample_ids.size():
		var appearance_id: String = sample_ids[i]
		var actor: CharacterActor = CharacterFactory.create(
			StringName(appearance_id), StringName(appearance_id), _spawn_root
		)
		_ok(actor != null, "height sample create %s" % appearance_id)
		if actor == null:
			continue
		actor.global_position = Vector3(float(i) * 1.2, 0.0, 0.0)
		var controller: CharacterVariantController = _find_controller(actor)
		_ok(controller != null, "height sample controller %s" % appearance_id)
		if controller == null:
			actor.queue_free()
			continue
		controller.ensure_slot_bindings()
		await get_tree().process_frame
		var skel: Skeleton3D = controller.get_body_skeleton()
		_ok(skel != null, "%s has Skeleton3D" % appearance_id)
		var hair_att: BoneAttachment3D = controller.get_node_or_null("HairRoot") as BoneAttachment3D
		_ok(hair_att != null and hair_att.use_external_skeleton, "%s HairRoot external" % appearance_id)
		if hair_att != null and skel != null:
			var resolved: Node = hair_att.get_node_or_null(hair_att.external_skeleton)
			_ok(resolved == skel, "%s HairRoot external resolves" % appearance_id)
			_ok(hair_att.bone_idx >= 0, "%s HairRoot bone_idx>=0 (got %s)" % [appearance_id, hair_att.bone_idx])
		var hair_y: float = controller.get_visible_slot_mesh_global_y("HairRoot")
		var top_y: float = controller.get_visible_slot_mesh_global_y("TopRoot")
		var bottom_y: float = controller.get_visible_slot_mesh_global_y("BottomRoot")
		_ok(hair_y > 1.35, "%s hair Y>1.35 (got %s)" % [appearance_id, snappedf(hair_y, 0.001)])
		_ok(top_y > 0.9, "%s top Y>0.9 (got %s)" % [appearance_id, snappedf(top_y, 0.001)])
		_ok(bottom_y > 0.4, "%s bottom Y>0.4 (got %s)" % [appearance_id, snappedf(bottom_y, 0.001)])
		_ok(hair_y > top_y and top_y > bottom_y, "%s hair>top>bottom" % appearance_id)
		_ok(controller.count_visible_shoe_foot_meshes() == 2, "%s dual shoes in sample" % appearance_id)
		_ok(_top_silhouette_ok(controller, appearance_id), "%s top AABB thin shell" % appearance_id)
		_ok(_shoe_pair_size_ok(controller, appearance_id), "%s shoes foot-sized" % appearance_id)
		if appearance_id.begins_with("appearance_female_"):
			_ok(_female_hair_on_scalp(controller, appearance_id), "%s female hair on scalp" % appearance_id)
		hair_ys.append(hair_y)
		var top_mi: MeshInstance3D = _first_visible_mesh(controller.get_node_or_null("TopRoot"))
		if top_mi != null and top_mi.material_override is StandardMaterial3D:
			top_colors.append((top_mi.material_override as StandardMaterial3D).albedo_color)
		kept.append(actor)
	await _capture_lineup_evidence(kept)
	for actor_free in kept:
		if is_instance_valid(actor_free):
			actor_free.queue_free()
	await get_tree().process_frame
	var distinct_hair: bool = false
	for i in hair_ys.size():
		for j in range(i + 1, hair_ys.size()):
			if absf(hair_ys[i] - hair_ys[j]) > 0.05:
				distinct_hair = true
				break
	var distinct_color: bool = false
	for i in top_colors.size():
		for j in range(i + 1, top_colors.size()):
			if top_colors[i].is_equal_approx(top_colors[j]) == false:
				distinct_color = true
				break
	_ok(distinct_hair or distinct_color, "sample profiles look distinct (hair height or top color)")


func _capture_lineup_evidence(actors: Array[CharacterActor]) -> void:
	if actors.is_empty():
		return
	var dir_path: String = "res://docs/agent/qa/evidence/ap1_chars_fix3"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	var before_src: String = ProjectSettings.globalize_path("res://docs/agent/qa/evidence/ap1_chars_fix2/after_lineup_variants.png")
	var before_dst: String = ProjectSettings.globalize_path("%s/before_lineup_variants.png" % dir_path)
	if FileAccess.file_exists(before_src):
		DirAccess.copy_absolute(before_src, before_dst)
	var metrics: Array = []
	for actor in actors:
		if actor == null or not is_instance_valid(actor):
			continue
		var controller: CharacterVariantController = _find_controller(actor)
		if controller == null:
			continue
		var hair_att: BoneAttachment3D = controller.get_node_or_null("HairRoot") as BoneAttachment3D
		var top_sz: Vector3 = _visible_top_aabb_size(controller)
		var hair_c: Vector3 = _visible_slot_aabb_center(controller, "HairRoot")
		metrics.append({
			"id": String(actor.content_id),
			"hair_y": snappedf(controller.get_visible_slot_mesh_global_y("HairRoot"), 0.001),
			"top_y": snappedf(controller.get_visible_slot_mesh_global_y("TopRoot"), 0.001),
			"bottom_y": snappedf(controller.get_visible_slot_mesh_global_y("BottomRoot"), 0.001),
			"shoes_feet": controller.count_visible_shoe_foot_meshes(),
			"hair_child": String(controller.get_visible_slot_child_name("HairRoot")),
			"hair_path": controller.get_active_hair_resource_path(),
			"top_child": String(controller.get_visible_slot_child_name("TopRoot")),
			"bottom_child": String(controller.get_visible_slot_child_name("BottomRoot")),
			"hair_bone_idx": hair_att.bone_idx if hair_att != null else -1,
			"hair_ext": str(hair_att.external_skeleton) if hair_att != null else "",
			"top_aabb": [snappedf(top_sz.x, 0.001), snappedf(top_sz.y, 0.001), snappedf(top_sz.z, 0.001)],
			"hair_center": [snappedf(hair_c.x, 0.001), snappedf(hair_c.y, 0.001), snappedf(hair_c.z, 0.001)],
		})
	var metrics_path: String = "%s/after_slot_heights.json" % dir_path
	var metrics_file: FileAccess = FileAccess.open(metrics_path, FileAccess.WRITE)
	if metrics_file != null:
		metrics_file.store_string(JSON.stringify(metrics, "\t"))
		metrics_file.close()
		print("VC_CHARS_PRESENTATION_TEST metrics path=%s count=%s" % [metrics_path, metrics.size()])
	var light := DirectionalLight3D.new()
	light.name = "EvidenceLight"
	light.rotation_degrees = Vector3(-35.0, 35.0, 0.0)
	light.light_energy = 1.25
	_spawn_root.add_child(light)
	var env_node := WorldEnvironment.new()
	env_node.name = "EvidenceEnv"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.17, 0.2)
	env_node.environment = env
	_spawn_root.add_child(env_node)
	var cam := Camera3D.new()
	cam.name = "EvidenceCam"
	_spawn_root.add_child(cam)
	var mid_x: float = maxf(0.0, float(actors.size() - 1) * 0.6)
	cam.global_position = Vector3(mid_x, 1.4, 7.4)
	cam.look_at(Vector3(mid_x, 1.0, 0.0), Vector3.UP)
	cam.current = true
	await get_tree().process_frame
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		var out_path: String = "%s/after_lineup_variants.png" % dir_path
		var err: Error = img.save_png(out_path)
		print("VC_CHARS_PRESENTATION_TEST evidence save=%s path=%s" % [str(err), out_path])
	cam.queue_free()
	light.queue_free()
	env_node.queue_free()
	await get_tree().process_frame


func _slot_heights_sane(controller: CharacterVariantController, appearance_id: String) -> bool:
	var hair_y: float = controller.get_visible_slot_mesh_global_y("HairRoot")
	var top_y: float = controller.get_visible_slot_mesh_global_y("TopRoot")
	var bottom_y: float = controller.get_visible_slot_mesh_global_y("BottomRoot")
	if hair_y <= 1.35:
		push_error("%s hair Y=%s" % [appearance_id, hair_y])
		return false
	if top_y <= 0.9:
		push_error("%s top Y=%s" % [appearance_id, top_y])
		return false
	if bottom_y <= 0.4:
		push_error("%s bottom Y=%s" % [appearance_id, bottom_y])
		return false
	if not _top_silhouette_ok(controller, appearance_id):
		return false
	return hair_y > top_y and top_y > bottom_y


func _top_silhouette_ok(controller: CharacterVariantController, appearance_id: String) -> bool:
	var mi: MeshInstance3D = _first_visible_mesh(controller.get_node_or_null("TopRoot"))
	if mi == null or mi.mesh == null:
		return true
	# Prefer local BoxMesh size — idle bone tilt inflates world AABB without making clothing thicker.
	var sz: Vector3 = Vector3.ZERO
	if mi.mesh is BoxMesh:
		sz = (mi.mesh as BoxMesh).size
	else:
		sz = (mi.global_transform * mi.mesh.get_aabb()).size
	if sz.z >= 0.35:
		push_error("%s top depth z=%s" % [appearance_id, sz.z])
		return false
	if sz.x >= 0.55:
		push_error("%s top width x=%s" % [appearance_id, sz.x])
		return false
	return true


func _shoe_pair_size_ok(controller: CharacterVariantController, appearance_id: String) -> bool:
	var shoes: Node = controller.get_node_or_null("ShoesRoot")
	if shoes == null:
		return false
	var ok_count: int = 0
	for child in shoes.get_children():
		var n3: Node3D = child as Node3D
		if n3 == null or not n3.visible:
			continue
		for side in ["LeftFootAttachment", "RightFootAttachment"]:
			var att: Node = n3.get_node_or_null(side)
			if att == null:
				continue
			var mi: MeshInstance3D = _first_mesh(att)
			if mi == null or mi.mesh == null:
				continue
			var aabb: AABB = mi.global_transform * mi.mesh.get_aabb()
			# Foot-sized: long axis ~0.18-0.32, height under ankle (~<=0.14).
			if aabb.size.z < 0.18 or aabb.size.z > 0.34:
				push_error("%s %s length z=%s" % [appearance_id, side, aabb.size.z])
				return false
			if aabb.size.y > 0.14:
				push_error("%s %s height y=%s" % [appearance_id, side, aabb.size.y])
				return false
			if aabb.get_center().y > 0.22:
				push_error("%s %s centerY=%s" % [appearance_id, side, aabb.get_center().y])
				return false
			ok_count += 1
	return ok_count == 2


func _female_hair_on_scalp(controller: CharacterVariantController, appearance_id: String) -> bool:
	if controller.get_active_hair_resource_path() == "":
		return true
	var center: Vector3 = _visible_slot_aabb_center(controller, "HairRoot")
	var hair_att: BoneAttachment3D = controller.get_node_or_null("HairRoot") as BoneAttachment3D
	if hair_att == null:
		return false
	if center.y <= 1.35:
		push_error("%s hair centerY=%s" % [appearance_id, center.y])
		return false
	# Scalp sits above head bone; reject mouth/mustache zone near/below head bone.
	if center.y < hair_att.global_position.y + 0.08:
		push_error("%s hair below scalp (cY=%s headY=%s)" % [appearance_id, center.y, hair_att.global_position.y])
		return false
	return true


func _visible_top_aabb_size(controller: CharacterVariantController) -> Vector3:
	var mi: MeshInstance3D = _first_visible_mesh(controller.get_node_or_null("TopRoot"))
	if mi == null or mi.mesh == null:
		return Vector3.ZERO
	if mi.mesh is BoxMesh:
		return (mi.mesh as BoxMesh).size
	var aabb: AABB = mi.global_transform * mi.mesh.get_aabb()
	return aabb.size


func _visible_slot_aabb_center(controller: CharacterVariantController, slot_root_name: String) -> Vector3:
	var root: Node = controller.get_node_or_null(slot_root_name)
	if root == null:
		return Vector3.ZERO
	var sum := Vector3.ZERO
	var count: int = 0
	for child in root.get_children():
		var n3: Node3D = child as Node3D
		if n3 == null or not n3.visible:
			continue
		var stack: Array[Node] = [n3]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			var mi: MeshInstance3D = n as MeshInstance3D
			if mi != null and mi.mesh != null and mi.is_visible_in_tree():
				var aabb: AABB = mi.global_transform * mi.mesh.get_aabb()
				sum += aabb.get_center()
				count += 1
			for c in n.get_children():
				stack.append(c)
	if count <= 0:
		return Vector3.ZERO
	return sum / float(count)


func _list_appearance_ids() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var dir: DirAccess = DirAccess.open("res://data/content/appearances")
	if dir == null:
		return out
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres") and file_name.begins_with("appearance_"):
			out.append(file_name.get_basename())
		file_name = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out


func _find_controller(actor: CharacterActor) -> CharacterVariantController:
	if actor == null:
		return null
	var visual_root: Node = actor.get_node_or_null("VisualRoot")
	if visual_root == null:
		return null
	var queue: Array[Node] = [visual_root]
	while not queue.is_empty():
		var node: Node = queue.pop_front()
		var typed: CharacterVariantController = node as CharacterVariantController
		if typed != null:
			return typed
		for child in node.get_children():
			queue.append(child)
	return null


func _body_is_expected_pack(controller: CharacterVariantController, appearance_id: String) -> bool:
	var body: Node = controller.get_node_or_null("Body")
	if body == null:
		return false
	var scene_path: String = String(body.scene_file_path)
	if appearance_id.begins_with("appearance_male_"):
		return scene_path.ends_with("Superhero_Male_FullBody.gltf")
	if appearance_id.begins_with("appearance_female_"):
		return scene_path.ends_with("Superhero_Female_FullBody.gltf")
	return false


func _hair_selection_valid(controller: CharacterVariantController) -> bool:
	var path: String = controller.get_active_hair_resource_path()
	if path == "":
		return true # bald
	var allowed: PackedStringArray = PackedStringArray([
		"Hair_Buzzed.gltf",
		"Hair_BuzzedFemale.gltf",
		"Hair_SimpleParted.gltf",
		"Hair_Long.gltf",
		"Hair_Buns.gltf",
	])
	var file_name: String = path.get_file()
	if file_name == "Hair_Beard.gltf":
		return false
	return allowed.has(file_name)


func _materials_valid(controller: CharacterVariantController) -> bool:
	for slot_name in ["HairRoot", "TopRoot", "BottomRoot", "ShoesRoot", "HeadAccessoryRoot", "NeckAccessoryRoot", "HandAccessoryRoot"]:
		var slot: Node = controller.get_node_or_null(slot_name)
		if slot == null:
			return false
		for child in slot.get_children():
			var n3: Node3D = child as Node3D
			if n3 == null or not n3.visible:
				continue
			if String(n3.name).ends_with("_None"):
				continue
			if slot_name == "HairRoot" and not _has_mesh(n3):
				continue # bald
			var mi: MeshInstance3D = _first_mesh(n3)
			if mi == null or mi.mesh == null:
				return false
			if mi.material_override == null and mi.get_active_material(0) == null:
				return false
	return true


func _first_visible_mesh(slot: Node) -> MeshInstance3D:
	if slot == null:
		return null
	for child in slot.get_children():
		var n3: Node3D = child as Node3D
		if n3 == null or not n3.visible:
			continue
		var mi: MeshInstance3D = _first_mesh(n3)
		if mi != null:
			return mi
	return null


func _first_mesh(node: Node) -> MeshInstance3D:
	var as_mi: MeshInstance3D = node as MeshInstance3D
	if as_mi != null and as_mi.mesh != null:
		return as_mi
	for child in node.get_children():
		var found: MeshInstance3D = _first_mesh(child)
		if found != null:
			return found
	return null


func _has_mesh(node: Node) -> bool:
	return _first_mesh(node) != null


func _snapshot(controller: CharacterVariantController) -> Dictionary:
	return {
		"hair": String(controller.get_visible_slot_child_name("HairRoot")),
		"top": String(controller.get_visible_slot_child_name("TopRoot")),
		"bottom": String(controller.get_visible_slot_child_name("BottomRoot")),
		"shoes": String(controller.get_visible_slot_child_name("ShoesRoot")),
		"head": String(controller.get_visible_slot_child_name("HeadAccessoryRoot")),
		"neck": String(controller.get_visible_slot_child_name("NeckAccessoryRoot")),
		"hand": String(controller.get_visible_slot_child_name("HandAccessoryRoot")),
		"shoe_feet": controller.count_visible_shoe_foot_meshes(),
	}


func _dicts_equal(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for key in a.keys():
		if not b.has(key):
			return false
		if str(a[key]) != str(b[key]):
			return false
	return true
