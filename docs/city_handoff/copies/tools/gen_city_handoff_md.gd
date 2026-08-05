extends SceneTree
## Generate 03/04 markdown from handoff JSON (ASCII-safe).


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_write_catalog_md()
	_write_shot_md()
	print("GEN_MD_PASS")
	quit(0)


func _read_json(res_path: String) -> Dictionary:
	var abs_path: String = ProjectSettings.globalize_path(res_path)
	var txt: String = FileAccess.get_file_as_string(abs_path)
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _write_catalog_md() -> void:
	var cat: Dictionary = _read_json("res://docs/city_handoff/city_asset_catalog.json")
	var assets: Array = cat.get("assets", [])
	var by: Dictionary = {}
	for a: Variant in assets:
		var d: Dictionary = a
		var c: String = String(d.get("category", "other"))
		if not by.has(c):
			by[c] = []
		(by[c] as Array).append(d)
	var order: Array[String] = [
		"landmarks", "buildings", "corner_buildings", "shops_commercial", "residential_facades",
		"roads", "intersections", "sidewalks", "alleys", "walls_fences", "entrances_doors", "roofs",
		"large_street_decor", "small_street_decor", "transport", "vegetation", "lighting", "signage",
		"date_objects", "interaction_objects", "background_objects", "poi_prefab",
	]
	var out := ""
	out += "# 03 — City asset catalog\n\n"
	out += "Scanned: `assets/environment/city/downtown_megakit/meshes/` + `scenes/art/city/prefabs/`.\n\n"
	out += "Total entries: **%d**. Machine-readable: `city_asset_catalog.json`.\n\n" % int(cat.get("count", assets.size()))
	out += "Sizes are approximate mesh AABB after instantiate. Raw glTF usually has **no** collision (added in prefabs/scenes).\n"
	out += "Face orientation: see `face_orientation_hint` in JSON; verify in Godot.\n\n"
	out += "## Contact sheets\n\n"
	out += "| Sheet | Contents |\n|-------|----------|\n"
	out += "| `screenshots/assets_buildings_01.png` | buildings / facades batch 1 |\n"
	out += "| `screenshots/assets_buildings_02.png` | buildings / facades batch 2 |\n"
	out += "| `screenshots/assets_roads_01.png` | roads / sidewalks / intersections |\n"
	out += "| `screenshots/assets_landmarks_01.png` | landmark / large building samples |\n"
	out += "| `screenshots/assets_props_01.png` | props batch 1 |\n"
	out += "| `screenshots/assets_props_02.png` | props batch 2 |\n\n"
	out += "## Categories\n\n"
	var seen: Dictionary = {}
	for name: String in order:
		if not by.has(name):
			continue
		seen[name] = true
		var group: Array = by[name]
		out += "### %s (%d)\n\n" % [name, group.size()]
		out += "| Path | Size (approx) | Standalone | Collision | Role | Variant of |\n"
		out += "|------|---------------|------------|-----------|------|------------|\n"
		group.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.get("name", "")) < String(b.get("name", "")))
		for item: Variant in group:
			var d2: Dictionary = item
			var sz: String = _size_str(d2.get("approx_size", {}))
			out += "| `%s` | %s | %s | %s | %s | %s |\n" % [
				String(d2.get("path", "")),
				sz,
				str(d2.get("standalone_ok", false)),
				str(d2.get("has_collision", false)),
				String(d2.get("recommended_role", "")),
				String(d2.get("variant_of", "")),
			]
		out += "\n"
	for k: Variant in by.keys():
		var ks: String = String(k)
		if seen.has(ks):
			continue
		var group2: Array = by[ks]
		out += "### %s (%d)\n\n" % [ks, group2.size()]
		for item2: Variant in group2:
			out += "- `%s`\n" % String((item2 as Dictionary).get("path", ""))
		out += "\n"
	out += "## Other city-related packs\n\n"
	out += "Live city also uses project CSG and prefabs. Restaurant/lab/factory packs are separate from the street kit.\n\n"
	out += "## Known import notes\n\n"
	out += "- See `docs/ASSET_IMPORT_ERRORS.md`, `docs/IMPORT_LOG.md`.\n"
	out += "- Raw glTF without collision is expected.\n"
	out += "- Some Prop_* AABBs inflate after instantiate — verify scale in editor.\n"
	out += "- Live `city.tscn` is CSG-dominant; full Building_* kit is available but underused as POI facades.\n"
	_write_text("res://docs/city_handoff/03_CITY_ASSET_CATALOG.md", out)


func _size_str(v: Variant) -> String:
	if typeof(v) != TYPE_DICTIONARY:
		return ""
	var d: Dictionary = v
	if d.has("size"):
		var s: Array = d["size"]
		return "%s x %s x %s" % [str(s[0]), str(s[1]), str(s[2])]
	if d.has("note"):
		return String(d["note"])
	if d.has("error"):
		return "load_failed"
	return ""


func _write_shot_md() -> void:
	var data: Dictionary = _read_json("res://docs/city_handoff/screenshot_index_data.json")
	var shots: Array = data.get("shots", [])
	var out := ""
	out += "# 04 — Screenshot index\n\n"
	out += "Camera: FOV **75** for player-eye; ortho size listed for top-down. Eye height **1.65**.\n"
	out += "Renderer: dedicated SubViewport + Camera3D (not editor freelook). Live scene: `city.tscn`. Slice shots prefixed `slice_`.\n\n"
	out += "Total indexed frames: **%d** (includes contact sheets).\n\n" % int(data.get("count", shots.size()))
	out += "| File | Position | Rotation deg | Mode | What | Why |\n"
	out += "|------|----------|--------------|------|------|-----|\n"
	for s: Variant in shots:
		var d: Dictionary = s
		var pos: String = _arr(d.get("camera_position", []))
		var rot: String = _arr(d.get("camera_rotation_degrees", []))
		var mode: String = String(d.get("mode", ""))
		if d.has("fov_or_ortho"):
			mode = "%s (%s)" % [mode, str(d.get("fov_or_ortho"))]
		var what: String = String(d.get("what", "")).replace("|", "/")
		var why: String = String(d.get("why", "")).replace("|", "/")
		out += "| `%s` | %s | %s | %s | %s | %s |\n" % [
			String(d.get("file", "")), pos, rot, mode, what, why,
		]
	out += "\n## Series\n\n"
	out += "1. Top-down full / labeled / route — `01_`..`03_`\n"
	out += "2. Spawn eye — `04_`, `04b_`\n"
	out += "3. Route walk — `05_route_01`..`13`\n"
	out += "4. Junctions — `06_junction_*`\n"
	out += "5. POIs — `07_poi_*`\n"
	out += "6. Dense clusters — `08_dense_*`\n"
	out += "7. Edge to center — `09_edge_*`\n"
	out += "8. Center to landmarks — `10_center_*`\n"
	out += "9. Street Slice — `slice_*`\n"
	out += "10. Asset contact sheets — `screenshots/assets_*.png`\n\n"
	out += "Raw metadata: `screenshot_index_data.json`.\n"
	_write_text("res://docs/city_handoff/04_SCREENSHOT_INDEX.md", out)


func _arr(v: Variant) -> String:
	if typeof(v) != TYPE_ARRAY:
		return ""
	var a: Array = v
	var parts: PackedStringArray = PackedStringArray()
	for x: Variant in a:
		parts.append(str(x))
	return ", ".join(parts)


func _write_text(res_path: String, text: String) -> void:
	var f := FileAccess.open(ProjectSettings.globalize_path(res_path), FileAccess.WRITE)
	if f == null:
		push_error("write fail %s" % res_path)
		return
	f.store_string(text)
	f.close()
