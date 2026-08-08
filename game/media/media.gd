extends Node
## Media / Attention owner (MODULE 15).
## Autoload name: Media. Persistent state lives in GameState.
## No _process. No EventBus. No MODULE 16 scheduling.

signal attention_changed(new_value: int, delta: int)
signal photo_session_completed()
signal photo_published(photo_id: StringName, attention_gained: int)
signal incoming_offer_added(girl_id: StringName)
signal incoming_offer_read(girl_id: StringName)
signal feed_changed()
signal overload_ready()

var _signals_connected: bool = false
var _overload_ready_emitted: bool = false
var _active_session: MediaPhotoSession = null
var _last_new_offer_girl_ids: Array[StringName] = []


func _ready() -> void:
	_connect_signals()
	DfLog.info("MODULE_15", "Media ready")


func _connect_signals() -> void:
	if _signals_connected:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	if gs.has_signal("media_attention_changed") and not gs.is_connected("media_attention_changed", _on_gs_attention_changed):
		gs.connect("media_attention_changed", _on_gs_attention_changed)
	if gs.has_signal("state_reset") and not gs.is_connected("state_reset", _on_state_reset):
		gs.connect("state_reset", _on_state_reset)
	_signals_connected = true


func _on_state_reset() -> void:
	_overload_ready_emitted = false
	_last_new_offer_girl_ids.clear()
	if _active_session != null and is_instance_valid(_active_session):
		_active_session.queue_free()
	_active_session = null


## Save/Load: suppress one-shot overload_ready replay; clear transient session.
func sync_after_load() -> void:
	_last_new_offer_girl_ids.clear()
	if _active_session != null and is_instance_valid(_active_session):
		_active_session.queue_free()
	_active_session = null
	_overload_ready_emitted = is_overload_ready()


func _on_gs_attention_changed(new_value: int, delta: int) -> void:
	attention_changed.emit(new_value, delta)
	_last_new_offer_girl_ids = _sync_threshold_offers()
	_maybe_emit_overload_ready()


func is_feature_unlocked() -> bool:
	var story: Node = get_node_or_null("/root/Story")
	if story == null or not story.has_method("is_feature_unlocked"):
		return false
	return bool(story.call("is_feature_unlocked", StoryTypes.StoryFeature.MEDIA_ATTENTION))


func is_feed_active() -> bool:
	return is_feature_unlocked() and is_photo_session_completed()


func is_photo_session_completed() -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	return bool(gs.call("is_media_photo_session_completed"))


func is_photo_session_available() -> bool:
	return is_feature_unlocked() and not is_photo_session_completed()


func get_attention() -> int:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return 0
	return int(gs.call("get_media_attention"))


func is_overload_ready() -> bool:
	return get_attention() >= MediaContent.OVERLOAD_READY_ATTENTION \
		and get_incoming_offer_count() >= MediaContent.OVERLOAD_READY_OFFERS


func get_incoming_offer_count() -> int:
	return get_incoming_offer_girl_ids().size()


func get_incoming_offer_girl_ids() -> Array[StringName]:
	var gs: Node = get_node_or_null("/root/GameState")
	var out: Array[StringName] = []
	if gs == null:
		return out
	var raw: Array = gs.call("get_media_incoming_offer_girl_ids") as Array
	for entry in raw:
		out.append(entry as StringName)
	return out


func get_feed_event_ids() -> Array[StringName]:
	var gs: Node = get_node_or_null("/root/GameState")
	var out: Array[StringName] = []
	if gs == null:
		return out
	var raw: Array = gs.call("get_media_feed_event_ids") as Array
	for entry in raw:
		out.append(entry as StringName)
	return out


func get_published_photo_ids() -> Array[StringName]:
	var gs: Node = get_node_or_null("/root/GameState")
	var out: Array[StringName] = []
	if gs == null:
		return out
	var raw: Array = gs.call("get_media_published_photo_ids") as Array
	for entry in raw:
		out.append(entry as StringName)
	return out


func get_photo_pose(shot_id: StringName) -> StringName:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return &""
	return gs.call("get_media_photo_pose", shot_id) as StringName


func get_photo_attention_value(photo_id: StringName) -> int:
	var pose_id: StringName = get_photo_pose(photo_id)
	if String(pose_id) == "":
		return 0
	return MediaContent.pose_attention(pose_id)


func is_photo_prepared(photo_id: StringName) -> bool:
	return String(get_photo_pose(photo_id)) != ""


func is_photo_published(photo_id: StringName) -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	return bool(gs.call("is_media_photo_published", photo_id))


func can_publish_photo_today() -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	var day: Node = get_node_or_null("/root/GameDay")
	if gs == null or day == null:
		return false
	var last: int = int(gs.call("get_media_last_photo_publish_day"))
	var current: int = int(day.call("get_current_day"))
	return last != current


func has_active_photo_session() -> bool:
	return _active_session != null and is_instance_valid(_active_session) and not _active_session.is_finished()


func get_active_photo_session() -> MediaPhotoSession:
	if has_active_photo_session():
		return _active_session
	return null


## Start modal photo session. Returns session node or null.
func start_photo_session(player: Node = null) -> MediaPhotoSession:
	if not is_photo_session_available():
		return null
	if has_active_photo_session():
		return _active_session
	var session: MediaPhotoSession = MediaPhotoSession.new()
	_active_session = session
	var tree: SceneTree = get_tree()
	if tree != null and tree.root != null:
		tree.root.add_child(session)
	else:
		add_child(session)
	if not session.session_finished.is_connected(_on_session_finished):
		session.session_finished.connect(_on_session_finished)
	if not session.session_aborted.is_connected(_on_session_aborted):
		session.session_aborted.connect(_on_session_aborted)
	if not session.start(player):
		_active_session = null
		if is_instance_valid(session):
			session.queue_free()
		return null
	return session


func _on_session_finished() -> void:
	_active_session = null


func _on_session_aborted() -> void:
	_active_session = null


## Commit completed session poses + article + first Attention. Exactly once.
func complete_photo_session(pose_by_shot: Dictionary) -> bool:
	if not is_feature_unlocked():
		return false
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	if bool(gs.call("is_media_photo_session_completed")):
		return false
	for shot_id in MediaContent.SHOT_IDS:
		if not pose_by_shot.has(shot_id):
			push_error("[Media] complete_photo_session missing shot %s" % shot_id)
			return false
		var pose_id: StringName = pose_by_shot[shot_id] as StringName
		if MediaContent.pose_attention(pose_id) <= 0:
			push_error("[Media] complete_photo_session unknown pose %s" % pose_id)
			return false
		if not bool(gs.call("set_media_photo_pose", shot_id, pose_id)):
			push_error("[Media] complete_photo_session failed to store pose")
			return false
	if not bool(gs.call("mark_media_photo_session_completed")):
		return false
	if bool(gs.call("append_media_feed_event", MediaContent.FEED_ARTICLE_EDITOR)):
		feed_changed.emit()
	_last_new_offer_girl_ids.clear()
	gs.call("add_media_attention", MediaContent.ARTICLE_ATTENTION)
	# Threshold sync happens via media_attention_changed.
	photo_session_completed.emit()
	return true


func publish_photo(photo_id: StringName) -> MediaPublishResult:
	var result: MediaPublishResult = MediaPublishResult.new()
	result.photo_id = photo_id
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		result.error = MediaTypes.PublishError.LOCKED
		return result
	if not is_feature_unlocked():
		result.error = MediaTypes.PublishError.LOCKED
		return result
	if not bool(gs.call("is_media_photo_session_completed")):
		result.error = MediaTypes.PublishError.PHOTO_SESSION_REQUIRED
		return result
	if not MediaContent.is_known_photo(photo_id):
		result.error = MediaTypes.PublishError.UNKNOWN_PHOTO
		return result
	var pose_id: StringName = gs.call("get_media_photo_pose", photo_id) as StringName
	if String(pose_id) == "":
		result.error = MediaTypes.PublishError.NOT_PREPARED
		return result
	if bool(gs.call("is_media_photo_published", photo_id)):
		result.error = MediaTypes.PublishError.ALREADY_PUBLISHED
		return result
	if not can_publish_photo_today():
		result.error = MediaTypes.PublishError.DAILY_LIMIT
		return result
	var day: Node = get_node_or_null("/root/GameDay")
	if day == null:
		result.error = MediaTypes.PublishError.LOCKED
		return result
	var gain: int = MediaContent.pose_attention(pose_id)
	if not bool(gs.call("mark_media_photo_published", photo_id)):
		result.error = MediaTypes.PublishError.ALREADY_PUBLISHED
		return result
	var current_day: int = int(day.call("get_current_day"))
	gs.call("set_media_last_photo_publish_day", current_day)
	var feed_id: StringName = MediaContent.feed_photo_event_id(photo_id)
	if bool(gs.call("append_media_feed_event", feed_id)):
		feed_changed.emit()
	_last_new_offer_girl_ids.clear()
	var before: int = int(gs.call("get_media_attention"))
	var after: int = int(gs.call("add_media_attention", gain))
	var actual_gain: int = after - before
	result.ok = true
	result.error = MediaTypes.PublishError.OK
	result.attention_gained = actual_gain
	result.attention_after = after
	for gid in _last_new_offer_girl_ids:
		result.new_offer_girl_ids.append(gid)
	photo_published.emit(photo_id, actual_gain)
	return result


func mark_offer_read(girl_id: StringName) -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	if not bool(gs.call("has_media_incoming_offer", girl_id)):
		return false
	if bool(gs.call("mark_media_offer_read", girl_id)):
		incoming_offer_read.emit(girl_id)
		return true
	return false


func is_offer_read(girl_id: StringName) -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	return bool(gs.call("is_media_offer_read", girl_id))


func _sync_threshold_offers() -> Array[StringName]:
	var created: Array[StringName] = []
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return created
	var attention: int = int(gs.call("get_media_attention"))
	var desired: int = MediaContent.desired_threshold_offer_count(attention)
	var current: int = get_incoming_offer_count()
	while current < desired:
		var girl_id: StringName = _pick_next_candidate()
		if String(girl_id) == "":
			push_warning("[Media] no eligible media candidate left; attention=%s offers=%s" % [attention, current])
			break
		if not _create_incoming_offer(girl_id):
			break
		created.append(girl_id)
		current += 1
	return created


func _pick_next_candidate() -> StringName:
	var gs: Node = get_node_or_null("/root/GameState")
	var discovery: Node = get_node_or_null("/root/GirlDiscovery")
	if gs == null or discovery == null:
		return &""
	var experience: int = int(gs.call("get_experience"))
	for girl_id in MediaContent.CANDIDATE_PRIORITY:
		if bool(gs.call("has_media_incoming_offer", girl_id)):
			continue
		var def: GirlDefinition = discovery.call("get_girl_definition", girl_id) as GirlDefinition
		if def == null:
			continue
		if def.is_story:
			continue
		if def.required_experience > experience:
			continue
		return girl_id
	return &""


func _create_incoming_offer(girl_id: StringName) -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	var discovery: Node = get_node_or_null("/root/GirlDiscovery")
	if gs == null or discovery == null:
		return false
	if bool(gs.call("has_media_incoming_offer", girl_id)):
		return false
	if not bool(gs.call("has_girl_contact", girl_id)):
		if discovery.has_method("discover_girl_from_media"):
			discovery.call("discover_girl_from_media", girl_id)
		gs.call("add_girl_contact", girl_id)
	if not bool(gs.call("add_media_incoming_offer", girl_id)):
		return false
	var feed_id: StringName = MediaContent.feed_inbound_event_id(girl_id)
	if bool(gs.call("append_media_feed_event", feed_id)):
		feed_changed.emit()
	incoming_offer_added.emit(girl_id)
	return true


func _maybe_emit_overload_ready() -> void:
	if _overload_ready_emitted:
		return
	if not is_overload_ready():
		return
	_overload_ready_emitted = true
	overload_ready.emit()
