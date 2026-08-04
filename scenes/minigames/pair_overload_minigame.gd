extends CanvasLayer
## «Парный перегруз» — dual-lane collect/avoid arcade (~75s).

const UiEscapeScript := preload("res://core/ui_escape.gd")
const DURATION_SEC := 75.0
const LANE_COUNT := 3

signal finished(result: Dictionary)

var _root: Control
var _hud: Label
var _timer_lbl: Label
var _player_area: Control
var _girl_area: Control
var _transfer_btn: Button
var _close_btn: Button
var _running: bool = false
var _time_left: float = DURATION_SEC
var _spawn_cd: float = 0.0
var _player_lane: int = 1
var _girl_lane: int = 1
var _player_score: int = 0
var _girl_score: int = 0
var _joint_bonus: int = 0
var _broken_hits: int = 0
var _transfer_ready: bool = false
var _girl_id: String = ""
var _from_date: bool = false
var _standalone: bool = true
var _girl_ai_speed: float = 1.0
var _girl_ai_accuracy: float = 0.55
var _items: Array[Dictionary] = []
var _item_nodes: Dictionary = {}
var _next_item_id: int = 1


func _ready() -> void:
	add_to_group("arcade_minigame")
	layer = 27
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.05, 0.02, 0.12, 0.72)
	_root.add_child(dim)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -420.0
	panel.offset_top = -260.0
	panel.offset_right = 420.0
	panel.offset_bottom = 260.0
	_root.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "Парный перегруз"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	_timer_lbl = Label.new()
	_timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_timer_lbl)
	_hud = Label.new()
	_hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_hud)
	var lanes := HBoxContainer.new()
	lanes.add_theme_constant_override("separation", 16)
	lanes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(lanes)
	_player_area = _make_lane_board("Ты — A/D или ←/→, пробел собрать")
	_girl_area = _make_lane_board("Она (ИИ)")
	lanes.add_child(_player_area)
	lanes.add_child(_girl_area)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vbox.add_child(row)
	_transfer_btn = Button.new()
	_transfer_btn.text = "Передать бонус партнёру [F]"
	_transfer_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_transfer_btn.pressed.connect(_try_transfer)
	row.add_child(_transfer_btn)
	_close_btn = Button.new()
	_close_btn.text = "Сдаться"
	_close_btn.pressed.connect(func() -> void: _end_game(true))
	row.add_child(_close_btn)


func _make_lane_board(caption: String) -> Control:
	var wrap := Control.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.custom_minimum_size = Vector2(360, 280)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.12, 0.1, 0.18)
	wrap.add_child(bg)
	var lab := Label.new()
	lab.text = caption
	lab.position = Vector2(8, 4)
	wrap.add_child(lab)
	for i in LANE_COUNT:
		var lane_line := ColorRect.new()
		lane_line.color = Color(1, 1, 1, 0.08)
		lane_line.position = Vector2(20 + i * 110, 30)
		lane_line.size = Vector2(90, 240)
		wrap.add_child(lane_line)
	var catcher := ColorRect.new()
	catcher.name = "Catcher"
	catcher.color = Color(0.9, 0.75, 0.2)
	catcher.size = Vector2(70, 14)
	wrap.add_child(catcher)
	return wrap


func open(payload: Dictionary = {}) -> void:
	_girl_id = str(payload.get("girl_id", ""))
	_from_date = bool(payload.get("from_date", false))
	_standalone = not _from_date
	_configure_girl_ai()
	_running = true
	_time_left = DURATION_SEC
	_spawn_cd = 0.4
	_player_lane = 1
	_girl_lane = 1
	_player_score = 0
	_girl_score = 0
	_joint_bonus = 0
	_broken_hits = 0
	_transfer_ready = false
	_items.clear()
	for k in _item_nodes.keys():
		var n: Node = _item_nodes[k]
		if is_instance_valid(n):
			n.queue_free()
	_item_nodes.clear()
	_next_item_id = 1
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh_hud()
	_place_catchers()


func close() -> void:
	_running = false
	visible = false
	if UiEscapeScript.any_overlay_open(get_tree()):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _configure_girl_ai() -> void:
	_girl_ai_speed = 1.0
	_girl_ai_accuracy = 0.55
	if _girl_id.is_empty() or Game == null or Game.girls == null:
		return
	var traits: Array = Game.girls.girl_traits(StringName(_girl_id))
	var primaries: Array = Game.girls.girl_primary_traits(StringName(_girl_id))
	for t in traits + primaries:
		var tid := str(t)
		if tid in ["sport", "active", "punctual", "ambitious"]:
			_girl_ai_speed += 0.15
			_girl_ai_accuracy += 0.08
		elif tid in ["calm", "attentive"]:
			_girl_ai_accuracy += 0.12
		elif tid in ["chaos", "daring", "witty"]:
			_girl_ai_speed += 0.2
			_girl_ai_accuracy -= 0.05
		elif tid in ["media", "tech"]:
			_girl_ai_accuracy += 0.06
	_girl_ai_accuracy = clampf(_girl_ai_accuracy, 0.35, 0.92)
	_girl_ai_speed = clampf(_girl_ai_speed, 0.7, 1.8)


func _process(delta: float) -> void:
	if not visible or not _running:
		return
	_time_left -= delta
	_spawn_cd -= delta
	if _spawn_cd <= 0.0:
		_spawn_pair()
		_spawn_cd = randf_range(0.45, 0.85)
	_update_items(delta)
	_update_girl_ai(delta)
	_place_catchers()
	_refresh_hud()
	if _time_left <= 0.0:
		_end_game(false)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _running:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_A, KEY_LEFT:
				_player_lane = maxi(0, _player_lane - 1)
				get_viewport().set_input_as_handled()
			KEY_D, KEY_RIGHT:
				_player_lane = mini(LANE_COUNT - 1, _player_lane + 1)
				get_viewport().set_input_as_handled()
			KEY_SPACE:
				_try_catch_player()
				get_viewport().set_input_as_handled()
			KEY_F:
				_try_transfer()
				get_viewport().set_input_as_handled()


func _spawn_pair() -> void:
	var kinds := ["heart", "star", "coin", "broken"]
	var weights := [0.34, 0.28, 0.22, 0.16]
	var kind := _pick_weighted(kinds, weights)
	var lane := randi() % LANE_COUNT
	_spawn_item(kind, lane, true)
	var girl_kind := kind
	if randf() < 0.35:
		girl_kind = _pick_weighted(kinds, weights)
	var girl_lane := lane if randf() < 0.45 else randi() % LANE_COUNT
	_spawn_item(girl_kind, girl_lane, false)


func _pick_weighted(kinds: Array, weights: Array) -> String:
	var r := randf()
	var acc := 0.0
	for i in kinds.size():
		acc += float(weights[i])
		if r <= acc:
			return str(kinds[i])
	return str(kinds[0])


func _spawn_item(kind: String, lane: int, for_player: bool) -> void:
	var id := _next_item_id
	_next_item_id += 1
	var area: Control = _player_area if for_player else _girl_area
	var node := ColorRect.new()
	node.size = Vector2(36, 36)
	match kind:
		"heart":
			node.color = Color(1.0, 0.35, 0.55)
		"star":
			node.color = Color(1.0, 0.9, 0.25)
		"coin":
			node.color = Color(0.95, 0.75, 0.2)
		_:
			node.color = Color(0.45, 0.15, 0.2)
	area.add_child(node)
	_item_nodes[id] = node
	_items.append({
		"id": id,
		"kind": kind,
		"lane": lane,
		"y": 36.0,
		"speed": randf_range(90.0, 150.0) * (1.0 if for_player else _girl_ai_speed),
		"for_player": for_player,
	})
	_layout_item(_items[_items.size() - 1])


func _layout_item(it: Dictionary) -> void:
	var node: ColorRect = _item_nodes.get(int(it["id"])) as ColorRect
	if node == null or not is_instance_valid(node):
		return
	var lane := int(it["lane"])
	node.position = Vector2(35 + lane * 110, float(it["y"]))


func _place_catchers() -> void:
	_place_catcher(_player_area, _player_lane, Color(0.95, 0.8, 0.25))
	_place_catcher(_girl_area, _girl_lane, Color(0.7, 0.45, 0.95))


func _place_catcher(area: Control, lane: int, color: Color) -> void:
	var c := area.get_node_or_null("Catcher") as ColorRect
	if c == null:
		return
	c.color = color
	c.position = Vector2(30 + lane * 110, 250)


func _update_items(delta: float) -> void:
	var remain: Array[Dictionary] = []
	for it in _items:
		it["y"] = float(it["y"]) + float(it["speed"]) * delta
		if float(it["y"]) >= 250.0:
			_auto_resolve(it)
			var node: Node = _item_nodes.get(int(it["id"])) as Node
			if is_instance_valid(node):
				node.queue_free()
			_item_nodes.erase(int(it["id"]))
		else:
			_layout_item(it)
			remain.append(it)
	_items = remain


func _auto_resolve(it: Dictionary) -> void:
	var for_player := bool(it["for_player"])
	var lane := int(it["lane"])
	var catcher := _player_lane if for_player else _girl_lane
	if lane != catcher:
		return
	_apply_pickup(str(it["kind"]), for_player)


func _try_catch_player() -> void:
	for i in range(_items.size() - 1, -1, -1):
		var it: Dictionary = _items[i]
		if not bool(it["for_player"]):
			continue
		if int(it["lane"]) != _player_lane:
			continue
		if float(it["y"]) < 200.0:
			continue
		_apply_pickup(str(it["kind"]), true)
		var node: Node = _item_nodes.get(int(it["id"])) as Node
		if is_instance_valid(node):
			node.queue_free()
		_item_nodes.erase(int(it["id"]))
		_items.remove_at(i)
		return


func _update_girl_ai(_delta: float) -> void:
	var best_lane := _girl_lane
	var best_y := -1.0
	for it in _items:
		if bool(it["for_player"]):
			continue
		var kind := str(it["kind"])
		var y := float(it["y"])
		if kind == "broken":
			if int(it["lane"]) == _girl_lane and y > 180.0 and randf() < _girl_ai_accuracy:
				_girl_lane = (_girl_lane + 1) % LANE_COUNT
			continue
		if y > best_y and randf() < _girl_ai_accuracy:
			best_y = y
			best_lane = int(it["lane"])
	if best_y >= 0.0:
		_girl_lane = best_lane


func _apply_pickup(kind: String, for_player: bool) -> void:
	var pts := 0
	match kind:
		"heart":
			pts = 3
			_transfer_ready = true
		"star":
			pts = 4
		"coin":
			pts = 2
		"broken":
			pts = -3
			_broken_hits += 1
	if for_player:
		_player_score = maxi(0, _player_score + pts)
	else:
		_girl_score = maxi(0, _girl_score + pts)
	if kind != "broken" and _player_lane == _girl_lane and randf() < 0.25:
		_joint_bonus += 1
		_player_score += 1
		_girl_score += 1


func _try_transfer() -> void:
	if not _running or not _transfer_ready:
		return
	if _player_score < 2:
		return
	_player_score -= 2
	_girl_score += 3
	_joint_bonus += 2
	_transfer_ready = false
	EventBus.toast("Передал бонус — она вспыхнула!", &"ok")


func _refresh_hud() -> void:
	_timer_lbl.text = "Время: %dс" % int(ceil(_time_left))
	var joint := _player_score + _girl_score + _joint_bonus
	_hud.text = "Ты %d · Она %d · Совместно %d · Передача: %s" % [
		_player_score, _girl_score, joint, "готова" if _transfer_ready else "—"
	]


func _end_game(aborted: bool) -> void:
	if not _running:
		return
	_running = false
	var joint := _player_score + _girl_score + _joint_bonus
	var result := {
		"aborted": aborted,
		"player_score": _player_score,
		"girl_score": _girl_score,
		"joint_score": joint,
		"broken_hits": _broken_hits,
		"girl_id": _girl_id,
		"from_date": _from_date,
		"standalone": _standalone,
	}
	_apply_rewards(result)
	finished.emit(result)
	close()


func _apply_rewards(result: Dictionary) -> void:
	if bool(result.get("aborted", false)):
		EventBus.toast("Парный перегруз прерван", &"info")
		return
	var joint := int(result.get("joint_score", 0))
	var gid := str(result.get("girl_id", ""))
	if Game.economy != null:
		Game.economy.add(&"popularity", 0.15 + float(joint) * 0.01, &"arcade")
	if gid != "" and Game.girls != null:
		var bond := clampf(float(joint) * 0.35 - float(result.get("broken_hits", 0)) * 1.5, -4.0, 18.0)
		if bond != 0.0:
			Game.girls.add_bond(StringName(gid), bond)
		var obs := "В аркаде она ловила %s — совместный счёт %d." % [
			"звёзды" if int(result.get("girl_score", 0)) >= int(result.get("player_score", 0)) else "ритм рядом",
			joint,
		]
		Game.girls.add_observation(StringName(gid), "arcade_pair_overload", obs, "attention", "arcade")
		if bool(result.get("from_date", false)) and Game.dating != null and not Game.dating.active_manual.is_empty():
			Game.dating.active_manual["score"] = float(Game.dating.active_manual.get("score", 0.0)) + clampf(float(joint) * 0.04, 0.2, 1.8)
			Game.dating.active_manual["bond_delta"] = float(Game.dating.active_manual.get("bond_delta", 0.0)) + bond * 0.4
			EventBus.toast("Аркада: совместно %d — свидание продолжается" % joint, &"ok")
			if Game.dating.has_method("resume_after_arcade"):
				Game.dating.resume_after_arcade()
			EventBus.notify.emit("ARCADE_RESUME_DATE", &"date_fx")
		else:
			EventBus.toast("Парный перегруз: совместно %d" % joint, &"ok")
	else:
		EventBus.toast("Парный перегруз: %d очков (соло)" % int(result.get("player_score", 0)), &"ok")
