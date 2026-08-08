class_name UiAccentPulse
extends RefCounted
## Brief Control modulate pulse for dating / badge accents (MODULE 23 §32).


static func play(control: Control, accent: Color, duration: float = 0.20) -> void:
	if control == null or not is_instance_valid(control):
		return
	var dur: float = clampf(duration, 0.12, 0.35)
	var base: Color = control.modulate
	var tween: Tween = control.create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate", accent, dur * 0.4)
	tween.tween_property(control, "modulate", base, dur * 0.6)


static func play_dating_reaction(control: Control, reaction: int) -> void:
	var accent: Color = Color(1.0, 1.0, 1.0, 1.0)
	if reaction > 0:
		accent = Color(1.15, 1.12, 0.85, 1.0)
	elif reaction < 0:
		accent = Color(1.12, 0.88, 0.88, 1.0)
	else:
		accent = Color(1.05, 1.05, 1.05, 1.0)
	play(control, accent, 0.20)


static func play_badge(control: Control) -> void:
	play(control, Color(1.18, 1.14, 0.92, 1.0), 0.22)
