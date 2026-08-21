class_name ObjectivePanel
extends VBoxContainer

var _title: RichTextLabel
var _description: RichTextLabel
var _subgoal_host: VBoxContainer
var _next_step: RichTextLabel


func _ready() -> void:
	add_theme_constant_override("separation", 4)
	var heading: RichTextLabel = GameTermView.create("ЦЕЛЬ")
	heading.add_theme_font_size_override("normal_font_size", 18)
	add_child(heading)
	_title = heading
	_description = GameTermView.create("")
	_description.add_theme_color_override("default_color", LabUi.MUTED)
	add_child(_description)
	_subgoal_host = VBoxContainer.new()
	_subgoal_host.add_theme_constant_override("separation", 2)
	add_child(_subgoal_host)
	_next_step = GameTermView.create("")
	add_child(_next_step)


func bind(view: ObjectiveView) -> void:
	if _title == null:
		return
	if view == null or view.title.is_empty():
		visible = false
		return
	visible = true
	GameTermView.apply(_title, "ЦЕЛЬ — %s" % view.title)
	GameTermView.apply(_description, view.description)
	_description.visible = not view.description.is_empty()
	for child in _subgoal_host.get_children():
		child.queue_free()
	for subgoal in view.subgoals:
		_subgoal_host.add_child(_subgoal_label(subgoal))
	GameTermView.apply(_next_step, view.next_step_text)
	_next_step.visible = not view.next_step_text.is_empty()


func collect_text() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append(_plain(_title))
	if _description.visible:
		lines.append(_plain(_description))
	for child in _subgoal_host.get_children():
		var rtl: RichTextLabel = child as RichTextLabel
		if rtl != null:
			lines.append(_plain(rtl))
	if _next_step.visible:
		lines.append(_plain(_next_step))
	return "\n".join(lines)


func _subgoal_label(subgoal: ObjectiveSubgoalView) -> RichTextLabel:
	var mark: String = "✓" if subgoal.completed else "○"
	var line: String = "%s %s" % [mark, subgoal.label]
	if not subgoal.progress_text.is_empty():
		line += " — %s" % subgoal.progress_text
	var rtl: RichTextLabel = GameTermView.create(line)
	if subgoal.completed:
		rtl.modulate = Color(LabUi.MUTED.r, LabUi.MUTED.g, LabUi.MUTED.b, 0.85)
	elif subgoal.is_current:
		rtl.add_theme_color_override("default_color", LabUi.ACCENT)
	return rtl


func _plain(rtl: RichTextLabel) -> String:
	if rtl == null:
		return ""
	return rtl.get_parsed_text()
