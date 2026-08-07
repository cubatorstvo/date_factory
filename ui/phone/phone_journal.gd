class_name PhoneJournal
extends Control
## Functional phone journal for discovered girls (MODULE 08)
## + salary section when StoryFeature.SALARY_MINE unlocked (MODULE 13).
## No Dating CTA / messaging / scheduling.

signal opened()
signal closed()

var _list: ItemList = null
var _detail: RichTextLabel = null
var _title: Label = null
var _close_btn: Button = null
var _player: Node = null
var _is_open: bool = false
var _listed_ids: Array[StringName] = []

var _salary_section: VBoxContainer = null
var _salary_title: Label = null
var _salary_stats: Label = null
var _salary_advance_btn: Button = null
var _salary_pending_hint: Label = null
var _salary_feedback: Label = null
var _salary_signals_connected: bool = false


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_connect_salary_signals()


func open(player: Node = null) -> void:
	_player = player
	if _player == null:
		var tree: SceneTree = get_tree()
		if tree != null:
			_player = tree.get_first_node_in_group("player")
	if _player != null and _player.has_method("enter_modal_ui"):
		_player.call("enter_modal_ui")
	_clear_salary_feedback()
	refresh()
	visible = true
	_is_open = true
	opened.emit()


func close() -> void:
	if not _is_open and not visible:
		return
	visible = false
	_is_open = false
	if _player != null and _player.has_method("enter_gameplay"):
		_player.call("enter_gameplay")
	closed.emit()


func is_open() -> bool:
	return _is_open


func get_listed_girl_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for gid in _listed_ids:
		out.append(gid)
	return out


func get_detail_text() -> String:
	if _detail == null:
		return ""
	return String(_detail.text)


func select_girl_by_id(girl_id: StringName) -> bool:
	for i in range(_listed_ids.size()):
		if _listed_ids[i] == girl_id:
			_list.select(i)
			_show_detail(girl_id)
			return true
	return false


func refresh() -> void:
	_refresh_list()
	_refresh_salary_section()


func has_salary_section_visible() -> bool:
	return _salary_section != null and _salary_section.visible


func is_salary_advance_controls_visible() -> bool:
	return _salary_advance_btn != null and _salary_advance_btn.visible


func is_salary_advance_enabled() -> bool:
	return _salary_advance_btn != null and _salary_advance_btn.visible and not _salary_advance_btn.disabled


func get_salary_stats_text() -> String:
	if _salary_stats == null:
		return ""
	return String(_salary_stats.text)


func get_salary_feedback_text() -> String:
	if _salary_feedback == null:
		return ""
	return String(_salary_feedback.text)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.12, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 40)
	root.add_theme_constant_override("margin_right", 40)
	root.add_theme_constant_override("margin_top", 30)
	root.add_theme_constant_override("margin_bottom", 30)
	add_child(root)
	var vbox := VBoxContainer.new()
	root.add_child(vbox)
	_title = Label.new()
	_title.text = "Телефон — Журнал"
	_title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_title)
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(split)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(220, 0)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_item_selected)
	split.add_child(_list)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.fit_content = false
	split.add_child(_detail)
	_build_salary_section(vbox)
	_close_btn = Button.new()
	_close_btn.text = "Закрыть"
	_close_btn.pressed.connect(close)
	vbox.add_child(_close_btn)


func _build_salary_section(parent: VBoxContainer) -> void:
	_salary_section = VBoxContainer.new()
	_salary_section.visible = false
	_salary_section.add_theme_constant_override("separation", 4)
	parent.add_child(_salary_section)
	var sep := HSeparator.new()
	_salary_section.add_child(sep)
	_salary_title = Label.new()
	_salary_title.text = "ЗАРПЛАТА"
	_salary_title.add_theme_font_size_override("font_size", 18)
	_salary_section.add_child(_salary_title)
	_salary_stats = Label.new()
	_salary_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_salary_section.add_child(_salary_stats)
	var advance_row := HBoxContainer.new()
	advance_row.add_theme_constant_override("separation", 12)
	_salary_section.add_child(advance_row)
	_salary_advance_btn = Button.new()
	_salary_advance_btn.text = "Получить зарплату вперёд"
	_salary_advance_btn.visible = false
	_salary_advance_btn.pressed.connect(_on_salary_advance_pressed)
	advance_row.add_child(_salary_advance_btn)
	_salary_pending_hint = Label.new()
	_salary_pending_hint.visible = false
	advance_row.add_child(_salary_pending_hint)
	_salary_feedback = Label.new()
	_salary_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_salary_section.add_child(_salary_feedback)


func _connect_salary_signals() -> void:
	if _salary_signals_connected:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_signal("money_changed") and not gs.is_connected("money_changed", _on_money_changed_salary):
			gs.connect("money_changed", _on_money_changed_salary)
		if gs.has_signal("authority_changed") and not gs.is_connected("authority_changed", _on_authority_changed_salary):
			gs.connect("authority_changed", _on_authority_changed_salary)
	var salary: Node = get_node_or_null("/root/SalaryMine")
	if salary != null:
		if salary.has_signal("salary_period_opened") and not salary.is_connected("salary_period_opened", _on_salary_period_opened):
			salary.connect("salary_period_opened", _on_salary_period_opened)
		if salary.has_signal("salary_pending_changed") and not salary.is_connected("salary_pending_changed", _on_salary_pending_changed):
			salary.connect("salary_pending_changed", _on_salary_pending_changed)
		if salary.has_signal("salary_claimed") and not salary.is_connected("salary_claimed", _on_salary_claimed):
			salary.connect("salary_claimed", _on_salary_claimed)
	var prog: Node = get_node_or_null("/root/Progression")
	if prog != null and prog.has_signal("perk_purchased") and not prog.is_connected("perk_purchased", _on_perk_purchased_salary):
		prog.connect("perk_purchased", _on_perk_purchased_salary)
	var story: Node = get_node_or_null("/root/Story")
	if story != null and story.has_signal("feature_unlocked") and not story.is_connected("feature_unlocked", _on_feature_unlocked_salary):
		story.connect("feature_unlocked", _on_feature_unlocked_salary)
	_salary_signals_connected = true


func _on_money_changed_salary(_new_value: int, _delta: int) -> void:
	_request_salary_refresh()


func _on_authority_changed_salary(_new_value: int, _delta: int) -> void:
	_request_salary_refresh()


func _on_salary_period_opened(_status: SalaryStatus) -> void:
	_request_salary_refresh()


func _on_salary_pending_changed(_amount: int) -> void:
	_request_salary_refresh()


func _on_salary_claimed(_amount: int, _method: SalaryTypes.ClaimMethod) -> void:
	_request_salary_refresh()


func _on_perk_purchased_salary(_perk_id: StringName, _characteristic: GameTypes.PlayerCharacteristic, _cost: int) -> void:
	_request_salary_refresh()


func _on_feature_unlocked_salary(_feature: StoryTypes.StoryFeature) -> void:
	_request_salary_refresh()


func _request_salary_refresh() -> void:
	if _is_open:
		_refresh_salary_section()


func _clear_salary_feedback() -> void:
	if _salary_feedback != null:
		_salary_feedback.text = ""


func _refresh_salary_section() -> void:
	if _salary_section == null:
		return
	var story: Node = get_node_or_null("/root/Story")
	var unlocked: bool = false
	if story != null and story.has_method("is_feature_unlocked"):
		unlocked = bool(story.call("is_feature_unlocked", StoryTypes.StoryFeature.SALARY_MINE))
	_salary_section.visible = unlocked
	if not unlocked:
		return
	var salary: Node = get_node_or_null("/root/SalaryMine")
	if salary == null or not salary.has_method("get_status"):
		return
	var status: SalaryStatus = salary.call("get_status") as SalaryStatus
	if status == null:
		return
	var day_suffix: String = ""
	var day_node: Node = get_node_or_null("/root/GameDay")
	if day_node != null and day_node.has_method("get_current_day"):
		day_suffix = " · День %d" % int(day_node.call("get_current_day"))
	_salary_title.text = "ЗАРПЛАТА%s" % day_suffix
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Авторитет: %d" % status.authority)
	lines.append("Разряд: %d" % status.salary_level)
	lines.append("За период: %d" % status.gross_per_period)
	lines.append("Накоплено: %d" % status.pending_salary)
	if status.passive_enabled:
		lines.append("Автоматически: %d / период" % status.passive_per_period)
	_salary_stats.text = "\n".join(lines)
	var show_advance: bool = status.salary_advance_owned
	_salary_advance_btn.visible = show_advance
	_salary_pending_hint.visible = show_advance
	if show_advance:
		_salary_advance_btn.disabled = not status.salary_advance_available
		_salary_pending_hint.text = "Получить %d" % status.pending_salary


func _on_salary_advance_pressed() -> void:
	var salary: Node = get_node_or_null("/root/SalaryMine")
	if salary == null or not salary.has_method("claim_salary_advance"):
		return
	var result: SalaryClaimResult = salary.call("claim_salary_advance") as SalaryClaimResult
	if result == null:
		return
	if result.ok:
		_salary_feedback.text = "Получено удалённо: +%d" % result.amount
	else:
		_salary_feedback.text = _claim_error_text(result.error)
	_refresh_salary_section()


func _claim_error_text(error: SalaryTypes.ClaimError) -> String:
	match error:
		SalaryTypes.ClaimError.NO_PENDING:
			return "Нет накопленной выплаты"
		SalaryTypes.ClaimError.ADVANCE_ALREADY_USED:
			return "Уже использовано в этом периоде"
		SalaryTypes.ClaimError.PERK_REQUIRED:
			return "Нужен перк"
		SalaryTypes.ClaimError.LOCKED:
			return "Нет накопленной выплаты"
		SalaryTypes.ClaimError.BUSY:
			return "Нет накопленной выплаты"
		_:
			return "Нет накопленной выплаты"


func _refresh_list() -> void:
	_listed_ids.clear()
	if _list != null:
		_list.clear()
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	var ids: Array = gs.call("get_discovered_girl_ids") as Array
	var gd: Node = get_node_or_null("/root/GirlDiscovery")
	for entry in ids:
		var gid: StringName = entry as StringName
		_listed_ids.append(gid)
		var display: String = String(gid)
		if gd != null:
			var def: GirlDefinition = gd.call("get_girl_definition", gid) as GirlDefinition
			if def != null and def.display_name.strip_edges() != "":
				display = def.display_name
		var has_contact: bool = bool(gs.call("has_girl_contact", gid))
		var status: String = "Номер получен" if has_contact else "Номера нет"
		_list.add_item("%s — %s" % [display, status])
	if _listed_ids.is_empty():
		_detail.text = "Пока нет записей."
	elif _list.get_selected_items().is_empty():
		_list.select(0)
		_show_detail(_listed_ids[0])


func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _listed_ids.size():
		return
	_show_detail(_listed_ids[index])


func _show_detail(girl_id: StringName) -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	var gd: Node = get_node_or_null("/root/GirlDiscovery")
	var db: Node = get_node_or_null("/root/ContentDB")
	if gs == null or gd == null:
		_detail.text = ""
		return
	var def: GirlDefinition = gd.call("get_girl_definition", girl_id) as GirlDefinition
	var lines: PackedStringArray = PackedStringArray()
	var name: String = String(girl_id)
	if def != null and def.display_name.strip_edges() != "":
		name = def.display_name
	lines.append("[b]%s[/b]" % name)
	var has_contact: bool = bool(gs.call("has_girl_contact", girl_id))
	if has_contact:
		lines.append("Статус: Номер получен")
	else:
		lines.append("Статус: Номера нет")
	var rel: int = int(gs.call("get_girl_relationship", girl_id))
	lines.append("Отношения: %+d / 5" % rel)
	if bool(gs.call("is_girl_conquered", girl_id)):
		lines.append("Отношения завершены")
	if has_contact:
		var date_cd: int = int(gs.call("get_girl_date_cooldown_days_remaining", girl_id))
		if date_cd > 0:
			lines.append("Следующее свидание: через %d дн." % date_cd)
		else:
			lines.append("Следующее свидание: доступно")
	else:
		var disc_cd: int = int(gs.call("get_girl_retry_days_remaining", girl_id))
		if disc_cd > 0:
			lines.append("Повторное знакомство: через %d дн." % disc_cd)
	lines.append("")
	lines.append("[b]Наблюдения[/b]")
	var known: Array = gs.call("get_known_girl_clue_indices", girl_id) as Array
	if known.is_empty():
		lines.append("Пока нет наблюдений")
	elif def != null:
		for k in known:
			var idx: int = int(k)
			if idx >= 0 and idx < def.clue_notes.size():
				lines.append("- %s" % def.clue_notes[idx])
	lines.append("")
	if bool(gs.call("is_primary_trait_revealed", girl_id)) and def != null and db != null:
		var trait_def: PrimaryTraitDefinition = db.call("get_primary_trait", def.primary_trait) as PrimaryTraitDefinition
		if trait_def != null:
			lines.append("[b]Основная черта:[/b] %s" % trait_def.display_name)
			lines.append("Нравится: %s" % _format_tags(trait_def.liked_tags))
			lines.append("Не нравится: %s" % _format_tags(trait_def.disliked_tags))
		else:
			lines.append("Характер: ?")
	else:
		lines.append("Характер: ?")
	lines.append("")
	if bool(gs.call("is_secondary_trait_revealed", girl_id)) and def != null and db != null:
		var sec_def: SecondaryTraitDefinition = db.call("get_secondary_trait", def.secondary_trait) as SecondaryTraitDefinition
		if sec_def != null:
			lines.append("[b]Доп. черта:[/b] %s" % sec_def.display_name)
			if sec_def.description.strip_edges() != "":
				lines.append(sec_def.description)
		else:
			lines.append("Доп. черта: ?")
	else:
		lines.append("Доп. черта: ?")
	lines.append("")
	lines.append("[b]Известные реакции[/b]")
	var reactions: Dictionary = gs.call("get_girl_known_reactions", girl_id) as Dictionary
	if reactions.is_empty():
		lines.append("Пока нет наблюдений")
	else:
		for source_key in reactions.keys():
			var source_id: StringName = source_key as StringName
			var reaction: int = int(reactions[source_key])
			var label: String = _resolve_reaction_source_label(source_id)
			if label == "":
				continue
			lines.append("- %s: %s" % [label, _reaction_text(reaction)])
	_detail.text = "\n".join(lines)


func _format_tags(tags: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for tag in tags:
		parts.append(String(GameTypes.ActionTag.find_key(int(tag))))
	return ", ".join(parts)


func _reaction_text(reaction: int) -> String:
	match reaction:
		-1:
			return "негативная"
		0:
			return "нейтральная"
		1:
			return "позитивная"
	return str(reaction)


func _resolve_reaction_source_label(source_id: StringName) -> String:
	var db: Node = get_node_or_null("/root/ContentDB")
	if db != null:
		if db.has_method("find_dating_greeting"):
			var greeting: DatingGreetingDefinition = db.call("find_dating_greeting", source_id) as DatingGreetingDefinition
			if greeting != null and greeting.label.strip_edges() != "":
				return greeting.label
		if source_id == &"dating_greeting_silence":
			return "Ничего не говорить"
		if db.has_method("find_dating_action"):
			var action: DatingActionDefinition = db.call("find_dating_action", source_id) as DatingActionDefinition
			if action != null and action.label.strip_edges() != "":
				return action.label
		if String(source_id).begins_with("date_event_") and db.has_method("get_dating_event"):
			var ev: DatingEventDefinition = db.call("get_dating_event", source_id) as DatingEventDefinition
			if ev != null:
				var title: String = ev.title.strip_edges()
				return title if title != "" else String(ev.id)
	var gd: Node = get_node_or_null("/root/GirlDiscovery")
	if gd != null:
		var approach: DiscoveryApproachDefinition = gd.call("find_discovery_approach", source_id) as DiscoveryApproachDefinition
		if approach != null and approach.label.strip_edges() != "":
			return approach.label
	# Production UI: skip unresolved technical IDs.
	if OS.is_debug_build() or OS.has_feature("editor"):
		push_warning("[PhoneJournal] unresolved reaction source: %s" % String(source_id))
	return ""
