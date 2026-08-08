extends CanvasLayer
## Coherent perk-tree Progression UI (MODULE 22 §§33–39).
## Presentation only — purchases go through Progression.purchase_perk.


signal purchase_notified(message: String)


const THEME_PATH: String = "res://ui/theme/date_factory_theme.tres"
const BODY_FONT_SIZE: int = 18
const TITLE_FONT_SIZE: int = 22
const HEADER_FONT_SIZE: int = 20
const MAX_STAT: int = 8

const _TAB_CHARS: Array[GameTypes.PlayerCharacteristic] = [
	GameTypes.PlayerCharacteristic.MUSCLE,
	GameTypes.PlayerCharacteristic.APPEARANCE,
	GameTypes.PlayerCharacteristic.CAPITAL,
	GameTypes.PlayerCharacteristic.AURA,
]


var _player: Node = null
var _on_closed: Callable = Callable()
var _selected_char: GameTypes.PlayerCharacteristic = GameTypes.PlayerCharacteristic.MUSCLE
var _selected_perk_id: StringName = &""

var _root: Control = null
var _points_label: Label = null
var _stat_header: Label = null
var _stat_note: Label = null
var _perk_host: VBoxContainer = null
var _detail_name: Label = null
var _detail_body: Label = null
var _detail_status: Label = null
var _buy_btn: Button = null
var _close_btn: Button = null
var _tab_buttons: Dictionary = {}
var _perk_buttons: Dictionary = {}
var _first_focus_control: Control = null


func get_visible_perk_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for key in _perk_buttons.keys():
		ids.append(StringName(str(key)))
	return ids


func get_selected_characteristic() -> GameTypes.PlayerCharacteristic:
	return _selected_char


func select_perk(perk_id: StringName) -> void:
	_selected_perk_id = perk_id
	var prog: Node = get_node_or_null("/root/Progression")
	if prog != null:
		_refresh_detail(prog)
		_highlight_selected()


func purchase_selected() -> void:
	_on_buy_pressed()


func select_characteristic(ch: GameTypes.PlayerCharacteristic) -> void:
	_select_tab(ch)


func open(
	player: Node,
	on_closed: Callable = Callable(),
	characteristic: GameTypes.PlayerCharacteristic = GameTypes.PlayerCharacteristic.MUSCLE,
) -> void:
	_player = player
	_on_closed = on_closed
	_selected_char = characteristic
	_selected_perk_id = &""
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_refresh()
	visible = true
	if _player != null and _player.has_method("enter_modal_ui"):
		_player.call("enter_modal_ui")
	call_deferred("_focus_first_control")


func close() -> void:
	_audio_play_ui(AudioIds.UI_BACK)
	var p: Node = _player
	var cb: Callable = _on_closed
	_player = null
	_on_closed = Callable()
	_selected_perk_id = &""
	if is_instance_valid(self):
		queue_free()
	if cb.is_valid():
		cb.call(p)
	elif p != null and p.has_method("enter_gameplay"):
		p.call("enter_gameplay")


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	_tab_buttons.clear()
	_perk_buttons.clear()
	_first_focus_control = null

	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var theme_res: Resource = null
	if ResourceLoader.exists(THEME_PATH):
		theme_res = load(THEME_PATH)
	if theme_res is Theme:
		_root.theme = theme_res as Theme

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.04, 0.05, 0.07, 0.72)
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(860, 620)
	_apply_panel_style(panel)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(root_vbox)

	var title := Label.new()
	title.text = "ПРОКАЧКА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", Color(0.95, 0.95, 0.92))
	root_vbox.add_child(title)

	_points_label = Label.new()
	_points_label.name = "PointsLabel"
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_points_label.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	_points_label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.55))
	root_vbox.add_child(_points_label)

	var tabs := HBoxContainer.new()
	tabs.name = "Tabs"
	tabs.add_theme_constant_override("separation", 8)
	root_vbox.add_child(tabs)
	for ch in _TAB_CHARS:
		var btn := Button.new()
		btn.text = _char_tab_title(ch)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 36)
		btn.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
		var bound_ch: GameTypes.PlayerCharacteristic = ch
		btn.pressed.connect(func() -> void:
			_select_tab(bound_ch)
		)
		tabs.add_child(btn)
		_tab_buttons[int(ch)] = btn
		if _first_focus_control == null:
			_first_focus_control = btn

	_stat_header = Label.new()
	_stat_header.name = "StatHeader"
	_stat_header.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	_stat_header.add_theme_color_override("font_color", Color(0.94, 0.94, 0.9))
	root_vbox.add_child(_stat_header)

	_stat_note = Label.new()
	_stat_note.name = "StatNote"
	_stat_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stat_note.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	_stat_note.add_theme_color_override("font_color", Color(0.78, 0.8, 0.82))
	root_vbox.add_child(_stat_note)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root_vbox.add_child(body)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 360)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)

	_perk_host = VBoxContainer.new()
	_perk_host.name = "PerkHost"
	_perk_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_perk_host.add_theme_constant_override("separation", 8)
	scroll.add_child(_perk_host)

	var detail := PanelContainer.new()
	detail.name = "DetailPanel"
	detail.custom_minimum_size = Vector2(300, 0)
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_detail_style(detail)
	body.add_child(detail)

	var detail_margin := MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 10)
	detail_margin.add_theme_constant_override("margin_right", 10)
	detail_margin.add_theme_constant_override("margin_top", 10)
	detail_margin.add_theme_constant_override("margin_bottom", 10)
	detail.add_child(detail_margin)

	var detail_vbox := VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 8)
	detail_margin.add_child(detail_vbox)

	var detail_title := Label.new()
	detail_title.text = "ОПИСАНИЕ"
	detail_title.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	detail_title.add_theme_color_override("font_color", Color(0.85, 0.88, 0.9))
	detail_vbox.add_child(detail_title)

	_detail_name = Label.new()
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_name.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	_detail_name.add_theme_color_override("font_color", Color(0.97, 0.97, 0.94))
	detail_vbox.add_child(_detail_name)

	_detail_status = Label.new()
	_detail_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_status.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	_detail_status.add_theme_color_override("font_color", Color(0.8, 0.84, 0.78))
	detail_vbox.add_child(_detail_status)

	_detail_body = Label.new()
	_detail_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_body.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	_detail_body.add_theme_color_override("font_color", Color(0.9, 0.9, 0.88))
	detail_vbox.add_child(_detail_body)

	_buy_btn = Button.new()
	_buy_btn.name = "BuyButton"
	_buy_btn.text = "Купить"
	_buy_btn.custom_minimum_size = Vector2(0, 40)
	_buy_btn.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	_buy_btn.pressed.connect(_on_buy_pressed)
	detail_vbox.add_child(_buy_btn)

	_close_btn = Button.new()
	_close_btn.name = "CloseButton"
	_close_btn.text = "Закрыть"
	_close_btn.custom_minimum_size = Vector2(0, 36)
	_close_btn.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	_close_btn.pressed.connect(close)
	root_vbox.add_child(_close_btn)


func _apply_panel_style(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15, 0.94)
	style.border_color = Color(0.35, 0.4, 0.45, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)


func _apply_detail_style(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.13, 0.9)
	style.border_color = Color(0.3, 0.34, 0.38, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", style)


func _select_tab(ch: GameTypes.PlayerCharacteristic) -> void:
	if ch != _selected_char:
		_audio_play_ui(AudioIds.UI_CLICK)
	_selected_char = ch
	_selected_perk_id = &""
	_refresh()


func _refresh() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	var prog: Node = get_node_or_null("/root/Progression")
	if gs == null or prog == null or _points_label == null:
		return

	var points: int = int(gs.call("get_upgrade_points"))
	_points_label.text = "БАЛЛЫ ПРОКАЧКИ: %d" % points

	var level: int = int(gs.call("get_characteristic", _selected_char))
	var char_title: String = _char_header_title(_selected_char)
	_stat_header.text = "%s %d / %d" % [char_title, level, MAX_STAT]
	_stat_note.text = "Каждый купленный перк этой ветки = +1 %s" % _char_note_name(_selected_char)

	for ch_key in _tab_buttons.keys():
		var tab_btn: Button = _tab_buttons[ch_key] as Button
		if tab_btn == null:
			continue
		tab_btn.disabled = int(ch_key) == int(_selected_char)

	_rebuild_perk_nodes(prog)
	_refresh_detail(prog)


func _rebuild_perk_nodes(prog: Node) -> void:
	for child in _perk_host.get_children():
		child.queue_free()
	_perk_buttons.clear()

	var perks: Array = prog.call("get_perks_for_characteristic", _selected_char) as Array
	var by_slot: Dictionary = {}
	for entry in perks:
		var def: PerkDefinition = entry as PerkDefinition
		if def == null:
			continue
		var key: String = "%d_%d" % [int(def.section), def.order_in_section]
		by_slot[key] = def

	_perk_host.add_child(_make_single_node_row(by_slot.get("0_1") as PerkDefinition, prog))
	_perk_host.add_child(_make_single_node_row(by_slot.get("0_2") as PerkDefinition, prog))
	_perk_host.add_child(_make_branch_pair_row(
		by_slot.get("1_1") as PerkDefinition,
		by_slot.get("2_1") as PerkDefinition,
		prog,
	))
	_perk_host.add_child(_make_branch_pair_row(
		by_slot.get("1_2") as PerkDefinition,
		by_slot.get("2_2") as PerkDefinition,
		prog,
	))
	_perk_host.add_child(_make_single_node_row(by_slot.get("3_1") as PerkDefinition, prog))
	_perk_host.add_child(_make_single_node_row(by_slot.get("3_2") as PerkDefinition, prog))

	if _selected_perk_id == &"":
		_auto_select_first_perk(perks)


func _auto_select_first_perk(perks: Array) -> void:
	for entry in perks:
		var def: PerkDefinition = entry as PerkDefinition
		if def == null:
			continue
		_selected_perk_id = def.id
		return


func _make_single_node_row(def: PerkDefinition, prog: Node) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if def == null:
		var placeholder := Label.new()
		placeholder.text = "—"
		row.add_child(placeholder)
		return row
	var node_btn: Button = _make_perk_node_button(def, prog)
	node_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(node_btn)
	return row


func _make_branch_pair_row(def_a: PerkDefinition, def_b: PerkDefinition, prog: Node) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	if def_a != null:
		var btn_a: Button = _make_perk_node_button(def_a, prog)
		btn_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(btn_a)
	else:
		var spacer_a := Control.new()
		spacer_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer_a)
	if def_b != null:
		var btn_b: Button = _make_perk_node_button(def_b, prog)
		btn_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(btn_b)
	else:
		var spacer_b := Control.new()
		spacer_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer_b)
	return row


func _make_perk_node_button(def: PerkDefinition, prog: Node) -> Button:
	var avail: int = int(prog.call("get_perk_availability", def.id))
	var cost: int = int(prog.call("get_perk_purchase_cost", def.id))
	var status: String = _avail_text(avail)
	var btn := Button.new()
	btn.name = "Perk_%s" % String(def.id)
	btn.text = "%s\nСтоимость: %d\n%s" % [def.display_name, cost, status]
	btn.custom_minimum_size = Vector2(0, 72)
	btn.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var perk_id: StringName = def.id
	btn.pressed.connect(func() -> void:
		_audio_play_ui(AudioIds.UI_CLICK)
		_selected_perk_id = perk_id
		_refresh_detail(prog)
		_highlight_selected()
	)
	_perk_buttons[String(def.id)] = btn
	_tint_perk_button(btn, avail, String(def.id) == String(_selected_perk_id))
	return btn


func _tint_perk_button(btn: Button, avail: int, selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(3)
	style.set_border_width_all(2 if selected else 1)
	match avail:
		int(Progression.PerkAvailability.OWNED):
			style.bg_color = Color(0.14, 0.28, 0.18, 0.95)
			style.border_color = Color(0.45, 0.75, 0.5, 0.95)
		int(Progression.PerkAvailability.AVAILABLE):
			style.bg_color = Color(0.16, 0.22, 0.3, 0.95)
			style.border_color = Color(0.55, 0.7, 0.9, 0.95)
		int(Progression.PerkAvailability.NOT_ENOUGH_POINTS):
			style.bg_color = Color(0.28, 0.18, 0.12, 0.95)
			style.border_color = Color(0.8, 0.55, 0.3, 0.9)
		_:
			style.bg_color = Color(0.12, 0.12, 0.14, 0.9)
			style.border_color = Color(0.35, 0.35, 0.38, 0.8)
	if selected:
		style.border_color = Color(0.95, 0.85, 0.4, 1.0)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = hover.bg_color.lightened(0.08)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)


func _highlight_selected() -> void:
	var prog: Node = get_node_or_null("/root/Progression")
	if prog == null:
		return
	for perk_key in _perk_buttons.keys():
		var btn: Button = _perk_buttons[perk_key] as Button
		if btn == null:
			continue
		var pid: StringName = StringName(str(perk_key))
		var avail: int = int(prog.call("get_perk_availability", pid))
		_tint_perk_button(btn, avail, String(pid) == String(_selected_perk_id))


func _refresh_detail(prog: Node) -> void:
	if _detail_name == null or _buy_btn == null:
		return
	if _selected_perk_id == &"":
		_detail_name.text = "Выберите перк"
		_detail_status.text = ""
		_detail_body.text = ""
		_buy_btn.disabled = true
		_buy_btn.text = "Купить"
		return

	var def: PerkDefinition = null
	var db: Node = get_node_or_null("/root/ContentDB")
	if db != null:
		def = db.call("get_perk", _selected_perk_id) as PerkDefinition
	if def == null:
		_detail_name.text = "Перк недоступен"
		_detail_status.text = ""
		_detail_body.text = ""
		_buy_btn.disabled = true
		_buy_btn.text = "Купить"
		return

	var avail: int = int(prog.call("get_perk_availability", def.id))
	var cost: int = int(prog.call("get_perk_purchase_cost", def.id))
	_detail_name.text = def.display_name
	_detail_status.text = "Статус: %s\nСтоимость: %d" % [_avail_text(avail), cost]
	_detail_body.text = _product_description(def)
	var can_buy: bool = avail == int(Progression.PerkAvailability.AVAILABLE)
	_buy_btn.disabled = not can_buy
	_buy_btn.text = "Купить за %d" % cost


func _product_description(def: PerkDefinition) -> String:
	if def == null:
		return ""
	var text: String = def.description.strip_edges()
	if text == "":
		return def.display_name
	return text


func _on_buy_pressed() -> void:
	if _selected_perk_id == &"":
		return
	var prog: Node = get_node_or_null("/root/Progression")
	if prog == null:
		return
	var cost_before: int = int(prog.call("get_perk_purchase_cost", _selected_perk_id))
	var result: int = int(prog.call("purchase_perk", _selected_perk_id))
	if result == int(Progression.PerkPurchaseResult.SUCCESS):
		_audio_play_ui(AudioIds.UI_PURCHASE)
		var msg: String = "Куплен перк за %d" % cost_before
		purchase_notified.emit(msg)
		_try_hud_notify(msg)
	else:
		_audio_play_ui(AudioIds.UI_DENIED)
	_refresh()


func _try_hud_notify(message: String) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var hud: Node = tree.get_first_node_in_group("game_hud")
	if hud != null and hud.has_method("show_notification"):
		hud.call("show_notification", message)


func _focus_first_control() -> void:
	if _buy_btn != null and not _buy_btn.disabled:
		_buy_btn.grab_focus()
		return
	if _first_focus_control != null and is_instance_valid(_first_focus_control):
		_first_focus_control.grab_focus()
		return
	if _close_btn != null:
		_close_btn.grab_focus()


func _avail_text(avail: int) -> String:
	match avail:
		int(Progression.PerkAvailability.OWNED):
			return "КУЛЕНО"
		int(Progression.PerkAvailability.AVAILABLE):
			return "ДОСТУПНО"
		int(Progression.PerkAvailability.LOCKED_PREREQUISITE):
			return "НУЖЕН ПРЕДЫДУЩИЙ ПЕРК"
		int(Progression.PerkAvailability.NOT_ENOUGH_POINTS):
			return "НЕ ХВАТАЕТ БАЛЛОВ"
		_:
			return "НЕДОСТУПНО"


func _char_tab_title(ch: GameTypes.PlayerCharacteristic) -> String:
	match ch:
		GameTypes.PlayerCharacteristic.MUSCLE:
			return "МЫШЦА"
		GameTypes.PlayerCharacteristic.APPEARANCE:
			return "ВНЕШНОСТЬ"
		GameTypes.PlayerCharacteristic.CAPITAL:
			return "КАПИТАЛ"
		GameTypes.PlayerCharacteristic.AURA:
			return "АУРА"
	return "?"


func _char_header_title(ch: GameTypes.PlayerCharacteristic) -> String:
	match ch:
		GameTypes.PlayerCharacteristic.MUSCLE:
			return "МЫШЦА"
		GameTypes.PlayerCharacteristic.APPEARANCE:
			return "ВНЕШНОСТЬ"
		GameTypes.PlayerCharacteristic.CAPITAL:
			return "КАПИТАЛ"
		GameTypes.PlayerCharacteristic.AURA:
			return "АУРА"
	return "ХАРАКТЕРИСТИКА"


func _char_note_name(ch: GameTypes.PlayerCharacteristic) -> String:
	match ch:
		GameTypes.PlayerCharacteristic.MUSCLE:
			return "Мышца"
		GameTypes.PlayerCharacteristic.APPEARANCE:
			return "Внешность"
		GameTypes.PlayerCharacteristic.CAPITAL:
			return "Капитал"
		GameTypes.PlayerCharacteristic.AURA:
			return "Аура"
	return "характеристика"


func _audio_play_ui(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_ui"):
		ad.call("play_ui", sound_id)
