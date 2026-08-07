extends Node3D
## Visual smoke scene for MODULE 04 screenshots (does not quit).


func _ready() -> void:
	var spawn: Node3D = get_node_or_null("SpawnRoot") as Node3D
	if spawn == null:
		spawn = Node3D.new()
		spawn.name = "SpawnRoot"
		add_child(spawn)
	var male: CharacterActor = CharacterFactory.create(&"appearance_male_base", &"preview_male", spawn)
	var female: CharacterActor = CharacterFactory.create(&"appearance_female_base", &"preview_female", spawn)
	if male != null:
		male.global_position = Vector3(-1.2, 0.0, 0.0)
		male.get_animation_controller().play_loop(&"idle")
	if female != null:
		female.global_position = Vector3(1.2, 0.0, 0.0)
		female.get_animation_controller().play_loop(&"idle")
	DfLog.info("MODULE_04_VISUAL", "spawned male=%s female=%s" % [male != null, female != null])
