extends SceneTree
## Configure Godot humanoid retargeting for UAL and PACK_019 women.


const UAL_IMPORT := "res://assets/animation/universal_library/source/UAL1_Standard.glb.import"
const UAL_MAP_PATH := "res://assets/animation/universal_library/retargeted/DF_UAL_BoneMap.tres"
const WOMEN_MAP_PATH := "res://assets/animation/universal_library/retargeted/DF_Women_BoneMap.tres"
const WOMEN_DIR := "res://assets/characters/women_modular/meshes/individuals"
const HERO_IMPORTS := [
	"res://assets/characters/hero_base/meshes/bodies/Superhero_Male_FullBody.gltf.import",
	"res://assets/characters/hero_base/meshes/bodies/Superhero_Female_FullBody.gltf.import",
]

const UAL_BONES := {
	&"Root": &"root",
	&"Hips": &"pelvis",
	&"Spine": &"spine_01",
	&"Chest": &"spine_02",
	&"UpperChest": &"spine_03",
	&"Neck": &"neck_01",
	&"Head": &"Head",
	&"LeftShoulder": &"clavicle_l",
	&"LeftUpperArm": &"upperarm_l",
	&"LeftLowerArm": &"lowerarm_l",
	&"LeftHand": &"hand_l",
	&"RightShoulder": &"clavicle_r",
	&"RightUpperArm": &"upperarm_r",
	&"RightLowerArm": &"lowerarm_r",
	&"RightHand": &"hand_r",
	&"LeftUpperLeg": &"thigh_l",
	&"LeftLowerLeg": &"calf_l",
	&"LeftFoot": &"foot_l",
	&"LeftToes": &"ball_l",
	&"RightUpperLeg": &"thigh_r",
	&"RightLowerLeg": &"calf_r",
	&"RightFoot": &"foot_r",
	&"RightToes": &"ball_r",
}

const WOMEN_BONES := {
	&"Root": &"Root",
	&"Hips": &"Hips",
	&"Spine": &"Abdomen",
	&"Chest": &"Torso",
	&"UpperChest": &"Chest",
	&"Neck": &"Neck",
	&"Head": &"Head",
	&"LeftShoulder": &"Shoulder.L",
	&"LeftUpperArm": &"UpperArm.L",
	&"LeftLowerArm": &"LowerArm.L",
	&"LeftHand": &"Wrist.L",
	&"RightShoulder": &"Shoulder.R",
	&"RightUpperArm": &"UpperArm.R",
	&"RightLowerArm": &"LowerArm.R",
	&"RightHand": &"Wrist.R",
	&"LeftUpperLeg": &"UpperLeg.L",
	&"LeftLowerLeg": &"LowerLeg.L",
	&"LeftFoot": &"Foot.L",
	&"LeftToes": &"PT.L",
	&"RightUpperLeg": &"UpperLeg.R",
	&"RightLowerLeg": &"LowerLeg.R",
	&"RightFoot": &"Foot.R",
	&"RightToes": &"PT.R",
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(UAL_MAP_PATH.get_base_dir()))
	var ual_map := _make_map(UAL_BONES)
	var women_map := _make_map(WOMEN_BONES)
	var ual_err := ResourceSaver.save(ual_map, UAL_MAP_PATH)
	var women_err := ResourceSaver.save(women_map, WOMEN_MAP_PATH)
	if ual_err != OK or women_err != OK:
		push_error("Unable to save BoneMap resources: %s / %s" % [ual_err, women_err])
		quit(1)
		return

	var configured := 0
	configured += int(_configure_import(UAL_IMPORT, "Armature/Skeleton3D", ual_map))
	for hero_import: String in HERO_IMPORTS:
		configured += int(_configure_import(hero_import, "Armature/Skeleton3D", ual_map))
	var dir := DirAccess.open(WOMEN_DIR)
	if dir == null:
		push_error("Women directory missing")
		quit(1)
		return
	for file_name in dir.get_files():
		if file_name.ends_with(".gltf"):
			var import_path := WOMEN_DIR.path_join(file_name + ".import")
			configured += int(_configure_import(import_path, "CharacterArmature/Skeleton3D", women_map))
	print("RETARGET_IMPORTS_CONFIGURED=", configured)
	print("UAL_MAP=", UAL_MAP_PATH)
	print("WOMEN_MAP=", WOMEN_MAP_PATH)
	quit(0 if configured >= 13 else 1)


func _make_map(mapping: Dictionary) -> BoneMap:
	var bone_map := BoneMap.new()
	bone_map.profile = SkeletonProfileHumanoid.new()
	for profile_bone: StringName in mapping:
		bone_map.set_skeleton_bone_name(profile_bone, mapping[profile_bone])
	return bone_map


func _configure_import(import_path: String, skeleton_path: String, bone_map: BoneMap) -> bool:
	var cfg := ConfigFile.new()
	var load_err := cfg.load(import_path)
	if load_err != OK:
		push_error("Import config load failed: %s" % import_path)
		return false
	var node_options := {
		"rest_pose/external_animation_library": null,
		"retarget/bone_map": bone_map,
		"retarget/bone_renamer/rename_bones": true,
		"retarget/bone_renamer/unique_node/make_unique": false,
		"retarget/bone_renamer/unique_node/skeleton_name": &"Skeleton3D",
		"retarget/remove_tracks/except_bone_transform": false,
		"retarget/remove_tracks/unimportant_positions": true,
		"retarget/remove_tracks/unmapped_bones": true,
		"retarget/rest_fixer/apply_node_transforms": true,
		"retarget/rest_fixer/normalize_position_tracks": true,
		"retarget/rest_fixer/overwrite_axis": true,
		"retarget/rest_fixer/fix_silhouette/enable": true,
		"retarget/rest_fixer/fix_silhouette/filter": PackedStringArray(["LeftFoot", "RightFoot", "LeftToes", "RightToes"]),
		"retarget/rest_fixer/fix_silhouette/threshold": 15.0,
		"retarget/rest_fixer/fix_silhouette/base_height_adjustment": 0.0,
	}
	cfg.set_value("params", "_subresources", {
		"nodes": {
			"PATH:" + skeleton_path: node_options,
		},
	})
	var save_err := cfg.save(import_path)
	if save_err != OK:
		push_error("Import config save failed: %s" % import_path)
		return false
	print("CONFIGURED ", import_path)
	return true
