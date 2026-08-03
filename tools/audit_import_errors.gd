extends SceneTree
## Scan imported packs for load/mesh/material issues. Writes ASSET_IMPORT_ERRORS.md


const OUT := "res://docs/ASSET_IMPORT_ERRORS.md"

var _issues: Array[Dictionary] = []
var _checked := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var packs := {
		"PACK_001": "res://assets/environment/city/downtown_megakit",
		"PACK_002": "res://assets/environment/factory/kenney_factory",
		"PACK_015": "res://assets/environment/lab/scifi_essentials",
		"PACK_016": "res://assets/environment/restaurant/sushi_restaurant",
		"PACK_017": "res://assets/props/food",
		"PACK_018": "res://assets/environment/interior/house_interior",
		"PACK_019": "res://assets/characters/women_modular",
		"PACK_020": "res://assets/animation/universal_library",
		"PACK_021": "res://assets/characters/hero_base",
	}
	for pack_id in packs.keys():
		await _scan_pack(str(pack_id), str(packs[pack_id]))

	# Known structural limitations (not silent)
	_issues.append({
		"pack": "PACK_019",
		"resource": "UAL retarget",
		"path": "res://assets/animation/universal_library/libraries/DF_UAL_Aliases.res",
		"type": "skeleton_mismatch",
		"cause": "Women skeletons (62 bones, Root/Hips) differ from UAL (65 bones, root/pelvis)",
		"fix": "Women use DF_Women_Aliases from embedded PACK_019 clips; UAL reserved for Hero/Clone",
		"status": "MITIGATED",
	})
	_issues.append({
		"pack": "PACK_019",
		"resource": "sit/stand aliases",
		"path": "res://assets/animation/universal_library/libraries/DF_Women_Aliases.res",
		"type": "missing_clip_fallback",
		"cause": "No Sitting_Enter/Sitting_Exit in Modular Women individuals",
		"fix": "sit->Idle_Neutral (loop), stand->Idle (oneshot) technical fallbacks",
		"status": "OPEN_LIMITATION",
	})
	_issues.append({
		"pack": "PACK_015",
		"resource": "lab terminals",
		"path": "res://assets/environment/lab/scifi_essentials",
		"type": "content_gap",
		"cause": "Pack is combat/sci-fi props; dedicated lab terminals scarce",
		"fix": "Use available desk/locker/drone meshes + blockout in Clone_Lab_Base",
		"status": "OPEN_LIMITATION",
	})

	_write_report()
	print("AUDIT checked=", _checked, " issues=", _issues.size())
	quit(0)


func _scan_pack(pack_id: String, res_dir: String) -> void:
	var abs_dir := ProjectSettings.globalize_path(res_dir)
	if not DirAccess.dir_exists_absolute(abs_dir):
		_issues.append({
			"pack": pack_id,
			"resource": res_dir,
			"path": res_dir,
			"type": "missing_directory",
			"cause": "Expected pack directory not found",
			"fix": "Re-copy from audit extract if needed",
			"status": "OPEN",
		})
		return
	var models := _list_models(abs_dir)
	# Sample up to 12 models per pack for deep checks + always first/last
	var sample: Array[String] = []
	if models.size() <= 12:
		sample = models
	else:
		for i in 8:
			sample.append(models[i])
		sample.append(models[models.size() / 2])
		sample.append(models[models.size() - 1])
		# Prefer known critical files
		for m in models:
			var low := m.to_lower()
			if low.contains("ual1_standard.glb") or low.contains("casual.gltf") or low.contains("superhero_male"):
				if not sample.has(m):
					sample.append(m)
	for abs_model in sample:
		await _check_model(pack_id, abs_model)


func _check_model(pack_id: String, abs_model: String) -> void:
	_checked += 1
	var res_path := "res://" + abs_model.replace("\\", "/").replace(ProjectSettings.globalize_path("res://").replace("\\", "/") , "")
	# normalize
	var project_abs := ProjectSettings.globalize_path("res://").replace("\\", "/")
	var norm := abs_model.replace("\\", "/")
	if norm.begins_with(project_abs):
		res_path = "res://" + norm.substr(project_abs.length()).trim_prefix("/")
	else:
		res_path = ProjectSettings.localize_path(abs_model)

	# sidecar bin for gltf
	if res_path.to_lower().ends_with(".gltf"):
		var bin_guess := res_path.get_basename() + ".bin"
		var abs_bin := ProjectSettings.globalize_path(bin_guess)
		# many glTF share a bin or embed; only flag if .gltf references external and missing — soft check: adjacent .bin optional
		pass

	var packed: Resource = load(res_path)
	if packed == null:
		_issues.append({
			"pack": pack_id,
			"resource": res_path.get_file(),
			"path": res_path,
			"type": "load_failed",
			"cause": "ResourceLoader returned null",
			"fix": "Reimport or fix broken external references",
			"status": "OPEN",
		})
		return
	if not (packed is PackedScene):
		return
	var n: Node = (packed as PackedScene).instantiate()
	if not _has_mesh(n):
		_issues.append({
			"pack": pack_id,
			"resource": res_path.get_file(),
			"path": res_path,
			"type": "missing_mesh",
			"cause": "Instanced scene has no MeshInstance3D with mesh",
			"fix": "Inspect import; replace broken placeholder if needed",
			"status": "OPEN",
		})
	if not _has_any_material(n):
		_issues.append({
			"pack": pack_id,
			"resource": res_path.get_file(),
			"path": res_path,
			"type": "missing_material",
			"cause": "No active materials on mesh surfaces",
			"fix": "Restore textures/materials or assign base material",
			"status": "OPEN",
		})
	var scale_issue := _odd_scale(n)
	if scale_issue != "":
		_issues.append({
			"pack": pack_id,
			"resource": res_path.get_file(),
			"path": res_path,
			"type": "suspicious_scale",
			"cause": scale_issue,
			"fix": "Adjust import scale / node scale if scene placement breaks",
			"status": "OPEN",
		})
	n.free()
	await process_frame


func _list_models(abs_dir: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(abs_dir)
	if d == null:
		return out
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		if f.begins_with("."):
			f = d.get_next()
			continue
		var full := abs_dir.path_join(f)
		if d.current_is_dir():
			out.append_array(_list_models(full))
		else:
			var low := f.to_lower()
			if low.ends_with(".gltf") or low.ends_with(".glb") or low.ends_with(".fbx"):
				out.append(full)
		f = d.get_next()
	out.sort()
	return out


func _has_mesh(n: Node) -> bool:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		return true
	for c in n.get_children():
		if _has_mesh(c):
			return true
	return false


func _has_any_material(n: Node) -> bool:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.material_override != null:
			return true
		if mi.mesh != null:
			for i in mi.mesh.get_surface_count():
				if mi.get_active_material(i) != null:
					return true
	for c in n.get_children():
		if _has_any_material(c):
			return true
	return false


func _odd_scale(n: Node) -> String:
	if n is Node3D:
		var s := (n as Node3D).scale
		if s.x <= 0.001 or s.y <= 0.001 or s.z <= 0.001:
			return "near-zero scale %s" % str(s)
		if s.x >= 100.0 or s.y >= 100.0 or s.z >= 100.0:
			return "huge scale %s" % str(s)
	for c in n.get_children():
		var r := _odd_scale(c)
		if r != "":
			return r
	return ""


func _write_report() -> void:
	var md: PackedStringArray = []
	md.append("# ASSET_IMPORT_ERRORS")
	md.append("")
	md.append("Technical import audit for DATE FACTORY stabilization pass.")
	md.append("")
	md.append("| Metric | Value |")
	md.append("|---|---|")
	md.append("| Models sampled | %d |" % _checked)
	md.append("| Issues logged | %d |" % _issues.size())
	md.append("")
	md.append("| Pack | Resource | Path | Type | Cause | Fix | Status |")
	md.append("|---|---|---|---|---|---|---|")
	for i in _issues:
		md.append("| %s | %s | `%s` | %s | %s | %s | %s |" % [
			str(i.get("pack", "")),
			str(i.get("resource", "")),
			str(i.get("path", "")),
			str(i.get("type", "")),
			str(i.get("cause", "")).replace("|", "/"),
			str(i.get("fix", "")).replace("|", "/"),
			str(i.get("status", "")),
		])
	md.append("")
	md.append("Statuses: `OPEN` unresolved, `MITIGATED` workaround applied, `OPEN_LIMITATION` accepted for visual pass, `FIXED` corrected in this pass.")
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string("\n".join(md) + "\n")
	f.close()
	print("WROTE ", OUT)
