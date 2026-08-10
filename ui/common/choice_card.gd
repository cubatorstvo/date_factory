class_name ChoiceCard
extends PanelContainer

signal chosen

@onready var title_label: Label = %TitleLabel
@onready var detail_label: Label = %DetailLabel
@onready var action_button: Button = %ActionButton


func _ready() -> void:
	_bind_nodes()
	action_button.pressed.connect(func() -> void: chosen.emit())


func configure(title: String, detail: String, action_text: String = "Выбрать") -> void:
	_bind_nodes()
	title_label.text = title
	detail_label.text = detail
	action_button.text = action_text


func _bind_nodes() -> void:
	if title_label == null:
		title_label = find_child("TitleLabel", true, false) as Label
	if detail_label == null:
		detail_label = find_child("DetailLabel", true, false) as Label
	if action_button == null:
		action_button = find_child("ActionButton", true, false) as Button
