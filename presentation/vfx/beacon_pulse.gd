class_name BeaconPulse
extends RefCounted
## Final signal beacon pulse (Label3D / Node3D) — MODULE 23 §32.


static func play_label(label: Label3D, duration: float = 0.55) -> void:
	if label == null or not is_instance_valid(label):
		return
	var dur: float = clampf(duration, 0.2, 1.2)
	var base_mod: Color = label.modulate
	var peak: Color = Color(
		minf(base_mod.r * 1.35, 1.5),
		minf(base_mod.g * 1.25, 1.5),
		minf(base_mod.b * 1.45, 1.6),
		1.0,
	)
	var base_scale: Vector3 = label.scale
	var peak_scale: Vector3 = base_scale * 1.06
	var tween: Tween = label.create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(label, "modulate", peak, dur * 0.4)
	tween.parallel().tween_property(label, "scale", peak_scale, dur * 0.4)
	tween.tween_property(label, "modulate", base_mod, dur * 0.6)
	tween.parallel().tween_property(label, "scale", base_scale, dur * 0.6)


static func play_on_location(location: Node, beacon_name: String = "FinalSignalBeacon") -> void:
	if location == null or not is_instance_valid(location):
		return
	var found: Node = location.find_child(beacon_name, true, false)
	if found is Label3D:
		play_label(found as Label3D)
