class_name ConfirmationDialogView
extends Control

signal confirmed
signal cancelled

@onready var _message_label: Label = %MessageLabel
@onready var _yes_button: Button = %YesButton
@onready var _no_button: Button = %NoButton

var _on_confirm: Callable = Callable()
var _on_cancel: Callable = Callable()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiScaleHelper.apply_to_control(self)
	_yes_button.pressed.connect(_confirm)
	_no_button.pressed.connect(_cancel)


func open(
	message: String,
	on_confirm: Callable = Callable(),
	on_cancel: Callable = Callable(),
) -> void:
	_message_label.text = message
	_on_confirm = on_confirm
	_on_cancel = on_cancel
	visible = true
	_yes_button.grab_focus()


func close() -> void:
	visible = false
	_on_confirm = Callable()
	_on_cancel = Callable()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_cancel()
		get_viewport().set_input_as_handled()


func _confirm() -> void:
	var callback: Callable = _on_confirm
	close()
	confirmed.emit()
	if callback.is_valid():
		callback.call()


func _cancel() -> void:
	var callback: Callable = _on_cancel
	close()
	cancelled.emit()
	if callback.is_valid():
		callback.call()
