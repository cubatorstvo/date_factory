extends SceneTree

const OUT := "res://docs/city_poi_refactor/contact_sheets/prefab_"

const PREFABS: Array[String] = [
	"res://scenes/art/city/prefabs/CafeTwoHearts.tscn",
	"res://scenes/art/city/prefabs/ParkRestaurant.tscn",
	"res://scenes/art/city/prefabs/CinemaFacade.tscn",
	"res://scenes/art/city/prefabs/ArcadeFacade.tscn",
	"res://scenes/art/city/prefabs/FlowerShop.tscn",
	"res://scenes/art/city/prefabs/GiftShop.tscn",
	"res://scenes/art/city/prefabs/ClothingShop.tscn",
	"res://scenes/art/city/prefabs/JewelryShop.tscn",
	"res://scenes/art/city/prefabs/HomewareShop.tscn",
	"res://scenes/art/city/prefabs/BookstoreFacade.tscn",
	"res://scenes/art/city/prefabs/GymFacade.tscn",
	"res://scenes/art/city/prefabs/PhotoStudio.tscn",
	"res://scenes/art/city/prefabs/BarberShop.tscn",
	"res://scenes/art/city/prefabs/AgencyOffice.tscn",
	"res://scenes/art/city/prefabs/BarFacade.tscn",
	"res://scenes/art/city/prefabs/InternetCafe.tscn",
	"res://scenes/art/city/prefabs/PlayerHomeFacade.tscn",
	"res://scenes/art/city/prefabs/DuckFeeding.tscn",
	"res://scenes/art/city/prefabs/MainBench.tscn",
	"res://scenes/art/city/prefabs/KaraokeStand.tscn",
	"res://scenes/art/city/prefabs/BusStopCandy.tscn",
	"res://scenes/art/city/prefabs/ParkBench.tscn",
]


func _initialize() -> void:
	for p in PREFABS:
		await _cap(p)
	quit(0)


func _cap(path: String) -> void:
	if not ResourceLoader.exists(path):
		print("SKIP ", path)
		return
	var ps := load(path) as PackedScene
	if ps == null:
		print("FAIL ", path)
		return
	var n := ps.instantiate() as Node3D
	root.add_child(n)
	await process_frame
	var aabb := AABB()
	var first := true
	for mi_v in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi_v as MeshInstance3D
		if m.mesh == null:
			continue
		var local := m.get_aabb()
		var xf: Transform3D = m.global_transform
		var corners: Array[Vector3] = [local.position, local.position + local.size]
		for corner in corners:
			var p2: Vector3 = xf * corner
			if first:
				aabb = AABB(p2, Vector3.ZERO)
				first = false
			else:
				aabb = aabb.expand(p2)
	var vp := SubViewport.new()
	vp.size = Vector2i(900, 600)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var w := Node3D.new()
	vp.add_child(w)
	var holder := n.get_parent()
	n.reparent(w)
	var cam := Camera3D.new()
	w.add_child(cam)
	cam.current = true
	var l := DirectionalLight3D.new()
	w.add_child(l)
	l.rotation_degrees = Vector3(-40, 30, 0)
	l.light_energy = 1.15
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.5, 0.65, 0.8)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.78, 0.82)
	e.ambient_light_energy = 0.5
	we.environment = e
	w.add_child(we)
	var c := aabb.get_center()
	var ext: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if ext < 0.1:
		ext = 4.0
	cam.position = c + Vector3(ext * 0.85, ext * 0.4, ext * 1.05)
	cam.look_at(c + Vector3(0, aabb.size.y * 0.2, 0), Vector3.UP)
	await process_frame
	await process_frame
	await process_frame
	var img: Image = vp.get_texture().get_image()
	var outp := OUT + path.get_file().get_basename() + ".png"
	if img != null:
		img.save_png(outp)
		print("PREF ", outp)
	n.reparent(holder if holder != null else root)
	vp.queue_free()
	n.queue_free()
	await process_frame
