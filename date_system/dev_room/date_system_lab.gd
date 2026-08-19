class_name DateSystemLab
extends Control

const SECTIONS: Array[Array] = [
	["date", "СВИДАНИЕ"],
	["girls", "ДЕВУШКИ"],
	["girl_difficulty", "СЛОЖНОСТЬ ДЕВУШЕК"],
	["tags", "ТЕГИ"],
	["base_moves", "БАЗОВЫЕ ХОДЫ"],
	["unlock_moves", "ОТКРЫВАЕМЫЕ ХОДЫ"],
	["situations", "СИТУАЦИИ"],
	["secondary", "SECONDARY"],
	["locations", "МЕСТА"],
	["formats", "ФОРМАТЫ МЕСТ"],
	["outfits", "НАРЯДЫ"],
	["stats", "ХАРАКТЕРИСТИКИ"],
	["rules", "ПРАВИЛА СВИДАНИЯ"],
	["balance", "БАЛАНС"],
	["test_state", "ТЕСТОВОЕ СОСТОЯНИЕ"],
	["validation", "ВАЛИДАЦИЯ"],
]

var catalog_service: DateCatalogService = DateCatalogService.new()
var progress_store: DateProgressStore = DateProgressStore.new()
var validator: ContentValidator = ContentValidator.new()

var _section: String = "date"
var _status: Label
var _content_host: Control
var _play_panel: DatePlayPanel
var _search: LineEdit
var _list: ItemList
var _form_host: VBoxContainer
var _draft: Resource
var _selected_index: int = -1
var _dirty: bool = false
var _editor_root: Control
var _save_bar: HBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	LabUi.apply_theme(self)
	var bg := ColorRect.new()
	bg.color = LabUi.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	catalog_service.load_catalog()
	if catalog_service.catalog == null:
		var factory := SeedContentFactory.new()
		catalog_service.catalog = factory.build_catalog()
		factory.export_to_disk()
		catalog_service.load_catalog()
	progress_store.load_store(catalog_service.catalog)
	randomize()
	_build_shell()


func _build_shell() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var header := HBoxContainer.new()
	header.add_child(LabUi.heading("DATE SYSTEM LAB"))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	_status = Label.new()
	_status.text = "Готово"
	_status.add_theme_color_override("font_color", LabUi.MUTED)
	header.add_child(_status)
	root.add_child(header)
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(split)
	var nav := ItemList.new()
	nav.custom_minimum_size = Vector2(240, 0)
	for section in SECTIONS:
		nav.add_item(str(section[1]))
	nav.item_selected.connect(func(index: int) -> void:
		_show_section(str(SECTIONS[index][0]))
	)
	split.add_child(nav)
	_content_host = Control.new()
	_content_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(_content_host)
	nav.select(0)


func _show_section(section: String) -> void:
	_section = section
	for child in _content_host.get_children():
		_content_host.remove_child(child)
		child.queue_free()
	_play_panel = null
	_editor_root = null
	match section:
		"date":
			_play_panel = DatePlayPanel.new()
			_play_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
			_play_panel.setup(catalog_service, progress_store)
			_content_host.add_child(_play_panel)
			_play_panel.status_message.connect(_set_status)
		"validation":
			_content_host.add_child(_build_validation())
		"balance":
			_content_host.add_child(_build_balance())
		"test_state":
			_content_host.add_child(_build_test_state())
		_:
			_content_host.add_child(_build_editor())


func _set_status(text: String) -> void:
	_status.text = text


func _build_validation() -> Control:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(LabUi.heading("Валидация"))
	var btn := LabUi.button("ПРОВЕРИТЬ ВЕСЬ КОНТЕНТ")
	root.add_child(btn)
	var table := RichTextLabel.new()
	table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table.scroll_active = true
	root.add_child(table)
	btn.pressed.connect(func() -> void:
		var issues: Array[ContentValidationIssue] = validator.validate(catalog_service.catalog)
		if issues.is_empty():
			table.text = "Ошибок нет."
			_set_status("Валидация: OK")
			return
		var lines := PackedStringArray(["severity | code | resource_type | resource_id | field | message"])
		for issue in issues:
			var data: Dictionary = issue.to_dictionary()
			lines.append("%s | %s | %s | %s | %s | %s" % [data["severity"], data["code"], issue.resource_type, issue.resource_id, issue.field, issue.message])
		table.text = "\n".join(lines)
		_set_status("Валидация: %d проблем" % issues.size())
	)
	return root


func _build_balance() -> Control:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	root.add_child(LabUi.heading("Баланс"))
	var overview := RichTextLabel.new()
	overview.fit_content = true
	overview.scroll_active = false
	overview.bbcode_enabled = false
	overview.text = _balance_overview_text()
	root.add_child(overview)
	var tools := HBoxContainer.new()
	var seeds := SpinBox.new()
	seeds.min_value = 1
	seeds.max_value = 100000
	seeds.value = 10000
	tools.add_child(LabUi.labeled_row("Seeds", seeds))
	var btn := LabUi.button("СИМУЛИРОВАТЬ BASE")
	tools.add_child(btn)
	root.add_child(tools)
	var results := RichTextLabel.new()
	results.size_flags_vertical = Control.SIZE_EXPAND_FILL
	results.scroll_active = true
	root.add_child(results)
	btn.pressed.connect(func() -> void:
		_set_status("Симуляция BASE...")
		results.text = _run_balance_simulation(int(seeds.value))
		_set_status("Симуляция BASE завершена")
	)
	return root


func _balance_overview_text() -> String:
	var catalog: DateContentCatalog = catalog_service.catalog
	var lines := PackedStringArray(["Girl | Difficulty | Positive Tags | Negative Tags | Relationship Range | Theoretical positive availability"])
	var diagnostics := DateBalanceDiagnostics.new()
	for girl in catalog.girls:
		if girl == null or not girl.enabled:
			continue
		var preset: GirlDifficultyPreset = catalog.find_girl_difficulty(girl.difficulty_preset_id)
		var difficulty_name: String = preset.display_name if preset != null else String(girl.difficulty_preset_id)
		var enabled_count: int = catalog.enabled_tags().size()
		var positive_count: int = girl.positive_tag_ids.size()
		var theory: String = DateBalanceMath.format_percent(diagnostics.theoretical_availability(catalog, girl))
		lines.append("%s | %s | %d / %d | %d negative | %d..%d | %s" % [
			girl.display_name,
			difficulty_name,
			positive_count,
			enabled_count,
			girl.negative_tag_ids.size(),
			girl.relationship_min,
			girl.relationship_max,
			theory,
		])
	return "\n".join(lines)


func _run_balance_simulation(seed_count: int) -> String:
	var catalog: DateContentCatalog = catalog_service.catalog
	var diagnostics := DateBalanceDiagnostics.new()
	var lines := PackedStringArray()
	for girl in catalog.girls:
		if girl == null or not girl.enabled:
			continue
		var result: Dictionary = diagnostics.simulate_girl(catalog, girl, seed_count)
		lines.append(girl.display_name)
		for row in result["situations"]:
			lines.append("%s | episodes %d | at least one positive BASE %s | all negative BASE %s | average positive BASE %.2f" % [
				str(row["situation_name"]),
				int(row["episodes"]),
				DateBalanceMath.format_percent(float(row["at_least_one"])),
				DateBalanceMath.format_percent(float(row["all_negative"])),
				float(row["average_positive"]),
			])
		lines.append("aggregate | episodes %d | at least one positive BASE %s | all negative BASE %s | average positive BASE %.2f" % [
			int(result["episodes"]),
			DateBalanceMath.format_percent(float(result["at_least_one"])),
			DateBalanceMath.format_percent(float(result["all_negative"])),
			float(result["average_positive"]),
		])
		lines.append("")
	return "\n".join(lines)


func _build_test_state() -> Control:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(LabUi.heading("Тестовое состояние"))
	var player: TestPlayerState = progress_store.player_state
	for stat in catalog_service.catalog.progression_stats:
		var spin := SpinBox.new()
		spin.min_value = stat.min_level
		spin.max_value = stat.max_level
		spin.value = player.get_stat(stat.id)
		var stat_id: StringName = stat.id
		spin.value_changed.connect(func(value: float) -> void:
			player.set_stat(stat_id, int(value))
			progress_store.save_store()
			_show_section("test_state")
		)
		root.add_child(LabUi.labeled_row(stat.display_name, spin))
	var quality := SpinBox.new()
	quality.min_value = catalog_service.catalog.date_rules.apartment_quality_min
	quality.max_value = catalog_service.catalog.date_rules.apartment_quality_max
	quality.value = player.apartment_quality
	quality.value_changed.connect(func(value: float) -> void:
		player.apartment_quality = int(value)
		progress_store.save_store()
	)
	root.add_child(LabUi.labeled_row("Качество квартиры", quality))
	var prepared := CheckBox.new()
	prepared.text = "Подготовлена"
	prepared.button_pressed = player.apartment_prepared
	prepared.toggled.connect(func(pressed: bool) -> void:
		player.apartment_prepared = pressed
		progress_store.save_store()
	)
	root.add_child(LabUi.labeled_row("Подготовка квартиры", prepared))
	root.add_child(LabUi.heading("Открываемые ходы"))
	var header := Label.new()
	header.text = "Ход | Requirement | Current | State"
	root.add_child(header)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	scroll.add_child(list)
	for move in catalog_service.catalog.moves:
		if move.kind != DateTypes.DateMoveKind.UNLOCKABLE or move.unlock_requirement == null:
			continue
		var current: int = player.get_stat(move.unlock_requirement.stat_id)
		var unlocked: bool = current >= move.unlock_requirement.required_level
		var row := Label.new()
		var stat: ProgressionStat = catalog_service.catalog.find_stat(move.unlock_requirement.stat_id)
		row.text = "%s | %s %d | %d | %s" % [
			move.display_name,
			stat.display_name if stat != null else String(move.unlock_requirement.stat_id),
			move.unlock_requirement.required_level,
			current,
			"Unlocked" if unlocked else "Locked",
		]
		list.add_child(row)
	return root


func _build_editor() -> Control:
	_editor_root = VBoxContainer.new()
	_editor_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var tools := HBoxContainer.new()
	_search = LineEdit.new()
	_search.placeholder_text = "Поиск"
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(func(_t: String) -> void:
		_refresh_list()
	)
	tools.add_child(_search)
	for pair in [["Создать", _create_item], ["Дублировать", _duplicate_item], ["Удалить", _delete_item]]:
		var btn := LabUi.button(str(pair[0]))
		btn.pressed.connect(pair[1])
		tools.add_child(btn)
	_editor_root.add_child(tools)
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_editor_root.add_child(split)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(280, 0)
	_list.item_selected.connect(func(index: int) -> void:
		_select_index(index)
	)
	split.add_child(_list)
	var form_scroll := ScrollContainer.new()
	split.add_child(form_scroll)
	_form_host = VBoxContainer.new()
	_form_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_scroll.add_child(_form_host)
	_save_bar = HBoxContainer.new()
	var save_btn := LabUi.button("Сохранить")
	save_btn.pressed.connect(_save_item)
	var cancel_btn := LabUi.button("Отменить изменения")
	cancel_btn.pressed.connect(_cancel_item)
	_save_bar.add_child(save_btn)
	_save_bar.add_child(cancel_btn)
	_editor_root.add_child(_save_bar)
	_refresh_list()
	if _list.item_count > 0:
		_list.select(0)
		_select_index(0)
	return _editor_root


func _items() -> Array:
	var catalog: DateContentCatalog = catalog_service.catalog
	match _section:
		"girls":
			return catalog.girls
		"girl_difficulty":
			return catalog.girl_difficulty_presets
		"tags":
			return catalog.tags
		"base_moves":
			return _moves_of(DateTypes.DateMoveKind.BASE)
		"unlock_moves":
			return _moves_of(DateTypes.DateMoveKind.UNLOCKABLE)
		"situations":
			return catalog.situations
		"secondary":
			return catalog.secondary_rules
		"locations":
			return catalog.locations
		"formats":
			return catalog.location_formats
		"outfits":
			return catalog.outfits
		"stats":
			return catalog.progression_stats
		"rules":
			return [catalog.date_rules]
		_:
			return []


func _moves_of(kind: DateTypes.DateMoveKind) -> Array:
	var result: Array = []
	for move in catalog_service.catalog.moves:
		if move.kind == kind:
			result.append(move)
	return result


func _refresh_list() -> void:
	if _list == null:
		return
	_list.clear()
	var query: String = _search.text.to_lower() if _search != null else ""
	var enabled_count: int = catalog_service.catalog.enabled_tags().size() if catalog_service.catalog != null else 0
	for item in _items():
		if item == null:
			continue
		var label: String = "DateRules"
		if _section == "girl_difficulty":
			var positive_count: int = int(item.positive_tag_count)
			label = "%s | %d | %d" % [str(item.display_name), positive_count, maxi(0, enabled_count - positive_count)]
		else:
			if "display_name" in item:
				label = str(item.display_name)
			if "id" in item:
				label = "%s  [%s]" % [label, String(item.id)]
		if query.is_empty() or query in label.to_lower():
			_list.add_item(label)
			_list.set_item_metadata(_list.item_count - 1, item)


func _select_index(index: int) -> void:
	_selected_index = index
	var item: Resource = _list.get_item_metadata(index)
	_draft = item.duplicate(true)
	_dirty = false
	_rebuild_form()


func _rebuild_form() -> void:
	for child in _form_host.get_children():
		_form_host.remove_child(child)
		child.queue_free()
	if _draft == null:
		return
	match _section:
		"tags", "formats":
			_add_common_identity(_draft)
		"stats":
			_add_common_identity(_draft)
			_add_int(_draft, "min_level", "min_level")
			_add_int(_draft, "max_level", "max_level")
		"outfits":
			_add_common_identity(_draft)
			_add_int(_draft, "score_bonus", "score_bonus")
		"locations":
			_add_common_identity(_draft)
			_add_int(_draft, "base_quality_bonus", "base_quality_bonus")
			_add_enum(_draft, "preference_mode", "preference_mode", ["NEUTRAL", "THEMATIC"])
			_add_id_selector(_draft, "location_format_id", "location_format", catalog_service.catalog.location_formats)
			_add_bool(_draft, "uses_apartment_quality", "uses_apartment_quality")
			_add_bool(_draft, "uses_apartment_preparation", "uses_apartment_preparation")
		"secondary":
			_add_common_identity(_draft)
			_add_enum(_draft, "condition_type", "condition_type", ["DISTINCT_SUCCESS_TAGS", "NO_FAILURES"])
			_add_int(_draft, "success_score", "success_score")
			_add_int(_draft, "failure_score", "failure_score")
			_add_dict_params()
		"situations":
			_add_common_identity(_draft)
			_add_text(_draft, "situation_text", "situation_text")
			_add_phases()
			_add_float(_draft, "weight", "weight")
			_add_situation_move_lists()
		"girls":
			_add_girl_form()
		"girl_difficulty":
			_add_difficulty_form()
		"base_moves", "unlock_moves":
			_add_move_form()
		"rules":
			_add_rules_form()


func _add_common_identity(res: Resource) -> void:
	_add_string(res, "id", "id")
	_add_string(res, "display_name", "display_name")
	_add_text(res, "description", "description")
	if "enabled" in res:
		_add_bool(res, "enabled", "enabled")


func _add_string(res: Resource, property: String, title: String) -> void:
	var edit := LineEdit.new()
	edit.text = str(res.get(property))
	edit.text_changed.connect(func(value: String) -> void:
		if property == "id":
			res.set(property, StringName(value))
		else:
			res.set(property, value)
		_dirty = true
	)
	_form_host.add_child(LabUi.labeled_row(title, edit))


func _add_text(res: Resource, property: String, title: String) -> void:
	var edit := TextEdit.new()
	edit.custom_minimum_size = Vector2(0, 90)
	edit.text = str(res.get(property))
	edit.text_changed.connect(func() -> void:
		res.set(property, edit.text)
		_dirty = true
	)
	_form_host.add_child(LabUi.labeled_row(title, edit))


func _add_bool(res: Resource, property: String, title: String) -> void:
	var box := CheckBox.new()
	box.button_pressed = bool(res.get(property))
	box.toggled.connect(func(pressed: bool) -> void:
		res.set(property, pressed)
		_dirty = true
	)
	_form_host.add_child(LabUi.labeled_row(title, box))


func _add_int(res: Resource, property: String, title: String) -> void:
	_add_bounded_int(res, property, title, -99, 99, true)


func _add_bounded_int(res: Resource, property: String, title: String, min_value: int, max_value: int, unbounded: bool = false) -> void:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.allow_greater = unbounded
	spin.allow_lesser = unbounded
	spin.value = int(res.get(property))
	spin.value_changed.connect(func(value: float) -> void:
		res.set(property, int(value))
		_dirty = true
	)
	_form_host.add_child(LabUi.labeled_row(title, spin))


func _add_float(res: Resource, property: String, title: String) -> void:
	var spin := SpinBox.new()
	spin.step = 0.1
	spin.min_value = 0
	spin.max_value = 99
	spin.value = float(res.get(property))
	spin.value_changed.connect(func(value: float) -> void:
		res.set(property, value)
		_dirty = true
	)
	_form_host.add_child(LabUi.labeled_row(title, spin))


func _add_enum(res: Resource, property: String, title: String, names: Array) -> void:
	var button := OptionButton.new()
	for i in names.size():
		button.add_item(str(names[i]), i)
	button.select(int(res.get(property)))
	button.item_selected.connect(func(index: int) -> void:
		res.set(property, index)
		_dirty = true
	)
	_form_host.add_child(LabUi.labeled_row(title, button))


func _add_id_selector(res: Resource, property: String, title: String, items: Array) -> void:
	var button := OptionButton.new()
	button.add_item("—", 0)
	button.set_item_metadata(0, StringName())
	var selected: int = 0
	for i in items.size():
		button.add_item(str(items[i].display_name), i + 1)
		button.set_item_metadata(i + 1, items[i].id)
		if items[i].id == res.get(property):
			selected = i + 1
	button.select(selected)
	button.item_selected.connect(func(index: int) -> void:
		res.set(property, button.get_item_metadata(index))
		_dirty = true
	)
	_form_host.add_child(LabUi.labeled_row(title, button))


func _add_phases() -> void:
	var situation: DateSituation = _draft as DateSituation
	var row := HBoxContainer.new()
	for pair in [[DateTypes.DatePhase.OPENING, "OPENING"], [DateTypes.DatePhase.CORE, "CORE"], [DateTypes.DatePhase.CLOSING, "CLOSING"]]:
		var box := CheckBox.new()
		box.text = str(pair[1])
		box.button_pressed = situation.allowed_phases.has(int(pair[0]))
		var phase_value: int = int(pair[0])
		box.toggled.connect(func(pressed: bool) -> void:
			if pressed and not situation.allowed_phases.has(phase_value):
				situation.allowed_phases.append(phase_value)
			elif not pressed:
				situation.allowed_phases.erase(phase_value)
			_dirty = true
		)
		row.add_child(box)
	_form_host.add_child(LabUi.labeled_row("allowed_phases", row))


func _add_situation_move_lists() -> void:
	var situation: DateSituation = _draft as DateSituation
	var base_names: PackedStringArray = PackedStringArray()
	var unlock_names: PackedStringArray = PackedStringArray()
	for move in catalog_service.catalog.applicable_moves(situation.id, DateTypes.DateMoveKind.BASE):
		base_names.append(move.display_name)
	for move in catalog_service.catalog.applicable_moves(situation.id, DateTypes.DateMoveKind.UNLOCKABLE):
		unlock_names.append(move.display_name)
	var base := Label.new()
	base.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	base.text = "Applicable BASE Moves: %s" % ", ".join(base_names)
	var unlock := Label.new()
	unlock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	unlock.text = "Applicable UNLOCKABLE Moves: %s" % ", ".join(unlock_names)
	_form_host.add_child(base)
	_form_host.add_child(unlock)


func _add_dict_params() -> void:
	var rule: SecondaryRule = _draft as SecondaryRule
	var edit := TextEdit.new()
	edit.custom_minimum_size = Vector2(0, 90)
	edit.text = JSON.stringify(rule.condition_parameters)
	edit.text_changed.connect(func() -> void:
		var parsed: Variant = JSON.parse_string(edit.text)
		if parsed is Dictionary:
			rule.condition_parameters = parsed
			_dirty = true
	)
	_form_host.add_child(LabUi.labeled_row("condition_parameters", edit))


func _add_girl_form() -> void:
	var girl: GirlProfile = _draft as GirlProfile
	girl.sync_negative_tags(catalog_service.catalog.enabled_tags())
	_add_common_identity(girl)
	_add_int(girl, "relationship_min", "relationship_min")
	_add_int(girl, "relationship_start", "relationship_start")
	_add_int(girl, "relationship_max", "relationship_max")
	_add_girl_difficulty_selector(girl)
	var enabled_count: int = catalog_service.catalog.enabled_tags().size()
	var required: int = _positive_tag_required(girl)
	var positive_count: int = girl.positive_tag_ids.size()
	var required_label := Label.new()
	required_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	required_label.text = "Положительных тегов требуется: %d" % required
	_form_host.add_child(required_label)
	var negative_label := Label.new()
	negative_label.text = "Отрицательных тегов: %d" % maxi(0, enabled_count - required)
	_form_host.add_child(negative_label)
	var theory := Label.new()
	theory.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var draws: int = 3
	if catalog_service.catalog.date_rules != null:
		draws = catalog_service.catalog.date_rules.base_moves_per_episode
	var chance: float = DateBalanceMath.at_least_one_positive_probability(enabled_count, required, draws)
	theory.text = "Теоретическая базовая доступность положительного тега: %s" % DateBalanceMath.format_percent(chance)
	_form_host.add_child(theory)
	_add_id_selector(girl, "secondary_rule_id", "secondary_rule", catalog_service.catalog.secondary_rules)
	var counter := Label.new()
	counter.text = "Положительные теги: %d / %d" % [positive_count, required]
	_form_host.add_child(counter)
	var grid := GridContainer.new()
	grid.columns = 3
	for header in ["TAG", "НРАВИТСЯ", "НЕ НРАВИТСЯ"]:
		var title := Label.new()
		title.text = header
		grid.add_child(title)
	for tag in catalog_service.catalog.tags:
		if tag == null or not tag.enabled:
			continue
		var name_label := Label.new()
		name_label.text = tag.display_name
		grid.add_child(name_label)
		var selected: bool = girl.positive_tag_ids.has(tag.id)
		var like := CheckBox.new()
		like.button_pressed = selected
		var dislike := CheckBox.new()
		dislike.button_pressed = not selected
		var tag_id: StringName = tag.id
		like.toggled.connect(func(pressed: bool) -> void:
			_set_girl_liked_tag(girl, tag_id, pressed)
			_dirty = true
			_rebuild_form.call_deferred()
		)
		dislike.toggled.connect(func(pressed: bool) -> void:
			_set_girl_liked_tag(girl, tag_id, not pressed)
			_dirty = true
			_rebuild_form.call_deferred()
		)
		grid.add_child(like)
		grid.add_child(dislike)
	_form_host.add_child(grid)
	_form_host.add_child(LabUi.heading("Любимые форматы"))
	for format in catalog_service.catalog.location_formats:
		var box := CheckBox.new()
		box.text = format.display_name
		box.button_pressed = girl.favorite_location_format_ids.has(format.id)
		var format_id: StringName = format.id
		box.toggled.connect(func(pressed: bool) -> void:
			if pressed and not girl.favorite_location_format_ids.has(format_id):
				girl.favorite_location_format_ids.append(format_id)
			elif not pressed:
				girl.favorite_location_format_ids.erase(format_id)
			_dirty = true
		)
		_form_host.add_child(box)


func _add_girl_difficulty_selector(girl: GirlProfile) -> void:
	var button := OptionButton.new()
	var selected: int = 0
	var presets: Array[GirlDifficultyPreset] = catalog_service.catalog.enabled_girl_difficulty_presets()
	var current: GirlDifficultyPreset = catalog_service.catalog.find_girl_difficulty(girl.difficulty_preset_id)
	if current != null and not current.enabled:
		presets.append(current)
	for i in presets.size():
		var preset: GirlDifficultyPreset = presets[i]
		button.add_item(preset.display_name, i)
		button.set_item_metadata(i, preset.id)
		if preset.id == girl.difficulty_preset_id:
			selected = i
	if presets.is_empty():
		button.add_item("—", 0)
		button.set_item_metadata(0, StringName())
	else:
		button.select(selected)
	button.item_selected.connect(func(index: int) -> void:
		girl.difficulty_preset_id = button.get_item_metadata(index)
		_dirty = true
		_rebuild_form.call_deferred()
	)
	_form_host.add_child(LabUi.labeled_row("Сложность", button))


func _add_difficulty_form() -> void:
	var preset: GirlDifficultyPreset = _draft as GirlDifficultyPreset
	_add_string(preset, "id", "ID")
	_add_string(preset, "display_name", "Название")
	_add_text(preset, "description", "Описание")
	_add_bool(preset, "enabled", "Enabled")
	var enabled_count: int = catalog_service.catalog.enabled_tags().size()
	_add_bounded_int(preset, "positive_tag_count", "Количество положительных тегов", 1, maxi(1, enabled_count - 1))
	_add_int(preset, "sort_order", "Порядок")


func _positive_tag_required(girl: GirlProfile) -> int:
	if girl == null or catalog_service.catalog == null:
		return 0
	var preset: GirlDifficultyPreset = catalog_service.catalog.find_girl_difficulty(girl.difficulty_preset_id)
	if preset == null:
		return 0
	return preset.positive_tag_count


func _set_girl_liked_tag(girl: GirlProfile, tag_id: StringName, liked: bool) -> void:
	girl.positive_tag_ids.erase(tag_id)
	if liked:
		girl.positive_tag_ids.append(tag_id)
	girl.sync_negative_tags(catalog_service.catalog.enabled_tags())


func _add_move_form() -> void:
	var move: DateMove = _draft as DateMove
	_add_common_identity(move)
	if move.kind == DateTypes.DateMoveKind.UNLOCKABLE:
		if move.unlock_requirement == null:
			move.unlock_requirement = UnlockRequirement.new()
		_add_id_selector(move.unlock_requirement, "stat_id", "unlock stat", catalog_service.catalog.progression_stats)
		_add_int(move.unlock_requirement, "required_level", "required_level")
		_add_int(move, "max_uses_per_date", "max_uses_per_date")
	_form_host.add_child(LabUi.heading("Mappings"))
	var add_btn := LabUi.button("Добавить mapping")
	add_btn.pressed.connect(func() -> void:
		var mapping := DateMoveSituationMapping.new()
		move.situation_mappings.append(mapping)
		_dirty = true
		_rebuild_form()
	)
	_form_host.add_child(add_btn)
	for i in move.situation_mappings.size():
		_form_host.add_child(_mapping_editor(move, i))


func _mapping_editor(move: DateMove, index: int) -> PanelContainer:
	var mapping: DateMoveSituationMapping = move.situation_mappings[index]
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	panel.add_child(box)
	var sit := OptionButton.new()
	LabUi.fill_selector(sit, catalog_service.catalog.situations, mapping.situation_id)
	sit.item_selected.connect(func(selected: int) -> void:
		mapping.situation_id = sit.get_item_metadata(selected)
		_dirty = true
	)
	box.add_child(LabUi.labeled_row("Situation", sit))
	var tag := OptionButton.new()
	LabUi.fill_selector(tag, catalog_service.catalog.tags, mapping.tag_id)
	tag.item_selected.connect(func(selected: int) -> void:
		mapping.tag_id = tag.get_item_metadata(selected)
		_dirty = true
	)
	box.add_child(LabUi.labeled_row("Tag", tag))
	for pair in [["option_text", mapping.option_text], ["positive_result_text", mapping.positive_result_text], ["negative_result_text", mapping.negative_result_text]]:
		var edit := TextEdit.new()
		edit.custom_minimum_size = Vector2(0, 60)
		edit.text = str(pair[1])
		var field: String = str(pair[0])
		edit.text_changed.connect(func() -> void:
			mapping.set(field, edit.text)
			_dirty = true
		)
		box.add_child(LabUi.labeled_row(field, edit))
	var remove := Button.new()
	remove.text = "Удалить mapping"
	remove.pressed.connect(func() -> void:
		move.situation_mappings.remove_at(index)
		_dirty = true
		_rebuild_form()
	)
	box.add_child(remove)
	return panel


func _add_rules_form() -> void:
	var rules: DateRules = _draft as DateRules
	for prop in [
		"opening_episode_count", "core_episode_count", "closing_episode_count", "base_moves_per_episode",
		"opening_choice_score", "core_positive_score", "core_negative_score", "closing_positive_score", "closing_negative_score",
		"location_preference_success", "location_preference_failure", "apartment_unprepared_penalty",
		"apartment_quality_min", "apartment_quality_max",
	]:
		_add_int(rules, prop, prop)
	var enabled_count: int = catalog_service.catalog.enabled_tags().size()
	_add_bounded_int(rules, "min_distinct_base_tags_per_situation", "Минимум разных базовых тегов в ситуации", 1, maxi(1, enabled_count))
	_add_bool(rules, "allow_situation_repeats", "allow_situation_repeats")
	_add_bool(rules, "show_locked_unlockable_moves", "show_locked_unlockable_moves")
	_add_bool(rules, "reveal_tag_after_use", "reveal_tag_after_use")
	_add_bool(rules, "reveal_secondary_after_first_completed_date", "reveal_secondary_after_first_completed_date")


func _kind_name() -> String:
	match _section:
		"girls":
			return "GirlProfile"
		"girl_difficulty":
			return "GirlDifficultyPreset"
		"tags":
			return "DateTag"
		"base_moves", "unlock_moves":
			return "DateMove"
		"situations":
			return "DateSituation"
		"secondary":
			return "SecondaryRule"
		"locations":
			return "DateLocation"
		"formats":
			return "LocationFormat"
		"outfits":
			return "Outfit"
		"stats":
			return "ProgressionStat"
		"rules":
			return "DateRules"
		_:
			return ""


func _create_item() -> void:
	if _section == "rules":
		return
	var created: Resource = _new_resource()
	catalog_service.add_to_catalog(created)
	_draft = created
	_dirty = true
	_refresh_list()
	_rebuild_form()
	_set_status("Создан черновик. Сохраните, чтобы записать .tres.")


func _new_resource() -> Resource:
	var suffix: String = str(Time.get_ticks_msec())
	match _section:
		"girls":
			var girl := GirlProfile.new()
			girl.id = StringName("girl_%s" % suffix)
			girl.display_name = "Новая девушка"
			var starter: GirlDifficultyPreset = catalog_service.catalog.find_girl_difficulty(&"starter")
			if starter != null:
				girl.difficulty_preset_id = starter.id
			return girl
		"girl_difficulty":
			var preset := GirlDifficultyPreset.new()
			preset.id = StringName("difficulty_%s" % suffix)
			preset.display_name = "Новая сложность"
			preset.enabled = true
			preset.positive_tag_count = 4
			preset.sort_order = catalog_service.catalog.girl_difficulty_presets.size()
			return preset
		"tags":
			var tag := DateTag.new()
			tag.id = StringName("tag_%s" % suffix)
			tag.display_name = "Новый тег"
			return tag
		"base_moves", "unlock_moves":
			var move := DateMove.new()
			move.id = StringName("move_%s" % suffix)
			move.display_name = "Новый ход"
			move.kind = DateTypes.DateMoveKind.UNLOCKABLE if _section == "unlock_moves" else DateTypes.DateMoveKind.BASE
			move.max_uses_per_date = 1 if _section == "unlock_moves" else 0
			if _section == "unlock_moves":
				move.unlock_requirement = UnlockRequirement.new()
			return move
		"situations":
			var situation := DateSituation.new()
			situation.id = StringName("situation_%s" % suffix)
			situation.display_name = "Новая ситуация"
			situation.allowed_phases = [int(DateTypes.DatePhase.CORE)]
			return situation
		"secondary":
			var rule := SecondaryRule.new()
			rule.id = StringName("secondary_%s" % suffix)
			rule.display_name = "Новое Secondary"
			rule.condition_parameters = {
				"counted_phases": [
					int(DateTypes.DatePhase.OPENING),
					int(DateTypes.DatePhase.CORE),
					int(DateTypes.DatePhase.CLOSING),
				],
				"required_count": 3,
			}
			return rule
		"locations":
			var location := DateLocation.new()
			location.id = StringName("location_%s" % suffix)
			location.display_name = "Новое место"
			return location
		"formats":
			var format := LocationFormat.new()
			format.id = StringName("format_%s" % suffix)
			format.display_name = "Новый формат"
			return format
		"outfits":
			var outfit := Outfit.new()
			outfit.id = StringName("outfit_%s" % suffix)
			outfit.display_name = "Новый наряд"
			return outfit
		"stats":
			var stat := ProgressionStat.new()
			stat.id = StringName("stat_%s" % suffix)
			stat.display_name = "Новая характеристика"
			return stat
		_:
			return Resource.new()


func _duplicate_item() -> void:
	if _draft == null or _section == "rules":
		return
	var copy: Resource = _draft.duplicate(true)
	copy.id = StringName("%s_copy" % String(copy.id))
	copy.display_name = "%s (копия)" % str(copy.display_name)
	catalog_service.add_to_catalog(copy)
	_draft = copy
	_dirty = true
	_refresh_list()
	_rebuild_form()


func _delete_item() -> void:
	if _draft == null or _section == "rules":
		return
	var original: Resource = _list.get_item_metadata(_selected_index)
	var deps: Array[Dictionary] = catalog_service.find_dependents(original.id, _kind_name())
	var dialog := ConfirmationDialog.new()
	if deps.is_empty():
		dialog.dialog_text = "Удалить %s?" % String(original.id)
	else:
		var lines := PackedStringArray(["Объект используется:"])
		for dep in deps:
			lines.append("%s %s (%s)" % [dep["type"], dep["id"], dep["field"]])
		dialog.dialog_text = "\n".join(lines)
	add_child(dialog)
	dialog.confirmed.connect(func() -> void:
		var path: String = catalog_service.path_for(original)
		catalog_service.remove_from_catalog(original)
		if not path.is_empty() and FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		catalog_service.save_catalog()
		_draft = null
		_refresh_list()
		_rebuild_form()
		_set_status("Удалено.")
		dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void:
		dialog.queue_free()
	)
	dialog.popup_centered()


func _save_item() -> void:
	if _draft == null:
		return
	if _draft is GirlProfile:
		(_draft as GirlProfile).sync_negative_tags(catalog_service.catalog.enabled_tags())
	var temp_catalog: DateContentCatalog = catalog_service.catalog.snapshot()
	_swap_into(temp_catalog, _draft)
	var issues: Array[ContentValidationIssue] = validator.validate(temp_catalog)
	var blocking: Array[ContentValidationIssue] = []
	for issue in issues:
		if issue.severity != DateTypes.ValidationSeverity.ERROR:
			continue
		if issue.resource_id == String(_draft.get("id")) or _section == "rules":
			blocking.append(issue)
	if not blocking.is_empty() and _section != "rules":
		_set_status("Сохранение отклонено: %s" % blocking[0].message)
		return
	var original: Resource = _list.get_item_metadata(_selected_index) if _selected_index >= 0 and _selected_index < _list.item_count else null
	var path: String = catalog_service.path_for(original) if original != null else ""
	if path.is_empty():
		path = catalog_service.default_path_for(_kind_name(), String(_draft.get("id")))
	_draft.resource_path = path
	var err: Error = catalog_service.save_resource(_draft, path)
	if err != OK:
		_set_status("Ошибка ResourceSaver: %d" % err)
		return
	_replace_original(_draft)
	catalog_service.save_catalog()
	catalog_service.reload()
	progress_store.load_store(catalog_service.catalog)
	_set_status("Сохранено: %s" % path)
	_dirty = false
	_refresh_list()


func _cancel_item() -> void:
	if _selected_index >= 0:
		_select_index(_selected_index)
		_set_status("Изменения отменены.")


func _swap_into(catalog: DateContentCatalog, draft: Resource) -> void:
	if draft is DateRules:
		catalog.date_rules = draft
		return
	var arrays: Array = [catalog.tags, catalog.moves, catalog.situations, catalog.girls, catalog.girl_difficulty_presets, catalog.secondary_rules, catalog.location_formats, catalog.locations, catalog.outfits, catalog.progression_stats]
	for arr in arrays:
		for i in arr.size():
			if arr[i] != null and arr[i].id == draft.get("id"):
				arr[i] = draft
				return
	if draft is DateTag:
		catalog.tags.append(draft)
	elif draft is DateMove:
		catalog.moves.append(draft)
	elif draft is DateSituation:
		catalog.situations.append(draft)
	elif draft is GirlProfile:
		catalog.girls.append(draft)
	elif draft is GirlDifficultyPreset:
		catalog.girl_difficulty_presets.append(draft)
	elif draft is SecondaryRule:
		catalog.secondary_rules.append(draft)
	elif draft is LocationFormat:
		catalog.location_formats.append(draft)
	elif draft is DateLocation:
		catalog.locations.append(draft)
	elif draft is Outfit:
		catalog.outfits.append(draft)
	elif draft is ProgressionStat:
		catalog.progression_stats.append(draft)


func _replace_original(draft: Resource) -> void:
	if draft is DateRules:
		catalog_service.catalog.date_rules = draft
		return
	var found: bool = false
	var arrays: Array = [
		catalog_service.catalog.tags, catalog_service.catalog.moves, catalog_service.catalog.situations,
		catalog_service.catalog.girls, catalog_service.catalog.girl_difficulty_presets, catalog_service.catalog.secondary_rules, catalog_service.catalog.location_formats,
		catalog_service.catalog.locations, catalog_service.catalog.outfits, catalog_service.catalog.progression_stats,
	]
	for arr in arrays:
		for i in arr.size():
			if arr[i] != null and arr[i].id == draft.get("id"):
				arr[i] = draft
				found = true
	if not found:
		catalog_service.add_to_catalog(draft)
