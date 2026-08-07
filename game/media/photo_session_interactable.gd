class_name PhotoSessionInteractable
extends Interactable
## Physical photo-session entry at Editor studio (MODULE 15).
## Scene placement is M15_B — this script only.

var _busy: bool = false


func _ready() -> void:
	prompt_action = MediaContent.PHOTO_SESSION_PROMPT
	monitoring = false
	monitorable = true
	collision_layer = 4
	collision_mask = 0
	_ensure_collision()
	_connect_presence_signals()
	_refresh_presence()


func can_interact(player: Node) -> bool:
	if not super.can_interact(player):
		return false
	if _busy:
		return false
	if not _is_feature_unlocked():
		return false
	# Available for start, or focusable after completion for done prompt.
	if not _is_session_available() and not _is_session_completed():
		return false
	if player == null or not player.has_method("get_control_mode"):
		return true
	var mode: Variant = player.call("get_control_mode")
	return int(mode) == int(PlayerController.ControlMode.GAMEPLAY)


func get_interaction_prompt(_player: Node) -> String:
	if _is_session_completed():
		return MediaContent.PHOTO_SESSION_DONE_PROMPT
	if _is_session_available():
		return "[E] %s" % MediaContent.PHOTO_SESSION_PROMPT
	return ""


func _on_interact(player: Node) -> void:
	if _busy:
		return
	if _is_session_completed():
		return
	if not can_interact(player):
		return
	var media: Node = get_node_or_null("/root/Media")
	if media == null or not media.has_method("start_photo_session"):
		return
	_busy = true
	var session: Variant = media.call("start_photo_session", player)
	if session == null:
		_busy = false
		return
	if session is MediaPhotoSession:
		var photo_session: MediaPhotoSession = session as MediaPhotoSession
		if not photo_session.session_finished.is_connected(_on_session_done):
			photo_session.session_finished.connect(_on_session_done)
		if not photo_session.session_aborted.is_connected(_on_session_done):
			photo_session.session_aborted.connect(_on_session_done)
	else:
		_busy = false


func _on_session_done() -> void:
	_busy = false
	_refresh_presence()


func _ensure_collision() -> void:
	var shape_node: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null:
		shape_node = get_node_or_null("Collision") as CollisionShape3D
	if shape_node != null:
		return
	shape_node = CollisionShape3D.new()
	shape_node.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 2.0, 1.4)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 1.0, 0.0)
	add_child(shape_node)


func _connect_presence_signals() -> void:
	var media: Node = get_node_or_null("/root/Media")
	if media != null:
		if media.has_signal("photo_session_completed") and not media.is_connected("photo_session_completed", _on_photo_session_completed):
			media.connect("photo_session_completed", _on_photo_session_completed)
	var story: Node = get_node_or_null("/root/Story")
	if story != null and story.has_signal("feature_unlocked"):
		if not story.is_connected("feature_unlocked", _on_feature_unlocked):
			story.connect("feature_unlocked", _on_feature_unlocked)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_signal("state_reset"):
		if not gs.is_connected("state_reset", _on_state_reset):
			gs.connect("state_reset", _on_state_reset)


func _refresh_presence() -> void:
	var unlocked: bool = _is_feature_unlocked()
	visible = unlocked
	monitorable = unlocked
	var completed_visual: Node3D = get_node_or_null("CompletedVisual") as Node3D
	if completed_visual != null:
		completed_visual.visible = unlocked and _is_session_completed()


func _on_photo_session_completed() -> void:
	_refresh_presence()


func _on_feature_unlocked(_feature: Variant) -> void:
	_refresh_presence()


func _on_state_reset() -> void:
	_busy = false
	_refresh_presence()


func _is_feature_unlocked() -> bool:
	var media: Node = get_node_or_null("/root/Media")
	if media != null and media.has_method("is_feature_unlocked"):
		return bool(media.call("is_feature_unlocked"))
	return false


func _is_session_available() -> bool:
	var media: Node = get_node_or_null("/root/Media")
	if media != null and media.has_method("is_photo_session_available"):
		return bool(media.call("is_photo_session_available"))
	return false


func _is_session_completed() -> bool:
	var media: Node = get_node_or_null("/root/Media")
	if media != null and media.has_method("is_photo_session_completed"):
		return bool(media.call("is_photo_session_completed"))
	return false
