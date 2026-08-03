extends SceneTree
## Build project AnimationLibraries with stable aliases from imported sources.


const UAL_PATH := "res://assets/animation/universal_library/source/UAL1_Standard.glb"
const WOMEN_PATH := "res://assets/characters/women_modular/meshes/individuals/Casual.gltf"
const OUT_UAL := "res://assets/animation/universal_library/libraries/DF_UAL_Aliases.res"
const OUT_WOMEN := "res://assets/animation/universal_library/libraries/DF_Women_Aliases.res"
const OUT_MAP := "res://assets/animation/universal_library/libraries/UAL_CLIP_MAP.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	var ual_map := {
		"idle": "Idle",
		"walk": "Walk",
		"run": "Sprint",
		"sit": "Sitting_Enter",
		"stand": "Sitting_Exit",
		"gesture": "Interact",
		"react": "Hit_Chest",
	}
	var women_map := {
		"idle": "Idle",
		"walk": "Walk",
		"run": "Run",
		"sit": "Idle_Neutral", ## no dedicated sit in PACK_019
		"stand": "Idle", ## no dedicated stand-up
		"gesture": "Wave",
		"react": "HitRecieve",
	}
	var loop_aliases := ["idle", "walk", "run"]
	var ual_ok := _build_lib(UAL_PATH, ual_map, loop_aliases, OUT_UAL, false)
	var women_ok := _build_lib(WOMEN_PATH, women_map, loop_aliases + ["sit"], OUT_WOMEN, true)
	var report := {
		"ual_path": UAL_PATH,
		"ual_library": OUT_UAL,
		"ual_ok": ual_ok,
		"ual_aliases": ual_map,
		"women_path": WOMEN_PATH,
		"women_library": OUT_WOMEN,
		"women_ok": women_ok,
		"women_aliases": women_map,
		"loop_aliases": loop_aliases,
		"notes": [
			"UAL used (non root-motion) UAL1_Standard.glb",
			"Women sit/stand are technical fallbacks (no Sitting_* clips in PACK_019)",
		],
	}
	var f := FileAccess.open(OUT_MAP, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "\t"))
	f.close()
	print("BUILD_ANIM_LIBS ual=%s women=%s" % [str(ual_ok), str(women_ok)])
	quit(0 if ual_ok and women_ok else 1)


func _build_lib(src_path: String, alias_map: Dictionary, loop_aliases: Array, out_path: String, reset_root: bool) -> bool:
	var packed: PackedScene = load(src_path) as PackedScene
	if packed == null:
		push_error("load fail " + src_path)
		return false
	var root: Node = packed.instantiate()
	var ap: AnimationPlayer = _find_ap(root)
	if ap == null:
		push_error("no AP " + src_path)
		root.free()
		return false
	var lib := AnimationLibrary.new()
	for alias in alias_map.keys():
		var src_name: String = str(alias_map[alias])
		if not ap.has_animation(src_name):
			push_error("missing clip %s in %s" % [src_name, src_path])
			root.free()
			return false
		var anim: Animation = ap.get_animation(src_name).duplicate(true)
		if alias in loop_aliases:
			anim.loop_mode = Animation.LOOP_LINEAR
		else:
			anim.loop_mode = Animation.LOOP_NONE
		if reset_root:
			_neutralize_root_motion(anim)
		lib.add_animation(StringName(alias), anim)
		print("ADD ", out_path.get_file(), " ", alias, " <- ", src_name, " loop=", anim.loop_mode)
	var err := ResourceSaver.save(lib, out_path)
	root.free()
	if err != OK:
		push_error("save fail %s err=%s" % [out_path, str(err)])
		return false
	return true


func _neutralize_root_motion(anim: Animation) -> void:
	## Drop position tracks that move the root/hips so coded locomotion stays in control.
	for i in range(anim.get_track_count() - 1, -1, -1):
		var path := str(anim.track_get_path(i))
		var low := path.to_lower()
		if anim.track_get_type(i) != Animation.TYPE_POSITION_3D:
			continue
		if low.ends_with(":position") or low.contains("root") or low.contains("hips") or low.contains("pelvis"):
			# Keep pelvis local if it's a relative bone — only strip explicit root position.
			if low.contains("root") or path.begins_with(".") or path == ":position":
				anim.remove_track(i)


func _find_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for c in n.get_children():
		var r := _find_ap(c)
		if r != null:
			return r
	return null
