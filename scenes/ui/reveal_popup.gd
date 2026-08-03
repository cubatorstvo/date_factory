class_name RevealPopup
extends CanvasLayer
## 4 popup kinds: notify · warn · reveal (крупное открытие) · decision.
## Also presents trait / girl / stage / clone with distinct motion + SFX.

const UiEscapeScript := preload("res://core/ui_escape.gd")

signal closed

static func ui(tree: SceneTree = null) -> RevealPopup:
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("reveal_ui") as RevealPopup


@onready var title_label: Label = $Center/Panel/Content/Title
@onready var body_label: Label = $Center/Panel/Content/Body
@onready var icon: ColorRect = $Center/Panel/Content/Icon
@onready var skip_button: Button = $Center/Panel/Content/Skip

var _closing: bool = false
var _showing: bool = false
var _queue: Array = []
var _kind: String = "reveal"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("reveal_ui")
	visible = false
	if skip_button:
		skip_button.text = "Понятно"
		skip_button.pressed.connect(close)


func reveal(title: String, body: String, icon_color: Color = UiStyle.ACCENT) -> void:
	present(&"reveal", title, body, icon_color)


func present(kind: StringName, title: String, body: String, icon_color: Color = UiStyle.ACCENT) -> void:
	_queue.append({"kind": str(kind), "title": title, "body": body, "color": icon_color})
	_pump()


func present_trait(trait_name: String, girl_name: String) -> void:
	present(&"reveal", "Черта подтверждена", "%s: теперь ясно — %s." % [girl_name, trait_name], UiStyle.OK)


func present_girl(girl_name: String, blurb: String = "") -> void:
	var text := blurb if not blurb.is_empty() else "Новый контакт в телефоне."
	present(&"reveal", "Знакомство: %s" % girl_name, text, Color(1.0, 0.72, 0.35))


func present_stage(stage_title: String, goal: String) -> void:
	present(&"reveal", "Новая стадия: %s" % stage_title, goal, Color(1.0, 0.3, 0.55))


func present_clone(clone_name: String, decision: String) -> void:
	present(&"reveal", "Дубль: %s" % clone_name, "Решение приёмки: %s" % decision, Color(0.45, 0.85, 1.0))


func present_notify(title: String, body: String) -> void:
	present(&"notify", title, body, UiStyle.TEXT_DIM)


func present_warn(title: String, body: String) -> void:
	present(&"warn", title, body, UiStyle.WARN)


func present_decision(title: String, body: String) -> void:
	present(&"decision", title, body, UiStyle.ACCENT_2)


func present_crisis(title: String, body: String) -> void:
	present(&"warn", title, body, UiStyle.BAD)


func force_close() -> void:
	_queue.clear()
	_closing = true
	_showing = false
	visible = false
	var panel := get_node_or_null("Center/Panel") as Control
	if panel:
		panel.modulate.a = 1.0
		panel.scale = Vector2.ONE
	_restore_mouse()
	closed.emit()


func close() -> void:
	if _closing or not visible:
		return
	_closing = true
	set_meta("_auto_close_token", -1)
	## Sync hide — never await a node-bound tween (killed tweens hang forever).
	## Expansion door → stage_changed rebuilds the world and can kill open tweens.
	var panel := get_node_or_null("Center/Panel") as Control
	if panel:
		panel.modulate.a = 1.0
		panel.scale = Vector2.ONE
	visible = false
	_showing = false
	_closing = false
	_restore_mouse()
	closed.emit()
	call_deferred("_pump")


func _pump() -> void:
	if _showing or _queue.is_empty():
		return
	_showing = true
	_closing = false
	var item: Dictionary = _queue.pop_front()
	_kind = str(item.get("kind", "reveal"))
	title_label.text = str(item.get("title", ""))
	body_label.text = str(item.get("body", ""))
	icon.color = item.get("color", UiStyle.ACCENT)
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var panel: Control = $Center/Panel
	var start_scale := Vector2(0.97, 0.97)
	var pop_dur := 0.14
	var hold := 2.2
	var sfx_kind := &"pop"
	match _kind:
		"notify":
			start_scale = Vector2(0.99, 0.99)
			pop_dur = 0.10
			hold = 1.6
			sfx_kind = &"info"
			if skip_button:
				skip_button.text = "Ок"
		"warn":
			start_scale = Vector2(1.04, 1.04)
			pop_dur = 0.12
			hold = 2.6
			sfx_kind = &"warn"
			if skip_button:
				skip_button.text = "Понял риск"
		"decision":
			start_scale = Vector2(0.92, 0.92)
			pop_dur = 0.20
			hold = 3.6
			sfx_kind = &"event_start"
			if skip_button:
				skip_button.text = "К выбору"
		_:
			start_scale = Vector2(0.88, 0.88)
			pop_dur = 0.26
			hold = 3.4
			sfx_kind = &"unlock"
			if skip_button:
				skip_button.text = "Понятно"
	panel.scale = start_scale
	panel.modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(panel, "scale", Vector2.ONE, pop_dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, pop_dur * 0.85)
	Sfx.play_ui(sfx_kind)
	_schedule_auto_close(hold)


func _schedule_auto_close(hold: float) -> void:
	var token: int = Time.get_ticks_msec()
	set_meta("_auto_close_token", token)
	await get_tree().create_timer(hold).timeout
	if not is_instance_valid(self):
		return
	if int(get_meta("_auto_close_token", 0)) != token:
		return
	if visible and not _closing:
		close()


func _restore_mouse() -> void:
	if UiEscapeScript.any_overlay_open(get_tree()):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
