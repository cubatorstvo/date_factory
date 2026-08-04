extends CanvasLayer
## Persistent HUD chrome (UiLayers.HUD = 5). Toasts live on ToastHost (UiLayers.TOAST).

const UiEscapeScript := preload("res://core/ui_escape.gd")

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
var _wait_panel: Panel = null
var _wait_label: Label = null
var _wait_skip_btn: Button = null
var _wait_stand_btn: Button = null


func _ready() -> void:
	add_to_group("hud")
	layer = UiLayers.HUD
	_ensure_toast_host()
	_build_date_wait_panel()
	resources_label.text = ""
	goal_label.text = ""
	status_panel.visible = false
	status_panel.size = Vector2(820.0, 78.0)
	resources_label.size.x = 780.0
	goal_label.size.x = 780.0
	goal_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
	EventBus.time_changed.connect(func(_d, _m): _refresh())
	EventBus.date_scheduled.connect(func(_p): _refresh())
	EventBus.date_cancelled.connect(func(_p):
		hide_date_wait()
		_refresh()
	)
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
	hide_date_wait()
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


func _ensure_toast_host() -> void:
	## Host toasts on a dedicated high CanvasLayer so they paint above phone/modals.
	## See UiLayers stacking policy (newer/transient overlays win over older UI).
	if toast_panel == null or toast_label == null:
		return
	if get_node_or_null("ToastHost") != null:
		return
	var host := CanvasLayer.new()
	host.name = "ToastHost"
	host.layer = UiLayers.TOAST
	add_child(host)
	var toast_root := Control.new()
	toast_root.name = "Root"
	toast_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toast_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(toast_root)
	toast_panel.reparent(toast_root)
	toast_label.reparent(toast_root)
	_ignore_mouse_recursive(toast_root)


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
	var toast_host := get_node_or_null("ToastHost") as CanvasLayer
	if toast_host != null:
		toast_host.layer = UiLayers.TOAST
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
		resources_label.text = ""
		goal_label.text = ""
		status_panel.visible = false
		return
	status_panel.visible = true
	status_panel.size = Vector2(820.0, 96.0)
	resources_label.text = "$%d   ·   ★ %.0f   ·   ВНИМАНИЕ %.0f/%.0f   ·   СВИДАНИЯ %d" % [
		int(Game.economy.get_value(&"money")),
		Game.economy.get_value(&"popularity"),
		Game.economy.get_value(&"attention"),
		Game.economy.max_attention,
		Game.total_successful_dates,
	]
	var clock_line := ""
	if Game.time != null:
		clock_line = Game.time.format_day_clock()
	var date_line := ""
	if Game.dating != null and Game.dating.schedule != null:
		date_line = Game.dating.schedule.hud_line()
	var goal_core := "%s   •   %s" % [
		Loc.stage_title(Game.stage_id),
		Game.quests.primary_text(),
	]
	if not clock_line.is_empty():
		goal_label.text = "%s   ·   %s" % [clock_line, goal_core]
	else:
		goal_label.text = goal_core
	if not date_line.is_empty():
		goal_label.text = "%s\n%s" % [goal_label.text, date_line]
	if goal_label.text.length() > 120:
		goal_label.text = goal_label.text.substr(0, 117) + "..."


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


func _build_date_wait_panel() -> void:
	_wait_panel = Panel.new()
	_wait_panel.name = "DateWaitPanel"
	_wait_panel.visible = false
	_wait_panel.add_to_group("date_wait_ui")
	_wait_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_wait_panel.anchor_left = 0.5
	_wait_panel.anchor_top = 0.55
	_wait_panel.anchor_right = 0.5
	_wait_panel.anchor_bottom = 0.55
	_wait_panel.offset_left = -180.0
	_wait_panel.offset_top = -70.0
	_wait_panel.offset_right = 180.0
	_wait_panel.offset_bottom = 70.0
	add_child(_wait_panel)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 12.0
	vbox.offset_top = 10.0
	vbox.offset_right = -12.0
	vbox.offset_bottom = -10.0
	vbox.add_theme_constant_override("separation", 8)
	_wait_panel.add_child(vbox)
	_wait_label = Label.new()
	_wait_label.text = "Ждёшь свидание…"
	_wait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_wait_label)
	_wait_skip_btn = Button.new()
	_wait_skip_btn.text = "Подождать до времени"
	_wait_skip_btn.focus_mode = Control.FOCUS_NONE
	_wait_skip_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	_wait_skip_btn.pressed.connect(func() -> void:
		InteractionRouter.wait_for_scheduled_time()
	)
	vbox.add_child(_wait_skip_btn)
	_wait_stand_btn = Button.new()
	_wait_stand_btn.text = "Встать"
	_wait_stand_btn.focus_mode = Control.FOCUS_NONE
	_wait_stand_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	_wait_stand_btn.pressed.connect(func() -> void:
		InteractionRouter.stand_up_from_table()
	)
	vbox.add_child(_wait_stand_btn)


func show_date_wait(until: int = 0) -> void:
	if _wait_panel == null:
		_build_date_wait_panel()
	if _wait_label:
		if until > 0:
			_wait_label.text = "До свидания ещё %d мин. Ждать за столом?" % until
		else:
			_wait_label.text = "Ждёшь свидание…"
	_wait_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func hide_date_wait() -> void:
	if _wait_panel != null:
		_wait_panel.visible = false
	if not UiEscapeScript.any_overlay_open(get_tree()):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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
