class_name DateInvitePanel
extends Control
## Phone date-invite modal. Books a pending appointment; does not start dates.

const ACTION_BUTTON_SCENE: String = "res://ui/common/action_button.tscn"
const UNAVAILABLE_TEXT: String = "Недоступно"
const LOCATION_HOME: StringName = &"apartment"

@onready var _title_label: Label = %TitleLabel
@onready var _venue_list: VBoxContainer = %VenueList
@onready var _hour_12: Button = %Hour12
@onready var _hour_15: Button = %Hour15
@onready var _hour_18: Button = %Hour18
@onready var _hour_21: Button = %Hour21
@onready var _message_label: Label = %MessageLabel
@onready var _confirm_btn: Button = %ConfirmButton
@onready var _cancel_btn: Button = %CancelButton

var _girl_id: StringName = &""
var _player: Node = null
var _phone: Node = null
var _location_id: StringName = LOCATION_HOME
var _hour: int = 12
var _venue_available: Dictionary = {}
var _venue_cost: Dictionary = {}
var _venue_buttons: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiScaleHelper.apply_to_control(self)
	_hour_12.pressed.connect(_on_hour_pressed.bind(12))
	_hour_15.pressed.connect(_on_hour_pressed.bind(15))
	_hour_18.pressed.connect(_on_hour_pressed.bind(18))
	_hour_21.pressed.connect(_on_hour_pressed.bind(21))
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	_cancel_btn.pressed.connect(close)


func open(girl_id: StringName, phone: Node, player: Node) -> void:
	_girl_id = girl_id
	_phone = phone
	_player = player
	_message_label.text = ""
	if _title_label != null:
		_title_label.text = "Позвать на свидание"
	_populate_from_api()
	visible = true
	_confirm_btn.grab_focus()


func close() -> void:
	visible = false
	_message_label.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause") or event.is_action_pressed("phone"):
		close()
		get_viewport().set_input_as_handled()


func _on_hour_pressed(hour: int) -> void:
	_select_hour(hour)


func _select_venue(location_id: StringName) -> void:
	_location_id = location_id
	for lid in _venue_buttons.keys():
		var btn: Button = _venue_buttons[lid] as Button
		if btn == null or not is_instance_valid(btn):
			continue
		btn.set_pressed_no_signal(lid == location_id)
	_update_confirm_enabled()


func _select_hour(hour: int) -> void:
	_hour = hour
	_hour_12.set_pressed_no_signal(hour == 12)
	_hour_15.set_pressed_no_signal(hour == 15)
	_hour_18.set_pressed_no_signal(hour == 18)
	_hour_21.set_pressed_no_signal(hour == 21)
	_update_confirm_enabled()


func _populate_from_api() -> void:
	_venue_available.clear()
	_venue_cost.clear()
	var rel: Node = get_node_or_null("/root/Relationships")
	var has_venues: bool = rel != null and rel.has_method("get_date_invite_venues")
	var has_hours: bool = rel != null and rel.has_method("get_date_invite_hours")
	if not has_venues or not has_hours:
		_apply_fallback_options()
		return
	var venues: Array = rel.call("get_date_invite_venues") as Array
	_apply_venues(venues)
	var hours: Array = rel.call("get_date_invite_hours") as Array
	_apply_hours(hours)
	_select_default_options()
	_update_confirm_enabled()


func _apply_fallback_options() -> void:
	_clear_venue_buttons()
	_hour_12.text = "12:00"
	_hour_15.text = "15:00"
	_hour_18.text = "18:00"
	_hour_21.text = "21:00"
	_hour_12.disabled = true
	_hour_15.disabled = true
	_hour_18.disabled = true
	_hour_21.disabled = true
	_venue_available[LOCATION_HOME] = false
	_message_label.text = UNAVAILABLE_TEXT
	_select_hour(12)
	_confirm_btn.disabled = true


func _clear_venue_buttons() -> void:
	_venue_buttons.clear()
	if _venue_list == null:
		return
	for child in _venue_list.get_children():
		child.queue_free()


func _apply_venues(venues: Array) -> void:
	_clear_venue_buttons()
	var packed: PackedScene = load(ACTION_BUTTON_SCENE) as PackedScene
	if packed == null:
		_message_label.text = UNAVAILABLE_TEXT
		return
	for item in venues:
		var row: Dictionary = item as Dictionary
		if row.is_empty():
			continue
		var location_id: StringName = StringName(str(row.get("location_id", "")))
		var label: String = str(row.get("label", "")).strip_edges()
		var cost: int = int(row.get("cost", 0))
		var available: bool = bool(row.get("available", false))
		var reason: String = str(row.get("reason", "")).strip_edges()
		if label == "":
			label = String(location_id)
		var cost_text: String = "бесплатно"
		if cost > 0:
			cost_text = UiNumberFormat.format_money(cost)
		var text: String = "%s (%s)" % [label, cost_text]
		if not available and reason != "":
			text = "%s — %s" % [text, reason]
		var btn: Button = packed.instantiate() as Button
		if btn == null:
			continue
		btn.toggle_mode = true
		btn.text = text
		btn.disabled = not available
		btn.custom_minimum_size = Vector2(420, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.clip_text = false
		btn.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		btn.pressed.connect(_on_venue_button_pressed.bind(location_id))
		_venue_list.add_child(btn)
		_venue_buttons[location_id] = btn
		_venue_available[location_id] = available
		_venue_cost[location_id] = cost


func _on_venue_button_pressed(location_id: StringName) -> void:
	if not bool(_venue_available.get(location_id, false)):
		return
	_select_venue(location_id)


func _apply_hours(hours: Array) -> void:
	var by_hour: Dictionary = {}
	for item in hours:
		var row: Dictionary = item as Dictionary
		if row.is_empty():
			continue
		var hour: int = int(row.get("hour", -1))
		by_hour[hour] = row
	_apply_hour_button(_hour_12, 12, by_hour)
	_apply_hour_button(_hour_15, 15, by_hour)
	_apply_hour_button(_hour_18, 18, by_hour)
	_apply_hour_button(_hour_21, 21, by_hour)


func _apply_hour_button(button: Button, hour: int, by_hour: Dictionary) -> void:
	if not by_hour.has(hour):
		button.text = "%02d:00" % hour
		button.disabled = true
		return
	var row: Dictionary = by_hour[hour] as Dictionary
	var label: String = str(row.get("label", "")).strip_edges()
	if label == "":
		label = "%02d:00" % hour
	var next_day: bool = bool(row.get("next_day", false))
	if next_day and not label.contains("завтра"):
		label = "%s (завтра)" % label
	button.text = label
	button.disabled = false


func _select_default_options() -> void:
	var venue: StringName = LOCATION_HOME
	if not bool(_venue_available.get(LOCATION_HOME, false)):
		for lid in _venue_available.keys():
			if bool(_venue_available[lid]):
				venue = lid as StringName
				break
	_select_venue(venue)
	var default_hour: int = 12
	if _hour_12.disabled:
		if not _hour_15.disabled:
			default_hour = 15
		elif not _hour_18.disabled:
			default_hour = 18
		elif not _hour_21.disabled:
			default_hour = 21
	_select_hour(default_hour)


func _update_confirm_enabled() -> void:
	var venue_ok: bool = bool(_venue_available.get(_location_id, false))
	var hour_btn: Button = _hour_button(_hour)
	var hour_ok: bool = hour_btn != null and not hour_btn.disabled
	_confirm_btn.disabled = not (venue_ok and hour_ok)


func _hour_button(hour: int) -> Button:
	match hour:
		12:
			return _hour_12
		15:
			return _hour_15
		18:
			return _hour_18
		21:
			return _hour_21
		_:
			return null


func _on_confirm_pressed() -> void:
	_message_label.text = ""
	if _confirm_btn.disabled:
		return
	var rel: Node = get_node_or_null("/root/Relationships")
	if rel == null or not rel.has_method("confirm_date_invite"):
		_message_label.text = UNAVAILABLE_TEXT
		return
	var result: Dictionary = rel.call(
		"confirm_date_invite", _girl_id, _location_id, _hour
	) as Dictionary
	if result.is_empty() or not bool(result.get("ok", false)):
		var msg: String = str(result.get("message", "")).strip_edges()
		if msg == "":
			msg = UNAVAILABLE_TEXT
		_message_label.text = msg
		return
	var booked: String = str(result.get("message", "")).strip_edges()
	close()
	if _phone != null and _phone.has_method("close"):
		_phone.close()
	_notify_hud(booked)


func _notify_hud(message: String) -> void:
	if message.strip_edges() == "":
		return
	var world: Node = get_node_or_null("/root/World")
	if world == null or not world.has_method("get_game_hud"):
		return
	var hud: Node = world.call("get_game_hud") as Node
	if hud != null and hud.has_method("show_notification"):
		hud.call("show_notification", message)
