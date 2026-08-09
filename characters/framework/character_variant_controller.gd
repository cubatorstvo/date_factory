class_name CharacterVariantController
extends Node3D
## Presentation-only modular outfit/hair controller for PACK_021 bases.
## Shows exactly one child per slot and applies per-instance material color overrides.
## Binds BoneAttachment3D slots (and nested sleeve/foot attachments) to Body Skeleton3D.

const HAIR_COLOR_MAP: Dictionary = {
	&"black": Color(0.08, 0.07, 0.07),
	&"brown": Color(0.28, 0.16, 0.08),
	&"blond": Color(0.82, 0.72, 0.42),
	&"red": Color(0.62, 0.18, 0.10),
	&"unusual": Color(0.22, 0.10, 0.34),
}

const CLOTH_COLOR_MAP: Dictionary = {
	&"gray": Color(0.45, 0.46, 0.48),
	&"navy": Color(0.12, 0.18, 0.34),
	&"black": Color(0.08, 0.08, 0.09),
	&"white": Color(0.88, 0.88, 0.90),
	&"red": Color(0.62, 0.16, 0.14),
	&"green": Color(0.18, 0.42, 0.24),
	&"beige": Color(0.72, 0.62, 0.48),
	&"teal": Color(0.14, 0.42, 0.46),
	&"purple": Color(0.34, 0.18, 0.42),
	&"orange": Color(0.72, 0.38, 0.14),
}

## Slot root name -> preferred bone name (PACK_021 Superhero_*_FullBody).
const SLOT_BONE_MAP: Dictionary = {
	"HairRoot": &"Head",
	"TopRoot": &"UpperChest",
	"BottomRoot": &"Hips",
	"HeadAccessoryRoot": &"Head",
	"NeckAccessoryRoot": &"Neck",
	"HandAccessoryRoot": &"LeftHand",
}

## Nested attachment node name -> preferred bone.
const NESTED_BONE_MAP: Dictionary = {
	"LeftSleeveAttachment": &"LeftUpperArm",
	"RightSleeveAttachment": &"RightUpperArm",
	"HoodAttachment": &"Head",
	"LeftLegAttachment": &"LeftUpperLeg",
	"RightLegAttachment": &"RightUpperLeg",
	"LeftFootAttachment": &"LeftFoot",
	"RightFootAttachment": &"RightFoot",
}

## Fallbacks if a preferred bone is missing on a future rig.
const BONE_FALLBACKS: Dictionary = {
	&"Head": [&"Head", &"head", &"Neck", &"Chest"],
	&"UpperChest": [&"UpperChest", &"Chest", &"Spine", &"Hips"],
	&"Hips": [&"Hips", &"hips", &"Spine", &"Root"],
	&"LeftFoot": [&"LeftFoot", &"LeftToes", &"LeftLowerLeg", &"Hips"],
	&"RightFoot": [&"RightFoot", &"RightToes", &"RightLowerLeg", &"Hips"],
	&"Neck": [&"Neck", &"Head", &"UpperChest", &"Chest"],
	&"LeftHand": [&"LeftHand", &"LeftLowerArm", &"LeftUpperArm", &"UpperChest"],
	&"LeftUpperArm": [&"LeftUpperArm", &"LeftArm", &"LeftLowerArm", &"UpperChest"],
	&"RightUpperArm": [&"RightUpperArm", &"RightArm", &"RightLowerArm", &"UpperChest"],
	&"LeftUpperLeg": [&"LeftUpperLeg", &"LeftLeg", &"LeftLowerLeg", &"Hips"],
	&"RightUpperLeg": [&"RightUpperLeg", &"RightLeg", &"RightLowerLeg", &"Hips"],
}

var _slots_bound: bool = false


func _ready() -> void:
	_ensure_slot_bindings()


func apply_variants(
	hair_variant: StringName = &"0",
	hair_color: StringName = &"brown",
	top_variant: StringName = &"0",
	top_color: StringName = &"gray",
	bottom_variant: StringName = &"0",
	bottom_color: StringName = &"navy",
	shoes_variant: StringName = &"0",
	head_accessory: StringName = &"none",
	neck_accessory: StringName = &"none",
	hand_accessory: StringName = &"none"
) -> void:
	_ensure_slot_bindings()
	_select_slot_child("HairRoot", _hair_node_name(hair_variant))
	_select_slot_child("TopRoot", _numbered_node_name("Top", top_variant, 0, 3))
	_select_slot_child("BottomRoot", _numbered_node_name("Bottom", bottom_variant, 0, 2))
	_select_slot_child("ShoesRoot", _numbered_node_name("Shoes", shoes_variant, 0, 1))
	_select_slot_child("HeadAccessoryRoot", _accessory_node_name("Head", head_accessory))
	_select_slot_child("NeckAccessoryRoot", _accessory_node_name("Neck", neck_accessory))
	_select_slot_child("HandAccessoryRoot", _accessory_node_name("Hand", hand_accessory))
	_apply_color_to_visible("HairRoot", _resolve_hair_color(hair_color))
	_apply_color_to_visible("TopRoot", _resolve_cloth_color(top_color))
	_apply_color_to_visible("BottomRoot", _resolve_cloth_color(bottom_color))
	_apply_color_to_visible("ShoesRoot", _resolve_cloth_color(&"black"))


func apply_from_profile(profile: AppearanceProfileDefinition) -> void:
	if profile == null:
		return
	apply_variants(
		profile.hair_variant,
		profile.hair_color,
		profile.top_variant,
		profile.top_color,
		profile.bottom_variant,
		profile.bottom_color,
		profile.shoes_variant,
		profile.head_accessory,
		profile.neck_accessory,
		profile.hand_accessory
	)


func ensure_slot_bindings() -> bool:
	return _ensure_slot_bindings()


func get_body_skeleton() -> Skeleton3D:
	return _find_body_skeleton()


func get_visible_slot_child_name(slot_root_name: String) -> StringName:
	var root: Node = get_node_or_null(slot_root_name)
	if root == null:
		return &""
	for child in root.get_children():
		if _is_node_visible(child):
			return StringName(child.name)
	return &""


func count_visible_slot_children(slot_root_name: String) -> int:
	var root: Node = get_node_or_null(slot_root_name)
	if root == null:
		return 0
	var count: int = 0
	for child in root.get_children():
		if _is_node_visible(child):
			count += 1
	return count


func count_visible_shoe_foot_meshes() -> int:
	var shoes_root: Node = get_node_or_null("ShoesRoot")
	if shoes_root == null:
		return 0
	var count: int = 0
	for child in shoes_root.get_children():
		if not _is_node_visible(child):
			continue
		var left_att: Node = child.get_node_or_null("LeftFootAttachment")
		var right_att: Node = child.get_node_or_null("RightFootAttachment")
		if left_att != null and _has_visible_mesh(left_att):
			count += 1
		if right_att != null and _has_visible_mesh(right_att):
			count += 1
	return count


func get_visible_slot_mesh_global_y(slot_root_name: String) -> float:
	var root: Node = get_node_or_null(slot_root_name)
	if root == null:
		return -INF
	for child in root.get_children():
		var n3: Node3D = child as Node3D
		if n3 == null or not n3.visible:
			continue
		if String(n3.name).ends_with("_None") or (slot_root_name == "HairRoot" and not _has_visible_mesh(n3)):
			# Bald / empty holder: use attachment height.
			return n3.global_position.y
		var center_y: float = _visible_mesh_aabb_center_y(n3)
		if center_y > -INF:
			return center_y
		return n3.global_position.y
	return -INF


func _visible_mesh_aabb_center_y(node: Node) -> float:
	var sum_y: float = 0.0
	var count: int = 0
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		var mi: MeshInstance3D = n as MeshInstance3D
		if mi != null and mi.mesh != null and mi.is_visible_in_tree():
			var aabb: AABB = mi.global_transform * mi.mesh.get_aabb()
			sum_y += aabb.get_center().y
			count += 1
		for child in n.get_children():
			stack.append(child)
	if count <= 0:
		return -INF
	return sum_y / float(count)


func has_active_primitive_hair() -> bool:
	var hair_root: Node = get_node_or_null("HairRoot")
	if hair_root == null:
		return false
	for child in hair_root.get_children():
		if not _is_node_visible(child):
			continue
		var stack: Array[Node] = [child]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			var mi: MeshInstance3D = node as MeshInstance3D
			if mi != null and mi.mesh != null:
				if mi.mesh is BoxMesh or mi.mesh is SphereMesh or mi.mesh is CapsuleMesh:
					return true
			for c in node.get_children():
				stack.append(c)
	return false


func get_active_hair_resource_path() -> String:
	var hair_root: Node = get_node_or_null("HairRoot")
	if hair_root == null:
		return ""
	for child in hair_root.get_children():
		if not _is_node_visible(child):
			continue
		if not _has_visible_mesh(child):
			return "" # bald
		for sub in child.get_children():
			var n3: Node3D = sub as Node3D
			if n3 == null:
				continue
			var path: String = String(n3.scene_file_path)
			if path != "":
				return path
	return ""


func sample_visible_hair_albedo() -> Color:
	var hair_root: Node = get_node_or_null("HairRoot")
	if hair_root == null:
		return Color(0, 0, 0, 0)
	for child in hair_root.get_children():
		if not _is_node_visible(child):
			continue
		var mi: MeshInstance3D = _find_first_mesh(child)
		if mi == null:
			return Color(0, 0, 0, 0)
		var mat: Material = mi.material_override
		if mat == null:
			mat = mi.get_active_material(0)
		var std: StandardMaterial3D = mat as StandardMaterial3D
		if std != null:
			return std.albedo_color
	return Color(0, 0, 0, 0)


func _ensure_slot_bindings() -> bool:
	var skel: Skeleton3D = _find_body_skeleton()
	if skel == null:
		if not _slots_bound:
			push_warning("[CharacterVariantController] Body Skeleton3D not found")
		return false
	var all_ok: bool = true
	for slot_name in SLOT_BONE_MAP.keys():
		var att: BoneAttachment3D = get_node_or_null(String(slot_name)) as BoneAttachment3D
		if att == null:
			push_warning("[CharacterVariantController] missing slot root: %s" % String(slot_name))
			all_ok = false
			continue
		if not _bind_attachment(att, skel, SLOT_BONE_MAP[slot_name] as StringName):
			all_ok = false
	# Nested sleeve/leg/foot attachments anywhere under this visual.
	var nested_ok: bool = _bind_nested_attachments(self, skel)
	all_ok = all_ok and nested_ok
	_slots_bound = all_ok
	return all_ok


func _bind_nested_attachments(node: Node, skel: Skeleton3D) -> bool:
	var ok: bool = true
	var att: BoneAttachment3D = node as BoneAttachment3D
	if att != null and NESTED_BONE_MAP.has(String(att.name)):
		var preferred: StringName = NESTED_BONE_MAP[String(att.name)] as StringName
		if not _bind_attachment(att, skel, preferred):
			ok = false
	for child in node.get_children():
		if not _bind_nested_attachments(child, skel):
			ok = false
	return ok


func _bind_attachment(att: BoneAttachment3D, skel: Skeleton3D, preferred: StringName) -> bool:
	var bone_name: String = _resolve_bone_name(skel, preferred)
	if bone_name == "":
		push_warning(
			"[CharacterVariantController] no bone for attachment %s (wanted %s)"
			% [att.name, String(preferred)]
		)
		return false
	att.use_external_skeleton = true
	att.external_skeleton = att.get_path_to(skel)
	att.bone_name = bone_name
	return true


func _find_body_skeleton() -> Skeleton3D:
	var body: Node = get_node_or_null("Body")
	if body == null:
		return _find_skeleton_recursive(self)
	var under_body: Skeleton3D = _find_skeleton_recursive(body)
	if under_body != null:
		return under_body
	return _find_skeleton_recursive(self)


func _find_skeleton_recursive(node: Node) -> Skeleton3D:
	if node == null:
		return null
	var as_skel: Skeleton3D = node as Skeleton3D
	if as_skel != null:
		return as_skel
	for child in node.get_children():
		var found: Skeleton3D = _find_skeleton_recursive(child)
		if found != null:
			return found
	return null


func _resolve_bone_name(skel: Skeleton3D, preferred: StringName) -> String:
	var candidates: Array = BONE_FALLBACKS.get(preferred, [preferred]) as Array
	for candidate in candidates:
		var name: String = String(candidate)
		if skel.find_bone(name) >= 0:
			return name
	var want: String = String(preferred).to_lower()
	for i in skel.get_bone_count():
		var bn: String = skel.get_bone_name(i)
		if bn.to_lower() == want:
			return bn
	return ""


func _select_slot_child(slot_root_name: String, child_name: StringName) -> void:
	var root: Node = get_node_or_null(slot_root_name)
	if root == null:
		push_warning("[CharacterVariantController] missing slot root: %s" % slot_root_name)
		return
	var found: bool = false
	for child in root.get_children():
		var match_name: bool = StringName(child.name) == child_name
		_set_node_visible(child, match_name)
		if match_name:
			found = true
	if not found and child_name != &"":
		push_warning(
			"[CharacterVariantController] missing slot child %s/%s" % [slot_root_name, String(child_name)]
		)


func _apply_color_to_visible(slot_root_name: String, color: Color) -> void:
	var root: Node = get_node_or_null(slot_root_name)
	if root == null:
		return
	for child in root.get_children():
		if not _is_node_visible(child):
			continue
		_apply_color_recursive(child, color)


func _apply_color_recursive(node: Node, color: Color) -> void:
	var mi: MeshInstance3D = node as MeshInstance3D
	if mi != null:
		_apply_instance_color(mi, color)
	for child in node.get_children():
		_apply_color_recursive(child, color)


func _apply_instance_color(mi: MeshInstance3D, color: Color) -> void:
	## Duplicate active material per instance — never mutate shared imported materials.
	var base: Material = mi.material_override
	if base == null:
		base = mi.get_active_material(0)
	var mat: Material
	if base != null:
		mat = base.duplicate()
	else:
		mat = StandardMaterial3D.new()
	var std: StandardMaterial3D = mat as StandardMaterial3D
	if std != null:
		std.albedo_color = color
		if std.roughness <= 0.0:
			std.roughness = 0.72
	elif mat is ShaderMaterial:
		var sm: ShaderMaterial = mat as ShaderMaterial
		if sm.get_shader_parameter("albedo_color") != null:
			sm.set_shader_parameter("albedo_color", color)
		elif sm.get_shader_parameter("base_color") != null:
			sm.set_shader_parameter("base_color", color)
	mi.material_override = mat


func _hair_node_name(variant: StringName) -> StringName:
	var idx: int = _normalize_variant_index(variant, 0, 4, true)
	return StringName("Hair_%02d" % idx)


func _numbered_node_name(prefix: String, variant: StringName, min_n: int, max_n: int) -> StringName:
	var idx: int = _normalize_variant_index(variant, min_n, max_n, false)
	return StringName("%s_%02d" % [prefix, idx])


func _normalize_variant_index(variant: Variant, min_n: int, max_n: int, is_hair: bool) -> int:
	## Accept 0/"0"/"00" … max, and migrate legacy 1-based "01"–"05" deterministically.
	var key: String = String(variant).strip_edges().to_lower()
	if key.begins_with("hair_"):
		key = key.substr(5)
	var digits: String = ""
	for i in key.length():
		var ch: String = key.substr(i, 1)
		if ch >= "0" and ch <= "9":
			digits += ch
	if digits == "":
		return min_n
	var raw: int = int(digits)
	# Remapped appearances write "0".."4". Accept "00".."04" as 0..4.
	# Legacy "05"/5 -> 4. Leftover 1-based zero-padded ids above max -> -1.
	# Hair also migrates leftover zero-padded "01".."05" when value==5 already handled;
	# unpadded remapped data is preferred so "04" stays index 4.
	if raw == 5:
		raw = 4
	elif (not is_hair) and digits.length() == 2 and raw > max_n and (raw - 1) >= min_n and (raw - 1) <= max_n:
		raw = raw - 1
	return clampi(raw, min_n, max_n)


func _accessory_node_name(prefix: String, accessory: StringName) -> StringName:
	var key: String = String(accessory).strip_edges().to_lower()
	if key == "" or key == "none" or key == "0" or key == "00":
		return StringName("%s_None" % prefix)
	if key == "glasses" or key == "hat":
		return StringName("%s_%s" % [prefix, key.capitalize()])
	if key.begins_with(prefix.to_lower() + "_"):
		var rest: String = key.substr(prefix.length() + 1)
		if rest == "none":
			return StringName("%s_None" % prefix)
		if rest == "glasses" or rest == "hat":
			return StringName("%s_%s" % [prefix, rest.capitalize()])
		if rest.is_valid_int():
			var rest_n: int = int(rest)
			if rest_n <= 0:
				return StringName("%s_None" % prefix)
			# Scene labels stay Neck_01/Neck_02 / Hand_01/Hand_02.
			return StringName("%s_%02d" % [prefix, clampi(rest_n, 1, 2)])
	if key.is_valid_int():
		var n: int = int(key)
		if n <= 0:
			return StringName("%s_None" % prefix)
		return StringName("%s_%02d" % [prefix, clampi(n, 1, 2)])
	return StringName("%s_None" % prefix)


func _resolve_hair_color(color_id: StringName) -> Color:
	var key: StringName = StringName(String(color_id).strip_edges().to_lower())
	if HAIR_COLOR_MAP.has(key):
		return HAIR_COLOR_MAP[key] as Color
	if key == &"dark" or key == &"unusual/dark":
		return HAIR_COLOR_MAP[&"unusual"] as Color
	return HAIR_COLOR_MAP[&"brown"] as Color


func _resolve_cloth_color(color_id: StringName) -> Color:
	var key: StringName = StringName(String(color_id).strip_edges().to_lower())
	if CLOTH_COLOR_MAP.has(key):
		return CLOTH_COLOR_MAP[key] as Color
	return CLOTH_COLOR_MAP[&"gray"] as Color


func _is_node_visible(node: Node) -> bool:
	var n3: Node3D = node as Node3D
	if n3 != null:
		return n3.visible
	if "visible" in node:
		return bool(node.get("visible"))
	return true


func _set_node_visible(node: Node, visible: bool) -> void:
	var n3: Node3D = node as Node3D
	if n3 != null:
		n3.visible = visible
		return
	if "visible" in node:
		node.set("visible", visible)


func _find_first_mesh(node: Node) -> MeshInstance3D:
	var as_mi: MeshInstance3D = node as MeshInstance3D
	if as_mi != null and as_mi.mesh != null:
		return as_mi
	var named: MeshInstance3D = node.get_node_or_null("Mesh") as MeshInstance3D
	if named != null:
		return named
	for child in node.get_children():
		var found: MeshInstance3D = _find_first_mesh(child)
		if found != null:
			return found
	return null


func _has_visible_mesh(node: Node) -> bool:
	return _find_first_mesh(node) != null
