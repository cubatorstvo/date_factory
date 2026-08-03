extends SceneTree
## Load art test scenes + character prefabs; report failures.


const SCENES := [
	"res://scenes/art/rooms/Apartment_Blockout_Finalized.tscn",
	"res://scenes/art/city/City_Street_Slice.tscn",
	"res://scenes/art/restaurant/Sushi_Date_Restaurant.tscn",
	"res://scenes/art/lab/Clone_Lab_Base.tscn",
	"res://scenes/art/factory/Date_Factory_Base.tscn",
	"res://scenes/art/testbeds/Character_Testbed.tscn",
	"res://assets/characters/hero_base/prefabs/Hero.tscn",
	"res://assets/characters/women_modular/prefabs/Girl_Casual.tscn",
	"res://assets/materials/base/City_Base_Concrete.tres",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var errors: PackedStringArray = PackedStringArray()
	for path in SCENES:
		if not ResourceLoader.exists(path):
			errors.append("missing:%s" % path)
			continue
		var res: Resource = load(path)
		if res == null:
			errors.append("load_fail:%s" % path)
			continue
		if res is PackedScene:
			var n: Node = (res as PackedScene).instantiate()
			if n == null:
				errors.append("instance_fail:%s" % path)
			else:
				n.free()
	if errors.is_empty():
		print("ART_SCENES_OK count=%d" % SCENES.size())
		quit(0)
	else:
		print("ART_SCENES_FAIL ", errors)
		quit(1)
