extends SceneTree
## Build stable project AnimationLibraries from humanoid-normalized imports.


const UAL_PATH := "res://assets/animation/universal_library/source/UAL1_Standard.glb"
const WOMEN_PATH := "res://assets/characters/women_modular/meshes/individuals/Casual.gltf"
const OUT_UAL := "res://assets/animation/universal_library/libraries/DF_UAL_Aliases.res"
const OUT_WOMEN := "res://assets/animation/universal_library/libraries/DF_Women_Aliases.res"
const OUT_WOMEN_SEATED := "res://assets/animation/universal_library/retargeted/DF_Women_Seated.res"
const OUT_MAP := "res://assets/animation/universal_library/libraries/UAL_CLIP_MAP.json"

const LOOP_ALIASES := ["idle", "walk", "run", "approach", "sit_idle", "seated_gesture"]


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
		"sit_enter": "Sitting_Enter",
		"sit_idle": "Sitting_Idle",
		"seated_gesture": "Sitting_Talking",
		"stand": "Sitting_Exit",
		"sit_exit": "Sitting_Exit",
		"gesture": "Interact",
		"react": "Hit_Chest",
	}
	var women_native_map := {
		"idle": "Idle",
		"walk": "Walk",
		"run": "Run",
		"approach": "Walk",
		"turn": "Idle",
		"gesture": "Wave",
		"react": "HitRecieve",
	}
	var women_seated_map := {
		"sit": "Sitting_Enter",
		"sit_enter": "Sitting_Enter",
		"sit_idle": "Sitting_Idle",
		"seated_gesture": "Sitting_Talking",
		"stand": "Sitting_Exit",
		"sit_exit": "Sitting_Exit",
	}
	var ual_ok := _build_library_from_source(UAL_PATH, ual_map, LOOP_ALIASES, OUT_UAL)
	var women_ok := _build_women_library(women_native_map, women_seated_map)
	var report := {
		"ual_path": UAL_PATH,
		"ual_library": OUT_UAL,
		"ual_ok": ual_ok,
		"ual_aliases": ual_map,
		"women_path": WOMEN_PATH,
		"women_library": OUT_WOMEN,
		"women_seated_library": OUT_WOMEN_SEATED,
		"women_ok": women_ok,
		"women_native_aliases": women_native_map,
		"women_retargeted_aliases": women_seated_map,
		"loop_aliases": LOOP_ALIASES,
		"notes": [
			"All skeletons normalized through SkeletonProfileHumanoid BoneMaps",
			"Women sitting clips are UAL Sitting_* retargets, not idle fallbacks",
			"Only Root translation is stripped; Hips vertical motion is retained for chair sitting",
		],
	}
	var file := FileAccess.open(OUT_MAP, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("BUILD_ANIM_LIBS ual=%s women=%s" % [str(ual_ok), str(women_ok)])
	quit(0 if ual_ok and women_ok else 1)


func _build_library_from_source(
	source_path: String,
	alias_map: Dictionary,
	loop_aliases: Array,
	out_path: String
) -> bool:
	var packed: PackedScene = load(source_path) as PackedScene
	if packed == null:
		push_error("Animation source load failed: " + source_path)
		return false
	var root: Node = packed.instantiate()
	var player: AnimationPlayer = _find_animation_player(root)
	if player == null:
		push_error("AnimationPlayer missing: " + source_path)
		root.free()
		return false
	var library: AnimationLibrary = AnimationLibrary.new()
	var ok: bool = _append_aliases(library, player, alias_map, loop_aliases, "", "")
	var save_err: Error = ResourceSaver.save(library, out_path) if ok else ERR_INVALID_DATA
	root.free()
	if save_err != OK:
		push_error("AnimationLibrary save failed: %s (%s)" % [out_path, save_err])
		return false
	return true


func _build_women_library(native_map: Dictionary, seated_map: Dictionary) -> bool:
	var women_packed := load(WOMEN_PATH) as PackedScene
	var ual_packed := load(UAL_PATH) as PackedScene
	if women_packed == null or ual_packed == null:
		push_error("Women or UAL source missing")
		return false
	var women_root := women_packed.instantiate()
	var ual_root := ual_packed.instantiate()
	var women_player := _find_animation_player(women_root)
	var ual_player := _find_animation_player(ual_root)
	if women_player == null or ual_player == null:
		push_error("Women or UAL AnimationPlayer missing")
		women_root.free()
		ual_root.free()
		return false

	var combined := AnimationLibrary.new()
	var seated := AnimationLibrary.new()
	var native_ok := _append_aliases(combined, women_player, native_map, LOOP_ALIASES, "", "")
	var seated_ok := _append_aliases(
		seated,
		ual_player,
		seated_map,
		LOOP_ALIASES,
		"Armature/Skeleton3D",
		"CharacterArmature/Skeleton3D"
	)
	if native_ok and seated_ok:
		for alias in seated.get_animation_list():
			combined.add_animation(alias, seated.get_animation(alias))
	var seated_err := ResourceSaver.save(seated, OUT_WOMEN_SEATED) if seated_ok else ERR_INVALID_DATA
	var combined_err := ResourceSaver.save(combined, OUT_WOMEN) if native_ok and seated_ok else ERR_INVALID_DATA
	women_root.free()
	ual_root.free()
	if seated_err != OK or combined_err != OK:
		push_error("Women libraries save failed: seated=%s combined=%s" % [seated_err, combined_err])
		return false
	return true


func _append_aliases(
	library: AnimationLibrary,
	player: AnimationPlayer,
	alias_map: Dictionary,
	loop_aliases: Array,
	from_prefix: String,
	to_prefix: String
) -> bool:
	for alias_variant in alias_map.keys():
		var alias: String = String(alias_variant)
		var source_name: String = String(alias_map[alias_variant])
		if not player.has_animation(source_name):
			push_error("Missing clip %s for alias %s" % [source_name, alias])
			return false
		var animation: Animation = player.get_animation(source_name).duplicate(true) as Animation
		animation.resource_name = alias
		animation.loop_mode = Animation.LOOP_LINEAR if alias in loop_aliases else Animation.LOOP_NONE
		if from_prefix != "":
			_repath_skeleton_tracks(animation, from_prefix, to_prefix)
		_strip_root_translation(animation)
		library.add_animation(StringName(alias), animation)
		print("ADD ", alias, " <- ", source_name, " loop=", animation.loop_mode)
	return true


func _repath_skeleton_tracks(animation: Animation, from_prefix: String, to_prefix: String) -> void:
	for track_index in animation.get_track_count():
		var old_path := String(animation.track_get_path(track_index))
		if old_path.begins_with(from_prefix + ":"):
			animation.track_set_path(track_index, NodePath(to_prefix + old_path.substr(from_prefix.length())))


func _strip_root_translation(animation: Animation) -> void:
	for track_index in range(animation.get_track_count() - 1, -1, -1):
		if animation.track_get_type(track_index) != Animation.TYPE_POSITION_3D:
			continue
		var path := String(animation.track_get_path(track_index))
		var bone_name := path.get_slice(":", 1)
		if bone_name == "Root" or bone_name == "root" or path == ":position":
			animation.remove_track(track_index)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null
