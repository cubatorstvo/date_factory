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
	var label := Label.new()
	label.text = title
	label.custom_minimum_size = Vector2(220, 0)
	label.add_theme_color_override("font_color", MUTED)
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


static func tag_bbcode(display_name: String, knowledge: DateTypes.TagKnowledge, locked: bool = false) -> String:
	var wrapped: String = "[lb]%s[rb]" % display_name
	if locked:
		wrapped += " 🔒"
	match knowledge:
		DateTypes.TagKnowledge.POSITIVE, DateTypes.TagKnowledge.NEGATIVE:
			return "[color=#%s]%s[/color]" % [tag_knowledge_color(knowledge).to_html(false), wrapped]
		_:
			return wrapped


static func tag_label(display_name: String, knowledge: DateTypes.TagKnowledge, locked: bool = false) -> Label:
	var label := Label.new()
	label.text = "[%s]" % display_name
	if locked:
		label.text += " 🔒"
	match knowledge:
		DateTypes.TagKnowledge.POSITIVE, DateTypes.TagKnowledge.NEGATIVE:
			label.add_theme_color_override("font_color", tag_knowledge_color(knowledge))
	return label


static func tag_knowledge_row(title: String, catalog: DateContentCatalog, ids: Array[StringName], knowledge: DateTypes.TagKnowledge) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var title_label := Label.new()
	title_label.text = title
	row.add_child(title_label)
	if ids.is_empty():
		var empty := Label.new()
		empty.text = "—"
		row.add_child(empty)
		return row
	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for tag_id in ids:
		var tag_name: String = String(tag_id)
		if catalog != null:
			var tag: DateTag = catalog.find_tag(tag_id)
			if tag != null:
				tag_name = tag.display_name
		flow.add_child(tag_label(tag_name, knowledge))
	row.add_child(flow)
	return row


static func known_preference_block(catalog: DateContentCatalog, progress: GirlProgress) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var likes: Array[StringName] = []
	var dislikes: Array[StringName] = []
	if progress != null:
		likes = progress.revealed_positive_tag_ids
		dislikes = progress.revealed_negative_tag_ids
	box.add_child(tag_knowledge_row("Любит:", catalog, likes, DateTypes.TagKnowledge.POSITIVE))
	box.add_child(tag_knowledge_row("Не любит:", catalog, dislikes, DateTypes.TagKnowledge.NEGATIVE))
	return box


static func bbcode_block(text: String, default_color: Color = TEXT) -> RichTextLabel:
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtl.add_theme_color_override("default_color", default_color)
	rtl.text = text
	return rtl


static func local_object_toolkit_bbcode(catalog: DateContentCatalog, object_id: StringName, progress: GirlProgress = null, player: TestPlayerState = null) -> String:
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
		var tag: DateTag = catalog.find_tag(move.local_tag_id)
		var tag_name: String = tag.display_name if tag != null else String(move.local_tag_id)
		var knowledge: DateTypes.TagKnowledge = DateTypes.TagKnowledge.UNKNOWN
		if progress != null:
			knowledge = progress.tag_knowledge(move.local_tag_id)
		var locked: bool = false
		var req_text: String = ""
		if move.unlock_requirement != null:
			var stat: ProgressionStat = catalog.find_stat(move.unlock_requirement.stat_id)
			var stat_name: String = stat.display_name if stat != null else String(move.unlock_requirement.stat_id)
			req_text = " (%s %d)" % [stat_name, move.unlock_requirement.required_level]
			if player != null:
				locked = player.get_stat(move.unlock_requirement.stat_id) < move.unlock_requirement.required_level
		parts.append("%s%s" % [tag_bbcode(tag_name, knowledge, locked), req_text])
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
	var name_label := Label.new()
	name_label.text = title
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", score_color(value))
	row.add_child(name_label)
	var value_label := Label.new()
	value_label.text = signed(value)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 22)
	value_label.add_theme_color_override("font_color", score_color(value))
	row.add_child(value_label)
	return row
