class_name LabUi
extends RefCounted

const BG := Color("1a1410")
const PANEL := Color("251c16")
const PANEL_ALT := Color("31241c")
const ACCENT := Color("d4a017")
const TEXT := Color("f2e6d4")
const MUTED := Color("a89880")
const POSITIVE := Color("3dba6a")
const NEGATIVE := Color("e05252")
const LOCKED := Color("6a5a4a")
const VENUE_SOURCE_LABEL := "ЛОКАЦИЯ"
const CANONICAL_DATE_VENUE_IDS: Array[StringName] = [&"apartment", &"cafe", &"leisure_center", &"restaurant"]
const APARTMENT_OBJECT_MAX := 12
const OUTFIT_TIER_CASUAL := 0
const CASUAL_DATE_OUTFIT_MESSAGE := "Для этого свидания нужен образ интереснее повседневного."
const CASUAL_DATE_OUTFIT_REQUIREMENT := "Одежда: выше «Повседневной»"


static func apply_theme(root: Control) -> void:
	var theme := Theme.new()
	theme.default_font_size = 16
	_style_panel(theme, "panel", "PanelContainer", PANEL)
	_style_panel(theme, "panel", "Panel", PANEL_ALT)
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_color", "LineEdit", TEXT)
	root.theme = theme
	root.modulate = Color.WHITE


static func _style_panel(theme: Theme, style_name: String, type: String, color: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(6)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	theme.set_stylebox(style_name, type, box)


static func heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", ACCENT)
	return label


static func button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 36)
	return btn


static func labeled_row(title: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label: RichTextLabel = GameTermView.create(title)
	label.custom_minimum_size = Vector2(220, 0)
	label.add_theme_color_override("default_color", MUTED)
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


static func fill_selector(button: OptionButton, items: Array, selected_id: StringName = &"") -> void:
	button.clear()
	var selected_index: int = 0
	for i in items.size():
		var item: Resource = items[i]
		button.add_item(str(item.display_name), i)
		button.set_item_metadata(i, item.id)
		if item.id == selected_id:
			selected_index = i
	if button.item_count > 0:
		button.select(selected_index)


static func tag_knowledge_color(knowledge: DateTypes.TagKnowledge) -> Color:
	match knowledge:
		DateTypes.TagKnowledge.POSITIVE:
			return POSITIVE
		DateTypes.TagKnowledge.NEGATIVE:
			return NEGATIVE
		_:
			return TEXT


static func tag_bbcode(display_name: String, knowledge: DateTypes.TagKnowledge, _locked: bool = false) -> String:
	var wrapped: String = "[b][lb]%s[rb][/b]" % display_name
	match knowledge:
		DateTypes.TagKnowledge.POSITIVE, DateTypes.TagKnowledge.NEGATIVE:
			return "[color=#%s]%s[/color]" % [tag_knowledge_color(knowledge).to_html(false), wrapped]
		_:
			return wrapped


static func tag_label(display_name: String, knowledge: DateTypes.TagKnowledge, _locked: bool = false) -> Control:
	var registry: GameTermRegistry = GameTermRegistry.from_shared_catalog()
	var term: GameTerm = registry.find_by_alias(display_name) if registry != null else null
	var knowledge_map: Dictionary = {}
	if term != null:
		knowledge_map[term.id] = knowledge
	var rtl: RichTextLabel = GameTermView.create("[%s]" % display_name, knowledge_map, registry)
	rtl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
	return rtl


static func tag_knowledge_row(title: String, catalog: DateContentCatalog, ids: Array[StringName], knowledge: DateTypes.TagKnowledge, unknown_count: int = -1) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var title_label := Label.new()
	title_label.text = title
	title_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(title_label)
	if ids.is_empty():
		var empty := Label.new()
		empty.text = "—"
		empty.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		row.add_child(empty)
		if unknown_count >= 0:
			row.add_child(_unknown_preference_label(unknown_count))
		return row
	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.alignment = FlowContainer.ALIGNMENT_BEGIN
	for tag_id in ids:
		var tag_name: String = String(tag_id)
		if catalog != null:
			var tag: DateTag = catalog.find_tag(tag_id)
			if tag != null:
				tag_name = tag.display_name
		flow.add_child(tag_label(tag_name, knowledge))
	if unknown_count >= 0:
		flow.add_child(_unknown_preference_label(unknown_count))
	row.add_child(flow)
	return row


static func _unknown_preference_label(unknown_count: int) -> Label:
	var unknown := Label.new()
	unknown.text = "(Неизвестно %d)" % unknown_count
	unknown.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	unknown.add_theme_color_override("font_color", MUTED)
	return unknown


static func trait_block(catalog: DateContentCatalog, girl: GirlProfile) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var girl_trait: GirlTrait = null
	if catalog != null and girl != null:
		girl_trait = catalog.find_trait(girl.trait_id)
	var title := Label.new()
	if girl_trait == null:
		title.text = "Особенность: —"
		box.add_child(title)
		return box
	title.text = "Особенность: %s" % girl_trait.display_name
	box.add_child(title)
	var description := Label.new()
	description.text = girl_trait.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", MUTED)
	box.add_child(description)
	return box


static func known_preference_block(catalog: DateContentCatalog, progress: GirlProgress, girl: GirlProfile = null) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var likes: Array[StringName] = []
	var dislikes: Array[StringName] = []
	var unknown_likes: int = 0
	var unknown_dislikes: int = 0
	if progress != null:
		likes = progress.known_positive_tag_ids(girl)
		dislikes = progress.known_negative_tag_ids(girl)
		unknown_likes = progress.unknown_positive_tag_count(girl, catalog)
		unknown_dislikes = progress.unknown_negative_tag_count(girl, catalog)
	box.add_child(tag_knowledge_row("Любит:", catalog, likes, DateTypes.TagKnowledge.POSITIVE, unknown_likes))
	box.add_child(tag_knowledge_row("Не любит:", catalog, dislikes, DateTypes.TagKnowledge.NEGATIVE, unknown_dislikes))
	return box


static func bbcode_block(text: String, default_color: Color = TEXT, tag_knowledge: Dictionary = {}) -> RichTextLabel:
	var rtl: RichTextLabel = GameTermView.create(text, tag_knowledge)
	rtl.add_theme_color_override("default_color", default_color)
	return rtl


static func tag_knowledge_map(progress: GirlProgress, girl: GirlProfile = null) -> Dictionary:
	var result: Dictionary = {}
	if progress == null:
		return result
	for tag_id in progress.known_positive_tag_ids(girl):
		result[tag_id] = DateTypes.TagKnowledge.POSITIVE
	for tag_id in progress.known_negative_tag_ids(girl):
		result[tag_id] = DateTypes.TagKnowledge.NEGATIVE
	return result


static func local_object_toolkit_bbcode(catalog: DateContentCatalog, object_id: StringName, _progress: GirlProgress = null, player: DatePlayerSnapshot = null) -> String:
	if catalog == null:
		return String(object_id)
	var local_object: DateLocalObject = catalog.find_local_object(object_id)
	if local_object == null:
		return String(object_id)
	var parts: PackedStringArray = PackedStringArray()
	for move_id in local_object.move_ids:
		var move: DateMove = catalog.find_move(move_id)
		if move == null:
			continue
		var tag_name: String = _move_tag_display_name(catalog, move)
		var chip: String = "[%s]" % tag_name
		var lock_suffix: String = _move_lock_suffix(catalog, move, player)
		if not lock_suffix.is_empty():
			chip += lock_suffix
		parts.append(chip)
	var tags_text: String = " / ".join(parts) if not parts.is_empty() else "—"
	return "%s — %s" % [local_object.display_name, tags_text]

static func canonical_date_venues(catalog: DateContentCatalog) -> Array[DateVenue]:
	var result: Array[DateVenue] = []
	if catalog == null:
		return result
	var by_id: Dictionary = {}
	for location in catalog.date_venues:
		if location == null:
			continue
		by_id[location.id] = location
	for venue_id in CANONICAL_DATE_VENUE_IDS:
		if by_id.has(venue_id):
			result.append(by_id[venue_id])
	return result


static func characteristic_requirement_text(stat_name: String, level: int) -> String:
	return "требуется %s ур. %d" % [stat_name, level]


static func characteristic_lock_suffix(stat_name: String, level: int) -> String:
	return " 🔒 %s" % characteristic_requirement_text(stat_name, level)


static func local_move_option_text(option: DateMoveOption) -> String:
	if option == null:
		return ""
	var tag_name: String = option.tag_display_name.strip_edges()
	var object_name: String = option.local_object_display_name.strip_edges()
	var action_text: String = option.option_text.strip_edges()
	if action_text.begins_with("[") and action_text.find("]") >= 0:
		return action_text
	if action_text.is_empty():
		action_text = option.display_name.strip_edges()
	if object_name.is_empty():
		return "[%s] %s" % [tag_name, action_text]
	return "[%s] %s: %s" % [tag_name, object_name, action_text]

static func outfit_tier_label(tier: int) -> String:
	return "Повседневная" if tier <= OUTFIT_TIER_CASUAL else "Одетый"


static func required_outfit_tier(definition: GirlDefinition) -> int:
	if definition == null:
		return OUTFIT_TIER_CASUAL
	var min_tier: int = OUTFIT_TIER_CASUAL
	for requirement in definition.date_requirements:
		if requirement is OutfitAboveCasualGirlRequirement:
			min_tier = maxi(min_tier, 1)
	return min_tier


static func outfit_preview_text(catalog: DateContentCatalog, outfit: Outfit) -> String:
	if outfit == null:
		return "Outfit: —"
	var lines := PackedStringArray()
	lines.append(outfit.display_name)
	lines.append("Story Stage: %d" % outfit.min_story_stage)
	lines.append("Outfit tier: %d · %s" % [outfit.tier, outfit_tier_label(outfit.tier)])
	if outfit.stat_id != &"" and catalog != null:
		var stat: CharacteristicDefinition = catalog.find_characteristic(outfit.stat_id)
		var stat_name: String = stat.display_name if stat != null else String(outfit.stat_id)
		lines.append("%s +1" % stat_name)
	elif outfit.stat_id != &"":
		lines.append("%s +1" % String(outfit.stat_id))
	if outfit.has_outfit_move() and catalog != null:
		var outfit_move: DateMove = catalog.find_move(outfit.outfit_move_id)
		if outfit_move != null:
			var tag: DateTag = catalog.find_tag(outfit_move.fixed_tag_id)
			var tag_name: String = tag.display_name if tag != null else String(outfit_move.fixed_tag_id)
			lines.append("Outfit Move: [%s] %s" % [tag_name, outfit_move.display_name])
		else:
			lines.append("Outfit Move: —")
	else:
		lines.append("Outfit Move: —")
	return "\n".join(lines)


static func outfit_eligibility_text(required_tier: int, current_tier: int) -> String:
	var satisfied: bool = current_tier >= required_tier
	return "Минимум Outfit tier: %d (%s)\nТекущий tier: %d (%s)\n%s" % [
		required_tier,
		outfit_tier_label(required_tier),
		current_tier,
		outfit_tier_label(current_tier),
		"подходит" if satisfied else "не подходит",
	]


static func apartment_yes_no(value: bool) -> String:
	return "Да" if value else "Нет"


static func apartment_accent_label(accent_name: String) -> String:
	var name: String = accent_name.strip_edges()
	return name if not name.is_empty() else "Нет"


static func apartment_object_local_id(object_def: ApartmentObjectDefinition) -> StringName:
	if object_def == null:
		return &""
	if object_def.has_method("local_object_id"):
		return object_def.local_object_id()
	var value: Variant = object_def.get("local_object_id")
	if typeof(value) == TYPE_STRING_NAME:
		return value
	if typeof(value) == TYPE_STRING:
		return StringName(value)
	return object_def.id


static func apartment_summary_text(owned_count: int, prepared: bool, accent_name: String, owned_max: int = APARTMENT_OBJECT_MAX) -> String:
	return "Квартира\nПредметы: %d / %d\nПодготовлена: %s\nАкцент интерьера: %s" % [
		owned_count,
		owned_max,
		apartment_yes_no(prepared),
		apartment_accent_label(accent_name),
	]


static func venue_card_bbcode(
	catalog: DateContentCatalog,
	location: DateVenue,
	object_ids: Array[StringName],
	progress: GirlProgress = null,
	player: DatePlayerSnapshot = null,
	girl: GirlProfile = null,
	source_uses: int = 1,
	owned_count: int = -1,
	owned_max: int = APARTMENT_OBJECT_MAX,
	accent_object_id: StringName = &"",
	sonya_bonus: bool = false,
	prepared_state: int = -1
) -> String:
	var lines := PackedStringArray()
	if location == null:
		return ""
	lines.append("%s — $%d" % [location.display_name, location.price])
	if sonya_bonus and location.id == &"restaurant":
		lines.append("Локальный ход ×2 — постоянный столик Сони")
	else:
		lines.append("Локальный ход ×%d" % maxi(source_uses, 1))
	var is_apartment: bool = location.id == &"apartment" or location.uses_apartment_preparation
	if is_apartment and owned_count >= 0:
		lines.append("Предметы: %d / %d" % [owned_count, owned_max])
	if is_apartment and prepared_state >= 0:
		lines.append("Подготовлена: %s" % apartment_yes_no(prepared_state > 0))
	var accent_name: String = ""
	if accent_object_id != &"" and catalog != null:
		var accent_object: DateLocalObject = catalog.find_local_object(accent_object_id)
		if accent_object != null:
			accent_name = accent_object.display_name
	if is_apartment:
		lines.append("Акцент интерьера: %s" % apartment_accent_label(accent_name))
	var girl_trait: GirlTrait = null
	if catalog != null and girl != null:
		girl_trait = catalog.find_trait(girl.trait_id)
	if girl_trait != null and girl_trait.kind == GirlTrait.Kind.VENUE and girl_trait.date_venue_id == location.id:
		lines.append("Особенность девушки: +1 к результату свидания здесь")
	lines.append("")
	for object_id in object_ids:
		var local_object: DateLocalObject = catalog.find_local_object(object_id) if catalog != null else null
		if local_object == null:
			continue
		if is_apartment:
			var move: DateMove = catalog.find_move(local_object.move_ids[0]) if not local_object.move_ids.is_empty() else null
			var tag_name: String = _move_tag_display_name(catalog, move)
			lines.append("[%s] %s" % [tag_name, local_object.display_name])
		else:
			for move_id in local_object.move_ids:
				var move: DateMove = catalog.find_move(move_id)
				if move == null:
					continue
				var tag_name: String = _move_tag_display_name(catalog, move)
				var line: String = "[%s]" % tag_name
				var requirement: String = _move_requirement_text(catalog, move)
				if not requirement.is_empty():
					line += " %s" % requirement
				lines.append(line)
	if is_apartment and not accent_name.is_empty():
		lines.append("Положительный локальный ход: +2")
	return "\n".join(lines)

static func _move_tag_display_name(catalog: DateContentCatalog, move: DateMove) -> String:
	if move == null:
		return ""
	if catalog != null:
		var tag: DateTag = catalog.find_tag(move.fixed_tag_id)
		if tag != null:
			return tag.display_name
	return String(move.fixed_tag_id)


static func _move_requirement_text(catalog: DateContentCatalog, move: DateMove) -> String:
	if move == null or move.unlock_requirement == null:
		return ""
	var stat_name: String = String(move.unlock_requirement.stat_id)
	if catalog != null:
		var stat: CharacteristicDefinition = catalog.find_characteristic(move.unlock_requirement.stat_id)
		if stat != null:
			stat_name = stat.display_name
	return characteristic_requirement_text(stat_name, move.unlock_requirement.required_level)


static func _move_lock_suffix(catalog: DateContentCatalog, move: DateMove, player: DatePlayerSnapshot) -> String:
	if move == null or move.unlock_requirement == null:
		return ""
	var required_level: int = move.unlock_requirement.required_level
	if player != null and player.get_stat(move.unlock_requirement.stat_id) >= required_level:
		return ""
	var stat_name: String = String(move.unlock_requirement.stat_id)
	if catalog != null:
		var stat: CharacteristicDefinition = catalog.find_characteristic(move.unlock_requirement.stat_id)
		if stat != null:
			stat_name = stat.display_name
	return characteristic_lock_suffix(stat_name, required_level)

static func signed(value: int) -> String:
	return "0" if value == 0 else "%+d" % value


static func score_color(value: int) -> Color:
	if value > 0:
		return POSITIVE
	if value < 0:
		return NEGATIVE
	return MUTED


static func tally_row(title: String, value: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var color: Color = score_color(value)
	var name_label: RichTextLabel = GameTermView.create(title)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("normal_font_size", 22)
	name_label.add_theme_color_override("default_color", color)
	row.add_child(name_label)
	var value_label := Label.new()
	value_label.text = signed(value)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 22)
	value_label.add_theme_color_override("font_color", color)
	row.add_child(value_label)
	return row
