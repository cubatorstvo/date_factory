extends SceneTree
## Headless orthogonal top-down capture of compact city (no game window focus).


const CITY := "res://scenes/world/city/city.tscn"
const OUT_PNG := "res://docs/release/research/city_compact_layout_topdown.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	var packed := load(CITY) as PackedScene
	if packed == null:
		push_error("CAPTURE_FAIL load")
		quit(2)
		return
	var city := packed.instantiate() as Node3D
	if city == null:
		push_error("CAPTURE_FAIL instantiate")
		quit(2)
		return

	var vp := SubViewport.new()
	vp.name = "CaptureVP"
	vp.size = Vector2i(1600, 1000)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	vp.world_3d = World3D.new()
	get_root().add_child(vp)
	vp.add_child(city)

	var cam := Camera3D.new()
	cam.name = "TopDownCam"
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 30.0
	cam.position = Vector3(-2.0, 40.0, 2.0)
	cam.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	cam.current = true
	city.add_child(cam)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55.0, 35.0, 0.0)
	key.light_energy = 1.2
	city.add_child(key)

	# Allow a few frames for meshes / import.
	for _i in 12:
		await process_frame

	var img: Image = vp.get_texture().get_image()
	if img == null:
		push_error("CAPTURE_FAIL image null")
		quit(3)
		return
	var err: Error = img.save_png(ProjectSettings.globalize_path(OUT_PNG))
	print("CAPTURE_TOPDOWN path=%s err=%s size=%dx%d" % [OUT_PNG, error_string(err), img.get_width(), img.get_height()])
	if err != OK:
		quit(1)
		return
	print("CAPTURE_TOPDOWN_PASS")
	quit(0)
