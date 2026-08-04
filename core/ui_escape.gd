class_name UiEscape
extends RefCounted
## Esc priority: close any open overlay first; pause only when nothing else is up.


static func dismiss_overlays(tree: SceneTree) -> bool:
	## Returns true if something was closed.
	if tree == null:
		return false
	var closed := false

	var settings := tree.get_first_node_in_group("settings_ui")
	if settings == null:
		settings = _find_by_name(tree, "SettingsMenu")
	if settings != null and bool(settings.visible):
		if settings.has_method("close"):
			settings.call("close")
		else:
			settings.visible = false
		closed = true

	var reveal := tree.get_first_node_in_group("reveal_ui")
	if reveal != null and bool(reveal.visible):
		if reveal.has_method("force_close"):
			reveal.call("force_close")
		elif reveal.has_method("close"):
			reveal.call("close")
		else:
			reveal.visible = false
		closed = true

	var finale := tree.get_first_node_in_group("finale_ui")
	if finale != null and bool(finale.visible):
		if finale.has_method("close"):
			finale.call("close")
		else:
			finale.visible = false
		closed = true

	var event_ui := tree.get_first_node_in_group("event_ui")
	if event_ui != null and _is_overlay_open(event_ui):
		if event_ui.has_method("force_close"):
			event_ui.call("force_close")
		else:
			event_ui.visible = false
		if Game.events != null and not Game.events.active.is_empty():
			Game.events.active.clear()
			Game.events.event_closed.emit()
		closed = true

	var shop_ui := tree.get_first_node_in_group("shop_ui")
	if shop_ui != null and _is_overlay_open(shop_ui):
		if shop_ui.has_method("close"):
			shop_ui.call("close")
		else:
			shop_ui.visible = false
		closed = true

	var gym_ui := tree.get_first_node_in_group("gym_ui")
	if gym_ui != null and _is_overlay_open(gym_ui):
		if gym_ui.has_method("close"):
			gym_ui.call("close")
		else:
			gym_ui.visible = false
		closed = true

	var arcade_ui := tree.get_first_node_in_group("arcade_minigame")
	if arcade_ui != null and _is_overlay_open(arcade_ui):
		if arcade_ui.has_method("close"):
			arcade_ui.call("close")
		else:
			arcade_ui.visible = false
		closed = true

	for agency_group in ["photo_studio_ui", "barber_ui", "agency_board_ui", "elevator_ui", "district_gate_ui"]:
		var agency_ui := tree.get_first_node_in_group(agency_group)
		if agency_ui != null and _is_overlay_open(agency_ui):
			if agency_ui.has_method("close"):
				agency_ui.call("close")
			else:
				agency_ui.visible = false
			closed = true

	var date_ui := tree.get_first_node_in_group("date_ui")
	if date_ui != null and _is_overlay_open(date_ui):
		date_ui.visible = false
		closed = true
		if not Game.dating.active_manual.is_empty():
			Game.dating.active_manual.clear()
			Game.dating.date_ui_close.emit()

	var phone := tree.get_first_node_in_group("phone_ui")
	if phone != null and _is_overlay_open(phone):
		if phone.has_method("force_close"):
			phone.call("force_close")
		elif phone.has_method("set_open"):
			phone.call("set_open", false)
		else:
			phone.visible = false
		closed = true

	var player := tree.get_first_node_in_group("player")
	if player != null:
		player.set("_phone_open", false)
		player.set("_date_lock", false)

	if closed:
		var focus := tree.root.get_viewport().gui_get_focus_owner()
		if focus:
			focus.release_focus()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	return closed


static func any_overlay_open(tree: SceneTree) -> bool:
	## True when a modal/menu owns the cursor (FPS look must not re-capture).
	if tree == null:
		return false
	for group in ["settings_ui", "reveal_ui", "finale_ui", "event_ui", "shop_ui", "gym_ui", "arcade_minigame", "photo_studio_ui", "barber_ui", "agency_board_ui", "elevator_ui", "district_gate_ui", "date_ui", "phone_ui", "pause_ui", "clone_accept_ui", "date_wait_ui"]:
		var n := tree.get_first_node_in_group(group)
		if n != null and _is_overlay_open(n):
			return true
	var settings := _find_by_name(tree, "SettingsMenu")
	if settings != null and bool(settings.visible):
		return true
	return false


static func _is_overlay_open(node: Node) -> bool:
	if node == null:
		return false
	# Root visibility is the source of truth. Child Panel may stay visible=true
	# while the root is hidden — that must NOT block opening pause.
	return bool(node.visible)


static func _find_by_name(tree: SceneTree, node_name: String) -> Node:
	var scene := tree.current_scene
	if scene == null:
		return null
	return scene.find_child(node_name, true, false)
