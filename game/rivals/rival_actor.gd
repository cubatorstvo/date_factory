class_name RivalActor
extends Interactable
## Thin world adapter: rival_id + CharacterActor + RivalEncounters (MODULE 06/14A).
## Not AI. Display/stats come from RivalDefinition.

const LAYER_INTERACTABLE: int = 4
const ABSENT_DELAY_SEC: float = 0.8

@export var rival_id: StringName = &""

signal challenge_result(ok: bool, reason: StringName)

var _character: CharacterActor = null
var _collision: CollisionShape3D = null
var _feedback_ui: CanvasLayer = null
var _encounter_ui: RivalEncounterUI = null
var _departing: bool = false
var _absent: bool = false
var _awaiting_result: bool = false


func _ready() -> void:
	prompt_action = "Вызвать"
	collision_layer = LAYER_INTERACTABLE
	collision_mask = 0
	monitoring = false
	monitorable = true
	_ensure_collision()
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and bool(gs.call("is_rival_defeated", rival_id)):
		_become_absent(true)
		return
	_ensure_character()
	var encounters: Node = get_node_or_null("/root/RivalEncounters")
	if encounters != null:
		if encounters.has_signal("encounter_won") and not encounters.is_connected("encounter_won", _on_encounter_won):
			encounters.connect("encounter_won", _on_encounter_won)
		if encounters.has_signal("encounter_finished") and not encounters.is_connected("encounter_finished", _on_encounter_finished):
			encounters.connect("encounter_finished", _on_encounter_finished)
	_refresh_interaction()


func can_interact(player: Node) -> bool:
	if _absent or _departing:
		return false
	_refresh_interaction()
	return super.can_interact(player)


func get_interaction_prompt(player: Node) -> String:
	return super.get_interaction_prompt(player)


func _on_interact(player: Node) -> void:
	if _absent or _departing:
		return
	var encounters: Node = get_node_or_null("/root/RivalEncounters")
	if encounters == null:
		challenge_result.emit(false, &"NO_SERVICE")
		_show_feedback("Сервис соперников недоступен.", player)
		return
	var return_mode: int = int(PlayerController.ControlMode.MODAL_UI)
	var start: Dictionary = encounters.call(
		"start_encounter",
		rival_id,
		GameTypes.RivalEncounterInitiator.PLAYER,
		GameTypes.RivalEncounterContext.WORLD,
		return_mode,
	) as Dictionary
	var ok: bool = bool(start.get("ok", false))
	var reason: StringName = start.get("reason", &"") as StringName
	challenge_result.emit(ok, reason)
	if not ok:
		_show_start_failure(reason, player)
		_refresh_interaction()
		return
	_awaiting_result = true
	_open_choose_ui(player)
	_refresh_interaction()


func _on_encounter_won(result: RivalEncounterResult) -> void:
	if result == null:
		return
	if result.rival_id != rival_id:
		return
	if _absent or _departing:
		return
	_depart_after_defeat()


func _on_encounter_finished(result: RivalEncounterResult) -> void:
	if result == null:
		return
	if result.rival_id != rival_id:
		return
	if not _awaiting_result:
		return
	_awaiting_result = false
	var player: Node = get_tree().get_first_node_in_group("player")
	_open_result_ui(player, result)


func _depart_after_defeat() -> void:
	_departing = true
	interaction_enabled = false
	if _collision != null:
		_collision.disabled = true
	# Optional short react: slight turn / hide silhouette after delay.
	if _character != null and is_instance_valid(_character):
		_character.rotate_y(deg_to_rad(25.0))
	var tree: SceneTree = get_tree()
	if tree == null:
		_become_absent(true)
		return
	await tree.create_timer(ABSENT_DELAY_SEC).timeout
	if not is_instance_valid(self):
		return
	_become_absent(true)


func _become_absent(immediate_free: bool) -> void:
	_absent = true
	_departing = false
	interaction_enabled = false
	visible = false
	if _collision != null:
		_collision.disabled = true
	if _character != null and is_instance_valid(_character):
		_character.set_character_visible(false)
	if immediate_free:
		queue_free()


func _refresh_interaction() -> void:
	if _absent or _departing:
		interaction_enabled = false
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and bool(gs.call("is_rival_defeated", rival_id)):
		interaction_enabled = false
		return
	interaction_enabled = true
	prompt_action = "Вызвать"


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
	if _character != null:
		return
	var profile_id: StringName = &"appearance_male_base"
	var def: RivalDefinition = _find_rival_definition()
	if def != null and String(def.appearance_profile_id) != "":
		profile_id = def.appearance_profile_id
	_character = CharacterFactory.create(profile_id, rival_id, self)
	if _character != null:
		_character.name = "CharacterActor"
		_character.position = Vector3.ZERO


func _find_rival_definition() -> RivalDefinition:
	if String(rival_id) == "":
		return null
	var db: Node = get_node_or_null("/root/ContentDB")
	if db == null:
		return null
	# Avoid ContentDB.get_rival push_error for missing production rivals during early glue.
	var by_id: Variant = db.get("_rivals_by_id")
	if by_id is Dictionary and (by_id as Dictionary).has(rival_id):
		return (by_id as Dictionary)[rival_id] as RivalDefinition
	var path: String = "res://data/test/%s.tres" % String(rival_id)
	if ResourceLoader.exists(path):
		return load(path) as RivalDefinition
	return null


func _show_start_failure(reason: StringName, player: Node) -> void:
	var text: String = _reason_text(reason)
	if text == "":
		text = "Сейчас нельзя вызвать этого ухажёра."
	_show_feedback(text, player)


func _reason_text(reason: StringName) -> String:
	match reason:
		&"RIVAL_REFUSED_LOW_AUTHORITY":
			return "Недостаточно Авторитета. Он тебя не воспринимает всерьёз."
		&"COMPETITION_LOCKED":
			return "Этот вид состязания пока недоступен."
		&"NO_AVAILABLE_COMPETITION":
			return "Нет доступного состязания."
		&"ALREADY_DEFEATED":
			return "Этот ухажёр уже побеждён."
		&"ALREADY_FINISHED":
			return "Встреча уже завершена."
		_:
			return "Не удалось начать встречу: %s" % String(reason)


func _open_choose_ui(player: Node) -> void:
	_close_encounter_ui()
	var ui: RivalEncounterUI = RivalEncounterUI.create()
	_encounter_ui = ui
	if not ui.choose_closed.is_connected(_on_choose_ui_closed):
		ui.choose_closed.connect(_on_choose_ui_closed)
	ui.open_choose(player, false)


func _open_result_ui(player: Node, result: RivalEncounterResult) -> void:
	_close_encounter_ui()
	var ui: RivalEncounterUI = RivalEncounterUI.create()
	_encounter_ui = ui
	if not ui.result_closed.is_connected(_on_result_ui_closed):
		ui.result_closed.connect(_on_result_ui_closed)
	# Final exhibition uses open_exhibition_result / exhibition flag; world challenges show Authority.
	ui.open_result(player, result, false)


func _on_choose_ui_closed() -> void:
	_encounter_ui = null
	var encounters: Node = get_node_or_null("/root/RivalEncounters")
	if encounters == null or not bool(encounters.call("has_active_encounter")):
		_awaiting_result = false


func _on_result_ui_closed() -> void:
	_encounter_ui = null


func _close_encounter_ui() -> void:
	if _encounter_ui != null and is_instance_valid(_encounter_ui):
		_encounter_ui.dismiss_for_transition()
	_encounter_ui = null


func _show_feedback(text: String, player: Node) -> void:
	_close_feedback(player)
	var layer := CanvasLayer.new()
	layer.name = "RivalFeedbackUI"
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(380, 120)
	var vbox := VBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var btn := Button.new()
	btn.text = "Закрыть"
	btn.pressed.connect(func() -> void:
		_close_feedback(player)
	)
	vbox.add_child(label)
	vbox.add_child(btn)
	panel.add_child(vbox)
	layer.add_child(panel)
	add_child(layer)
	_feedback_ui = layer
	if player != null and player.has_method("enter_modal_ui"):
		player.call("enter_modal_ui")


func _close_feedback(player: Node) -> void:
	if _feedback_ui != null and is_instance_valid(_feedback_ui):
		_feedback_ui.queue_free()
	_feedback_ui = null
	if player != null and player.has_method("enter_gameplay"):
		player.call("enter_gameplay")
