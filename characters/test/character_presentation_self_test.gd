extends Node
## VC-CHARS presentation self-test: modular slots, materials, deterministic profiles.

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
	_run_all()
	if _failed == 0:
		print("VC_CHARS_PRESENTATION_TEST: ALL PASS (%s)" % _passed)
	else:
		print("VC_CHARS_PRESENTATION_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
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
		_ok(_body_is_expected_pack(controller, appearance_id), "%s PACK_021 body" % appearance_id)
		_ok(controller.count_visible_slot_children("HairRoot") == 1, "%s exactly one Hair" % appearance_id)
		_ok(controller.count_visible_slot_children("TopRoot") <= 1, "%s <=1 Top" % appearance_id)
		_ok(controller.count_visible_slot_children("BottomRoot") <= 1, "%s <=1 Bottom" % appearance_id)
		_ok(controller.count_visible_slot_children("ShoesRoot") <= 1, "%s <=1 Shoes" % appearance_id)
		_ok(controller.count_visible_slot_children("HeadAccessoryRoot") <= 1, "%s <=1 HeadAcc" % appearance_id)
		_ok(controller.count_visible_slot_children("NeckAccessoryRoot") <= 1, "%s <=1 NeckAcc" % appearance_id)
		_ok(controller.count_visible_slot_children("HandAccessoryRoot") <= 1, "%s <=1 HandAcc" % appearance_id)
		_ok(_materials_valid(controller), "%s materials valid" % appearance_id)
		snapshots[appearance_id] = _snapshot(controller)
		actor.queue_free()
	# Determinism: recreate and compare snapshots (no RNG / save-load randomization).
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
			var mi: MeshInstance3D = n3.get_node_or_null("Mesh") as MeshInstance3D
			if mi == null:
				return false
			if mi.mesh == null:
				return false
			if mi.material_override == null:
				return false
	return true


func _snapshot(controller: CharacterVariantController) -> Dictionary:
	return {
		"hair": String(controller.get_visible_slot_child_name("HairRoot")),
		"top": String(controller.get_visible_slot_child_name("TopRoot")),
		"bottom": String(controller.get_visible_slot_child_name("BottomRoot")),
		"shoes": String(controller.get_visible_slot_child_name("ShoesRoot")),
		"head": String(controller.get_visible_slot_child_name("HeadAccessoryRoot")),
		"neck": String(controller.get_visible_slot_child_name("NeckAccessoryRoot")),
		"hand": String(controller.get_visible_slot_child_name("HandAccessoryRoot")),
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
