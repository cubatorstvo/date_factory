extends Control
## Event popup (child of CanvasLayer root).

const UiEscapeScript := preload("res://core/ui_escape.gd")

@onready var title: Label = $Panel/VBox/Title
@onready var blurb: Label = $Panel/VBox/Blurb
@onready var buttons: VBoxContainer = $Panel/VBox/Buttons
@onready var panel: PanelContainer = $Panel

var _is_open: bool = false


func _ready() -> void:
	add_to_group("event_ui")
	visible = false
	Game.events.event_opened.connect(_open)
	Game.events.event_closed.connect(_close)


func _open(ev: Dictionary) -> void:
	_is_open = true
	var event_layer := get_parent() as CanvasLayer
	if event_layer != null:
		UiLayers.raise_popup(event_layer, UiLayers.EVENT)
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if panel:
		panel.modulate.a = 1.0
		panel.scale = Vector2.ONE
	Sfx.play_ui(&"event_start")
	title.text = str(ev.get("name", "Событие"))
	blurb.text = str(ev.get("blurb", ""))
	var cat := str(ev.get("category", ""))
	var cat_ru := {
		"prep": "Подготовка",
		"schedule": "Расписание",
		"media": "Медиа",
		"personal": "Личное",
		"tech": "Техника",
		"absurd": "Абсурд",
	}.get(cat, "")
	if cat_ru != "":
		title.text = "[%s] %s" % [cat_ru, title.text]
	_clear_buttons()
	for ch in ev.get("choices", []):
		var b := Button.new()
		b.text = str(ch.get("label", ch.get("id", "?")))
		b.focus_mode = Control.FOCUS_NONE
		b.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		var cid := str(ch.get("id", ""))
		b.pressed.connect(_on_choice.bind(cid))
		buttons.add_child(b)


func _on_choice(choice_id: String) -> void:
	if not _is_open:
		return
	_is_open = false
	for c in buttons.get_children():
		if c is BaseButton:
			(c as BaseButton).disabled = true
	if Game.events != null and not Game.events.active.is_empty():
		Game.events.choose(choice_id)
	# Always dismiss — choose may no-op or emit closed; never leave modal stuck.
	_close()
	if Game.events != null and not Game.events.active.is_empty():
		Game.events.active.clear()
		Game.events.event_closed.emit()


func force_close() -> void:
	_close()


func _close() -> void:
	## Sync hide — never await a node-bound tween (killed tweens hang forever).
	if not visible and not _is_open:
		return
	_is_open = false
	Sfx.play_ui(&"event_end")
	visible = false
	if panel:
		panel.modulate.a = 1.0
		panel.scale = Vector2.ONE
	_clear_buttons()
	_restore_mouse()


func _clear_buttons() -> void:
	if buttons == null:
		return
	for c in buttons.get_children():
		c.queue_free()


func _restore_mouse() -> void:
	if UiEscapeScript.any_overlay_open(get_tree()):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
