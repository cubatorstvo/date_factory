class_name GirlActor
extends Interactable
## Thin world adapter for girl discovery (MODULE 08).
## girl_id + CharacterActor appearance + proximity discover + Interactable.

const SEEN_RADIUS: float = 4.0
const LAYER_WORLD: int = 1
const LAYER_INTERACTABLE: int = 4
const LAYER_CHARACTERS: int = 8

@export var girl_id: StringName = &""

signal attempt_result(result: Dictionary)

var _character: CharacterActor = null
var _seen_area: Area3D = null
var _collision: CollisionShape3D = null
var _hidden_by_cooldown: bool = false
var _choice_ui: CanvasLayer = null
var _locked_ui: CanvasLayer = null


func _ready() -> void:
	collision_layer = LAYER_INTERACTABLE
	collision_mask = 0
	monitoring = false
	monitorable = true
	_ensure_collision()
	_ensure_character()
	_ensure_seen_trigger()
	var gd: Node = get_node_or_null("/root/GirlDiscovery")
	if gd != null and gd.has_signal("girl_available_again"):
		if not gd.is_connected("girl_available_again", _on_available_again):
			gd.connect("girl_available_again", _on_available_again)
	if gd != null and gd.has_signal("girl_discovery_failed"):
		if not gd.is_connected("girl_discovery_failed", _on_discovery_failed):
			gd.connect("girl_discovery_failed", _on_discovery_failed)
	if gd != null and gd.has_signal("girl_contact_added"):
		if not gd.is_connected("girl_contact_added", _on_contact_added):
			gd.connect("girl_contact_added", _on_contact_added)
	refresh_presence()


func get_character_actor() -> CharacterActor:
	return _character


func refresh_presence() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	var remaining: int = 0
	if gs != null:
		remaining = int(gs.call("get_girl_retry_days_remaining", girl_id))
	var should_hide: bool = remaining > 0
	_hidden_by_cooldown = should_hide
	visible = not should_hide
	if _collision != null:
		_collision.disabled = should_hide
	if _character != null:
		_character.set_character_visible(not should_hide)
	if _seen_area != null:
		_seen_area.monitoring = not should_hide
		var seen_shape: CollisionShape3D = _seen_area.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if seen_shape != null:
			seen_shape.disabled = should_hide
	_refresh_interaction()


func can_interact(player: Node) -> bool:
	if _hidden_by_cooldown:
		return false
	_refresh_interaction()
	return super.can_interact(player)


func get_interaction_prompt(player: Node) -> String:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and bool(gs.call("has_girl_contact", girl_id)):
		return "номер уже получен"
	prompt_action = "Познакомиться"
	return super.get_interaction_prompt(player)


func _on_interact(player: Node) -> void:
	var gd: Node = get_node_or_null("/root/GirlDiscovery")
	if gd == null:
		attempt_result.emit({"ok": false, "reason": &"NO_SERVICE"})
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and bool(gs.call("has_girl_contact", girl_id)):
		attempt_result.emit({"ok": false, "reason": &"ALREADY_CONTACT"})
		return
	var begin: Dictionary = gd.call("begin_attempt", girl_id) as Dictionary
	attempt_result.emit(begin)
	if not bool(begin.get("ok", false)):
		var reason: StringName = begin.get("reason", &"") as StringName
		if reason == &"LOCKED_EXPERIENCE":
			_show_locked_experience(begin, player)
		return
	_show_approach_choices(begin, player)


func _refresh_interaction() -> void:
	if _hidden_by_cooldown:
		interaction_enabled = false
		return
	interaction_enabled = true
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and bool(gs.call("has_girl_contact", girl_id)):
		prompt_action = "номер уже получен"
	else:
		prompt_action = "Познакомиться"


func _ensure_collision() -> void:
	_collision = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if _collision == null:
		_collision = CollisionShape3D.new()
		_collision.name = "CollisionShape3D"
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.45
		capsule.height = 1.8
		_collision.shape = capsule
		_collision.position = Vector3(0.0, 0.9, 0.0)
		add_child(_collision)


func _ensure_character() -> void:
	_character = get_node_or_null("CharacterActor") as CharacterActor
	if _character == null:
		var gd: Node = get_node_or_null("/root/GirlDiscovery")
		var profile_id: StringName = &"appearance_female_base"
		if gd != null:
			var def: GirlDefinition = gd.call("get_girl_definition", girl_id) as GirlDefinition
			if def != null and String(def.appearance_profile_id) != "":
				profile_id = def.appearance_profile_id
		_character = CharacterFactory.create(profile_id, girl_id, self)
		if _character != null:
			_character.name = "CharacterActor"
			_character.position = Vector3.ZERO


func _ensure_seen_trigger() -> void:
	_seen_area = get_node_or_null("SeenTrigger") as Area3D
	if _seen_area == null:
		_seen_area = Area3D.new()
		_seen_area.name = "SeenTrigger"
		add_child(_seen_area)
		var shape := CollisionShape3D.new()
		shape.name = "CollisionShape3D"
		var sphere := SphereShape3D.new()
		sphere.radius = SEEN_RADIUS
		shape.shape = sphere
		_seen_area.add_child(shape)
	_seen_area.collision_layer = 0
	_seen_area.collision_mask = LAYER_CHARACTERS | LAYER_WORLD
	# Player is CharacterBody3D on default layer 1 typically; also check group.
	_seen_area.collision_mask = 0xFFFFFFFF
	_seen_area.monitoring = true
	_seen_area.monitorable = false
	if not _seen_area.body_entered.is_connected(_on_seen_body_entered):
		_seen_area.body_entered.connect(_on_seen_body_entered)


func _on_seen_body_entered(body: Node3D) -> void:
	if _hidden_by_cooldown:
		return
	if body == null:
		return
	if not (body.is_in_group("player") or body is PlayerController):
		return
	var gd: Node = get_node_or_null("/root/GirlDiscovery")
	if gd != null:
		gd.call("discover_girl", girl_id)


func _on_available_again(gid: StringName) -> void:
	if gid != girl_id:
		return
	refresh_presence()


func _on_discovery_failed(gid: StringName, _cooldown_days: int) -> void:
	if gid != girl_id:
		return
	refresh_presence()


func _on_contact_added(gid: StringName) -> void:
	if gid != girl_id:
		return
	_refresh_interaction()


func _show_locked_experience(begin: Dictionary, player: Node) -> void:
	_close_choice_ui(player)
	var layer := CanvasLayer.new()
	layer.name = "LockedExperienceUI"
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(360, 120)
	var vbox := VBoxContainer.new()
	var label := Label.new()
	var req: int = int(begin.get("required_experience", 0))
	var cur: int = int(begin.get("experience", 0))
	label.text = "Нужна Опытность: %s\nСейчас: %s" % [req, cur]
	var btn := Button.new()
	btn.text = "Закрыть"
	btn.pressed.connect(func() -> void:
		_close_locked_ui(player)
	)
	vbox.add_child(label)
	vbox.add_child(btn)
	panel.add_child(vbox)
	layer.add_child(panel)
	add_child(layer)
	_locked_ui = layer
	_enter_modal(player)


func _show_approach_choices(begin: Dictionary, player: Node) -> void:
	_close_choice_ui(player)
	var layer := CanvasLayer.new()
	layer.name = "DiscoveryChoiceUI"
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(420, 280)
	var vbox := VBoxContainer.new()
	var setup := Label.new()
	setup.text = str(begin.get("setup_text", ""))
	setup.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(setup)
	var approaches: Array = begin.get("approaches", []) as Array
	for entry in approaches:
		var info: Dictionary = entry as Dictionary
		var btn := Button.new()
		var label_text: String = str(info.get("label", ""))
		if bool(info.get("has_requirement", false)):
			var char_name: String = _char_label(info.get("required_characteristic", 0))
			label_text += " (%s %s)" % [char_name, int(info.get("required_level", 0))]
		btn.text = label_text
		btn.disabled = not bool(info.get("available", false))
		var aid: StringName = info.get("id", &"") as StringName
		btn.pressed.connect(func() -> void:
			_resolve_choice(aid, player)
		)
		vbox.add_child(btn)
	var cancel := Button.new()
	cancel.text = "Отмена"
	cancel.pressed.connect(func() -> void:
		var gd: Node = get_node_or_null("/root/GirlDiscovery")
		if gd != null:
			gd.call("force_clear_attempt")
		_close_choice_ui(player)
	)
	vbox.add_child(cancel)
	panel.add_child(vbox)
	layer.add_child(panel)
	add_child(layer)
	_choice_ui = layer
	_enter_modal(player)


func _resolve_choice(approach_id: StringName, player: Node) -> void:
	var gd: Node = get_node_or_null("/root/GirlDiscovery")
	if gd == null:
		return
	var result: Dictionary = gd.call("select_approach", approach_id) as Dictionary
	attempt_result.emit(result)
	_close_choice_ui(player)
	_show_result_banner(result, player)
	refresh_presence()


func _show_result_banner(result: Dictionary, player: Node) -> void:
	var reason: StringName = result.get("reason", &"") as StringName
	var text: String = ""
	if reason == &"SUCCESS":
		text = "НОМЕР ПОЛУЧЕН\n%s" % str(result.get("result_text", ""))
	elif reason == &"FAILURE":
		text = "НЕ ВЫШЛО\n%s" % str(result.get("result_text", ""))
		if result.has("new_clue_index"):
			var gd: Node = get_node_or_null("/root/GirlDiscovery")
			var def: GirlDefinition = null
			if gd != null:
				def = gd.call("get_girl_definition", girl_id) as GirlDefinition
			var idx: int = int(result.get("new_clue_index", -1))
			if def != null and idx >= 0 and idx < def.clue_notes.size():
				text += "\n\nНовая заметка:\n%s" % def.clue_notes[idx]
		var days: int = int(result.get("cooldown_days", 0))
		text += "\n\nПовторная попытка через %s дн." % days
	else:
		return
	var layer := CanvasLayer.new()
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	var vbox := VBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var btn := Button.new()
	btn.text = "OK"
	btn.pressed.connect(func() -> void:
		if is_instance_valid(layer):
			layer.queue_free()
		_exit_modal(player)
	)
	vbox.add_child(label)
	vbox.add_child(btn)
	panel.add_child(vbox)
	layer.add_child(panel)
	add_child(layer)
	_enter_modal(player)


func _close_choice_ui(player: Node) -> void:
	if _choice_ui != null and is_instance_valid(_choice_ui):
		_choice_ui.queue_free()
	_choice_ui = null
	_exit_modal(player)


func _close_locked_ui(player: Node) -> void:
	if _locked_ui != null and is_instance_valid(_locked_ui):
		_locked_ui.queue_free()
	_locked_ui = null
	_exit_modal(player)


func _enter_modal(player: Node) -> void:
	if player != null and player.has_method("enter_modal_ui"):
		player.call("enter_modal_ui")


func _exit_modal(player: Node) -> void:
	if player != null and player.has_method("enter_gameplay"):
		player.call("enter_gameplay")


func _char_label(characteristic: Variant) -> String:
	match int(characteristic):
		int(GameTypes.PlayerCharacteristic.MUSCLE):
			return "Мышца"
		int(GameTypes.PlayerCharacteristic.APPEARANCE):
			return "Внешность"
		int(GameTypes.PlayerCharacteristic.CAPITAL):
			return "Капитал"
		int(GameTypes.PlayerCharacteristic.AURA):
			return "Аура"
	return "?"
