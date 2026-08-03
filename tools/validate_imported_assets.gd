extends SceneTree
## Technical validation for imported art assets / prefabs / test scenes.


const OUT := "res://docs/ASSET_TECHNICAL_VALIDATION.txt"
const ALIASES := ["idle", "walk", "run", "sit", "stand", "gesture", "react"]

var _pass := 0
var _warn := 0
var _err := 0
var _lines: PackedStringArray = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	_lines.append("DATE FACTORY — ASSET TECHNICAL VALIDATION")
	_lines.append("Generated: %s" % Time.get_datetime_string_from_system())
	_lines.append("")

	_section("Animation libraries")
	_check_exists("res://assets/animation/universal_library/source/UAL1_Standard.glb")
	_check_exists("res://assets/animation/universal_library/libraries/DF_UAL_Aliases.res")
	_check_exists("res://assets/animation/universal_library/libraries/DF_Women_Aliases.res")
	_check_exists("res://assets/animation/universal_library/libraries/UAL_CLIP_MAP.json")
	_check_anim_library("res://assets/animation/universal_library/libraries/DF_UAL_Aliases.res")
	_check_anim_library("res://assets/animation/universal_library/libraries/DF_Women_Aliases.res")

	_section("Character prefabs")
	var prefabs := [
		"res://assets/characters/hero_base/prefabs/Hero.tscn",
		"res://assets/characters/hero_base/prefabs/Clone.tscn",
		"res://assets/characters/women_modular/prefabs/Girl_Casual.tscn",
		"res://assets/characters/women_modular/prefabs/Girl_Formal.tscn",
		"res://assets/characters/women_modular/prefabs/Girl_Worker.tscn",
		"res://assets/characters/women_modular/prefabs/Manager_Suit.tscn",
	]
	var probe := Node3D.new()
	get_root().add_child(probe)
	for p in prefabs:
		await _check_prefab(p, probe)

	_section("Test scenes")
	var scenes := [
		"res://scenes/art/rooms/Apartment_Blockout_Finalized.tscn",
		"res://scenes/art/city/City_Street_Slice.tscn",
		"res://scenes/art/restaurant/Sushi_Date_Restaurant.tscn",
		"res://scenes/art/lab/Clone_Lab_Base.tscn",
		"res://scenes/art/factory/Date_Factory_Base.tscn",
		"res://scenes/art/testbeds/Character_Testbed.tscn",
	]
	for s in scenes:
		_check_scene_load(s)

	_section("Core pack model samples")
	var samples := [
		"res://assets/environment/city/downtown_megakit/meshes/Brick_90Angle_L.gltf",
		"res://assets/environment/factory/kenney_factory/meshes/box-large.glb",
		"res://assets/environment/lab/scifi_essentials/meshes",
		"res://assets/environment/restaurant/sushi_restaurant",
		"res://assets/props/food",
		"res://assets/environment/interior/house_interior",
		"res://assets/characters/women_modular/meshes/individuals/Casual.gltf",
		"res://assets/characters/hero_base/meshes/bodies/Superhero_Male_FullBody.gltf",
	]
	for s in samples:
		if s.ends_with(".gltf") or s.ends_with(".glb") or s.ends_with(".fbx"):
			_check_model(s)
		else:
			_check_dir_has_models(s)

	_section("Summary")
	_lines.append("PASS=%d WARNING=%d ERROR=%d" % [_pass, _warn, _err])
	_lines.append("RESULT=%s" % ("PASS" if _err == 0 and _warn == 0 else ("WARNING" if _err == 0 else "FAIL")))
	_lines.append("NOTE: WARNING is not counted as PASS.")

	var abs_out := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(abs_out.get_base_dir())
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string("\n".join(_lines) + "\n")
	f.close()
	print("\n".join(_lines))
	print("WROTE ", OUT)
	quit(0 if _err == 0 else 1)


func _section(title: String) -> void:
	_lines.append("")
	_lines.append("## " + title)


func _ok(msg: String) -> void:
	_pass += 1
	_lines.append("PASS: " + msg)
	print("PASS: ", msg)


func _warning(msg: String) -> void:
	_warn += 1
	_lines.append("WARNING: " + msg)
	print("WARNING: ", msg)


func _error(msg: String) -> void:
	_err += 1
	_lines.append("ERROR: " + msg)
	print("ERROR: ", msg)


func _check_exists(path: String) -> void:
	if ResourceLoader.exists(path) or FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)):
		_ok("exists " + path)
	else:
		_error("missing " + path)


func _check_anim_library(path: String) -> void:
	var lib := load(path) as AnimationLibrary
	if lib == null:
		_error("AnimationLibrary load failed " + path)
		return
	var missing: PackedStringArray = []
	for a in ALIASES:
		if not lib.has_animation(StringName(a)):
			missing.append(a)
	if missing.is_empty():
		_ok("aliases complete " + path)
	else:
		_error("missing aliases %s in %s" % [",".join(missing), path])


func _check_prefab(path: String, parent: Node) -> void:
	if not ResourceLoader.exists(path):
		_error("prefab missing " + path)
		return
	var ps := load(path) as PackedScene
	if ps == null:
		_error("prefab load failed " + path)
		return
	var n := ps.instantiate()
	parent.add_child(n)
	await process_frame
	await process_frame
	if not _has_mesh(n):
		_error("prefab has no mesh " + path)
	else:
		_ok("prefab mesh " + path)
	if _find_skel(n) == null:
		_error("prefab has no skeleton " + path)
	else:
		_ok("prefab skeleton " + path)
	var alias_count := 0
	for a in ALIASES:
		if n.has_method("has_alias") and bool(n.call("has_alias", a)):
			alias_count += 1
	if alias_count == ALIASES.size():
		_ok("prefab aliases 7/7 " + path)
	else:
		_error("prefab aliases %d/7 %s" % [alias_count, path])
	if n.has_method("play_alias"):
		var played := bool(n.call("play_alias", "idle"))
		await process_frame
		if played:
			_ok("prefab play idle " + path)
		else:
			_error("prefab play idle failed " + path)
	n.queue_free()
	await process_frame


func _check_scene_load(path: String) -> void:
	if not ResourceLoader.exists(path):
		_error("scene missing " + path)
		return
	var ps := load(path) as PackedScene
	if ps == null:
		_error("scene load failed " + path)
		return
	var n := ps.instantiate()
	if n == null:
		_error("scene instantiate failed " + path)
		return
	_ok("scene load " + path)
	if _count_mesh(n) == 0:
		_warning("scene has no MeshInstance3D " + path)
	n.free()


func _check_model(path: String) -> void:
	if not ResourceLoader.exists(path):
		# try find first model in nearby if exact missing
		_error("model missing " + path)
		return
	var ps := load(path) as PackedScene
	if ps == null:
		_error("model load failed " + path)
		return
	var n := ps.instantiate()
	if not _has_mesh(n):
		_error("model has no mesh " + path)
	else:
		_ok("model mesh " + path)
	if not _has_any_material(n):
		_warning("model materials missing/null " + path)
	else:
		_ok("model materials present " + path)
	n.free()


func _check_dir_has_models(path: String) -> void:
	var abs_path := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(abs_path):
		_error("directory missing " + path)
		return
	var count := _count_models_recursive(abs_path)
	if count > 0:
		_ok("directory models=%d %s" % [count, path])
	else:
		_error("directory has no gltf/glb/fbx " + path)


func _count_models_recursive(abs_path: String) -> int:
	var count := 0
	var d := DirAccess.open(abs_path)
	if d == null:
		return 0
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		if f.begins_with("."):
			f = d.get_next()
			continue
		var full := abs_path.path_join(f)
		if d.current_is_dir():
			count += _count_models_recursive(full)
		else:
			var low := f.to_lower()
			if low.ends_with(".gltf") or low.ends_with(".glb") or low.ends_with(".fbx"):
				count += 1
		f = d.get_next()
	return count


func _has_mesh(n: Node) -> bool:
	return _count_mesh(n) > 0


func _count_mesh(n: Node) -> int:
	var c := 0
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		c += 1
	for ch in n.get_children():
		c += _count_mesh(ch)
	return c


func _has_any_material(n: Node) -> bool:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.material_override != null:
			return true
		if mi.mesh != null:
			for i in mi.mesh.get_surface_count():
				if mi.get_active_material(i) != null:
					return true
	for ch in n.get_children():
		if _has_any_material(ch):
			return true
	return false


func _find_skel(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n as Skeleton3D
	for c in n.get_children():
		var r := _find_skel(c)
		if r != null:
			return r
	return null
