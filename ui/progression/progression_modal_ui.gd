extends CanvasLayer
## Functional Progression modal (MODULE 14A). Not final art.

var _player: Node = null
var _on_closed: Callable = Callable()
var _root: Control = null
var _points_label: Label = null
var _cost_label: Label = null
var _chars_label: Label = null
var _perk_list: VBoxContainer = null


func open(player: Node, on_closed: Callable = Callable()) -> void:
	_player = player
	_on_closed = on_closed
	layer = 40
	_build_ui()
	_refresh()
	visible = true
	if _player != null and _player.has_method("enter_modal_ui"):
		_player.call("enter_modal_ui")


func close() -> void:
	var p: Node = _player
	var cb: Callable = _on_closed
	_player = null
	_on_closed = Callable()
	if is_instance_valid(self):
		queue_free()
	if cb.is_valid():
		cb.call(p)
	elif p != null and p.has_method("enter_gameplay"):
		p.call("enter_gameplay")


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.05, 0.05, 0.06, 0.6)
	_root.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(520, 460)
	_root.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	margin.add_child(vbox)
	var title := Label.new()
	title.text = "Самооценка"
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	_points_label = Label.new()
	vbox.add_child(_points_label)
	_cost_label = Label.new()
	vbox.add_child(_cost_label)
	_chars_label = Label.new()
	_chars_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_chars_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 280)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	_perk_list = VBoxContainer.new()
	_perk_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_perk_list)
	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.pressed.connect(close)
	vbox.add_child(close_btn)


func _refresh() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	var prog: Node = get_node_or_null("/root/Progression")
	if gs == null or prog == null:
		return
	var points: int = int(gs.call("get_upgrade_points"))
	var next_cost: int = int(prog.call("get_next_perk_cost"))
	_points_label.text = "Баллы прокачки: %d" % points
	_cost_label.text = "Следующий перк стоит: %d" % next_cost
	var muscle: int = int(gs.call("get_muscle"))
	var appearance: int = int(gs.call("get_appearance"))
	var capital: int = int(gs.call("get_capital"))
	var aura: int = int(gs.call("get_aura"))
	_chars_label.text = "Мышца %d | Внешность %d | Капитал %d | Аура %d" % [
		muscle, appearance, capital, aura
	]
	for child in _perk_list.get_children():
		child.queue_free()
	var chars: Array = [
		GameTypes.PlayerCharacteristic.MUSCLE,
		GameTypes.PlayerCharacteristic.APPEARANCE,
		GameTypes.PlayerCharacteristic.CAPITAL,
		GameTypes.PlayerCharacteristic.AURA,
	]
	for ch in chars:
		var header := Label.new()
		header.text = _char_title(ch as GameTypes.PlayerCharacteristic)
		header.add_theme_font_size_override("font_size", 16)
		_perk_list.add_child(header)
		var perks: Array = prog.call("get_perks_for_characteristic", ch) as Array
		for entry in perks:
			var def: PerkDefinition = entry as PerkDefinition
			if def == null:
				continue
			_perk_list.add_child(_make_perk_row(def, prog))


func _make_perk_row(def: PerkDefinition, prog: Node) -> Control:
	var row := HBoxContainer.new()
	var avail: int = int(prog.call("get_perk_availability", def.id))
	var cost: int = int(prog.call("get_perk_purchase_cost", def.id))
	var status: String = _avail_text(avail)
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = "%s — %s — %d" % [def.display_name, status, cost]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	var buy := Button.new()
	buy.text = "Купить"
	var can_buy: bool = avail == int(Progression.PerkAvailability.AVAILABLE)
	buy.disabled = not can_buy
	if can_buy:
		var perk_id: StringName = def.id
		buy.pressed.connect(func() -> void:
			_buy_perk(perk_id)
		)
	row.add_child(buy)
	return row


func _buy_perk(perk_id: StringName) -> void:
	var prog: Node = get_node_or_null("/root/Progression")
	if prog == null:
		return
	prog.call("purchase_perk", perk_id)
	_refresh()


func _avail_text(avail: int) -> String:
	match avail:
		int(Progression.PerkAvailability.AVAILABLE):
			return "доступен"
		int(Progression.PerkAvailability.OWNED):
			return "куплен"
		int(Progression.PerkAvailability.LOCKED_PREREQUISITE):
			return "нужен предыдущий"
		int(Progression.PerkAvailability.NOT_ENOUGH_POINTS):
			return "мало баллов"
		_:
			return "недоступен"


func _char_title(ch: GameTypes.PlayerCharacteristic) -> String:
	match ch:
		GameTypes.PlayerCharacteristic.MUSCLE:
			return "Мышца"
		GameTypes.PlayerCharacteristic.APPEARANCE:
			return "Внешность"
		GameTypes.PlayerCharacteristic.CAPITAL:
			return "Капитал"
		GameTypes.PlayerCharacteristic.AURA:
			return "Аура"
	return "?"
