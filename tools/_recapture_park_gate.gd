extends SceneTree


func _initialize() -> void:
	var packed := load("res://scenes/world/city/city.tscn") as PackedScene
	if packed == null:
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	var world := Node3D.new()
	root.add_child(world)
	world.add_child(packed.instantiate())
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.look_at_from_position(Vector3(0.5, 1.7, 5.5), Vector3(0.5, 1.2, 3.4), Vector3.UP)
	camera.current = true
	var key := DirectionalLight3D.new()
	key.light_energy = 0.9
	key.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	world.add_child(key)
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "C:/Users/User/Documents/GodotProjects/date_factory/docs/archive/city-compact-visual-review-2026-08-06/04_park_gate_side.png"
	var error: Error = root.get_texture().get_image().save_png(path)
	print("CITY_PARK_GATE_RECAPTURE path=%s err=%s" % [path, error_string(error)])
	world.queue_free()
	await process_frame
	quit()
