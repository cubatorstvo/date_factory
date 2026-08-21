class_name GuidancePopup
extends Control

signal dismissed

const KIND_TUTORIAL: StringName = &"tutorial"
const KIND_MILESTONE: StringName = &"milestone"

var _kind: StringName = &""
var _title_label: Label
var _body_host: VBoxContainer
var _button: Button


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(520, 0)
	center.add_child(card)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	_title_label = LabUi.heading("")
	box.add_child(_title_label)
	_body_host = VBoxContainer.new()
	_body_host.add_theme_constant_override("separation", 6)
	box.add_child(_body_host)
	_button = LabUi.button("ПОНЯТНО")
	_button.pressed.connect(_on_dismiss_pressed)
	box.add_child(_button)

func present_tutorial(definition: TutorialDefinition) -> void:
	if definition == null:
		return
	_kind = KIND_TUTORIAL
	_title_label.text = definition.title
	_button.text = "ПОНЯТНО"
	_set_body_lines(PackedStringArray([definition.body]))
	visible = true


func present_milestone(definition: MilestoneDefinition) -> void:
	if definition == null:
		return
	_kind = KIND_MILESTONE
	_title_label.text = definition.title
	_button.text = "ПРОДОЛЖИТЬ"
	_set_body_lines(definition.body_lines)
	visible = true


func close() -> void:
	visible = false
	_kind = &""


func _set_body_lines(lines: PackedStringArray) -> void:
	for child in _body_host.get_children():
		child.queue_free()
	for line in lines:
		var rtl: RichTextLabel = GameTermView.create(line)
		_body_host.add_child(rtl)


func _on_dismiss_pressed() -> void:
	close()
	dismissed.emit()
