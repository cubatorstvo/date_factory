class_name WorldTransition
extends Interactable
## E-only travel door between locations (MODULE 12). Never auto-travels on body_entered.

@export var target_location_id: StringName = &""
@export var target_spawn_id: StringName = &"spawn_default"
@export var display_name: String = ""

var _cached_locked: bool = false
var _cached_reason: String = ""


func _ready() -> void:
	monitoring = false
	monitorable = true
	collision_layer = 4
	collision_mask = 0
	var story: Node = get_node_or_null("/root/Story")
	if story != null and story.has_signal("feature_unlocked"):
		if not story.is_connected("feature_unlocked", _on_feature_unlocked):
			story.connect("feature_unlocked", _on_feature_unlocked)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_signal("stage_changed"):
		if not gs.is_connected("stage_changed", _on_stage_changed):
			gs.connect("stage_changed", _on_stage_changed)
	refresh_access_prompt()


func refresh_access_prompt() -> void:
	var world: Node = get_node_or_null("/root/World")
	if world == null or not world.has_method("get_location_access"):
		_cached_locked = String(target_location_id) != "apartment"
		_cached_reason = "Пока недоступно по сюжету"
		return
	var access: WorldAccessResult = world.call("get_location_access", target_location_id) as WorldAccessResult
	if access == null:
		_cached_locked = true
		_cached_reason = "Пока недоступно по сюжету"
		return
	_cached_locked = access.status != WorldTypes.WorldAccessStatus.AVAILABLE
	if _cached_locked:
		if access.message != "":
			_cached_reason = access.message
		else:
			_cached_reason = "Пока недоступно по сюжету"
	else:
		_cached_reason = ""


func can_interact(_player: Node) -> bool:
	return interaction_enabled and is_inside_tree() and not is_queued_for_deletion()


func get_interaction_prompt(_player: Node) -> String:
	refresh_access_prompt()
	var label: String = display_name
	if label.strip_edges() == "":
		label = String(target_location_id)
	if _cached_locked:
		return "[E] Недоступно — %s" % _cached_reason
	return "[E] %s" % label


func _on_interact(player: Node) -> void:
	refresh_access_prompt()
	var world: Node = get_node_or_null("/root/World")
	if world == null or not world.has_method("request_travel"):
		push_error("[WorldTransition] World autoload missing")
		return
	if _cached_locked:
		world.call("request_travel", target_location_id, target_spawn_id)
		return
	world.call("request_travel", target_location_id, target_spawn_id)
	# silence unused in case future uses player
	if player == null:
		pass


func _on_feature_unlocked(_feature: StoryTypes.StoryFeature) -> void:
	refresh_access_prompt()


func _on_stage_changed(_new_stage: GameTypes.GameStage, _prev: GameTypes.GameStage) -> void:
	refresh_access_prompt()
