extends CanvasLayer
## Persistent HUD + crosshair (layer 5). Modals use higher layers.

@onready var resources_label: Label = $Root/Resources
@onready var goal_label: Label = $Root/Goal
@onready var hint_label: Label = $Root/Hint
@onready var toast_label: Label = $Root/Toast
@onready var bottleneck_label: Label = $Root/Bottleneck
@onready var crosshair: Control = $Root/Crosshair
@onready var status_panel: Panel = $Root/StatusPanel
@onready var hint_panel: Panel = $Root/HintPanel
@onready var toast_panel: Panel = $Root/ToastPanel

var _toast_time: float = 0.0
var _hint_tween: Tween


func _ready() -> void:
	resources_label.add_theme_font_size_override("font_size", 16)
	resources_label.add_theme_color_override("font_color", Color("#F2BD69"))
	goal_label.add_theme_font_size_override("font_size", 15)
	hint_label.add_theme_font_size_override("font_size", 17)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	EventBus.resource_changed.connect(func(_i, _v): _refresh())
	EventBus.quest_updated.connect(func(_q): _refresh())
	EventBus.interaction_hint.connect(_on_interaction_hint)
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
		root.modulate.a = 0.0
		create_tween().tween_property(root, "modulate:a", 1.0, 0.25)
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
			toast_panel.visible = false
	if Game.crises != null and Game.crises.is_active():
		bottleneck_label.text = Game.crises.hud_text()
	elif bottleneck_label.text.begins_with("КРИЗИС:"):
		bottleneck_label.text = ""


func _on_notify(message: String, kind: StringName) -> void:
	if kind == &"ui" or kind == &"date_fx":
		return
	toast_label.text = message
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	toast_panel.scale = Vector2(0.98, 0.98)
	var panel_tween := create_tween().set_parallel(true)
	panel_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	panel_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.2)
	panel_tween.tween_property(toast_panel, "scale", Vector2.ONE, 0.2)
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
	resources_label.text = "$%d   ·   ★ %.0f   ·   ВНИМАНИЕ %.1f/%.0f   ·   СКАНДАЛ %.0f   ·   ЛЕГЕНДА %.0f (%s)   ·   СВИДАНИЯ %d   ·   АВТО %d" % [
		int(Game.economy.get_value(&"money")),
		Game.economy.get_value(&"popularity"),
		Game.economy.get_value(&"attention"),
		Game.economy.max_attention,
		Game.economy.get_value(&"scandal"),
		Game.economy.get_value(&"legend"),
		_legend_band_short(),
		Game.total_successful_dates,
		Game.dating.automation_level,
	]
	goal_label.text = "%s   •   %s%s\n%s" % [
		Loc.stage_title(Game.stage_id),
		Loc.stage_goal(Game.stage_id),
		_stage4_act_suffix(),
		Game.quests.primary_text(),
	]


func _on_interaction_hint(text: String) -> void:
	hint_label.text = text
	if _hint_tween != null:
		_hint_tween.kill()
	if text.is_empty():
		hint_panel.visible = false
		return
	hint_panel.visible = true
	hint_panel.modulate.a = 0.0
	hint_panel.position.y = 648.0
	_hint_tween = create_tween().set_parallel(true)
	_hint_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_hint_tween.tween_property(hint_panel, "modulate:a", 1.0, 0.16)
	_hint_tween.tween_property(hint_panel, "position:y", 638.0, 0.16)


func _legend_band_short() -> String:
	match Game.economy.legend_band():
		"high":
			return "выс"
		"mid":
			return "сред"
		"low":
			return "низ"
		_:
			return "криз"


func _stage4_act_suffix() -> String:
	if str(Game.stage_id) != "stage_4":
		return ""
	var parts: PackedStringArray = []
	if Game.facility.has_flag("stage_4a"):
		parts.append("4A✓")
	else:
		parts.append("4A")
	if Game.facility.has_flag("stage_4b"):
		parts.append("4B✓")
	else:
		parts.append("4B")
	if Game.facility.has_flag("stage_4c"):
		parts.append("4C✓")
	else:
		parts.append("4C")
	return " | " + "/".join(parts)
