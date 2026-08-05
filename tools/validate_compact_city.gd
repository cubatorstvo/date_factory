extends SceneTree
## Headless validation for compact city.tscn layout contract.


const CITY := "res://scenes/world/city/city.tscn"
const REQUIRED_MARKERS := [
	"Markers/HomeEntrance",
	"Markers/PlayerSpawn",
	"Markers/ParkPicnicSpot",
	"Markers/ParkRestaurantEntrance",
	"Markers/GymEntrance",
	"Markers/BookstoreEntrance",
	"Markers/CinemaEntrance",
	"Markers/ArcadeEntrance",
	"Markers/PhotoStudioEntrance",
	"Markers/BarberEntrance",
	"Markers/AgencyOfficeEntrance",
]
const REQUIRED_NODES := [
	"Decor/ParkGate",
	"Decor/AgencyGate",
	"Decor/CentralPocket",
	"POIs/FlowerShop",
	"POIs/JewelryShop",
	"POIs/GiftShop",
	"POIs/ClothingShop",
	"POIs/HomewareShop",
	"POIs/ParkRestaurant",
	"POIs/MainBench",
	"POIs/DuckFeeding",
	"POIs/GymFacade",
	"POIs/CinemaFacade",
	"POIs/ArcadeFacade",
	"POIs/PhotoStudio",
	"POIs/BarberShop",
	"POIs/AgencyOffice",
	"POIs/BusStopCandy",
	"Architecture/PerimeterCollision/FloorCollider",
	"Buildings/CafeTwoHearts",
	"Buildings/HomeFacade",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	var packed := load(CITY) as PackedScene
	if packed == null:
		push_error("VALIDATE_FAIL load city")
		quit(2)
		return
	var root := packed.instantiate() as Node3D
	if root == null:
		push_error("VALIDATE_FAIL instantiate")
		quit(2)
		return
	get_root().add_child(root)
	await process_frame

	var fails: PackedStringArray = PackedStringArray()
	for path in REQUIRED_MARKERS:
		if root.get_node_or_null(path) == null:
			fails.append("missing marker %s" % path)
	for path in REQUIRED_NODES:
		if root.get_node_or_null(path) == null:
			fails.append("missing node %s" % path)

	var park_rest := root.get_node_or_null("Districts/ParkLeisure/ParkRestaurant") as CSGBox3D
	if park_rest != null and park_rest.size.length() < 0.01:
		fails.append("zero-size Districts/ParkLeisure/ParkRestaurant")

	var poi_rest := root.get_node_or_null("POIs/ParkRestaurant") as Node3D
	if poi_rest == null:
		fails.append("missing POIs/ParkRestaurant prefab")

	# Gate orientation: ParkGate barrier should be wider on X than Z (north side).
	var park_gate := root.get_node_or_null("Decor/ParkGate") as Node3D
	var agency_gate := root.get_node_or_null("Decor/AgencyGate") as Node3D
	if park_gate:
		var pb := park_gate.get_node_or_null("Barrier") as CSGBox3D
		if pb == null or pb.size.x < pb.size.z:
			fails.append("ParkGate barrier not side-north (expect size.x > size.z)")
	if agency_gate:
		var ab := agency_gate.get_node_or_null("Barrier") as CSGBox3D
		if ab == null or ab.size.z < ab.size.x:
			fails.append("AgencyGate barrier not side-west (expect size.z > size.x)")

	# Spawn / home near east pocket.
	var home := root.get_node_or_null("Markers/HomeEntrance") as Node3D
	if home and home.position.x < 10.0:
		fails.append("HomeEntrance not in residential east (x=%s)" % home.position.x)

	# Compact bounds: no POI farther west than -24 or east than 22.
	var pois := root.get_node_or_null("POIs") as Node3D
	if pois:
		for c in pois.get_children():
			if c is Node3D:
				var p: Vector3 = (c as Node3D).position
				if p.x < -24.0 or p.x > 22.0 or p.z < -12.0 or p.z > 16.0:
					fails.append("POI out of compact bounds %s @ %s" % [c.name, p])

	# Collision count under perimeter.
	var floor_c := root.get_node_or_null("Architecture/PerimeterCollision/FloorCollider") as StaticBody3D
	if floor_c == null:
		fails.append("no floor collider")

	# Missing resource probe: any ExtResource already failed at load; check prefab children exist.
	var prefab_ok := 0
	if pois:
		prefab_ok = pois.get_child_count()
	if prefab_ok < 15:
		fails.append("expected >=15 POI prefab instances, got %d" % prefab_ok)

	# Floating check: large roots y should be ~0.
	for path in ["POIs/ParkRestaurant", "Buildings/CafeTwoHearts", "Buildings/HomeFacade"]:
		var n := root.get_node_or_null(path) as Node3D
		if n and absf(n.position.y) > 0.25:
			fails.append("floating root %s y=%s" % [path, n.position.y])

	print("VALIDATE_CITY markers_ok=%s" % str(fails.is_empty()))
	print("VALIDATE_CITY poi_count=%d" % prefab_ok)
	if home:
		print("VALIDATE_CITY home=%s" % home.position)
	if park_gate:
		print("VALIDATE_CITY park_gate=%s" % park_gate.position)
	if agency_gate:
		print("VALIDATE_CITY agency_gate=%s" % agency_gate.position)
	for f in fails:
		print("VALIDATE_FAIL %s" % f)
	if fails.is_empty():
		print("VALIDATE_CITY_PASS")
		root.queue_free()
		quit(0)
	else:
		print("VALIDATE_CITY_FAIL count=%d" % fails.size())
		root.queue_free()
		quit(1)
