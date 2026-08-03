extends CanvasLayer
## Persistent HUD + crosshair (layer 5). Modals use higher layers.

@onready var resources_label: Label = $Root/Resources
@onready var goal_label: Label = $Root/Goal
@onready var hint_label: Label = $Root/Hint
@onready var toast_label: Label = $Root/Toast
@onready var bottleneck_label: Label = $Root/Bottleneck
@onready var crosshair: Control = $Root/Crosshair

var _toast_time: float = 0.0


func _ready() -> void:
	EventBus.resource_changed.connect(func(_i, _v): _refresh())
	EventBus.quest_updated.connect(func(_q): _refresh())
	EventBus.interaction_hint.connect(func(t): hint_label.text = t)
	EventBus.notify.connect(_on_notify)
	EventBus.bottleneck.connect(func(k, d): bottleneck_label.text = "Узкое место: %s — %s" % [str(k), d])
	Game.dating.date_ui_open.connect(_on_date_open)
	Game.dating.date_ui_close.connect(_on_date_close)
	EventBus.date_finished.connect(func(r):
		if str(r.get("target_id", "")) == "algorithm" and int(r.get("grade", 0)) >= 2:
			Game.start_postgame()
			EventBus.finale_completed.emit()
	)
	_make_hud_mouse_transparent()
	_refresh()


func _on_date_open(_p: Dictionary) -> void:
	# One composition during date: hide gameplay HUD so DateUI is alone.
	var root := get_node_or_null("Root") as Control
	if root:
		root.visible = false


func _on_date_close() -> void:
	var root := get_node_or_null("Root") as Control
	if root:
		root.visible = true
	if crosshair:
		crosshair.visible = true


func _make_hud_mouse_transparent() -> void:
	# Fullscreen HUD must never steal FPS mouse look.
	var root := get_node_or_null("Root") as Control
	if root:
		_ignore_mouse_recursive(root)


func _ignore_mouse_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in node.get_children():
		_ignore_mouse_recursive(c)


func _process(delta: float) -> void:
	if _toast_time > 0.0:
		_toast_time -= delta
		if _toast_time <= 0.0:
			toast_label.text = ""


func _on_notify(message: String, kind: StringName) -> void:
	if kind == &"ui" or kind == &"date_fx":
		return
	toast_label.text = message
	if kind == &"money" or kind == &"ok":
		var hud_root := get_node_or_null("Root") as Control
		var floating_text: Script = load("res://scenes/ui/floating_text.gd")
		if hud_root != null and floating_text != null:
			floating_text.spawn(hud_root, message, kind)
	toast_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(toast_label, "modulate:a", 1.0, 0.15)
	_toast_time = 3.5


func _refresh() -> void:
	if not Game.run_started:
		return
	resources_label.text = "$%d   ⭐%.0f   Внимание %.1f/%.0f   Скандал %.0f   Свиданий %d   Авто %d" % [
		int(Game.economy.get_value(&"money")),
		Game.economy.get_value(&"popularity"),
		Game.economy.get_value(&"attention"),
		Game.economy.max_attention,
		Game.economy.get_value(&"scandal"),
		Game.total_successful_dates,
		Game.dating.automation_level,
	]
	goal_label.text = "Цель: %s | Этап: %s" % [Game.quests.primary_text(), Loc.stage_title(Game.stage_id)]
