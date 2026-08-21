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
		var tag: DateTag = catalog.find_tag(move.fixed_tag_id)
		var tag_name: String = tag.display_name if tag != null else String(move.fixed_tag_id)
		var locked: bool = false
		var lock_suffix: String = ""
		if move.unlock_requirement != null and player != null:
			var current_level: int = player.get_stat(move.unlock_requirement.stat_id)
			var required_level: int = move.unlock_requirement.required_level
			if current_level < required_level:
				locked = true
				var stat: CharacteristicDefinition = catalog.find_characteristic(move.unlock_requirement.stat_id)
				var stat_name: String = stat.display_name if stat != null else String(move.unlock_requirement.stat_id)
				lock_suffix = " 🔒 Требуется: %s %d (сейчас %d)" % [stat_name, required_level, current_level]
		var chip: String = "[%s]" % tag_name
		if locked:
			chip += lock_suffix
		parts.append(chip)
	var tags_text: String = " / ".join(parts) if not parts.is_empty() else "—"
	return "%s — %s" % [local_object.display_name, tags_text]


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
