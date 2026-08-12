extends CanvasLayer
## Coherent perk-tree Progression UI (MODULE 22 §§33–39).
## Presentation only — purchases go through Progression.purchase_perk.


signal purchase_notified(message: String)


const PERK_BUTTON_SCENE: String = "res://ui/common/action_button.tscn"
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
var _embedded: bool = false
var _embedded_panel: Control = null

@onready var _root: Control = %Root
@onready var _points_label: Label = %PointsLabel
@onready var _stat_header: Label = %StatHeader
@onready var _stat_note: Label = %StatNote
@onready var _perk_host: GridContainer = %PerkHost
@onready var _detail_name: Label = %DetailName
@onready var _detail_body: Label = %DetailBody
@onready var _detail_status: Label = %DetailStatus
@onready var _buy_btn: Button = %BuyButton
@onready var _close_btn: Button = %CloseButton
var _tab_buttons: Dictionary = {}
var _perk_buttons: Dictionary = {}
var _first_focus_control: Control = null


func _ready() -> void:
	UiScaleHelper.apply_to_control(_root)
	_tab_buttons = {
		int(GameTypes.PlayerCharacteristic.MUSCLE): %MuscleTab,
		int(GameTypes.PlayerCharacteristic.APPEARANCE): %AppearanceTab,
		int(GameTypes.PlayerCharacteristic.CAPITAL): %CapitalTab,
		int(GameTypes.PlayerCharacteristic.AURA): %AuraTab,
	}
	for ch: GameTypes.PlayerCharacteristic in _TAB_CHARS:
		var button: Button = _tab_buttons[int(ch)] as Button
		button.pressed.connect(_select_tab.bind(ch))
	_first_focus_control = %MuscleTab
	_buy_btn.pressed.connect(_on_buy_pressed)
	_close_btn.pressed.connect(close)


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
	_embedded = false
	_player = player
	_on_closed = on_closed
	_selected_char = characteristic
	_selected_perk_id = &""
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_refresh()
	visible = true
	if _player != null and _player.has_method("enter_modal_ui"):
		_player.call("enter_modal_ui")
	call_deferred("_focus_first_control")


func embed_into(
	host: Control,
	player: Node,
	characteristic: GameTypes.PlayerCharacteristic = GameTypes.PlayerCharacteristic.MUSCLE,
) -> void:
	_embedded = true
	_player = player
	_on_closed = Callable()
	_selected_char = characteristic
	_selected_perk_id = &""
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	var dim: CanvasItem = _root.get_node_or_null("Dim") as CanvasItem
	if dim != null:
		dim.visible = false
	_close_btn.visible = false
	var title: Label = _root.find_child("Title", true, false) as Label
	if title != null:
		title.visible = false
	var panel: Control = _root.get_node_or_null("SafeMargin/Center/Panel") as Control
	if panel == null or host == null:
		push_error("[ProgressionUI] embed host/panel missing")
		return
	panel.reparent(host)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0.0, 480.0)
	_embedded_panel = panel
	_root.visible = false
	_refresh()
	call_deferred("_focus_first_control")


func refresh_embedded() -> void:
	if _embedded:
		_refresh()


func close() -> void:
	if _embedded:
		_teardown_embedded()
		return
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


func _teardown_embedded() -> void:
	_player = null
	_on_closed = Callable()
	_selected_perk_id = &""
	_embedded = false
	if _embedded_panel != null and is_instance_valid(_embedded_panel):
		_embedded_panel.queue_free()
	_embedded_panel = null
	if is_instance_valid(self):
		queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _embedded:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("phone"):
		close()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()


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
	for entry in perks:
		var def: PerkDefinition = entry as PerkDefinition
		if def == null:
			continue
		var button: Button = _make_perk_node_button(def, prog)
		if button != null:
			_perk_host.add_child(button)

	if _selected_perk_id == &"":
		_auto_select_first_perk(perks)


func _auto_select_first_perk(perks: Array) -> void:
	for entry in perks:
		var def: PerkDefinition = entry as PerkDefinition
		if def == null:
			continue
		_selected_perk_id = def.id
		return


func _make_perk_node_button(def: PerkDefinition, prog: Node) -> Button:
	var avail: int = int(prog.call("get_perk_availability", def.id))
	var cost: int = int(prog.call("get_perk_purchase_cost", def.id))
	var status: String = _avail_text(avail)
	var packed: PackedScene = load(PERK_BUTTON_SCENE) as PackedScene
	if packed == null:
		return null
	var btn: Button = packed.instantiate() as Button
	if btn == null:
		return null
	btn.name = "Perk_%s" % String(def.id)
	btn.text = "%s\nСтоимость: %d\n%s" % [def.display_name, cost, status]
	btn.custom_minimum_size = Vector2(0, 72)
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
	var gs: Node = get_node_or_null("/root/GameState")
	var had_tutorial_point: bool = false
	if gs != null:
		had_tutorial_point = bool(
			gs.call("get_story_flag", StoryIds.FLAG_TUTORIAL_UPGRADE_POINT)
		)
	var cost_before: int = int(prog.call("get_perk_purchase_cost", _selected_perk_id))
	var result: int = int(prog.call("purchase_perk", _selected_perk_id))
	if result == int(Progression.PerkPurchaseResult.SUCCESS):
		_audio_play_ui(AudioIds.UI_PURCHASE)
		var msg: String = "Куплен перк за %d" % cost_before
		purchase_notified.emit(msg)
		_try_hud_notify(msg)
		_mark_tutorial_upgrade_purchase(gs, had_tutorial_point)
	else:
		_audio_play_ui(AudioIds.UI_DENIED)
	_refresh()


func _mark_tutorial_upgrade_purchase(gs: Node, had_tutorial_point: bool) -> void:
	if gs == null or not had_tutorial_point:
		return
	# Tutorial point is consumed inside GameState._commit_perk_purchase.
	if bool(gs.call("get_story_flag", StoryIds.FLAG_TUTORIAL_UPGRADE_POINT)):
		return
	if bool(gs.call("get_story_flag", StoryIds.FLAG_TUTORIAL_UPGRADE_JOKE_DONE)):
		return
	gs.call("set_story_flag", StoryIds.FLAG_TUTORIAL_UPGRADE_AWAITING_RECLAIM, true)
	_try_hud_notify("Поговори с соседкой — она кое-что уточнит.")


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
