class_name MinigameResultOverlay
extends Control

@onready var _title_label: Label = %OutcomeTitle
@onready var _detail_label: Label = %OutcomeDetail


func configure(title: String, detail: String, color: Color) -> void:
	_bind_nodes()
	_title_label.text = title
	_title_label.add_theme_color_override(&"font_color", color)
	_detail_label.text = detail


func _bind_nodes() -> void:
	if _title_label == null:
		_title_label = find_child("OutcomeTitle", true, false) as Label
	if _detail_label == null:
		_detail_label = find_child("OutcomeDetail", true, false) as Label
