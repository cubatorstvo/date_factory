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


static func tag_label(display_name: String, knowledge: DateTypes.TagKnowledge) -> Label:
	var label := Label.new()
	label.text = "[%s]" % display_name
	match knowledge:
		DateTypes.TagKnowledge.POSITIVE:
			label.add_theme_color_override("font_color", POSITIVE)
		DateTypes.TagKnowledge.NEGATIVE:
			label.add_theme_color_override("font_color", NEGATIVE)
	return label


static func tag_bbcode(display_name: String, knowledge: DateTypes.TagKnowledge) -> String:
	var wrapped: String = "[lb]%s[rb]" % display_name
	match knowledge:
		DateTypes.TagKnowledge.POSITIVE:
			return "[color=#%s]%s[/color]" % [POSITIVE.to_html(false), wrapped]
		DateTypes.TagKnowledge.NEGATIVE:
			return "[color=#%s]%s[/color]" % [NEGATIVE.to_html(false), wrapped]
		_:
			return wrapped


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
