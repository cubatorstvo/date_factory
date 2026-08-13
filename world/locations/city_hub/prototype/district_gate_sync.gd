extends Node
## Opens DistrictGate instances from Story features.
## park_leisure → PUBLIC_CITY_ACCESS (STAGE_2)
## agency_row → SALARY_MINE (STAGE_3)
## main_street has no gate.


func _ready() -> void:
	var story: Node = get_node_or_null("/root/Story")
	if story != null and story.has_signal("feature_unlocked"):
		if not story.feature_unlocked.is_connected(_on_feature_unlocked):
			story.feature_unlocked.connect(_on_feature_unlocked)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_signal("stage_changed"):
		if not gs.stage_changed.is_connected(_on_stage_changed):
			gs.stage_changed.connect(_on_stage_changed)
	_ensure_interact_bind()
	call_deferred("refresh_gates")


func _ensure_interact_bind() -> void:
	if get_node_or_null("CityInteractBind") != null:
		return
	var script: GDScript = load("res://world/locations/city_hub/prototype/city_interact_bind.gd") as GDScript
	if script == null:
		return
	var bind: Node = script.new() as Node
	bind.name = "CityInteractBind"
	add_child(bind)


func _on_feature_unlocked(_feature: StoryTypes.StoryFeature) -> void:
	refresh_gates()


func _on_stage_changed(_new_stage: GameTypes.GameStage) -> void:
	refresh_gates()


func refresh_gates() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var story: Node = get_node_or_null("/root/Story")
	var park_open: bool = false
	var agency_open: bool = false
	if story != null and story.has_method("is_feature_unlocked"):
		park_open = bool(story.call("is_feature_unlocked", StoryTypes.StoryFeature.PUBLIC_CITY_ACCESS))
		agency_open = bool(story.call("is_feature_unlocked", StoryTypes.StoryFeature.SALARY_MINE))
	for node in tree.get_nodes_in_group("district_gate"):
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_method("set_unlocked"):
			continue
		var district: String = ""
		if "district_id" in node:
			district = str(node.get("district_id"))
		elif node.has_meta("district_id"):
			district = str(node.get_meta("district_id"))
		var open: bool = true
		if district == "park_leisure":
			open = park_open
		elif district == "agency_row":
			open = agency_open
		node.call("set_unlocked", open)
