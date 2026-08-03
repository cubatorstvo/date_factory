class_name TransitionOverlay
extends CanvasLayer

signal finished

@onready var shade: ColorRect = $Dim

func _ready() -> void:
	shade.modulate.a = 0.0
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE

func fade_out(duration: float = 0.25) -> void:
	show()
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(shade, "modulate:a", 1.0, duration)
	await tween.finished
	finished.emit()

func fade_in(duration: float = 0.25) -> void:
	show()
	if shade:
		shade.modulate.a = 1.0
		shade.mouse_filter = Control.MOUSE_FILTER_STOP
		var tween := create_tween()
		tween.tween_property(shade, "modulate:a", 0.0, duration)
		await tween.finished
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	finished.emit()
