extends Node
## Development-only visual playtest harness entry (no autoload).
## Launched by tools/visual_review/run_visual_playtest.py with DF_VISUAL_* env vars.
class_name VisualPlaytestRunner


var _mode: String = "layout"
var _run_id: String = "default"
var _out_dir: String = ""
var _ui_scale: int = 100
var _width: int = 0
var _height: int = 0
var _res_label: String = ""
var _capture: ScreenshotCapture = ScreenshotCapture.new()
var _auditor: UiLayoutAuditor = UiLayoutAuditor.new()
var _shots: Array[String] = []
var _defects: Array = []
var _stubs: Array[String] = []
var _notes: Array[String] = []
var _control_rows: Array = []
var _playthrough_meta: Dictionary = {}


func _ready() -> void:
	await _run_async()


func _run_async() -> void:
	_read_env()
	await _apply_window()
	UiScaleHelper.set_ui_scale_percent(_ui_scale)
	_res_label = "%dx%d" % [_width, _height]
	_capture.setup(self, _out_dir, _res_label, _mode)
	print("[VisualPlaytest] mode=%s run_id=%s out=%s res=%s ui=%d" % [
		_mode, _run_id, _out_dir, _res_label, _ui_scale,
	])
	match _mode:
		"layout":
			await _run_layout()
		"gallery":
			await _run_gallery()
		"playthrough":
			await _run_playthrough()
		_:
			_notes.append("unknown DF_VISUAL_MODE=%s; defaulting to layout" % _mode)
			await _run_layout()
	_write_reports()
	print("[VisualPlaytest] DONE shots=%d defects=%d" % [_shots.size(), _defects.size()])
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()


func _read_env() -> void:
	var mode_env: String = OS.get_environment("DF_VISUAL_MODE").strip_edges().to_lower()
	if not mode_env.is_empty():
		_mode = mode_env
	var run_env: String = OS.get_environment("DF_VISUAL_RUN_ID").strip_edges()
	if not run_env.is_empty():
		_run_id = run_env
	var out_env: String = OS.get_environment("DF_VISUAL_OUT").strip_edges()
	if not out_env.is_empty():
		_out_dir = out_env.replace("\\", "/")
	else:
		_out_dir = ProjectSettings.globalize_path("user://visual_playtest/%s" % _run_id)
	var scale_env: String = OS.get_environment("DF_UI_SCALE").strip_edges()
	if not scale_env.is_empty():
		_ui_scale = int(scale_env)
	var w_env: String = OS.get_environment("DF_VISUAL_WIDTH").strip_edges()
	var h_env: String = OS.get_environment("DF_VISUAL_HEIGHT").strip_edges()
	if not w_env.is_empty() and not h_env.is_empty():
		_width = int(w_env)
		_height = int(h_env)


func _apply_window() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if _width <= 0 or _height <= 0:
		var win_size: Vector2i = DisplayServer.window_get_size()
		_width = win_size.x
		_height = win_size.y
	else:
		DisplayServer.window_set_size(Vector2i(_width, _height))
		await get_tree().process_frame
		var win_size2: Vector2i = DisplayServer.window_get_size()
		_width = win_size2.x
		_height = win_size2.y
	if _width <= 0:
		_width = 1280
	if _height <= 0:
		_height = 720


func _shot_name(base: String) -> String:
	# Include ui scale so matrix relaunches do not overwrite.
	return "%s_ui%d" % [base, _ui_scale]


func _run_layout() -> void:
	var packed: PackedScene = load("res://ui/frontend/title_menu.tscn") as PackedScene
	var menu: TitleMenu = null
	if packed != null:
		menu = packed.instantiate() as TitleMenu
	else:
		menu = TitleMenu.new()
		_notes.append("title_menu.tscn missing; used TitleMenu.new()")
	add_child(menu)
	if menu.has_method("show_menu"):
		menu.show_menu()
	var path_main: String = await _capture.capture(_shot_name("000_main_menu"))
	if not path_main.is_empty():
		_shots.append(path_main)
	_defects.append_array(_auditor.audit_title_menu(menu))
	_control_rows.append_array(_auditor.control_snapshot(menu))

	# Nice-to-have: settings + save/load.
	var settings: SettingsPanel = SettingsPanel.new()
	menu.add_child(settings)
	settings.open()
	var path_settings: String = await _capture.capture(_shot_name("010_settings"))
	if not path_settings.is_empty():
		_shots.append(path_settings)
	_defects.append_array(_auditor.audit_visible_tree(settings))
	settings.close(false)
	await get_tree().process_frame

	var save_panel: SaveLoadPanel = SaveLoadPanel.new()
	menu.add_child(save_panel)
	save_panel.open_load()
	var path_save: String = await _capture.capture(_shot_name("030_save"))
	if not path_save.is_empty():
		_shots.append(path_save)
	_defects.append_array(_auditor.audit_visible_tree(save_panel))
	save_panel.close()
	await get_tree().process_frame
	menu.queue_free()


func _run_gallery() -> void:
	var gallery: VisualStateGallery = VisualStateGallery.new()
	gallery.host = self
	gallery.capture = _capture
	gallery.auditor = _auditor
	await gallery.run()
	_shots.append_array(gallery.shots)
	_defects.append_array(gallery.defects)
	_stubs.append_array(gallery.stub_missing)
	_control_rows.append_array(gallery.control_rows)


func _run_playthrough() -> void:
	var driver: PlaythroughDriver = PlaythroughDriver.new()
	driver.host = self
	driver.capture = _capture
	driver.auditor = _auditor
	await driver.run()
	_shots.append_array(driver.shots)
	_defects.append_array(driver.defects)
	_stubs.append_array(driver.unmet)
	_playthrough_meta = {
		"completed": driver.completed,
		"unmet": driver.unmet,
		"snapshots": driver.snapshots,
	}


func _write_reports() -> void:
	var mk_err: Error = DirAccess.make_dir_recursive_absolute(_out_dir)
	if mk_err != OK and not DirAccess.dir_exists_absolute(_out_dir):
		push_error("[VisualPlaytest] cannot create out dir: %s" % _out_dir)
		return
	var partials: String = "%s/partials" % _out_dir
	DirAccess.make_dir_recursive_absolute(partials)
	var report: Dictionary = {
		"mode": _mode,
		"run_id": _run_id,
		"resolution": _res_label,
		"ui_scale": _ui_scale,
		"out_dir": _out_dir,
		"shots": _shots,
		"shot_count": _shots.size(),
		"defects": _defects,
		"stubs": _stubs,
		"notes": _notes,
		"controls": _control_rows,
		"playthrough": _playthrough_meta,
	}
	var partial_path: String = "%s/%s_%s_ui%d.json" % [partials, _mode, _res_label, _ui_scale]
	_write_json(partial_path, report)
	# Also refresh a rolling report.json for single-launch convenience.
	_write_json("%s/report.json" % _out_dir, report)
	_write_md("%s/report.md" % _out_dir, report)


func _write_json(path: String, data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[VisualPlaytest] cannot write %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _write_md(path: String, data: Dictionary) -> void:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("# Visual Playtest Report")
	lines.append("")
	lines.append("- mode: `%s`" % str(data.get("mode", "")))
	lines.append("- run_id: `%s`" % str(data.get("run_id", "")))
	lines.append("- resolution: `%s`" % str(data.get("resolution", "")))
	lines.append("- ui_scale: `%s`" % str(data.get("ui_scale", "")))
	lines.append("- shots: `%s`" % str(data.get("shot_count", 0)))
	lines.append("")
	lines.append("## Shots")
	var shots_v: Variant = data.get("shots", [])
	if shots_v is Array:
		for s: Variant in shots_v as Array:
			lines.append("- `%s`" % str(s))
	lines.append("")
	lines.append("## Defects")
	var defects_v: Variant = data.get("defects", [])
	if defects_v is Array:
		var arr: Array = defects_v as Array
		if arr.is_empty():
			lines.append("- (none)")
		else:
			for d: Variant in arr:
				if d is Dictionary:
					var dd: Dictionary = d as Dictionary
					lines.append("- **%s** `%s`: %s" % [
						str(dd.get("severity", "")),
						str(dd.get("path", "")),
						str(dd.get("message", "")),
					])
				else:
					lines.append("- %s" % str(d))
	lines.append("")
	lines.append("## Stubs / unmet")
	var stubs_v: Variant = data.get("stubs", [])
	if stubs_v is Array:
		var stubs_arr: Array = stubs_v as Array
		if stubs_arr.is_empty():
			lines.append("- (none)")
		else:
			for s2: Variant in stubs_arr:
				lines.append("- %s" % str(s2))
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string("\n".join(lines) + "\n")
	file.close()
