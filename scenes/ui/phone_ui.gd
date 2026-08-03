extends Control
## Phone overlay with tabs.

@onready var panel: PanelContainer = $Panel
@onready var tabs: TabContainer = $Panel/Margin/Body/Tabs
@onready var candidates_list: ItemList = $Panel/Margin/Body/Tabs/Candidates/List
@onready var relations_list: ItemList = $Panel/Margin/Body/Tabs/Relations/List
@onready var upgrades_list: ItemList = $Panel/Margin/Body/Tabs/Upgrades/List
@onready var staff_list: ItemList = $Panel/Margin/Body/Tabs/Staff/List
@onready var clones_list: ItemList = $Panel/Margin/Body/Tabs/Clones/List
@onready var stats_label: Label = $Panel/Margin/Body/Tabs/Stats/Label
@onready var twitch_edit: LineEdit = $Panel/Margin/Body/Tabs/Twitch/Channel
@onready var twitch_status: Label = $Panel/Margin/Body/Tabs/Twitch/Status
@onready var schedule_label: Label = $Panel/Margin/Body/Tabs/Schedule/Label

var _open: bool = false
var _upgrade_ids: Array = []
var _staff_ids: Array = []
var _candidate_ids: Array = []
var _claimed_list: ItemList
var _journal_girls: ItemList
var _journal_body: RichTextLabel
var _journal_ids: Array = []
var _orbit_body: RichTextLabel
var _orbit_pending_option: OptionButton
var _orbit_btn_a: Button
var _orbit_btn_b: Button
var _orbit_btn_c: Button
var _orbit_depth_option: OptionButton
var _orbit_btn_deepen: Button
var _orbit_btn_expand: Button
var _orbit_syn_option: OptionButton
var _orbit_btn_syn_on: Button
var _orbit_btn_syn_off: Button
var _orbit_search_option: OptionButton
var _orbit_search_option2: OptionButton
var _orbit_btn_search_set: Button
var _orbit_btn_search_clear: Button
var _orbit_doctrine_option: OptionButton
var _orbit_btn_doctrine_on: Button
var _orbit_btn_doctrine_off: Button


func _ready() -> void:
	add_to_group("phone_ui")
	visible = false
	if panel:
		panel.visible = false
	# Prevent Twitch LineEdit from eating WASD.
	if twitch_edit:
		twitch_edit.focus_mode = Control.FOCUS_CLICK
	_ensure_claimed_tab()
	_ensure_journal_tab()
	_ensure_orbit_tab()
	var start_btn := get_node_or_null("Panel/Margin/Body/Tabs/Candidates/Start") as Button
	if start_btn:
		start_btn.text = "Подготовить и начать"
	var prepare_btn := get_node_or_null("Panel/Margin/Body/Tabs/Candidates/Prepare") as Button
	if prepare_btn:
		prepare_btn.text = "Только подготовить"
	var rel_tab := get_node_or_null("Panel/Margin/Body/Tabs/Relations") as Control
	if rel_tab:
		rel_tab.name = "Dating"
	$Panel/Margin/Body/Tabs/Upgrades/Buy.pressed.connect(_buy_selected_upgrade)
	$Panel/Margin/Body/Tabs/Staff/Hire.pressed.connect(_hire_selected)
	$Panel/Margin/Body/Tabs/Candidates/Prepare.pressed.connect(_prepare_selected)
	$Panel/Margin/Body/Tabs/Candidates/Start.pressed.connect(_start_selected)
	$Panel/Margin/Body/Tabs/Twitch/Connect.pressed.connect(_connect_twitch)
	var create_btn := get_node_or_null("Panel/Margin/Body/Tabs/Clones/Create") as Button
	if create_btn:
		create_btn.text = "Вырастить и принять дубль"
	$Panel/Margin/Body/Tabs/Clones/Create.pressed.connect(_start_clone_acceptance)
	$Panel/Margin/Body/Tabs/Stats/Save.pressed.connect(func(): Game.save_game())
	$Panel/Margin/Body/Tabs/Stats/Load.pressed.connect(func(): Game.load_game(); _refresh())
	Game.girls.girls_changed.connect(_refresh)
	Game.upgrades.upgrades_changed.connect(_refresh)
	Game.staff.staff_changed.connect(_refresh)
	Game.clones.clones_changed.connect(_refresh)
	if Game.trait_influence != null and not Game.trait_influence.influence_changed.is_connected(_refresh):
		Game.trait_influence.influence_changed.connect(_refresh)


func _ensure_journal_tab() -> void:
	if tabs == null:
		return
	if tabs.has_node("Journal"):
		_journal_girls = tabs.get_node("Journal/Split/Girls") as ItemList
		_journal_body = tabs.get_node("Journal/Split/Body") as RichTextLabel
		if _journal_girls and not _journal_girls.item_selected.is_connected(_on_journal_girl_selected):
			_journal_girls.item_selected.connect(_on_journal_girl_selected)
		return
	var box := VBoxContainer.new()
	box.name = "Journal"
	var hint := Label.new()
	hint.text = "Журнал: факты → гипотезы → подтверждённые черты"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)
	var split := HBoxContainer.new()
	split.name = "Split"
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var girls := ItemList.new()
	girls.name = "Girls"
	girls.custom_minimum_size = Vector2(180, 280)
	girls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	girls.item_selected.connect(_on_journal_girl_selected)
	split.add_child(girls)
	var body := RichTextLabel.new()
	body.name = "Body"
	body.bbcode_enabled = true
	body.fit_content = false
	body.scroll_active = true
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size = Vector2(240, 280)
	split.add_child(body)
	box.add_child(split)
	tabs.add_child(box)
	tabs.move_child(box, 2)
	_journal_girls = girls
	_journal_body = body


func _on_journal_girl_selected(index: int) -> void:
	_fill_journal_body(index)


func _fill_journal_body(index: int) -> void:
	if _journal_body == null:
		return
	if index < 0 or index >= _journal_ids.size():
		_journal_body.text = "Выбери контакт слева."
		return
	var id := StringName(str(_journal_ids[index]))
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[b]%s[/b]" % Game.girls.display_name(id))
	lines.append("Связь: %.0f%% · знание: %s (авто %.0f%%)" % [
		float(Game.girls.get_entry(id).get("bond", 0.0)),
		_knowledge_ru(Game.girls.knowledge_band(id)),
		Game.girls.automation_confidence(id) * 100.0,
	])
	lines.append("")
	lines.append("[b]Подтверждённые черты[/b]")
	var revealed: Array = Game.girls.revealed_traits(id)
	if revealed.is_empty():
		lines.append("— пока нет")
	else:
		for t in revealed:
			lines.append("• %s" % Loc.trait_name(str(t)))
	lines.append("")
	lines.append("[b]Гипотезы[/b]")
	var hyps: Array = Game.girls.hypotheses(id)
	var hyp_shown := 0
	for h in hyps:
		var st := str(h.get("status", ""))
		if st == "neutral":
			continue
		hyp_shown += 1
		var trait_txt := Loc.trait_name(str(h.get("trait_id", "?")))
		match st:
			"active":
				lines.append("• ? %s (активна)" % trait_txt)
			"confirmed":
				lines.append("• ✓ %s (подтверждена)" % trait_txt)
			"rejected":
				lines.append("• ✗ %s (отвергнута)" % trait_txt)
			_:
				lines.append("• %s [%s]" % [trait_txt, st])
	if hyp_shown == 0:
		lines.append("— пока нет")
	lines.append("")
	lines.append("[b]Факты / наблюдения[/b]")
	var obs: Array = Game.girls.observations(id)
	if obs.is_empty():
		lines.append("— пока нет")
	else:
		var from_i: int = maxi(0, obs.size() - 8)
		for i in range(from_i, obs.size()):
			var o: Dictionary = obs[i]
			lines.append("• %s" % str(o.get("text", "")))
	lines.append("")
	lines.append("[b]История реакций[/b]")
	var log: Array = Game.girls.reaction_log(id)
	if log.is_empty():
		lines.append("— пусто")
	else:
		var from_l: int = maxi(0, log.size() - 6)
		for i in range(from_l, log.size()):
			var row: Dictionary = log[i]
			lines.append("• %s → %s" % [str(row.get("quality", "?")), str(row.get("status", "?"))])
	_journal_body.text = "\n".join(lines)


func _knowledge_ru(band: String) -> String:
	match band:
		"full":
			return "полное"
		"high":
			return "высокое"
		"medium":
			return "среднее"
		_:
			return "низкое"


func _ensure_orbit_tab() -> void:
	if tabs == null:
		return
	if tabs.has_node("Orbit"):
		var orbit := tabs.get_node("Orbit") as Control
		_orbit_body = orbit.get_node_or_null("Body") as RichTextLabel
		if orbit.get_node_or_null("PickRow") == null:
			_attach_orbit_pick_row(orbit)
		else:
			_orbit_pending_option = orbit.get_node_or_null("PickRow/TraitPick") as OptionButton
			_orbit_btn_a = orbit.get_node_or_null("PickRow/BtnA") as Button
			_orbit_btn_b = orbit.get_node_or_null("PickRow/BtnB") as Button
			_orbit_btn_c = orbit.get_node_or_null("PickRow/BtnC") as Button
			_connect_orbit_branch_buttons()
		_ensure_orbit_extra_rows(orbit)
		return
	var box := VBoxContainer.new()
	box.name = "Orbit"
	var hint := Label.new()
	hint.text = "Орбита / черты — коллективное влияние"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)
	var body := RichTextLabel.new()
	body.name = "Body"
	body.bbcode_enabled = true
	body.fit_content = false
	body.scroll_active = true
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size = Vector2(0, 260)
	box.add_child(body)
	_attach_orbit_pick_row(box)
	_ensure_orbit_extra_rows(box)
	tabs.add_child(box)
	tabs.move_child(box, mini(3, tabs.get_child_count() - 1))
	_orbit_body = body


func _attach_orbit_pick_row(orbit: Control) -> void:
	var pick := HBoxContainer.new()
	pick.name = "PickRow"
	var opt := OptionButton.new()
	opt.name = "TraitPick"
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pick.add_child(opt)
	var ba := Button.new()
	ba.name = "BtnA"
	ba.text = "Ветка A"
	pick.add_child(ba)
	var bb := Button.new()
	bb.name = "BtnB"
	bb.text = "Ветка B"
	pick.add_child(bb)
	var bc := Button.new()
	bc.name = "BtnC"
	bc.text = "Ветка C"
	pick.add_child(bc)
	orbit.add_child(pick)
	_orbit_pending_option = opt
	_orbit_btn_a = ba
	_orbit_btn_b = bb
	_orbit_btn_c = bc
	_connect_orbit_branch_buttons()


func _connect_orbit_branch_buttons() -> void:
	if _orbit_btn_a and not _orbit_btn_a.pressed.is_connected(_on_orbit_branch_a):
		_orbit_btn_a.pressed.connect(_on_orbit_branch_a)
	if _orbit_btn_b and not _orbit_btn_b.pressed.is_connected(_on_orbit_branch_b):
		_orbit_btn_b.pressed.connect(_on_orbit_branch_b)
	if _orbit_btn_c and not _orbit_btn_c.pressed.is_connected(_on_orbit_branch_c):
		_orbit_btn_c.pressed.connect(_on_orbit_branch_c)
	if _orbit_pending_option and not _orbit_pending_option.item_selected.is_connected(_on_orbit_trait_selected):
		_orbit_pending_option.item_selected.connect(_on_orbit_trait_selected)


func _on_orbit_branch_a() -> void:
	_pick_orbit_branch("A")


func _on_orbit_branch_b() -> void:
	_pick_orbit_branch("B")


func _on_orbit_branch_c() -> void:
	_pick_orbit_branch("C")


func _on_orbit_trait_selected(index: int) -> void:
	if _orbit_pending_option == null or Game.trait_influence == null:
		return
	if index < 0 or index >= _orbit_pending_option.item_count:
		return
	var tid := str(_orbit_pending_option.get_item_metadata(index))
	if tid.is_empty():
		return
	if _orbit_btn_a:
		_orbit_btn_a.tooltip_text = Game.trait_influence.branch_preview(tid, "A")
	if _orbit_btn_b:
		_orbit_btn_b.tooltip_text = Game.trait_influence.branch_preview(tid, "B")
	if _orbit_btn_c:
		_orbit_btn_c.tooltip_text = Game.trait_influence.branch_preview(tid, "C")


func _ensure_orbit_extra_rows(orbit: Control) -> void:
	if orbit.get_node_or_null("DepthRow") == null:
		var drow := HBoxContainer.new()
		drow.name = "DepthRow"
		var dopt := OptionButton.new()
		dopt.name = "DepthPick"
		dopt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		drow.add_child(dopt)
		var bd := Button.new()
		bd.name = "BtnDeepen"
		bd.text = "Углубить"
		drow.add_child(bd)
		var be := Button.new()
		be.name = "BtnExpand"
		be.text = "2-я ветка"
		drow.add_child(be)
		orbit.add_child(drow)
		_orbit_depth_option = dopt
		_orbit_btn_deepen = bd
		_orbit_btn_expand = be
	else:
		_orbit_depth_option = orbit.get_node_or_null("DepthRow/DepthPick") as OptionButton
		_orbit_btn_deepen = orbit.get_node_or_null("DepthRow/BtnDeepen") as Button
		_orbit_btn_expand = orbit.get_node_or_null("DepthRow/BtnExpand") as Button
	if orbit.get_node_or_null("SynRow") == null:
		var srow := HBoxContainer.new()
		srow.name = "SynRow"
		var sopt := OptionButton.new()
		sopt.name = "SynPick"
		sopt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		srow.add_child(sopt)
		var bon := Button.new()
		bon.name = "BtnSynOn"
		bon.text = "Вкл синергию"
		srow.add_child(bon)
		var boff := Button.new()
		boff.name = "BtnSynOff"
		boff.text = "Снять"
		srow.add_child(boff)
		orbit.add_child(srow)
		_orbit_syn_option = sopt
		_orbit_btn_syn_on = bon
		_orbit_btn_syn_off = boff
	else:
		_orbit_syn_option = orbit.get_node_or_null("SynRow/SynPick") as OptionButton
		_orbit_btn_syn_on = orbit.get_node_or_null("SynRow/BtnSynOn") as Button
		_orbit_btn_syn_off = orbit.get_node_or_null("SynRow/BtnSynOff") as Button
	if _orbit_btn_deepen and not _orbit_btn_deepen.pressed.is_connected(_on_orbit_deepen):
		_orbit_btn_deepen.pressed.connect(_on_orbit_deepen)
	if _orbit_btn_expand and not _orbit_btn_expand.pressed.is_connected(_on_orbit_expand):
		_orbit_btn_expand.pressed.connect(_on_orbit_expand)
	if _orbit_btn_syn_on and not _orbit_btn_syn_on.pressed.is_connected(_on_orbit_syn_on):
		_orbit_btn_syn_on.pressed.connect(_on_orbit_syn_on)
	if _orbit_btn_syn_off and not _orbit_btn_syn_off.pressed.is_connected(_on_orbit_syn_off):
		_orbit_btn_syn_off.pressed.connect(_on_orbit_syn_off)
	if orbit.get_node_or_null("SearchRow") == null:
		var srow := HBoxContainer.new()
		srow.name = "SearchRow"
		var s1 := OptionButton.new()
		s1.name = "SearchPick"
		s1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		srow.add_child(s1)
		var s2 := OptionButton.new()
		s2.name = "SearchPick2"
		s2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		srow.add_child(s2)
		var bset := Button.new()
		bset.name = "BtnSearchSet"
		bset.text = "Поиск"
		srow.add_child(bset)
		var bclr := Button.new()
		bclr.name = "BtnSearchClear"
		bclr.text = "Сброс"
		srow.add_child(bclr)
		orbit.add_child(srow)
		_orbit_search_option = s1
		_orbit_search_option2 = s2
		_orbit_btn_search_set = bset
		_orbit_btn_search_clear = bclr
	else:
		_orbit_search_option = orbit.get_node_or_null("SearchRow/SearchPick") as OptionButton
		_orbit_search_option2 = orbit.get_node_or_null("SearchRow/SearchPick2") as OptionButton
		_orbit_btn_search_set = orbit.get_node_or_null("SearchRow/BtnSearchSet") as Button
		_orbit_btn_search_clear = orbit.get_node_or_null("SearchRow/BtnSearchClear") as Button
	if _orbit_btn_search_set and not _orbit_btn_search_set.pressed.is_connected(_on_orbit_search_set):
		_orbit_btn_search_set.pressed.connect(_on_orbit_search_set)
	if _orbit_btn_search_clear and not _orbit_btn_search_clear.pressed.is_connected(_on_orbit_search_clear):
		_orbit_btn_search_clear.pressed.connect(_on_orbit_search_clear)
	if orbit.get_node_or_null("DoctrineRow") == null:
		var drow := HBoxContainer.new()
		drow.name = "DoctrineRow"
		var dopt := OptionButton.new()
		dopt.name = "DoctrinePick"
		dopt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		drow.add_child(dopt)
		var don := Button.new()
		don.name = "BtnDoctrineOn"
		don.text = "Доктрина"
		drow.add_child(don)
		var doff := Button.new()
		doff.name = "BtnDoctrineOff"
		doff.text = "Снять доктр."
		drow.add_child(doff)
		orbit.add_child(drow)
		_orbit_doctrine_option = dopt
		_orbit_btn_doctrine_on = don
		_orbit_btn_doctrine_off = doff
	else:
		_orbit_doctrine_option = orbit.get_node_or_null("DoctrineRow/DoctrinePick") as OptionButton
		_orbit_btn_doctrine_on = orbit.get_node_or_null("DoctrineRow/BtnDoctrineOn") as Button
		_orbit_btn_doctrine_off = orbit.get_node_or_null("DoctrineRow/BtnDoctrineOff") as Button
	if _orbit_btn_doctrine_on and not _orbit_btn_doctrine_on.pressed.is_connected(_on_orbit_doctrine_on):
		_orbit_btn_doctrine_on.pressed.connect(_on_orbit_doctrine_on)
	if _orbit_btn_doctrine_off and not _orbit_btn_doctrine_off.pressed.is_connected(_on_orbit_doctrine_off):
		_orbit_btn_doctrine_off.pressed.connect(_on_orbit_doctrine_off)


func _on_orbit_doctrine_on() -> void:
	if Game.trait_influence == null or _orbit_doctrine_option == null:
		return
	var idx := _orbit_doctrine_option.selected
	if idx < 0:
		EventBus.toast("Нет доктрины для активации", &"warn")
		return
	var tid := str(_orbit_doctrine_option.get_item_metadata(idx))
	if Game.trait_influence.activate_doctrine(tid):
		Sfx.play_ui(&"confirm")
		_refresh()
	else:
		Sfx.play_ui(&"deny")


func _on_orbit_doctrine_off() -> void:
	if Game.trait_influence == null:
		return
	if Game.trait_influence.deactivate_doctrine():
		Sfx.play_ui(&"confirm")
		_refresh()
	else:
		Sfx.play_ui(&"deny")


func _on_orbit_search_set() -> void:
	if Game.trait_influence == null or _orbit_search_option == null:
		return
	var targets: Array = []
	var i1 := _orbit_search_option.selected
	if i1 >= 0:
		var t1 := str(_orbit_search_option.get_item_metadata(i1))
		if not t1.is_empty():
			targets.append(t1)
	if _orbit_search_option2 and _orbit_search_option2.selected >= 0:
		var t2 := str(_orbit_search_option2.get_item_metadata(_orbit_search_option2.selected))
		if not t2.is_empty() and not targets.has(t2):
			targets.append(t2)
	if targets.is_empty():
		EventBus.toast("Выбери черту для поиска", &"warn")
		Sfx.play_ui(&"deny")
		return
	if Game.trait_influence.set_search_targets(targets):
		Sfx.play_ui(&"confirm")
		_refresh()
	else:
		Sfx.play_ui(&"deny")


func _on_orbit_search_clear() -> void:
	if Game.trait_influence == null:
		return
	Game.trait_influence.clear_search()
	Sfx.play_ui(&"cancel")
	_refresh()


func _on_orbit_deepen() -> void:
	_pick_orbit_depth("deepen")


func _on_orbit_expand() -> void:
	_pick_orbit_depth("expand")


func _pick_orbit_depth(mode: String) -> void:
	if Game.trait_influence == null or _orbit_depth_option == null:
		return
	var idx := _orbit_depth_option.selected
	if idx < 0:
		EventBus.toast("Нет черты для порога 30", &"warn")
		return
	var tid := str(_orbit_depth_option.get_item_metadata(idx))
	if Game.trait_influence.choose_depth(tid, mode):
		Sfx.play_ui(&"confirm")
		_refresh()
	else:
		Sfx.play_ui(&"deny")


func _on_orbit_syn_on() -> void:
	if Game.trait_influence == null or _orbit_syn_option == null:
		return
	var idx := _orbit_syn_option.selected
	if idx < 0:
		EventBus.toast("Нет синергии для активации", &"warn")
		return
	var sid := str(_orbit_syn_option.get_item_metadata(idx))
	if Game.trait_influence.activate_synergy(sid):
		Sfx.play_ui(&"confirm")
		_refresh()
	else:
		Sfx.play_ui(&"deny")


func _on_orbit_syn_off() -> void:
	if Game.trait_influence == null or Game.trait_influence.active_synergies.is_empty():
		EventBus.toast("Нет активной синергии", &"warn")
		return
	var sid := str(Game.trait_influence.active_synergies[0])
	if Game.trait_influence.deactivate_synergy(sid):
		Sfx.play_ui(&"confirm")
		_refresh()
	else:
		Sfx.play_ui(&"deny")


func _pick_orbit_branch(branch: String) -> void:
	if Game.trait_influence == null or _orbit_pending_option == null:
		return
	var idx := _orbit_pending_option.selected
	if idx < 0:
		EventBus.toast("Нет черты для выбора ветки", &"warn")
		return
	var tid := str(_orbit_pending_option.get_item_metadata(idx))
	if tid.is_empty():
		tid = str(_orbit_pending_option.get_item_text(idx))
	if Game.trait_influence.choose_branch(tid, branch):
		Sfx.play_ui(&"confirm")
		_refresh()
	else:
		Sfx.play_ui(&"deny")


func _refresh_orbit_pickers() -> void:
	if _orbit_pending_option == null or Game.trait_influence == null:
		return
	var pending: Array = Game.trait_influence.pending_branch_traits()
	_orbit_pending_option.clear()
	for tid in pending:
		var i: int = _orbit_pending_option.item_count
		_orbit_pending_option.add_item(Game.trait_influence.display_name(str(tid)))
		_orbit_pending_option.set_item_metadata(i, str(tid))
	var has_pending: bool = not pending.is_empty()
	_orbit_pending_option.visible = has_pending
	if _orbit_btn_a:
		_orbit_btn_a.visible = has_pending
		_orbit_btn_a.disabled = not has_pending
	if _orbit_btn_b:
		_orbit_btn_b.visible = has_pending
		_orbit_btn_b.disabled = not has_pending
	if _orbit_btn_c:
		_orbit_btn_c.visible = has_pending
		_orbit_btn_c.disabled = not has_pending
	if has_pending:
		_orbit_pending_option.select(0)
		var tid0 := str(pending[0])
		if _orbit_btn_a:
			_orbit_btn_a.tooltip_text = Game.trait_influence.branch_preview(tid0, "A")
		if _orbit_btn_b:
			_orbit_btn_b.tooltip_text = Game.trait_influence.branch_preview(tid0, "B")
		if _orbit_btn_c:
			_orbit_btn_c.tooltip_text = Game.trait_influence.branch_preview(tid0, "C")
	if _orbit_depth_option:
		var depth_pending: Array = Game.trait_influence.pending_depth_traits()
		_orbit_depth_option.clear()
		for dtid in depth_pending:
			var di: int = _orbit_depth_option.item_count
			_orbit_depth_option.add_item(Game.trait_influence.display_name(str(dtid)))
			_orbit_depth_option.set_item_metadata(di, str(dtid))
		var has_depth: bool = not depth_pending.is_empty()
		_orbit_depth_option.visible = has_depth
		if _orbit_btn_deepen:
			_orbit_btn_deepen.visible = has_depth
			_orbit_btn_deepen.disabled = not has_depth
		if _orbit_btn_expand:
			_orbit_btn_expand.visible = has_depth
			_orbit_btn_expand.disabled = not has_depth
		if has_depth:
			_orbit_depth_option.select(0)
	if _orbit_syn_option:
		var syn_pending: Array = Game.trait_influence.pending_synergies()
		_orbit_syn_option.clear()
		for sid in syn_pending:
			var si: int = _orbit_syn_option.item_count
			var sd: Dictionary = Game.trait_influence.synergy_def(str(sid))
			_orbit_syn_option.add_item(str(sd.get("name", sid)))
			_orbit_syn_option.set_item_metadata(si, str(sid))
			_orbit_syn_option.set_item_tooltip_text(si, Game.trait_influence.synergy_preview(str(sid)))
		var can_syn: bool = not syn_pending.is_empty() and Game.trait_influence.synergy_slot_count() > 0
		_orbit_syn_option.visible = can_syn or not Game.trait_influence.active_synergies.is_empty()
		if _orbit_btn_syn_on:
			_orbit_btn_syn_on.visible = can_syn
			_orbit_btn_syn_on.disabled = not can_syn
		if _orbit_btn_syn_off:
			var has_active: bool = not Game.trait_influence.active_synergies.is_empty()
			_orbit_btn_syn_off.visible = has_active
			_orbit_btn_syn_off.disabled = not has_active
		if can_syn:
			_orbit_syn_option.select(0)
	if _orbit_search_option:
		var searchable: Array = Game.trait_influence.searchable_traits()
		_orbit_search_option.clear()
		if _orbit_search_option2:
			_orbit_search_option2.clear()
			_orbit_search_option2.add_item("—")
			_orbit_search_option2.set_item_metadata(0, "")
		for sid in searchable:
			var si: int = _orbit_search_option.item_count
			_orbit_search_option.add_item(Game.trait_influence.display_name(str(sid)))
			_orbit_search_option.set_item_metadata(si, str(sid))
			if _orbit_search_option2:
				var sj: int = _orbit_search_option2.item_count
				_orbit_search_option2.add_item(Game.trait_influence.display_name(str(sid)))
				_orbit_search_option2.set_item_metadata(sj, str(sid))
		var has_search: bool = not searchable.is_empty()
		_orbit_search_option.visible = has_search
		if _orbit_search_option2:
			_orbit_search_option2.visible = has_search
		if _orbit_btn_search_set:
			_orbit_btn_search_set.visible = has_search
			_orbit_btn_search_set.disabled = not has_search
		if _orbit_btn_search_clear:
			_orbit_btn_search_clear.visible = has_search
		var cur: Array = Game.trait_influence.get_search_targets()
		if has_search and not cur.is_empty():
			for i in range(_orbit_search_option.item_count):
				if str(_orbit_search_option.get_item_metadata(i)) == str(cur[0]):
					_orbit_search_option.select(i)
					break
			if cur.size() > 1 and _orbit_search_option2:
				for j in range(_orbit_search_option2.item_count):
					if str(_orbit_search_option2.get_item_metadata(j)) == str(cur[1]):
						_orbit_search_option2.select(j)
						break
		elif has_search:
			_orbit_search_option.select(0)
			if _orbit_search_option2:
				_orbit_search_option2.select(0)
	if _orbit_doctrine_option:
		var docs: Array = Game.trait_influence.pending_doctrines()
		if Game.trait_influence.active_doctrine != "" and not docs.has(Game.trait_influence.active_doctrine):
			docs.append(Game.trait_influence.active_doctrine)
		_orbit_doctrine_option.clear()
		for did in docs:
			var di: int = _orbit_doctrine_option.item_count
			var dd: Dictionary = Game.trait_influence.doctrine_def(str(did))
			_orbit_doctrine_option.add_item(str(dd.get("name", did)))
			_orbit_doctrine_option.set_item_metadata(di, str(did))
			_orbit_doctrine_option.set_item_tooltip_text(di, Game.trait_influence.doctrine_preview(str(did)))
		var has_doc: bool = not docs.is_empty()
		_orbit_doctrine_option.visible = has_doc
		if _orbit_btn_doctrine_on:
			_orbit_btn_doctrine_on.visible = has_doc and Game.trait_influence.active_doctrine == ""
			_orbit_btn_doctrine_on.disabled = not _orbit_btn_doctrine_on.visible
		if _orbit_btn_doctrine_off:
			var act: bool = Game.trait_influence.active_doctrine != ""
			_orbit_btn_doctrine_off.visible = act
			_orbit_btn_doctrine_off.disabled = not act
		if has_doc:
			_orbit_doctrine_option.select(0)


func _ensure_claimed_tab() -> void:
	if tabs == null:
		return
	if tabs.has_node("Mine"):
		_claimed_list = tabs.get_node("Mine/List") as ItemList
		return
	var box := VBoxContainer.new()
	box.name = "Mine"
	var list := ItemList.new()
	list.name = "List"
	list.custom_minimum_size = Vector2(0, 320)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(list)
	tabs.add_child(box)
	# Put after Dating/Relations (index 2).
	tabs.move_child(box, 2)
	_claimed_list = list


func force_close() -> void:
	_open = false
	var focus := get_viewport().gui_get_focus_owner()
	if focus and is_ancestor_of(focus):
		focus.release_focus()
	if twitch_edit:
		twitch_edit.release_focus()
	visible = false
	if panel:
		panel.visible = false
		panel.modulate.a = 1.0
		panel.scale = Vector2.ONE


func set_open(open: bool) -> void:
	_open = open
	if open:
		visible = true
		if panel:
			panel.visible = true
			panel.modulate.a = 0.0
			panel.scale = Vector2(0.94, 0.94)
			var tween := create_tween().set_parallel()
			tween.tween_property(panel, "modulate:a", 1.0, 0.18)
			tween.tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Game.quests.on_phone_opened()
		_refresh()
		Sfx.play_ui(&"click")
	else:
		force_close()
		Sfx.play_ui(&"cancel")


func _refresh() -> void:
	if not Game.run_started:
		return
	candidates_list.clear()
	_candidate_ids.clear()
	Game.girls.refresh_candidates(false)
	for c in Game.girls.candidates:
		_candidate_ids.append(c)
		var soft := str(c.get("soft_signal", ""))
		var line := "%s (%s) · %s · %.0f%%" % [
			str(c.get("name", "?")),
			str(c.get("archetype", "Кандидатка")),
			Loc.tier_name(c.get("tier", "simple")),
			float(c.get("bond", 0.0)),
		]
		if not soft.is_empty():
			line += " · сигнал: %s" % soft
		candidates_list.add_item(line)
	relations_list.clear()
	for e in Game.girls.list_dating():
		var id := str(e.get("id", ""))
		relations_list.add_item("%s | %s | связь %.0f%% | знание %s | черты %d/%d" % [
			Game.girls.display_name(StringName(id)),
			Loc.tier_name(e.get("tier", "simple")),
			float(e.get("bond", 0.0)),
			_knowledge_ru(Game.girls.knowledge_band(StringName(id))),
			Game.girls.revealed_traits(StringName(id)).size(),
			Game.girls.girl_traits(StringName(id)).size(),
		])
	if _journal_girls:
		_journal_girls.clear()
		_journal_ids.clear()
		var seen: Dictionary = {}
		for e2 in Game.girls.list_dating():
			var jid := str(e2.get("id", ""))
			if seen.has(jid):
				continue
			seen[jid] = true
			_journal_ids.append(jid)
			_journal_girls.add_item(Game.girls.display_name(StringName(jid)))
		for e3 in Game.girls.list_claimed():
			var jid2 := str(e3.get("id", ""))
			if seen.has(jid2):
				continue
			seen[jid2] = true
			_journal_ids.append(jid2)
			_journal_girls.add_item(Game.girls.display_name(StringName(jid2)) + " ★")
		# Always include contacts even if not yet dated.
		for cid in Game.girls.contacts:
			if seen.has(cid):
				continue
			seen[cid] = true
			_journal_ids.append(cid)
			_journal_girls.add_item(Game.girls.display_name(StringName(cid)))
		if not _journal_ids.is_empty():
			_journal_girls.select(0)
			_fill_journal_body(0)
		elif _journal_body:
			_journal_body.text = "Пока нет контактов для журнала."
	if _orbit_body and Game.trait_influence != null:
		_orbit_body.text = Game.trait_influence.phone_orbit_report()
		_refresh_orbit_pickers()
	elif _orbit_body:
		_orbit_body.text = "Модуль влияния ещё не подключён."
	if _claimed_list:
		_claimed_list.clear()
		for e in Game.girls.list_claimed():
			var id2 := str(e.get("id", ""))
			var prim: PackedStringArray = PackedStringArray()
			for p in Game.girls.girl_primary_traits(StringName(id2)):
				prim.append(Loc.trait_name(str(p)))
			var quirk := Game.girls.girl_quirk(StringName(id2))
			var quirk_txt := TraitsContent.quirk_label(quirk) if not quirk.is_empty() else "—"
			_claimed_list.add_item("%s | %s | %s | %s" % [
				Game.girls.display_name(StringName(id2)),
				Loc.tier_name(e.get("tier", "simple")),
				", ".join(prim) if not prim.is_empty() else "черты?",
				quirk_txt,
			])
	upgrades_list.clear()
	_upgrade_ids.clear()
	for u in Game.upgrades.available():
		_upgrade_ids.append(str(u.get("id", "")))
		upgrades_list.add_item("%s — %.0f$" % [str(u.get("name", "")), float(u.get("cost", 0))])
	staff_list.clear()
	_staff_ids.clear()
	for role_id in ContentDB.staff_roles.keys():
		if Game.staff.hired.has(role_id):
			continue
		if Game.staff.can_hire(StringName(role_id)):
			_staff_ids.append(role_id)
			var def: Dictionary = ContentDB.staff_roles[role_id]
			staff_list.add_item("%s — %.0f$" % [str(def.get("name", role_id)), float(def.get("cost", 0))])
	for h in Game.staff.list_hired():
		staff_list.add_item("✓ %s" % str(h.get("name", "")))
	clones_list.clear()
	for c in Game.clones.clones:
		var st: String = str(c.get("status", "approved"))
		var latent_n: int = int(c.get("latent_defects", []).size()) if c.get("latent_defects", []) is Array else 0
		clones_list.add_item("%s | %s | усталость %.0f%% | скрытых дефектов %d" % [
			str(c.get("name", "")),
			st,
			float(c.get("fatigue", 0)) * 100.0,
			latent_n,
		])
	if not Game.clones.pending.is_empty():
		clones_list.add_item("⏳ Приёмка: %s (шаг)" % str(Game.clones.pending.get("name", "дубль")))
	stats_label.text = "Успешных свиданий: %d\nВсего свиданий: %d\nИдеальных: %d\nПровалов: %d\nКлонов: %d\nПостгейм: %s\nЧастей мегамашины: %d" % [
		Game.total_successful_dates,
		int(Game.dating.stats.get("total", 0)),
		int(Game.dating.stats.get("perfect", 0)),
		int(Game.dating.stats.get("fail", 0)),
		Game.clones.clones.size(),
		Loc.yes_no(Game.postgame),
		Game.facility.mega_parts,
	]
	var venue_names: PackedStringArray = PackedStringArray()
	for v in Game.facility.unlocked_venues:
		venue_names.append(Loc.venue_name(v))
	schedule_label.text = "Автосвиданий сейчас: %d\nУровень автоматизации: %d\nРежим авто: %s\nДоступные места: %s\n(кнопка ниже меняет режим: осторожный / стандарт / риск)" % [
		Game.dating.active_autos.size(),
		Game.dating.automation_level,
		_auto_mode_label(),
		", ".join(venue_names),
	]
	_ensure_auto_mode_button()
	twitch_status.text = "Статус Twitch: %s" % Loc.online(Game.names.twitch_connected)


func _buy_selected_upgrade() -> void:
	var idx := upgrades_list.get_selected_items()
	if idx.is_empty():
		return
	var i: int = idx[0]
	if i >= 0 and i < _upgrade_ids.size():
		Game.upgrades.buy(StringName(_upgrade_ids[i]))
		_refresh()


func _hire_selected() -> void:
	var idx := staff_list.get_selected_items()
	if idx.is_empty():
		return
	var i: int = idx[0]
	if i >= 0 and i < _staff_ids.size():
		Game.staff.hire(StringName(_staff_ids[i]))
		_refresh()


func _prepare_selected() -> void:
	var idx := candidates_list.get_selected_items()
	if idx.is_empty():
		EventBus.toast("Выбери кандидатку в списке", &"warn")
		return
	var c: Dictionary = _candidate_ids[idx[0]]
	var girl_id := StringName(str(c.get("id", "")))
	Game.quests.on_profile_seen()
	var gift_id := &"flower"
	if Game.inventory.total_gifts() > 0:
		gift_id = StringName(str(Game.inventory.gift_counts.keys()[0]))
	elif Game.inventory.carried_item != &"":
		gift_id = Game.inventory.carried_item
	elif Game.inventory.can_buy_gift(&"flower", girl_id):
		Game.inventory.buy_gift(&"flower", girl_id)
	var venue := &"kitchen_table"
	if Game.facility.unlocked_venues.size() > 0:
		venue = Game.facility.unlocked_venues[Game.facility.unlocked_venues.size() - 1]
	Game.dating.set_prep(str(c.get("id", "")), gift_id, venue, Game.inventory.equipped_outfit)
	EventBus.toast("Подготовлено в телефоне. Подойди к столу или нажми «Подготовить и начать».", &"info")
	Sfx.play_ui(&"confirm")


func _start_selected() -> void:
	if not Game.quests.can_do(&"start_date"):
		EventBus.toast(Game.quests.gate_hint(&"start_date"), &"warn")
		return
	var idx := candidates_list.get_selected_items()
	if idx.is_empty():
		return
	var c: Dictionary = _candidate_ids[idx[0]]
	var id := str(c.get("id", ""))
	var kind := str(c.get("kind", ""))
	if kind == "proc" and not Game.girls.unlocked.has(id):
		Game.girls.add_contact(StringName(id), c)
	if not Game.dating.prepared.has(id):
		_prepare_selected()
	if not Game.dating.prepared.has(id):
		return
	if Game.dating.start_manual(id, kind == "unique"):
		Sfx.play_ui(&"confirm")
		set_open(false)
	else:
		Sfx.play_ui(&"deny")


func _start_clone_acceptance() -> void:
	if Game.clones.begin_acceptance():
		set_open(false)
		Sfx.play_ui(&"confirm")
	else:
		Sfx.play_ui(&"deny")
	_refresh()


func _auto_mode_label() -> String:
	match str(Game.dating.auto_risk_mode):
		"careful":
			return "осторожный"
		"risk":
			return "рисковый"
		_:
			return "стандарт"


func _ensure_auto_mode_button() -> void:
	var schedule := get_node_or_null("Panel/Margin/Body/Tabs/Schedule") as Control
	if schedule == null:
		return
	if schedule.has_node("RiskMode"):
		return
	var btn := Button.new()
	btn.name = "RiskMode"
	btn.text = "Сменить режим авто"
	btn.pressed.connect(func():
		Game.dating.cycle_auto_risk_mode()
		_refresh()
	)
	schedule.add_child(btn)


func _connect_twitch() -> void:
	Game.names.set_twitch_channel(twitch_edit.text)
	_refresh()
