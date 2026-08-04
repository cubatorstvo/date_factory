class_name TransitionOverlay
extends CanvasLayer

signal finished

@onready var shade: ColorRect = $Dim

var _active_tween: Tween


func _ready() -> void:
	if shade:
		shade.modulate.a = 0.0
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE


func fade_out(duration: float = 0.25) -> void:
	_tween_alpha(1.0, duration, true)


func fade_in(duration: float = 0.25) -> void:
	_tween_alpha(0.0, duration, false)


func run_blackout(out_duration: float, mid: Callable, in_duration: float, on_done: Callable = Callable()) -> void:
	## Sequenced fade-out → mid → fade-in bound to this CanvasLayer.
	var after_out := func() -> void:
		if mid.is_valid():
			mid.call()
		var after_in := func() -> void:
			if on_done.is_valid():
				on_done.call()
			finished.emit()
		_tween_alpha(0.0, in_duration, false, after_in)
	_tween_alpha(1.0, out_duration, true, after_out)


func _tween_alpha(target_alpha: float, duration: float, block_mouse: bool, on_complete: Callable = Callable()) -> void:
	show()
	if shade == null:
		if on_complete.is_valid():
			on_complete.call()
		else:
			finished.emit()
		return
	if block_mouse or target_alpha > 0.01:
		shade.mouse_filter = Control.MOUSE_FILTER_STOP
	if _active_tween != null:
		_active_tween.kill()
	_active_tween = create_tween()
	_active_tween.tween_property(shade, "modulate:a", target_alpha, maxf(0.01, duration))
	_active_tween.finished.connect(func() -> void:
		if target_alpha <= 0.01 and shade:
			shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if on_complete.is_valid():
			on_complete.call()
		else:
			finished.emit()
	, CONNECT_ONE_SHOT)
