extends SceneTree
## Set nodes/root_scale=0.01 on FBX imports that ship at Unity/cm scale 100.


const TARGET_DIRS := [
	"res://assets/props/food/meshes",
	"res://assets/environment/interior/house_interior/meshes",
	"res://assets/characters/women_modular/meshes/humanoid_rigs",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var changed := 0
	for d in TARGET_DIRS:
		var abs_dir := ProjectSettings.globalize_path(d)
		if not DirAccess.dir_exists_absolute(abs_dir):
			continue
		changed += _fix_dir(abs_dir)
	print("FBX_SCALE_FIXED files=", changed)
	quit(0)


func _fix_dir(abs_dir: String) -> int:
	var n := 0
	var d := DirAccess.open(abs_dir)
	if d == null:
		return 0
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		if f.begins_with("."):
			f = d.get_next()
			continue
		var full := abs_dir.path_join(f)
		if d.current_is_dir():
			n += _fix_dir(full)
		elif f.to_lower().ends_with(".fbx.import"):
			if _patch_import(full):
				n += 1
		f = d.get_next()
	return n


func _patch_import(abs_path: String) -> bool:
	var txt := FileAccess.get_file_as_string(abs_path)
	if txt == "":
		return false
	if txt.contains("nodes/root_scale=0.01"):
		return false
	var new_txt := txt
	if new_txt.contains("nodes/root_scale="):
		new_txt = new_txt.replace("nodes/root_scale=1.0", "nodes/root_scale=0.01")
		new_txt = new_txt.replace("nodes/root_scale=1", "nodes/root_scale=0.01")
	else:
		new_txt += "\nnodes/root_scale=0.01\n"
	if new_txt == txt:
		return false
	var f := FileAccess.open(abs_path, FileAccess.WRITE)
	f.store_string(new_txt)
	f.close()
	print("PATCH ", abs_path.get_file())
	return true
