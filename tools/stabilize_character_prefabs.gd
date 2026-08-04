extends SceneTree
## Rebuild character prefabs + Character_Testbed for technical animation validation.


const CTRL := "res://scenes/art/characters/character_anim_controller.gd"
const LIB_UAL := "res://assets/animation/universal_library/libraries/DF_UAL_Aliases.res"
const LIB_WOMEN := "res://assets/animation/universal_library/libraries/DF_Women_Aliases.res"
const TESTBED := "res://scenes/art/testbeds/Character_Testbed.tscn"
const TESTBED_CTRL := "res://scenes/art/testbeds/character_testbed_controller.gd"


const PREFABS := [
	{
		"path": "res://assets/characters/hero_base/prefabs/Hero.tscn",
		"name": "Hero",
		"mesh": "res://assets/characters/hero_base/meshes/bodies/Superhero_Male_FullBody.gltf",
		"lib": LIB_UAL,
		"y_off": 0.0,
	},
	{
		"path": "res://assets/characters/hero_base/prefabs/Clone.tscn",
		"name": "Clone",
		"mesh": "res://assets/characters/hero_base/meshes/bodies/Superhero_Male_FullBody.gltf",
		"lib": LIB_UAL,
		"y_off": 0.0,
	},
	{
		"path": "res://assets/characters/women_modular/prefabs/Girl_Casual.tscn",
		"name": "Girl_Casual",
		"mesh": "res://assets/characters/women_modular/meshes/individuals/Casual.gltf",
		"lib": LIB_WOMEN,
		"y_off": 0.0,
	},
	{
		"path": "res://assets/characters/women_modular/prefabs/Girl_Formal.tscn",
		"name": "Girl_Formal",
		"mesh": "res://assets/characters/women_modular/meshes/individuals/Formal.gltf",
		"lib": LIB_WOMEN,
		"y_off": 0.0,
	},
	{
		"path": "res://assets/characters/women_modular/prefabs/Girl_Worker.tscn",
		"name": "Girl_Worker",
		"mesh": "res://assets/characters/women_modular/meshes/individuals/Worker.gltf",
		"lib": LIB_WOMEN,
		"y_off": 0.0,
	},
	{
		"path": "res://assets/characters/women_modular/prefabs/Manager_Suit.tscn",
		"name": "Manager_Suit",
		"mesh": "res://assets/characters/women_modular/meshes/individuals/Suit.gltf",
		"lib": LIB_WOMEN,
		"y_off": 0.0,
	},
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	var ctrl_script: Script = load(CTRL) as Script
	var ual_lib: AnimationLibrary = load(LIB_UAL) as AnimationLibrary
	var women_lib: AnimationLibrary = load(LIB_WOMEN) as AnimationLibrary
	if ctrl_script == null or ual_lib == null or women_lib == null:
		push_error("Missing controller or libraries")
		quit(1)
		return
	for spec in PREFABS:
		var ok := _write_prefab(spec, ctrl_script, ual_lib if spec["lib"] == LIB_UAL else women_lib)
		print("PREFAB ", spec["name"], " ", "OK" if ok else "FAIL")
	var tb_ok := _write_testbed()
	print("TESTBED ", "OK" if tb_ok else "FAIL")
	quit(0 if tb_ok else 1)


func _write_prefab(spec: Dictionary, ctrl_script: Script, lib: AnimationLibrary) -> bool:
	var mesh_ps: PackedScene = load(spec["mesh"]) as PackedScene
	if mesh_ps == null:
		push_error("mesh missing " + str(spec["mesh"]))
		return false
	var root := CharacterBody3D.new()
	root.name = str(spec["name"])
	root.collision_layer = 2
	root.set_script(ctrl_script)
	root.set("alias_library", lib)
	root.set("library_name", &"df_aliases")
	root.set("autoplay_alias", &"idle")
	root.set("label_text", str(spec["name"]))
	root.set_meta("_df_anim_aliases", PackedStringArray([
		"idle", "walk", "run", "approach", "turn", "sit", "sit_enter",
		"sit_idle", "seated_gesture", "stand", "sit_exit", "gesture", "react",
	]))
	root.set_meta("_df_alias_library", spec["lib"])

	var visual: Node3D = mesh_ps.instantiate() as Node3D
	visual.name = "Visual"
	# Hide any nested mannequin leftovers; keep embedded AP for women.
	root.add_child(visual)
	visual.owner = root

	# Ensure AnimationPlayer under Visual so UAL paths Armature/Skeleton3D resolve.
	var ap := visual.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap == null:
		ap = AnimationPlayer.new()
		ap.name = "AnimationPlayer"
		visual.add_child(ap)
	if ap.has_animation_library(&"df_aliases"):
		ap.remove_animation_library(&"df_aliases")
	ap.add_animation_library(&"df_aliases", lib)
	ap.owner = root

	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.75
	var col := CollisionShape3D.new()
	col.name = "Collision"
	col.shape = shape
	col.transform.origin = Vector3(0.0, 0.875 + float(spec["y_off"]), 0.0)
	root.add_child(col)
	col.owner = root

	# Mark ownership recursively for packed scene.
	_set_owner_recursive(visual, root)

	var packed := PackedScene.new()
	var err_pack := packed.pack(root)
	if err_pack != OK:
		push_error("pack fail " + str(spec["name"]))
		root.free()
		return false
	var err_save := ResourceSaver.save(packed, str(spec["path"]))
	root.free()
	return err_save == OK


func _write_testbed() -> bool:
	var root := Node3D.new()
	root.name = "Character_Testbed"

	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.18, 0.2, 0.24)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.65, 0.68, 0.75)
	environment.ambient_light_energy = 0.85
	env.environment = environment
	root.add_child(env)
	env.owner = root

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-45.0, 35.0, 0.0)
	sun.light_energy = 1.1
	root.add_child(sun)
	sun.owner = root

	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "Floor"
	var box := BoxMesh.new()
	box.size = Vector3(24.0, 0.2, 12.0)
	floor_mesh.mesh = box
	floor_mesh.position = Vector3(0.0, -0.1, 0.0)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.28, 0.3, 0.34)
	floor_mesh.material_override = floor_mat
	root.add_child(floor_mesh)
	floor_mesh.owner = root

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.current = true
	root.add_child(cam)
	cam.owner = root
	cam.look_at_from_position(Vector3(0.0, 1.6, 7.5), Vector3(0.0, 1.0, 0.0), Vector3.UP)

	var chars := Node3D.new()
	chars.name = "Characters"
	root.add_child(chars)
	chars.owner = root

	var spacing := 2.4
	var start_x := -((PREFABS.size() - 1) * spacing) * 0.5
	for i in PREFABS.size():
		var spec: Dictionary = PREFABS[i]
		var ps: PackedScene = load(str(spec["path"])) as PackedScene
		if ps == null:
			push_error("prefab missing " + str(spec["path"]))
			continue
		var inst: Node3D = ps.instantiate() as Node3D
		inst.name = str(spec["name"])
		inst.position = Vector3(start_x + i * spacing, 0.0, 0.0)
		chars.add_child(inst)
		_set_owner_recursive(inst, root)

	var ui := CanvasLayer.new()
	ui.name = "TechUI"
	root.add_child(ui)
	ui.owner = root

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.offset_left = 12.0
	panel.offset_top = 12.0
	panel.offset_right = 420.0
	panel.offset_bottom = 220.0
	ui.add_child(panel)
	panel.owner = root

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)
	vbox.owner = root

	var title := Label.new()
	title.name = "Title"
	title.text = "Character Testbed (technical)"
	vbox.add_child(title)
	title.owner = root

	var status := Label.new()
	status.name = "Status"
	status.text = "alias: idle | keys 1-7 | Space=demo"
	vbox.add_child(status)
	status.owner = root

	var help := Label.new()
	help.name = "Help"
	help.text = "1 idle  2 walk  3 run  4 sit  5 stand  6 gesture  7 react\nA auto-demo cycle  D manual"
	vbox.add_child(help)
	help.owner = root

	var tb_script: Script = load(TESTBED_CTRL) as Script
	if tb_script == null:
		push_error("missing testbed controller")
		root.free()
		return false
	root.set_script(tb_script)

	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		root.free()
		return false
	var err := ResourceSaver.save(packed, TESTBED)
	root.free()
	return err == OK


func _set_owner_recursive(n: Node, owner: Node) -> void:
	n.owner = owner
	for c in n.get_children():
		_set_owner_recursive(c, owner)
