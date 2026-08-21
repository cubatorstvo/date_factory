class_name GuidancePopup
extends Control

signal dismissed

const KIND_TUTORIAL: StringName = &"tutorial"
const KIND_MILESTONE: StringName = &"milestone"

var _kind: StringName = &""
var _title_label: Label
var _body_host: VBoxContainer
var _button: Button
var _dim: ColorRect
var _center: CenterContainer


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.55)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)
	_center = CenterContainer.new()
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_center)
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(520, 0)
	_center.add_child(card)
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
	_fit_to_viewport()
	var viewport: Viewport = get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_fit_to_viewport):
		viewport.size_changed.connect(_fit_to_viewport)


func _exit_tree() -> void:
	var viewport: Viewport = get_viewport()
	if viewport != null and viewport.size_changed.is_connected(_fit_to_viewport):
		viewport.size_changed.disconnect(_fit_to_viewport)


func present_tutorial(definition: TutorialDefinition) -> void:
	if definition == null:
		return
	_kind = KIND_TUTORIAL
	_title_label.text = definition.title
	_button.text = "ПОНЯТНО"
	_set_body_lines(PackedStringArray([definition.body]))
	visible = true
	_fit_to_viewport()
	call_deferred("_fit_to_viewport")


func present_milestone(definition: MilestoneDefinition) -> void:
	if definition == null:
		return
	_kind = KIND_MILESTONE
	_title_label.text = definition.title
	_button.text = "ПРОДОЛЖИТЬ"
	_set_body_lines(definition.body_lines)
	visible = true
	_fit_to_viewport()
	call_deferred("_fit_to_viewport")


func close() -> void:
	visible = false
	_kind = &""


func _set_body_lines(lines: PackedStringArray) -> void:
	for child in _body_host.get_children():
		child.queue_free()
	for line in lines:
		var rtl: RichTextLabel = GameTermView.create(line)
		_body_host.add_child(rtl)


func _fit_to_viewport() -> void:
	_apply_full_rect(self)
	_apply_full_rect(_dim)
	_apply_full_rect(_center)


func _apply_full_rect(control: Control) -> void:
	if control == null or not control.is_inside_tree():
		return
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _on_dismiss_pressed() -> void:
	close()
	dismissed.emit()
