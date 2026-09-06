class_name ProgressionLabPanel
extends Control

signal status_message(text: String)

const DEFAULT_EXPORT_ROOT: String = "user://progression_lab_exports/"
const ARCHETYPE_IDS: PackedStringArray = ["EFFICIENT", "TYPICAL", "EXPLORER", "CHAOTIC", "POPULATION"]
const ARCHETYPE_LABELS: PackedStringArray = ["Efficient", "Typical", "Explorer", "Chaotic", "Population"]
const BAD_SEED_COLUMNS: PackedStringArray = [
	"seed",
	"archetype",
	"badness score",
	"hard warnings",
	"campaign days",
	"work actions",
	"max work-only streak",
	"money blocked",
	"max goal friction",
	"novelty density",
]
const CONFIG_PATHS: PackedStringArray = [
	"res://date_system/progression_lab/progression_lab_config.gd",
	"res://date_system/engine/progression_lab_config.gd",
	"res://date_system/dev_room/progression_lab_config.gd",
	"res://game/progression_lab/progression_lab_config.gd",
	"res://game/simulation/progression_lab_config.gd",
]
const RUNNER_PATHS: PackedStringArray = [
	"res://date_system/progression_lab/progression_lab_runner.gd",
	"res://date_system/engine/progression_lab_runner.gd",
	"res://date_system/dev_room/progression_lab_runner.gd",
	"res://game/progression_lab/progression_lab_runner.gd",
	"res://game/simulation/progression_lab_runner.gd",
]
const EXPORTER_PATHS: PackedStringArray = [
	"res://date_system/progression_lab/progression_lab_exporter.gd",
	"res://date_system/engine/progression_lab_exporter.gd",
	"res://date_system/dev_room/progression_lab_exporter.gd",
	"res://game/progression_lab/progression_lab_exporter.gd",
	"res://game/simulation/progression_lab_exporter.gd",
]
const OVERVIEW_KEYS: PackedStringArray = [
	"overview",
	"aggregate",
	"overall",
	"overall_stats",
	"campaign_stats",
	"campaign_day_distribution",
	"work_distribution",
	"date_distribution",
	"economy_support",
	"dead_days",
	"goal_friction",
	"novelty",
	"bad_seed_percentage",
	"warnings",
	"analysis_warnings",
	"performance",
]
const STAGE_KEYS: PackedStringArray = ["stages", "stage_metrics", "stage_stats"]
const ARCHETYPE_KEYS: PackedStringArray = ["archetypes", "archetype_metrics", "archetype_stats"]
const BAD_SEED_KEYS: PackedStringArray = ["top_badness_seeds", "top_bad_seeds", "hard_bad_seeds", "bad_seeds", "bad_seed_records", "bad_seed_summaries"]
const REPRESENTATIVE_KEYS: PackedStringArray = ["representative_seeds", "representative_seed_records"]
const ITEM_KEYS: PackedStringArray = ["items", "item_metrics", "item_utility"]

var _runner: Variant = null
var _exporter: Variant = null
var _config: Variant = null
var _result: Variant = null
var _isolation_result: Variant = null
var _selected_record: Variant = null
var _specific_record: Variant = null
var _selected_seed: int = -1
var _running: bool = false
var _isolation_running: bool = false
var _completed: int = 0
var _total: int = 0
var _export_dest_dir: String = ""
var _last_export_path: String = ""
var _engine_status: String = ""

var _config_identity: Label
var _end_stage_spin: SpinBox
var _archetype_option: OptionButton
var _n_spin: SpinBox
var _seed_start_spin: SpinBox
var _bad_seed_spin: SpinBox
var _run_btn: Button
var _cancel_btn: Button
var _replay_btn: Button
var _tests_btn: Button
var _progress_label: Label
var _isolation_target: OptionButton
var _isolation_mode: OptionButton
var _isolation_btn: Button
var _isolation_status: Label
var _overview_text: RichTextLabel
var _stages_text: RichTextLabel
var _archetypes_text: RichTextLabel
var _items_text: RichTextLabel
var _bad_header: Label
var _bad_list: ItemList
var _bad_replay_btn: Button
var _bad_log_btn: Button
var _bad_export_btn: Button
var _rep_list: ItemList
var _specific_seed_spin: SpinBox
var _specific_text: RichTextLabel
var _export_path_label: Label
var _dir_dialog: FileDialog
var _tabs: TabContainer


func setup() -> void:
	if is_node_ready():
		_resolve_engine()
		_refresh_config_identity()
		_refresh_export_path_label()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	_resolve_engine()
	_refresh_config_identity()
	_refresh_export_path_label()
	_set_seed_actions_enabled(false)
	_set_running_ui(false)


func _exit_tree() -> void:
	if _running:
		_cancel_run()


func _build() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	root.add_child(LabUi.heading("Monte Carlo Progression Lab"))
	var isolation_note := Label.new()
	isolation_note.text = "Runner isolates GameState. Population runs do not use the player save."
	isolation_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	isolation_note.add_theme_color_override("font_color", LabUi.MUTED)
	root.add_child(isolation_note)
	_config_identity = Label.new()
	_config_identity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_config_identity.add_theme_color_override("font_color", LabUi.MUTED)
	root.add_child(_config_identity)
	root.add_child(_build_controls())
	root.add_child(_build_run_row())
	_progress_label = Label.new()
	_progress_label.text = "Idle"
	_progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_progress_label.add_theme_color_override("font_color", LabUi.TEXT)
	root.add_child(_progress_label)
	root.add_child(_build_isolation_row())
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(_tabs)
	_overview_text = _add_text_tab(_tabs, "Overview")
	_stages_text = _add_text_tab(_tabs, "Stages")
	_archetypes_text = _add_text_tab(_tabs, "Archetypes")
	_tabs.add_child(_build_bad_seeds_tab())
	_tabs.add_child(_build_representative_tab())
	_items_text = _add_text_tab(_tabs, "Items")
	_tabs.add_child(_build_specific_seed_tab())
	_tabs.add_child(_build_export_tab())
	_dir_dialog = FileDialog.new()
	_dir_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	_dir_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_dir_dialog.title = "Export to..."
	_dir_dialog.min_size = Vector2(720, 480)
	_dir_dialog.dir_selected.connect(_on_export_dir_selected)
	add_child(_dir_dialog)


func _build_controls() -> HFlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 12)
	row.add_theme_constant_override("v_separation", 8)
	_end_stage_spin = _int_spin(1, 4, 4)
	row.add_child(_labeled_control("End Story Stage", _end_stage_spin))
	_archetype_option = OptionButton.new()
	_archetype_option.custom_minimum_size = Vector2(160, 0)
	for i in ARCHETYPE_LABELS.size():
		_archetype_option.add_item(ARCHETYPE_LABELS[i], i)
		_archetype_option.set_item_metadata(i, ARCHETYPE_IDS[i])
	_archetype_option.select(ARCHETYPE_IDS.size() - 1)
	row.add_child(_labeled_control("Archetype", _archetype_option))
	_n_spin = _int_spin(1, 100000, 1000)
	_n_spin.allow_greater = true
	row.add_child(_labeled_control("N simulations", _n_spin))
	for pair in [[100, "N=100"], [1000, "N=1k"], [10000, "N=10k"], [100000, "N=100k"]]:
		var preset_n: int = int(pair[0])
		var preset_btn: Button = LabUi.button(str(pair[1]))
		preset_btn.pressed.connect(_set_n.bind(preset_n))
		row.add_child(preset_btn)
	_seed_start_spin = _int_spin(1, 999999999, 1)
	_seed_start_spin.allow_greater = true
	row.add_child(_labeled_control("Base seed start", _seed_start_spin))
	_bad_seed_spin = _int_spin(1, 10000, 25)
	_bad_seed_spin.allow_greater = true
	row.add_child(_labeled_control("Bad seed count", _bad_seed_spin))
	return row


func _build_run_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_run_btn = LabUi.button("Run N simulations")
	_run_btn.pressed.connect(_on_run_pressed)
	row.add_child(_run_btn)
	_cancel_btn = LabUi.button("Cancel")
	_cancel_btn.pressed.connect(_on_cancel_pressed)
	row.add_child(_cancel_btn)
	_replay_btn = LabUi.button("Replay selected seed")
	_replay_btn.pressed.connect(_on_replay_selected_pressed)
	row.add_child(_replay_btn)
	_tests_btn = LabUi.button("Run lab tests")
	_tests_btn.pressed.connect(_on_tests_pressed)
	row.add_child(_tests_btn)
	return row


func _build_isolation_row() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var title := Label.new()
	title.text = "Goal Isolation"
	title.add_theme_color_override("font_color", LabUi.ACCENT)
	box.add_child(title)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	_isolation_target = OptionButton.new()
	_isolation_target.custom_minimum_size = Vector2(180, 0)
	var ids: Array[StringName] = CharacteristicIds.all_ids()
	var levels: PackedInt32Array = PackedInt32Array([1, 3, 5])
	for stat_id in ids:
		for level in levels:
			var idx: int = _isolation_target.item_count
			_isolation_target.add_item("%s %d" % [CharacteristicIds.display_name(stat_id), level], idx)
			_isolation_target.set_item_metadata(idx, {"id": stat_id, "level": level})
	row.add_child(_labeled_control("Characteristic milestone", _isolation_target))
	_isolation_mode = OptionButton.new()
	_isolation_mode.add_item("MINIMAL_CONTENT", 0)
	_isolation_mode.set_item_metadata(0, "MINIMAL_CONTENT")
	_isolation_mode.add_item("FULL_STAGE_CONTENT", 1)
	_isolation_mode.set_item_metadata(1, "FULL_STAGE_CONTENT")
	_isolation_mode.select(0)
	row.add_child(_labeled_control("Variant", _isolation_mode))
	var n_label := Label.new()
	n_label.text = "TYPICAL · N=1000"
	n_label.add_theme_color_override("font_color", LabUi.MUTED)
	row.add_child(n_label)
	_isolation_btn = LabUi.button("Run Goal Isolation")
	_isolation_btn.pressed.connect(_on_goal_isolation_pressed)
	row.add_child(_isolation_btn)
	box.add_child(row)
	_isolation_status = Label.new()
	_isolation_status.text = "Diagnostic only. Does not replace the population result used for export."
	_isolation_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_isolation_status.add_theme_color_override("font_color", LabUi.MUTED)
	box.add_child(_isolation_status)
	return box


func _build_bad_seeds_tab() -> Control:
	var root := VBoxContainer.new()
	root.name = "Bad Seeds"
	root.add_theme_constant_override("separation", 6)
	_bad_header = Label.new()
	_bad_header.text = " | ".join(BAD_SEED_COLUMNS)
	_bad_header.autowrap_mode = TextServer.AUTOWRAP_OFF
	_bad_header.add_theme_color_override("font_color", LabUi.MUTED)
	root.add_child(_bad_header)
	_bad_list = ItemList.new()
	_bad_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bad_list.select_mode = ItemList.SELECT_SINGLE
	_bad_list.item_selected.connect(_on_bad_seed_selected)
	root.add_child(_bad_list)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	_bad_replay_btn = LabUi.button("Replay seed")
	_bad_replay_btn.pressed.connect(_on_replay_selected_pressed)
	actions.add_child(_bad_replay_btn)
	_bad_log_btn = LabUi.button("View log")
	_bad_log_btn.pressed.connect(_on_view_log_pressed)
	actions.add_child(_bad_log_btn)
	_bad_export_btn = LabUi.button("Export seed")
	_bad_export_btn.pressed.connect(_on_export_specific_pressed)
	actions.add_child(_bad_export_btn)
	root.add_child(actions)
	return root


func _build_representative_tab() -> Control:
	var root := VBoxContainer.new()
	root.name = "Representative Seeds"
	root.add_theme_constant_override("separation", 6)
	var hint := Label.new()
	hint.text = "median · P10 duration · P90 duration · median economy-support · highest novelty · lowest novelty"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", LabUi.MUTED)
	root.add_child(hint)
	_rep_list = ItemList.new()
	_rep_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rep_list.select_mode = ItemList.SELECT_SINGLE
	_rep_list.item_selected.connect(_on_representative_selected)
	root.add_child(_rep_list)
	return root


func _build_specific_seed_tab() -> Control:
	var root := VBoxContainer.new()
	root.name = "Specific Seed"
	root.add_theme_constant_override("separation", 6)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	_specific_seed_spin = _int_spin(1, 999999999, 1)
	_specific_seed_spin.allow_greater = true
	row.add_child(_labeled_control("seed", _specific_seed_spin))
	var replay_btn: Button = LabUi.button("Replay")
	replay_btn.pressed.connect(_on_specific_replay_pressed)
	row.add_child(replay_btn)
	var view_btn: Button = LabUi.button("View full plan + path")
	view_btn.pressed.connect(_on_specific_view_pressed)
	row.add_child(view_btn)
	var export_btn: Button = LabUi.button("Export log")
	export_btn.pressed.connect(_on_specific_export_pressed)
	row.add_child(export_btn)
	root.add_child(row)
	_specific_text = _make_result_text()
	_specific_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_wrap_scroll(_specific_text))
	return root


func _build_export_tab() -> Control:
	var root := VBoxContainer.new()
	root.name = "Export"
	root.add_theme_constant_override("separation", 8)
	var hint := Label.new()
	hint.text = "Default root: %s" % DEFAULT_EXPORT_ROOT
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", LabUi.MUTED)
	root.add_child(hint)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	var full_btn: Button = LabUi.button("Export Full Statistics")
	full_btn.pressed.connect(_on_export_full_pressed)
	row.add_child(full_btn)
	var bad_btn: Button = LabUi.button("Export Bad Seed Logs")
	bad_btn.pressed.connect(_on_export_bad_pressed)
	row.add_child(bad_btn)
	var seed_btn: Button = LabUi.button("Export Specific Seed")
	seed_btn.pressed.connect(_on_export_specific_pressed)
	row.add_child(seed_btn)
	var dest_btn: Button = LabUi.button("Export to...")
	dest_btn.pressed.connect(_on_export_to_pressed)
	row.add_child(dest_btn)
	var open_btn: Button = LabUi.button("Open Export Folder")
	open_btn.pressed.connect(_on_open_export_folder_pressed)
	row.add_child(open_btn)
	root.add_child(row)
	_export_path_label = Label.new()
	_export_path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_export_path_label.add_theme_color_override("font_color", LabUi.TEXT)
	root.add_child(_export_path_label)
	return root


func _add_text_tab(tabs: TabContainer, title: String) -> RichTextLabel:
	var text: RichTextLabel = _make_result_text()
	var host: ScrollContainer = _wrap_scroll(text)
	host.name = title
	tabs.add_child(host)
	return text


func _wrap_scroll(inner: Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(inner)
	return scroll


func _make_result_text() -> RichTextLabel:
	var text := RichTextLabel.new()
	text.bbcode_enabled = false
	text.fit_content = true
	text.scroll_active = false
	text.selection_enabled = true
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_color_override("default_color", LabUi.TEXT)
	text.text = "No results yet."
	return text


func _labeled_control(title: String, control: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var label := Label.new()
	label.text = title
	label.add_theme_color_override("font_color", LabUi.MUTED)
	box.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(control)
	return box


func _int_spin(min_value: int, max_value: int, value: int) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = 1
	spin.rounded = true
	spin.value = value
	spin.custom_minimum_size = Vector2(120, 0)
	return spin


func _set_n(value: int) -> void:
	_n_spin.value = value


func _emit_status(text: String) -> void:
	status_message.emit(text)


func _resolve_engine() -> void:
	_config = _instantiate_lab_class("ProgressionLabConfig", CONFIG_PATHS)
	_runner = _instantiate_lab_class("ProgressionLabRunner", RUNNER_PATHS)
	_exporter = _instantiate_lab_class("ProgressionLabExporter", EXPORTER_PATHS)
	if _runner is Node:
		var runner_node: Node = _runner
		if runner_node.get_parent() == null:
			add_child(runner_node)
	if _runner != null and _runner.has_signal("batch_progress") and not _runner.batch_progress.is_connected(_on_batch_progress):
		_runner.batch_progress.connect(_on_batch_progress)
	if _runner != null and _runner.has_signal("replay_progress") and not _runner.replay_progress.is_connected(_on_replay_progress):
		_runner.replay_progress.connect(_on_replay_progress)
	var missing: PackedStringArray = PackedStringArray()
	if _config == null:
		missing.append("ProgressionLabConfig")
	if _runner == null:
		missing.append("ProgressionLabRunner")
	if _exporter == null:
		missing.append("ProgressionLabExporter")
	if missing.is_empty():
		_engine_status = ""
	else:
		_engine_status = "Engine API not loaded: %s. Panel is ready; wait for runner scripts." % ", ".join(missing)


func _instantiate_lab_class(class_key: String, fallback_paths: PackedStringArray) -> Variant:
	var class_path: String = _script_path_for_class(class_key)
	var created: Variant = _new_from_path(class_path)
	if created != null:
		return created
	for path in fallback_paths:
		created = _new_from_path(path)
		if created != null:
			return created
	return null


func _script_path_for_class(class_key: String) -> String:
	var classes: Array = ProjectSettings.get_global_class_list()
	for entry in classes:
		if str(entry.get("class", "")) == class_key:
			return str(entry.get("path", ""))
	return ""


func _new_from_path(path: String) -> Variant:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var loaded: Variant = load(path)
	if loaded is GDScript:
		var script: GDScript = loaded
		return script.new()
	return null


func _refresh_config_identity() -> void:
	if _config_identity == null:
		return
	var lines: PackedStringArray = PackedStringArray()
	if _config == null:
		lines.append("Active config: unavailable")
	else:
		var class_name_text: String = _config.get_class()
		if _config.get_script() != null:
			var script: Variant = _config.get_script()
			if script is Script:
				var global_name: String = (script as Script).get_global_name()
				if not global_name.is_empty():
					class_name_text = global_name
		var identity: String = "Active config: %s" % class_name_text
		var schema: Variant = _get_prop(_config, "schema_version")
		if schema != null:
			identity += " · schema_version=%s" % str(schema)
		lines.append(identity)
	if not _engine_status.is_empty():
		lines.append(_engine_status)
	_config_identity.text = "\n".join(lines)


func _current_archetype_mode() -> String:
	var index: int = _archetype_option.selected
	if index < 0:
		return "POPULATION"
	return str(_archetype_option.get_item_metadata(index))


func _prepare_config() -> Variant:
	if _config == null:
		_config = _instantiate_lab_class("ProgressionLabConfig", CONFIG_PATHS)
	if _config == null:
		return null
	_set_prop(_config, "bad_seed_count", int(_bad_seed_spin.value))
	_set_prop(_config, "default_bad_seed_count", int(_bad_seed_spin.value))
	_set_prop(_config, "default_n", int(_n_spin.value))
	_set_prop(_config, "n", int(_n_spin.value))
	_set_prop(_config, "end_story_stage", int(_end_stage_spin.value))
	_set_prop(_config, "base_seed_start", int(_seed_start_spin.value))
	_set_prop(_config, "archetype_mode", _current_archetype_mode())
	_set_prop(_config, "batch_size", 1)
	return _config


func _force_ui_batch_size() -> void:
	_set_prop(_config, "batch_size", 1)
	if _runner == null:
		return
	var runner_config: Variant = _get_prop(_runner, "config")
	_set_prop(runner_config, "batch_size", 1)


func _on_run_pressed() -> void:
	if _running:
		return
	if _runner == null or not _runner.has_method("configure") or not _runner.has_method("process_batch"):
		_emit_status("ProgressionLabRunner is not available")
		_refresh_config_identity()
		return
	var config: Variant = _prepare_config()
	if config == null:
		_emit_status("ProgressionLabConfig is not available")
		return
	_completed = 0
	_total = int(_n_spin.value)
	_running = true
	_set_running_ui(true)
	_show_run_progress(0, _total, 0.0, 0.0, 0.0)
	_emit_status("Monte Carlo: прогон 0 / %d" % _total)
	_runner.configure(config, int(_n_spin.value), int(_seed_start_spin.value), int(_end_stage_spin.value), _current_archetype_mode())
	_force_ui_batch_size()
	await _pump_batches()
	if _runner != null and _runner.has_method("get_result"):
		_result = _runner.get_result()
	_apply_result(_result)
	_emit_status("Monte Carlo run finished" if _result != null else "Monte Carlo run ended without a result")

func _on_tests_pressed() -> void:
	if _running:
		return
	_running = true
	_set_running_ui(true)
	var script: Script = load("res://date_system/tests/progression_lab_tests.gd") as Script
	if script == null:
		_emit_status("ProgressionLabTests is not available")
		_running = false
		_set_running_ui(false)
		return
	var tests: Object = script.new()
	_show_test_progress("lab", "starting", 0, 1)
	var failures: PackedStringArray = PackedStringArray()
	if tests.has_method("run_all_async"):
		failures = await tests.run_all_async(self)
	elif tests.has_method("run_all"):
		failures = tests.run_all()
	var summary: String = str(tests.summary()) if tests.has_method("summary") else ""
	if failures.is_empty():
		_emit_status("Lab tests passed · %s" % summary)
	else:
		_emit_status("Lab tests failed · %s" % summary)
		if _overview_text != null:
			_overview_text.text = "FAIL:\n" + "\n".join(failures)
	_running = false
	_set_running_ui(false)


func _show_test_progress(group: String, test_name: String, done: int, total: int) -> void:
	var line: String = "Test group: %s" % group
	line += " · Current test: %s" % test_name
	line += " · %d / %d" % [done, total]
	if total > 0:
		line += " · %.1f%%" % (100.0 * float(done) / float(total))
	if _progress_label != null:
		_progress_label.text = line
	_emit_status(line)


func _on_cancel_pressed() -> void:
	_cancel_run()
	_emit_status("Monte Carlo run cancelled")


func _cancel_run() -> void:
	_running = false
	_isolation_running = false
	if _runner != null and _runner.has_method("cancel"):
		_runner.cancel()
	_set_running_ui(false)


func _pump_batches() -> void:
	_show_run_progress(_completed, _total, 0.0, 0.0, 0.0)
	await get_tree().process_frame
	while _running:
		var finished: bool = true
		if _runner != null and _runner.has_method("process_batch"):
			finished = bool(_runner.process_batch())
		await get_tree().process_frame
		if finished or not _running:
			break
	if _running and not _isolation_running and _runner != null and _runner.has_method("process_replay_batch"):
		if _runner.has_method("begin_replay_verification"):
			_runner.begin_replay_verification()
		while _running:
			var replay_finished: bool = bool(_runner.process_replay_batch())
			await get_tree().process_frame
			if replay_finished or not _running:
				break
	_running = false
	_set_running_ui(false)

func _on_batch_progress(completed: Variant, total: Variant, runs_per_second: Variant, elapsed_sec: Variant, remaining_sec: Variant) -> void:
	_show_run_progress(int(completed), int(total), float(runs_per_second), float(elapsed_sec), float(remaining_sec))


func _on_replay_progress(completed: Variant, total: Variant, seed: Variant, matched: Variant, mismatched: Variant) -> void:
	var line: String = "Проверка replay %d / %d" % [int(completed), int(total)]
	line += " · Seed: %d" % int(seed)
	line += " · matched %d / mismatched %d" % [int(matched), int(mismatched)]
	if _progress_label != null:
		_progress_label.text = line
	_emit_status(line)

func _show_run_progress(completed: int, total: int, runs_per_second: float, elapsed_sec: float, remaining_sec: float) -> void:
	_completed = completed
	_total = total
	var mean_ms: float = 0.0
	if runs_per_second > 0.0:
		mean_ms = 1000.0 / runs_per_second
	var line: String = "Прогон %d / %d" % [completed, total]
	if _runner != null and bool(_runner.get("regression_mode")):
		var seed_value: int = 0
		if _runner.has_method("current_seed"):
			seed_value = int(_runner.current_seed())
		line = "Rival regression seed %d · %d / %d" % [seed_value, completed, total]
	if total > 0:
		line += " · %.1f%%" % (100.0 * float(completed) / float(total))
	if completed > 0:
		line += " · %.2f/s · mean %.0f ms · elapsed %s · ETA %s" % [
			runs_per_second,
			mean_ms,
			_format_seconds(elapsed_sec),
			_format_seconds(remaining_sec),
		]
	if _progress_label != null:
		_progress_label.text = line
	if _isolation_running and _isolation_status != null:
		_isolation_status.text = "Goal Isolation: прогон %d / %d · ETA %s" % [
			completed,
			total,
			_format_seconds(remaining_sec),
		]
	_emit_status(line)


func _set_running_ui(is_running: bool) -> void:
	if _run_btn != null:
		_run_btn.disabled = is_running
	if _cancel_btn != null:
		_cancel_btn.disabled = not is_running
	if _isolation_btn != null:
		_isolation_btn.disabled = is_running
	if _tests_btn != null:
		_tests_btn.disabled = is_running


func _on_replay_selected_pressed() -> void:
	var seed_value: int = _selected_seed
	if seed_value < 0:
		seed_value = int(_specific_seed_spin.value)
	_replay_and_show(seed_value, false)


func _on_view_log_pressed() -> void:
	var seed_value: int = _selected_seed
	if seed_value < 0:
		seed_value = int(_specific_seed_spin.value)
	_replay_and_show(seed_value, true)


func _on_specific_replay_pressed() -> void:
	_replay_and_show(int(_specific_seed_spin.value), false)


func _on_specific_view_pressed() -> void:
	_replay_and_show(int(_specific_seed_spin.value), true)


func _on_specific_export_pressed() -> void:
	_selected_seed = int(_specific_seed_spin.value)
	_on_export_specific_pressed()


func _replay_and_show(seed_value: int, detailed: bool) -> void:
	if _running:
		_emit_status("Wait for the current run to finish")
		return
	if _runner == null or not _runner.has_method("replay_seed"):
		_emit_status("ProgressionLabRunner.replay_seed is not available")
		return
	_selected_seed = seed_value
	_specific_seed_spin.value = seed_value
	var record: Variant = _runner.replay_seed(seed_value, detailed)
	_specific_record = record
	_selected_record = record
	_specific_text.text = _format_specific_seed(record)
	_tabs.current_tab = _tab_index_named("Specific Seed")
	_set_seed_actions_enabled(true)
	_emit_status("Replayed seed %d" % seed_value)


func _on_bad_seed_selected(index: int) -> void:
	_select_record_from_list(_bad_list, index)


func _on_representative_selected(index: int) -> void:
	_select_record_from_list(_rep_list, index)


func _select_record_from_list(list: ItemList, index: int) -> void:
	if index < 0 or index >= list.item_count:
		return
	var record: Variant = list.get_item_metadata(index)
	_selected_record = record
	_selected_seed = _record_seed(record)
	if _selected_seed >= 0:
		_specific_seed_spin.value = _selected_seed
	_set_seed_actions_enabled(_selected_seed >= 0)


func _on_goal_isolation_pressed() -> void:
	if _running:
		return
	if _runner == null or not _runner.has_method("run_goal_isolation"):
		_emit_status("ProgressionLabRunner.run_goal_isolation is not available")
		return
	var meta: Variant = _isolation_target.get_item_metadata(_isolation_target.selected)
	var stat_id: StringName = &"appearance"
	var level: int = 3
	if meta is Dictionary:
		var meta_dict: Dictionary = meta
		stat_id = meta_dict.get("id", stat_id)
		level = int(meta_dict.get("level", level))
	var content_mode: String = str(_isolation_mode.get_item_metadata(_isolation_mode.selected))
	_running = true
	_isolation_running = true
	_set_running_ui(true)
	_isolation_status.text = "Running Goal Isolation (%s %d, %s, TYPICAL, N=1000)..." % [
		CharacteristicIds.display_name(stat_id),
		level,
		content_mode,
	]
	_emit_status("Goal Isolation started")
	var previous: Variant = _result
	_completed = 0
	_total = 1000
	_prepare_config()
	if _runner.has_method("begin_goal_isolation"):
		_runner.begin_goal_isolation(stat_id, level, content_mode, 1000, int(_seed_start_spin.value), int(_end_stage_spin.value))
		_force_ui_batch_size()
		await _pump_batches()
		if _runner.has_method("get_result"):
			_isolation_result = _runner.get_result()
	elif typeof(_invoke_goal_isolation(stat_id, level, content_mode, 1000)) == TYPE_BOOL:
		await _pump_batches()
		if _runner.has_method("get_result"):
			_isolation_result = _runner.get_result()
	else:
		_isolation_result = _invoke_goal_isolation(stat_id, level, content_mode, 1000)
		_running = false
		_set_running_ui(false)
	_result = previous
	_isolation_running = false
	_isolation_status.text = "Goal Isolation finished. Compare work actions, work-only streak, days, Goal Friction, dead days."
	_apply_overview()
	_emit_status("Goal Isolation finished")


func _invoke_goal_isolation(stat_id: StringName, level: int, content_mode: String, n: int) -> Variant:
	return _runner.run_goal_isolation(stat_id, level, content_mode, n)


func _apply_result(result: Variant) -> void:
	_result = result
	_apply_overview()
	_stages_text.text = _format_stats_branch(result, "per_stage", "No stage metrics yet.")
	_archetypes_text.text = _format_stats_branch(result, "per_archetype", "No archetype metrics yet.")
	_items_text.text = _format_named_section(result, ITEM_KEYS, "No item metrics yet.")
	var top_bad: Array = _result_array(result, BAD_SEED_KEYS)
	var all_count: int = int(_get_prop(result, "bad_seed_count") if _get_prop(result, "bad_seed_count") != null else 0)
	if _bad_header != null:
		_bad_header.text = "Hard bad seeds: %d / %s | Top %d by badness score | %s" % [all_count, str(_get_prop(result, "n")), top_bad.size(), " | ".join(BAD_SEED_COLUMNS)]
	_fill_record_list(_bad_list, top_bad, true)
	_fill_record_list(_rep_list, _result_records(result, REPRESENTATIVE_KEYS), false)
	if _selected_seed < 0:
		_set_seed_actions_enabled(false)


func _apply_overview() -> void:
	var chunks: PackedStringArray = PackedStringArray()
	if _result == null:
		chunks.append("No population results yet.")
	else:
		chunks.append(_format_overview(_result))
	if _isolation_result != null:
		chunks.append("")
		chunks.append("Goal Isolation")
		chunks.append(_format_isolation(_isolation_result))
	_overview_text.text = "\n".join(chunks)


func _format_overview(result: Variant) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append(_format_performance(result))
	var statistics: Variant = _get_prop(result, "statistics")
	if statistics is Dictionary:
		var stats_dict: Dictionary = statistics
		if stats_dict.has("overall"):
			lines.append("")
			lines.append("Overall P10 / P50 / P90 / P95")
			lines.append(_format_percentile_table(stats_dict["overall"]))
	var warnings: Variant = _get_prop(result, "analysis_warnings")
	if warnings != null:
		lines.append("")
		lines.append("analysis_warnings")
		lines.append(_format_value(warnings, 0))
	var n_value: Variant = _get_prop(result, "n")
	var bad_count: Variant = _get_prop(result, "bad_seed_count")
	if bad_count == null:
		var bad_seeds: Variant = _get_prop(result, "all_bad_seeds")
		if bad_seeds is Array:
			bad_count = (bad_seeds as Array).size()
	if bad_count != null and n_value != null and int(n_value) > 0:
		var pct: float = 100.0 * float(int(bad_count)) / float(int(n_value))
		var stored_pct: Variant = _get_prop(result, "bad_seed_percentage")
		if stored_pct != null:
			pct = 100.0 * float(stored_pct)
		lines.append("")
		lines.append("Hard bad seeds: %d / %d (%.1f%%)" % [int(bad_count), int(n_value), pct])
		var top_badness: Variant = _get_prop(result, "top_badness_seeds")
		if top_badness == null:
			top_badness = _get_prop(result, "top_bad_seeds")
		if top_badness is Array:
			lines.append("Top %d by badness score: %d" % [(top_badness as Array).size(), (top_badness as Array).size()])
	var replay_total: Variant = _get_prop(result, "replay_total")
	if replay_total != null and int(replay_total) > 0:
		lines.append("Replay determinism: %d / %d matched" % [int(_get_prop(result, "replay_matched")), int(replay_total)])
	var version: Variant = _get_prop(result, "simulation_version")
	if version != null:
		lines.append("Simulation version: %s" % str(version))
		lines.append("Git dirty: %s" % str(_get_prop(result, "git_dirty")))
		lines.append("Worktree fingerprint: %s" % str(_get_prop(result, "worktree_fingerprint")))
	var rival_cash: Variant = _get_prop(result, "rival_cash_dependency")
	if rival_cash is Dictionary and not (rival_cash as Dictionary).is_empty():
		lines.append("")
		lines.append("Rival Cash Dependency")
		lines.append(_format_value(rival_cash, 0))
	return "\n".join(lines)


func _format_percentile_table(overall: Variant) -> String:
	if not (overall is Dictionary):
		return _format_value(overall, 0)
	var lines: PackedStringArray = PackedStringArray()
	var overall_dict: Dictionary = overall
	for key in overall_dict.keys():
		var entry: Variant = overall_dict[key]
		if entry is Dictionary:
			var row: Dictionary = entry
			lines.append("%s  P10=%s  P50=%s  P90=%s  P95=%s" % [
				str(key),
				str(row.get("P10", "")),
				str(row.get("P50", "")),
				str(row.get("P90", "")),
				str(row.get("P95", "")),
			])
		else:
			lines.append("%s: %s" % [str(key), str(entry)])
	return "\n".join(lines)


func _format_stats_branch(result: Variant, branch: String, empty_text: String) -> String:
	var statistics: Variant = _get_prop(result, "statistics")
	if statistics is Dictionary and (statistics as Dictionary).has(branch):
		return _format_value((statistics as Dictionary)[branch], 0)
	return empty_text


func _format_performance(result: Variant) -> String:
	var perf: Variant = _get_prop(result, "performance")
	var rps: Variant = _get_nested(result, PackedStringArray(["runs_per_second", "performance.runs_per_second"]))
	if perf is Dictionary:
		return "Performance: %s" % _format_value(perf, 0)
	if rps != null:
		return "Performance: %s runs/s" % str(rps)
	return "Performance: see progress line (runs/s, elapsed, ETA)."


func _format_isolation(result: Variant) -> String:
	var statistics: Variant = _get_prop(result, "statistics")
	if statistics is Dictionary and (statistics as Dictionary).has("overall"):
		return _format_percentile_table((statistics as Dictionary)["overall"])
	return _format_value(result, 0)


func _format_named_section(result: Variant, keys: PackedStringArray, empty_text: String) -> String:
	var value: Variant = _first_prop(result, keys)
	if value == null:
		return empty_text
	return _format_value(value, 0)


func _fill_record_list(list: ItemList, records: Array, is_bad: bool) -> void:
	list.clear()
	if records.is_empty():
		list.add_item("No rows yet." if not is_bad else "No bad seeds yet.")
		list.set_item_disabled(0, true)
		return
	for record in records:
		var line: String = _format_bad_seed_row(record)
		if not is_bad:
			var label: Variant = _get_prop(record, "label")
			if label == null:
				label = _get_prop(record, "role")
			if label != null:
				line = "%s | %s" % [str(label), line]
		var idx: int = list.item_count
		list.add_item(line)
		list.set_item_metadata(idx, record)


func _format_bad_seed_row(record: Variant) -> String:
	var warnings_value: Variant = _first_prop(record, PackedStringArray(["hard_warnings", "hard_warning_list", "hard_warning_count"]))
	var warnings_text: String = _format_warnings_cell(warnings_value)
	var cells: PackedStringArray = PackedStringArray([
		str(_record_seed(record)),
		str(_first_prop(record, PackedStringArray(["archetype", "archetype_mode"]))),
		str(_first_prop(record, PackedStringArray(["badness_score", "badness"]))),
		warnings_text,
		str(_first_prop(record, PackedStringArray(["campaign_days", "calendar_days"]))),
		str(_first_prop(record, PackedStringArray(["work_actions"]))),
		str(_first_prop(record, PackedStringArray(["max_work_only_streak", "max_consecutive_work_only_days"]))),
		str(_first_prop(record, PackedStringArray(["money_blocked", "money_blocked_decision_points"]))),
		str(_first_prop(record, PackedStringArray(["max_goal_friction", "max_goal_friction_ratio"]))),
		str(_first_prop(record, PackedStringArray(["novelty_density"]))),
	])
	return " | ".join(cells)


func _format_warnings_cell(value: Variant) -> String:
	if value == null:
		return "0"
	if value is Array:
		return str((value as Array).size())
	return str(value)


func _format_specific_seed(record: Variant) -> String:
	if record == null:
		return "No seed replay yet."
	var sections: PackedStringArray = PackedStringArray(["Profile", "StagePlans", "Timeline", "Metrics", "Warnings"])
	var keys_by_section: Dictionary = {
		"Profile": PackedStringArray(["profile", "player_profile", "traits"]),
		"StagePlans": PackedStringArray(["stage_plans", "StagePlans", "plans"]),
		"Timeline": PackedStringArray(["timeline_markdown", "timeline", "daily_timeline", "daily_log", "path"]),
		"Metrics": PackedStringArray(["campaign_metrics", "metrics", "run_metrics", "stage_metrics"]),
		"Warnings": PackedStringArray(["warnings", "hard_warnings", "hard_warning_list"]),
	}
	var lines: PackedStringArray = PackedStringArray()
	lines.append("seed %d" % _record_seed(record))
	for section in sections:
		lines.append("")
		lines.append(section)
		var value: Variant = _first_prop(record, keys_by_section[section])
		if value == null:
			lines.append("(not present on replay record)")
		else:
			lines.append(_format_value(value, 0))
	return "\n".join(lines)


func _on_export_full_pressed() -> void:
	_run_runner_export("export_full_statistics")


func _on_export_bad_pressed() -> void:
	_run_runner_export("export_bad_seeds_only")


func _on_export_specific_pressed() -> void:
	if _runner == null or not _runner.has_method("export_specific_seed"):
		_emit_status("ProgressionLabRunner.export_specific_seed is not available")
		return
	var seed_value: int = _selected_seed
	if seed_value < 0:
		seed_value = int(_specific_seed_spin.value)
	var path: String = str(_runner.export_specific_seed(seed_value, _export_destination()))
	_show_export_path(path)


func _run_runner_export(method_name: String) -> void:
	if _runner == null or not _runner.has_method(method_name):
		_emit_status("ProgressionLabRunner.%s is not available" % method_name)
		return
	if _result == null:
		_emit_status("Run simulations before exporting")
		return
	var dest: String = _export_destination()
	var path: String = str(_runner.call(method_name, dest))
	_show_export_path(path)


func _on_export_to_pressed() -> void:
	var root_abs: String = _absolute_path(_default_export_root())
	DirAccess.make_dir_recursive_absolute(root_abs)
	_dir_dialog.current_dir = root_abs
	_dir_dialog.popup_centered()


func _on_export_dir_selected(dir_path: String) -> void:
	_export_dest_dir = dir_path
	_last_export_path = dir_path
	_refresh_export_path_label()
	_emit_status("Export destination set")


func _on_open_export_folder_pressed() -> void:
	var path: String = _last_export_path
	if path.is_empty():
		path = _absolute_path(_default_export_root())
	DirAccess.make_dir_recursive_absolute(path)
	OS.shell_open(path)


func _export_destination() -> String:
	if not _export_dest_dir.is_empty():
		return _export_dest_dir
	return _default_export_root()


func _default_export_root() -> String:
	if _exporter != null and _exporter.has_method("default_export_root"):
		var root: String = str(_exporter.default_export_root())
		if not root.is_empty():
			return root
	return DEFAULT_EXPORT_ROOT


func _show_export_path(path: String) -> void:
	var abs_path: String = _absolute_path(path)
	if abs_path.is_empty():
		_emit_status("Export finished without a path")
		return
	_last_export_path = abs_path
	_refresh_export_path_label()
	_emit_status("Exported to %s" % abs_path)


func _refresh_export_path_label() -> void:
	if _export_path_label == null:
		return
	var dest: String = _absolute_path(_export_destination())
	var last_path: String = _last_export_path
	if last_path.is_empty():
		_export_path_label.text = "Export folder: %s" % dest
	else:
		_export_path_label.text = "Last export: %s\nDestination: %s" % [last_path, dest]


func _set_seed_actions_enabled(enabled: bool) -> void:
	if _replay_btn != null:
		_replay_btn.disabled = not enabled
	if _bad_replay_btn != null:
		_bad_replay_btn.disabled = not enabled
	if _bad_log_btn != null:
		_bad_log_btn.disabled = not enabled
	if _bad_export_btn != null:
		_bad_export_btn.disabled = not enabled


func _tab_index_named(tab_name: String) -> int:
	for i in _tabs.get_tab_count():
		if _tabs.get_tab_title(i) == tab_name:
			return i
	return 0


func _record_seed(record: Variant) -> int:
	var value: Variant = _first_prop(record, PackedStringArray(["seed", "base_seed"]))
	if value == null:
		return -1
	return int(value)


func _result_array(result: Variant, keys: PackedStringArray) -> Array:
	return _result_records(result, keys)


func _result_records(result: Variant, keys: PackedStringArray) -> Array:
	var value: Variant = _first_prop(result, keys)
	if value is Array:
		return value
	if value is Dictionary:
		var rows: Array = []
		var source: Dictionary = value
		for key in source.keys():
			var row: Variant = source[key]
			if row is Dictionary:
				var tagged: Dictionary = (row as Dictionary).duplicate(true)
				tagged["role"] = str(key)
				rows.append(tagged)
			else:
				rows.append({"role": str(key), "value": row})
		return rows
	return []


func _omit_large_arrays(value: Variant) -> Variant:
	if value is Dictionary:
		var slim: Dictionary = {}
		var source: Dictionary = value
		for key in source.keys():
			var item: Variant = source[key]
			if item is Array and (item as Array).size() > 12:
				slim[key] = "(%d rows)" % (item as Array).size()
			else:
				slim[key] = item
		return slim
	if value is Object:
		return _object_props(value, true)
	return value


func _format_value(value: Variant, indent: int) -> String:
	var pad: String = "  ".repeat(indent)
	if value == null:
		return "%s—" % pad
	if value is Array:
		var rows: PackedStringArray = PackedStringArray()
		var items: Array = value
		if items.is_empty():
			return "%s[]" % pad
		for i in mini(items.size(), 40):
			rows.append("%s- %s" % [pad, _format_value(items[i], indent + 1).strip_edges()])
		if items.size() > 40:
			rows.append("%s- … %d more" % [pad, items.size() - 40])
		return "\n".join(rows)
	if value is Dictionary:
		return _format_dictionary(value, indent)
	if value is Object:
		return _format_dictionary(_object_props(value, false), indent)
	return "%s%s" % [pad, str(value)]


func _format_dictionary(source: Dictionary, indent: int) -> String:
	var pad: String = "  ".repeat(indent)
	if source.is_empty():
		return "%s{}" % pad
	if _looks_like_stats(source):
		return "%s%s" % [pad, _format_stats_line(source)]
	var rows: PackedStringArray = PackedStringArray()
	for key in source.keys():
		var item: Variant = source[key]
		if item is Dictionary or item is Array or item is Object:
			rows.append("%s%s:" % [pad, str(key)])
			rows.append(_format_value(item, indent + 1))
		else:
			rows.append("%s%s: %s" % [pad, str(key), str(item)])
	return "\n".join(rows)


func _looks_like_stats(source: Dictionary) -> bool:
	return source.has("p50") or source.has("P50") or (source.has("mean") and source.has("min"))


func _format_stats_line(source: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for key in ["count", "mean", "sd", "standard_deviation", "min", "p10", "P10", "p25", "P25", "p50", "P50", "p75", "P75", "p90", "P90", "p95", "P95", "max"]:
		if source.has(key):
			parts.append("%s=%s" % [key, str(source[key])])
	if parts.is_empty():
		return str(source)
	return " ".join(parts)


func _object_props(host: Object, omit_large: bool) -> Dictionary:
	var props: Dictionary = {}
	for info in host.get_property_list():
		if int(info.get("usage", 0)) & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		var key: String = str(info.get("name", ""))
		if key.is_empty() or key.begins_with("_"):
			continue
		var item: Variant = host.get(key)
		if omit_large and item is Array and (item as Array).size() > 12:
			props[key] = "(%d rows)" % (item as Array).size()
		else:
			props[key] = item
	return props


func _first_prop(host: Variant, keys: PackedStringArray) -> Variant:
	for key in keys:
		var value: Variant = _get_prop(host, key)
		if value != null:
			return value
	return null


func _get_nested(host: Variant, keys: PackedStringArray) -> Variant:
	for key in keys:
		if key.contains("."):
			var parts: PackedStringArray = key.split(".")
			var cursor: Variant = host
			var ok: bool = true
			for part in parts:
				cursor = _get_prop(cursor, part)
				if cursor == null:
					ok = false
					break
			if ok:
				return cursor
		else:
			var value: Variant = _get_prop(host, key)
			if value != null:
				return value
	return null


func _get_prop(host: Variant, key: String) -> Variant:
	if host == null or key.is_empty():
		return null
	if host is Dictionary:
		var source: Dictionary = host
		if source.has(key):
			return source[key]
		return null
	if host is Object:
		var obj: Object = host
		if key in obj:
			return obj.get(key)
	return null


func _set_prop(host: Variant, key: String, value: Variant) -> void:
	if host == null or key.is_empty():
		return
	if host is Dictionary:
		var source: Dictionary = host
		source[key] = value
		return
	if host is Object:
		var obj: Object = host
		if key in obj:
			obj.set(key, value)


func _absolute_path(path: String) -> String:
	var trimmed: String = path.strip_edges()
	if trimmed.is_empty():
		return ""
	if trimmed.begins_with("user://") or trimmed.begins_with("res://"):
		return ProjectSettings.globalize_path(trimmed)
	return trimmed


func _format_seconds(value: float) -> String:
	if value < 0.0:
		return "—"
	var total: int = int(round(value))
	var minutes: int = total / 60
	var seconds: int = total % 60
	if minutes <= 0:
		return "%ds" % seconds
	return "%dm %02ds" % [minutes, seconds]
