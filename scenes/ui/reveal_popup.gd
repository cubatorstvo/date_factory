class_name RevealPopup
extends CanvasLayer
## Milestone popup. Queues messages so stage + unlock don't stack badly.

const UiEscapeScript := preload("res://core/ui_escape.gd")

signal closed

@onready var title_label: Label = $Center/Panel/Content/Title
@onready var body_label: Label = $Center/Panel/Content/Body
@onready var icon: ColorRect = $Center/Panel/Content/Icon
@onready var skip_button: Button = $Center/Panel/Content/Skip

var _closing: bool = false
var _showing: bool = false
var _queue: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("reveal_ui")
	visible = false
	if skip_button:
		skip_button.text = "Понятно"
		skip_button.pressed.connect(close)


func reveal(title: String, body: String, icon_color: Color = UiStyle.ACCENT) -> void:
	_queue.append({"title": title, "body": body, "color": icon_color})
	_pump()


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
	var tween := create_tween()
	tween.tween_property($Center/Panel, "modulate:a", 0.0, 0.16)
	await tween.finished
	visible = false
	_showing = false
	_closing = false
	_restore_mouse()
	closed.emit()
	_pump()


func _pump() -> void:
	if _showing or _queue.is_empty():
		return
	_showing = true
	_closing = false
	var item: Dictionary = _queue.pop_front()
	title_label.text = str(item.get("title", ""))
	body_label.text = str(item.get("body", ""))
	icon.color = item.get("color", UiStyle.ACCENT)
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Center/Panel.scale = Vector2(0.94, 0.94)
	$Center/Panel.modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property($Center/Panel, "scale", Vector2.ONE, 0.22)
	tween.tween_property($Center/Panel, "modulate:a", 1.0, 0.22)
	Sfx.play_ui(&"unlock")
	await get_tree().create_timer(3.2).timeout
	if visible and not _closing:
		close()


func _restore_mouse() -> void:
	if UiEscapeScript.any_overlay_open(get_tree()):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
