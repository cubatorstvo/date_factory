class_name CharacterVariantController
extends Node3D
## Presentation-only modular outfit/hair controller for PACK_021 bases.
## Shows exactly one child per slot and applies material color overrides.

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


func apply_variants(
	hair_variant: StringName = &"01",
	hair_color: StringName = &"brown",
	top_variant: StringName = &"01",
	top_color: StringName = &"gray",
	bottom_variant: StringName = &"01",
	bottom_color: StringName = &"navy",
	shoes_variant: StringName = &"01",
	head_accessory: StringName = &"none",
	neck_accessory: StringName = &"none",
	hand_accessory: StringName = &"none"
) -> void:
	_select_slot_child("HairRoot", _hair_node_name(hair_variant))
	_select_slot_child("TopRoot", _numbered_node_name("Top", top_variant, 4))
	_select_slot_child("BottomRoot", _numbered_node_name("Bottom", bottom_variant, 3))
	_select_slot_child("ShoesRoot", _numbered_node_name("Shoes", shoes_variant, 2))
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


func get_visible_slot_child_name(slot_root_name: String) -> StringName:
	var root: Node = get_node_or_null(slot_root_name)
	if root == null:
		return &""
	for child in root.get_children():
		var n3: Node3D = child as Node3D
		if n3 != null and n3.visible:
			return StringName(n3.name)
		elif child is CanvasItem and (child as CanvasItem).visible:
			return StringName(child.name)
		elif child.has_method("is_visible") and bool(child.call("is_visible")):
			return StringName(child.name)
		elif "visible" in child and bool(child.get("visible")):
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
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.72
		mi.material_override = mat
	for child in node.get_children():
		_apply_color_recursive(child, color)


func _hair_node_name(variant: StringName) -> StringName:
	var key: String = String(variant).strip_edges().to_lower()
	if key.begins_with("hair_"):
		key = key.substr(5)
	key = key.trim_prefix("0")
	if key == "" or not key.is_valid_int():
		key = "1"
	var idx: int = clampi(int(key), 1, 5)
	return StringName("Hair_%02d" % idx)


func _numbered_node_name(prefix: String, variant: StringName, max_n: int) -> StringName:
	var key: String = String(variant).strip_edges().to_lower()
	var lower_prefix: String = prefix.to_lower() + "_"
	if key.begins_with(lower_prefix):
		key = key.substr(lower_prefix.length())
	key = key.trim_prefix("0")
	if key == "" or not key.is_valid_int():
		key = "1"
	var idx: int = clampi(int(key), 1, max_n)
	return StringName("%s_%02d" % [prefix, idx])


func _accessory_node_name(prefix: String, accessory: StringName) -> StringName:
	var key: String = String(accessory).strip_edges().to_lower()
	if key == "" or key == "none" or key == "0":
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
			return StringName("%s_%02d" % [prefix, int(rest)])
	if key.is_valid_int():
		return StringName("%s_%02d" % [prefix, int(key)])
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
