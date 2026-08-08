class_name MeshEmissivePulse
extends RefCounted
## Short emissive charge on a MeshInstance3D (clone chamber / machine) — MODULE 23 §32.


static func play(mesh: MeshInstance3D, peak_energy: float = 2.4, duration: float = 0.45) -> void:
	if mesh == null or not is_instance_valid(mesh):
		return
	var mat: Material = mesh.material_override
	if mat == null:
		var std: StandardMaterial3D = StandardMaterial3D.new()
		std.albedo_color = Color(0.45, 0.75, 0.95, 1.0)
		std.emission_enabled = true
		std.emission = Color(0.35, 0.7, 1.0, 1.0)
		std.emission_energy_multiplier = 0.2
		mesh.material_override = std
		mat = std
	var std_mat: StandardMaterial3D = mat as StandardMaterial3D
	if std_mat == null:
		mesh.visible = true
		return
	std_mat.emission_enabled = true
	var base_energy: float = std_mat.emission_energy_multiplier
	var base_visible: bool = mesh.visible
	mesh.visible = true
	var dur: float = clampf(duration, 0.15, 1.0)
	var tween: Tween = mesh.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(std_mat, "emission_energy_multiplier", peak_energy, dur * 0.35)
	tween.tween_property(std_mat, "emission_energy_multiplier", base_energy, dur * 0.65)
	tween.finished.connect(
		func() -> void:
			if is_instance_valid(mesh):
				mesh.visible = base_visible
	)
