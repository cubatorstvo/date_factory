class_name SaveSlotCard
extends PanelContainer

signal save_pressed
signal load_pressed
signal delete_pressed

@onready var _title_label: Label = %TitleLabel
@onready var _body_label: Label = %BodyLabel
@onready var _save_button: Button = %SaveButton
@onready var _load_button: Button = %LoadButton
@onready var _delete_button: Button = %DeleteButton


func _ready() -> void:
	_bind_nodes()
	_save_button.pressed.connect(func() -> void: save_pressed.emit())
	_load_button.pressed.connect(func() -> void: load_pressed.emit())
	_delete_button.pressed.connect(func() -> void: delete_pressed.emit())


func configure(
	title: String,
	body: String,
	save_mode: bool,
	can_load: bool,
	can_delete: bool,
) -> void:
	_bind_nodes()
	_title_label.text = title
	_body_label.text = body
	_save_button.visible = save_mode
	_load_button.visible = not save_mode
	_load_button.disabled = not can_load
	_delete_button.visible = can_delete


func _bind_nodes() -> void:
	if _title_label == null:
		_title_label = find_child("TitleLabel", true, false) as Label
	if _body_label == null:
		_body_label = find_child("BodyLabel", true, false) as Label
	if _save_button == null:
		_save_button = find_child("SaveButton", true, false) as Button
	if _load_button == null:
		_load_button = find_child("LoadButton", true, false) as Button
	if _delete_button == null:
		_delete_button = find_child("DeleteButton", true, false) as Button
