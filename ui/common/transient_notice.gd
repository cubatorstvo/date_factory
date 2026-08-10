class_name TransientNotice
extends CanvasLayer

@onready var _label: Label = %MessageLabel


func show_message(message: String, duration: float = 1.5) -> void:
	_label.text = message
	visible = true
	if duration <= 0.0:
		return
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(self):
		queue_free()
