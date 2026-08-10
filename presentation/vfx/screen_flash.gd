class_name ScreenFlash
extends RefCounted
## Fullscreen canvas flash — presentation only (MODULE 23 §31–32).

const DEFAULT_LAYER: int = 110
const SCENE_PATH: String = "res://presentation/vfx/screen_flash.tscn"


static func play(
	host: Node,
	color: Color = Color(1.0, 1.0, 1.0, 0.88),
	duration: float = 0.25,
	layer: int = DEFAULT_LAYER,
) -> void:
	if host == null or not is_instance_valid(host):
		return
	var dur: float = clampf(duration, 0.05, 0.60)
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	if packed == null:
		return
	var canvas: CanvasLayer = packed.instantiate() as CanvasLayer
	if canvas == null:
		return
	canvas.layer = layer
	var rect: ColorRect = canvas.get_node_or_null("Flash") as ColorRect
	if rect == null:
		canvas.free()
		return
	rect.color = color
	host.add_child(canvas)
	var tween: Tween = canvas.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(rect, "color:a", 0.0, dur)
	tween.finished.connect(
		func() -> void:
			if is_instance_valid(canvas):
				canvas.queue_free()
	)


static func play_media_shutter(host: Node) -> void:
	play(host, Color(1.0, 1.0, 1.0, 0.92), 0.25, DEFAULT_LAYER)


static func play_slap_impact(host: Node, perfect: bool = false) -> void:
	var alpha: float = 0.55 if perfect else 0.38
	play(host, Color(1.0, 0.96, 0.92, alpha), 0.10 if perfect else 0.09, DEFAULT_LAYER)


static func play_clone_reveal(host: Node) -> void:
	play(host, Color(0.85, 0.95, 1.0, 0.55), 0.22, DEFAULT_LAYER)
