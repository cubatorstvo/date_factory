extends CanvasLayer
## Home-cluster elevator: apartment / themed apts / lab. Direct entry, no corridor.

const UiEscapeScript := preload("res://core/ui_escape.gd")

var _root: Control
var _list: VBoxContainer
var _hint: Label
var _incident_box: VBoxContainer
var _pending_dest: String = ""
var _incident_active: bool = false


func _ready() -> void:
	add_to_group("elevator_ui")
	layer = 28
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
	dim.color = Color(0.05, 0.07, 0.12, 0.62)
	_root.add_child(dim)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -300.0
	panel.offset_top = -260.0
	panel.offset_right = 300.0
	panel.offset_bottom = 260.0
	_root.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "Лифт"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.text = "Выбери этаж — вход сразу в квартиру / лабораторию."
	vbox.add_child(_hint)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 220)
	vbox.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_incident_box = VBoxContainer.new()
	_incident_box.visible = false
	_incident_box.add_theme_constant_override("separation", 6)
	vbox.add_child(_incident_box)
	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.pressed.connect(close)
	vbox.add_child(close_btn)


func open() -> void:
	_pending_dest = ""
	_incident_active = false
	_incident_box.visible = false
	_refresh()
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.play(&"elevator")


func close() -> void:
	if not visible:
		return
	visible = false
	_incident_box.visible = false
	if UiEscapeScript.any_overlay_open(get_tree()):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var dests: Array = []
	if Game.city != null and Game.city.has_method("elevator_destinations"):
		dests = Game.city.elevator_destinations()
	for d in dests:
		var unlocked := bool(d.get("unlocked", false))
		var btn := Button.new()
		var label := str(d.get("name", d.get("id", "?")))
		if unlocked:
			btn.text = label
		else:
			btn.text = "%s (купить · %.0f$)" % [label, float(d.get("cost", 0))]
		var dest_id := str(d.get("id", ""))
		if unlocked:
			btn.pressed.connect(_on_dest_pressed.bind(dest_id))
		else:
			btn.pressed.connect(_on_buy_pressed.bind(dest_id))
		_list.add_child(btn)


func _on_buy_pressed(dest_id: String) -> void:
	if Game.city == null:
		return
	if Game.city.buy_themed_apartment(StringName(dest_id)):
		_refresh()


func _on_dest_pressed(dest_id: String) -> void:
	if _incident_active:
		return
	_pending_dest = dest_id
	var incident: Dictionary = {}
	if Game.city != null and Game.city.has_method("try_elevator_wrong_girl"):
		incident = Game.city.try_elevator_wrong_girl()
	if bool(incident.get("active", false)):
		_show_incident(str(incident.get("prompt", "Неправильная девушка в лифте.")))
		return
	_travel_pending()


func _show_incident(prompt: String) -> void:
	_incident_active = true
	for c in _incident_box.get_children():
		c.queue_free()
	var lbl := Label.new()
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.text = prompt
	_incident_box.add_child(lbl)
	var wait_btn := Button.new()
	wait_btn.text = "Подождать следующий"
	wait_btn.pressed.connect(_on_incident_choice.bind("wait"))
	_incident_box.add_child(wait_btn)
	var ride_btn := Button.new()
	ride_btn.text = "Ехать вместе (риск)"
	ride_btn.pressed.connect(_on_incident_choice.bind("ride"))
	_incident_box.add_child(ride_btn)
	_incident_box.visible = true
	_hint.text = "Инцидент лифта"


func _on_incident_choice(choice: String) -> void:
	if Game.city != null and Game.city.has_method("resolve_elevator_incident"):
		Game.city.resolve_elevator_incident(choice)
	_incident_active = false
	_incident_box.visible = false
	if choice == "wait":
		_hint.text = "Ждёшь следующий лифт…"
		_pending_dest = ""
		return
	_travel_pending()


func _travel_pending() -> void:
	var dest := _pending_dest
	_pending_dest = ""
	if dest == "":
		return
	close()
	InteractionRouter.route(&"elevator_travel", null, null, {"dest": dest})
