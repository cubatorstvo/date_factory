class_name GameHUD
extends CanvasLayer
## Persistent presentation HUD (MODULE 22). Event-driven; no gameplay formulas.

const THEME_PATH := "res://ui/theme/date_factory_theme.tres"
const NOTIFY_SECONDS: float = 2.2
const STAGE_SECONDS: float = 3.0
const NOTIFY_QUEUE_MAX: int = 3
const REACH_MILESTONES: Array[int] = [25, 50, 75, 100]

const FEATURE_COPY := {
	int(StoryTypes.StoryFeature.SOCIAL_ACCESS): "ОТКРЫТО: СОЦИАЛЬНЫЙ ДОСТУП",
	int(StoryTypes.StoryFeature.PUBLIC_CITY_ACCESS): "Открыт новый район города",
	int(StoryTypes.StoryFeature.SALARY_MINE): "ОТКРЫТО: ЗАРПЛАТНАЯ ШАХТА",
	int(StoryTypes.StoryFeature.MEDIA_ATTENTION): "ОТКРЫТО: МЕДИЙНОЕ ВНИМАНИЕ",
	int(StoryTypes.StoryFeature.LABORATORY): "ОТКРЫТО: ЛАБОРАТОРИЯ",
	int(StoryTypes.StoryFeature.WORLD_EXPANSION): "ОТКРЫТО: МИРОВОЕ РАСШИРЕНИЕ",
	int(StoryTypes.StoryFeature.FINAL_DATE): "ОТКРЫТО: ФИНАЛЬНОЕ СВИДАНИЕ",
}

var _scale_root: Control
var _gameplay_root: Control
var _money_label: Label
var _authority_label: Label
var _experience_label: Label
var _points_label: Label
var _crosshair: Control
var _notify_panel: PanelContainer
var _notify_label: Label
var _stage_panel: PanelContainer
var _stage_title: Label
var _stage_subtitle: Label
var _tutorial_panel: PanelContainer
var _tutorial_label: Label
var _notify_timer: Timer
var _stage_timer: Timer
var _tutorial_timer: Timer

var _tutorials: TutorialPrompt = TutorialPrompt.new()
var _player: PlayerController = null
var _control_mode: PlayerController.ControlMode = PlayerController.ControlMode.GAMEPLAY
var _hooks_ready: bool = false
var _notify_queue: Array[String] = []
var _notify_showing: bool = false
var _pending_group_lines: PackedStringArray = PackedStringArray()
var _group_flush_scheduled: bool = false
var _reach_milestones_fired: Dictionary = {}
var _movement_armed: bool = false
var _title_suppressed: bool = false


func _ready() -> void:
	layer = 18
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_apply_theme_and_scale()
	_refresh_resources()
	_hook_signals()
	call_deferred("_bind_player")
	_update_visibility()


func set_title_suppressed(suppressed: bool) -> void:
	## MODULE24: hide gameplay HUD while title menu is active.
	_title_suppressed = suppressed
	_update_visibility()


func set_ui_scale_percent(percent: int) -> void:
	UiScaleHelper.set_ui_scale_percent(percent)
	_apply_theme_and_scale()


func get_ui_scale_percent() -> int:
	return int(round(UiScaleHelper.get_ui_scale() * 100.0))


func notify_major_money(amount: int, label: String = "") -> void:
	if amount == 0:
		return
	var prefix: String = label.strip_edges()
	if prefix == "":
		prefix = "Деньги"
	_enqueue_grouped("%s %s" % [prefix, UiNumberFormat.format_signed(amount)])


func show_notification(message: String) -> void:
	_enqueue_notification(message)


func _build_ui() -> void:
	_scale_root = Control.new()
	_scale_root.name = "ScaleRoot"
	_scale_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scale_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scale_root)

	_gameplay_root = Control.new()
	_gameplay_root.name = "GameplayRoot"
	_gameplay_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gameplay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scale_root.add_child(_gameplay_root)

	var resources := PanelContainer.new()
	resources.name = "ResourcePanel"
	resources.position = Vector2(16, 16)
	resources.custom_minimum_size = Vector2(220, 0)
	resources.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gameplay_root.add_child(resources)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	resources.add_child(vbox)
	_money_label = _make_hud_label("MoneyLabel", "$ 0")
	_authority_label = _make_hud_label("AuthorityLabel", "АВТОРИТЕТ 0")
	_experience_label = _make_hud_label("ExperienceLabel", "ОПЫТНОСТЬ 0")
	_points_label = _make_hud_label("PointsLabel", "БАЛЛЫ 0")
	for lab in [_money_label, _authority_label, _experience_label, _points_label]:
		vbox.add_child(lab)

	_crosshair = Control.new()
	_crosshair.name = "Crosshair"
	_crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_crosshair.custom_minimum_size = Vector2(12, 12)
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gameplay_root.add_child(_crosshair)
	var h := ColorRect.new()
	h.color = Color(0.93, 0.94, 0.95, 0.85)
	h.size = Vector2(10, 2)
	h.position = Vector2(1, 5)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crosshair.add_child(h)
	var v := ColorRect.new()
	v.color = Color(0.93, 0.94, 0.95, 0.85)
	v.size = Vector2(2, 10)
	v.position = Vector2(5, 1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crosshair.add_child(v)

	var notify_host := Control.new()
	notify_host.name = "NotifyHost"
	notify_host.set_anchors_preset(Control.PRESET_TOP_WIDE)
	notify_host.offset_top = 20
	notify_host.offset_bottom = 120
	notify_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scale_root.add_child(notify_host)
	_notify_panel = PanelContainer.new()
	_notify_panel.name = "NotifyPanel"
	_notify_panel.visible = false
	_notify_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notify_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_notify_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	notify_host.add_child(_notify_panel)
	_notify_label = Label.new()
	_notify_label.name = "NotifyLabel"
	_notify_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notify_label.add_theme_font_size_override("font_size", 20)
	_notify_panel.add_child(_notify_label)

	_stage_panel = PanelContainer.new()
	_stage_panel.name = "StageCard"
	_stage_panel.visible = false
	_stage_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_panel.set_anchors_preset(Control.PRESET_CENTER)
	_stage_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_stage_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_scale_root.add_child(_stage_panel)
	var stage_box := VBoxContainer.new()
	stage_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_stage_panel.add_child(stage_box)
	_stage_title = Label.new()
	_stage_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage_title.add_theme_font_size_override("font_size", 32)
	stage_box.add_child(_stage_title)
	_stage_subtitle = Label.new()
	_stage_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage_subtitle.add_theme_font_size_override("font_size", 24)
	stage_box.add_child(_stage_subtitle)

	_tutorial_panel = PanelContainer.new()
	_tutorial_panel.name = "TutorialPanel"
	_tutorial_panel.visible = false
	_tutorial_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_tutorial_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_tutorial_panel.offset_bottom = -96
	_tutorial_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_scale_root.add_child(_tutorial_panel)
	_tutorial_label = Label.new()
	_tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_label.add_theme_font_size_override("font_size", 18)
	_tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutorial_label.custom_minimum_size = Vector2(420, 0)
	_tutorial_panel.add_child(_tutorial_label)
	_tutorial_panel.gui_input.connect(_on_tutorial_gui_input)

	_notify_timer = Timer.new()
	_notify_timer.one_shot = true
	_notify_timer.wait_time = NOTIFY_SECONDS
	_notify_timer.timeout.connect(_on_notify_timeout)
	add_child(_notify_timer)
	_stage_timer = Timer.new()
	_stage_timer.one_shot = true
	_stage_timer.wait_time = STAGE_SECONDS
	_stage_timer.timeout.connect(_on_stage_timeout)
	add_child(_stage_timer)
	_tutorial_timer = Timer.new()
	_tutorial_timer.one_shot = true
	_tutorial_timer.wait_time = TutorialPrompt.DISPLAY_SECONDS
	_tutorial_timer.timeout.connect(_on_tutorial_timeout)
	add_child(_tutorial_timer)


func _make_hud_label(node_name: String, text: String) -> Label:
	var lab := Label.new()
	lab.name = node_name
	lab.text = text
	lab.add_theme_font_size_override("font_size", 20)
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lab


func _apply_theme_and_scale() -> void:
	var theme: Theme = null
	if ResourceLoader.exists(THEME_PATH):
		theme = load(THEME_PATH) as Theme
	if theme == null:
		theme = DateFactoryThemeBuilder.build()
	_scale_root.theme = theme
	UiScaleHelper.apply_to_control(_scale_root)


func _hook_signals() -> void:
	if _hooks_ready:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		_connect(gs, "money_changed", _on_money_changed)
		_connect(gs, "authority_changed", _on_authority_changed)
		_connect(gs, "experience_changed", _on_experience_changed)
		_connect(gs, "upgrade_points_changed", _on_upgrade_points_changed)
		_connect(gs, "stage_changed", _on_stage_changed)
		_connect(gs, "state_reset", _on_state_reset)
		_connect(gs, "world_reach_changed", _on_world_reach_changed)
	var story: Node = get_node_or_null("/root/Story")
	if story != null:
		_connect(story, "feature_unlocked", _on_feature_unlocked)
	var salary: Node = get_node_or_null("/root/SalaryMine")
	if salary != null:
		_connect(salary, "salary_claimed", _on_salary_claimed)
	var rivals: Node = get_node_or_null("/root/RivalEncounters")
	if rivals != null:
		_connect(rivals, "encounter_started", _on_rival_encounter_started)
	var dating: Node = get_node_or_null("/root/DatingCore")
	if dating != null:
		_connect(dating, "phase_changed", _on_dating_phase_changed)
	var first_clone: Node = get_node_or_null("/root/FirstClone")
	if first_clone != null:
		_connect(first_clone, "first_clone_completed", _on_first_clone_completed)
	_hooks_ready = true


func _connect(host: Object, signal_name: StringName, callable: Callable) -> void:
	if host == null:
		return
	if not host.has_signal(signal_name):
		return
	if host.is_connected(signal_name, callable):
		return
	host.connect(signal_name, callable)


func _bind_player() -> void:
	var world: Node = get_node_or_null("/root/World")
	var player: PlayerController = null
	if world != null and world.has_method("get_player"):
		player = world.call("get_player") as PlayerController
	if player == null:
		var tree: SceneTree = get_tree()
		if tree != null:
			player = tree.get_first_node_in_group("player") as PlayerController
	if player == null:
		return
	if _player == player:
		return
	if _player != null and is_instance_valid(_player):
		if _player.control_mode_changed.is_connected(_on_control_mode_changed):
			_player.control_mode_changed.disconnect(_on_control_mode_changed)
	_player = player
	_control_mode = _player.get_control_mode()
	if not _player.control_mode_changed.is_connected(_on_control_mode_changed):
		_player.control_mode_changed.connect(_on_control_mode_changed)
	_hide_player_fps_crosshair()
	_bind_phone_signals()
	_update_visibility()
	_try_show_next_tutorial()


func _hide_player_fps_crosshair() -> void:
	# GameHUD owns the single gameplay crosshair; Player FpsHud keeps [E] prompt.
	if _player == null:
		return
	var cross: CanvasItem = _player.get_node_or_null("FpsHud/Crosshair") as CanvasItem
	if cross != null:
		cross.visible = false


func _bind_phone_signals() -> void:
	var world: Node = get_node_or_null("/root/World")
	if world == null or not world.has_method("get_phone_journal"):
		return
	var phone: Node = world.call("get_phone_journal") as Node
	if phone == null:
		return
	_connect(phone, "opened", _on_phone_opened)


func _unhandled_input(event: InputEvent) -> void:
	if _control_mode != PlayerController.ControlMode.GAMEPLAY:
		return
	if _movement_armed:
		return
	var moved: bool = false
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		moved = true
	elif event.is_action_pressed("move_forward") or event.is_action_pressed("move_backward") \
			or event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		moved = true
	if moved:
		_movement_armed = true
		_tutorials.request(TutorialPrompt.PromptId.FIRST_MOVEMENT)
		_try_show_next_tutorial()


func _on_control_mode_changed(mode: PlayerController.ControlMode) -> void:
	_control_mode = mode
	_hide_player_fps_crosshair()
	_update_visibility()
	if mode == PlayerController.ControlMode.GAMEPLAY:
		_try_show_next_tutorial()


func _update_visibility() -> void:
	var gameplay: bool = (
		(not _title_suppressed)
		and _control_mode == PlayerController.ControlMode.GAMEPLAY
	)
	_gameplay_root.visible = gameplay
	if not gameplay:
		# Stage/notify rails must not ghost under modal/minigame owners.
		_stage_panel.visible = false
		_stage_timer.stop()
		_notify_panel.visible = false
		if _tutorials.is_showing():
			_dismiss_tutorial()
	elif _notify_showing:
		_notify_panel.visible = true


func _refresh_resources() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	var money: int = int(gs.call("get_money"))
	var authority: int = int(gs.call("get_authority"))
	var experience: int = int(gs.call("get_experience"))
	var points: int = int(gs.call("get_upgrade_points"))
	_money_label.text = UiNumberFormat.format_money(money)
	_authority_label.text = "АВТОРИТЕТ %d" % authority
	_experience_label.text = "ОПЫТНОСТЬ %d" % experience
	_points_label.text = "БАЛЛЫ %d" % points


func _on_money_changed(_new_value: int, _delta: int) -> void:
	_refresh_resources()


func _on_authority_changed(_new_value: int, delta: int) -> void:
	_refresh_resources()
	if delta != 0:
		_enqueue_grouped("Авторитет %s" % UiNumberFormat.format_signed(delta))


func _on_experience_changed(_new_value: int, delta: int) -> void:
	_refresh_resources()
	if delta != 0:
		_enqueue_grouped("Опытность %s" % UiNumberFormat.format_signed(delta))


func _on_upgrade_points_changed(_new_value: int, delta: int) -> void:
	_refresh_resources()
	if delta > 0:
		_enqueue_grouped("Балл прокачки %s" % UiNumberFormat.format_signed(delta))
		_tutorials.request(TutorialPrompt.PromptId.FIRST_UPGRADE_POINT)
		_try_show_next_tutorial()


func _on_stage_changed(new_stage: GameTypes.GameStage, _previous_stage: GameTypes.GameStage) -> void:
	_show_stage_card(new_stage)
	if new_stage == GameTypes.GameStage.STAGE_6:
		_tutorials.request(TutorialPrompt.PromptId.FIRST_STAGE6)
		_try_show_next_tutorial()


func _on_state_reset() -> void:
	_notify_queue.clear()
	_pending_group_lines = PackedStringArray()
	_group_flush_scheduled = false
	_notify_showing = false
	_notify_panel.visible = false
	_notify_timer.stop()
	_stage_panel.visible = false
	_stage_timer.stop()
	_dismiss_tutorial()
	_tutorials.reset_runtime()
	_reach_milestones_fired.clear()
	_movement_armed = false
	_refresh_resources()
	call_deferred("_bind_player")


func _on_world_reach_changed(new_value: int, _delta: int) -> void:
	for milestone in REACH_MILESTONES:
		if new_value >= milestone and not bool(_reach_milestones_fired.get(milestone, false)):
			_reach_milestones_fired[milestone] = true
			_enqueue_notification("Охват Земли: %d%%" % milestone)
			if milestone >= 100:
				_audio_play_sfx(AudioIds.FINAL_SIGNAL)
			else:
				_audio_play_sfx(AudioIds.REWARD_MAJOR)


func _on_feature_unlocked(feature: StoryTypes.StoryFeature) -> void:
	var copy: String = String(FEATURE_COPY.get(int(feature), ""))
	if copy.strip_edges() == "":
		return
	_enqueue_notification(copy)


func _on_salary_claimed(amount: int, _method: Variant) -> void:
	if amount > 0:
		notify_major_money(amount, "Зарплата")


func _on_phone_opened() -> void:
	_tutorials.request(TutorialPrompt.PromptId.FIRST_PHONE)
	_try_show_next_tutorial()


func _on_rival_encounter_started(_session: Variant) -> void:
	_tutorials.request(TutorialPrompt.PromptId.FIRST_RIVAL)
	_try_show_next_tutorial()


func _on_dating_phase_changed(_phase: Variant) -> void:
	_tutorials.request(TutorialPrompt.PromptId.FIRST_DATE)
	_try_show_next_tutorial()


func _on_first_clone_completed() -> void:
	_tutorials.request(TutorialPrompt.PromptId.FIRST_CLONE)
	_try_show_next_tutorial()


func _enqueue_grouped(line: String) -> void:
	if line.strip_edges() == "":
		return
	_pending_group_lines.append(line)
	if _group_flush_scheduled:
		return
	_group_flush_scheduled = true
	call_deferred("_flush_grouped_notifications")


func _flush_grouped_notifications() -> void:
	_group_flush_scheduled = false
	if _pending_group_lines.is_empty():
		return
	var text: String = "\n".join(_pending_group_lines)
	_pending_group_lines = PackedStringArray()
	_audio_play_sfx(AudioIds.REWARD_SMALL)
	_enqueue_notification(text)


func _enqueue_notification(text: String) -> void:
	var cleaned: String = text.strip_edges()
	if cleaned == "":
		return
	if _notify_queue.size() >= NOTIFY_QUEUE_MAX:
		_notify_queue.pop_front()
	_notify_queue.append(cleaned)
	if not _notify_showing:
		_show_next_notification()


func _show_next_notification() -> void:
	if _notify_queue.is_empty():
		_notify_showing = false
		_notify_panel.visible = false
		return
	_notify_showing = true
	_notify_label.text = _notify_queue.pop_front()
	_notify_panel.visible = _control_mode == PlayerController.ControlMode.GAMEPLAY
	_notify_timer.start(NOTIFY_SECONDS)


func _on_notify_timeout() -> void:
	_show_next_notification()


func _show_stage_card(stage: GameTypes.GameStage) -> void:
	if stage == GameTypes.GameStage.FINALE:
		_stage_title.text = "ФИНАЛ"
		_stage_subtitle.text = ""
		_stage_subtitle.visible = false
	else:
		var stage_no: int = int(stage)
		_stage_title.text = "СТАДИЯ %d" % stage_no
		var name: String = _stage_display_name(stage)
		_stage_subtitle.text = name.to_upper()
		_stage_subtitle.visible = name.strip_edges() != ""
	_stage_panel.visible = _control_mode == PlayerController.ControlMode.GAMEPLAY
	_stage_timer.start(STAGE_SECONDS)
	_audio_play_sfx(AudioIds.STAGE_ADVANCE)


func _stage_display_name(stage: GameTypes.GameStage) -> String:
	var story: Node = get_node_or_null("/root/Story")
	if story != null and story.has_method("get_current_definition"):
		var def: StoryStageDefinition = story.call("get_current_definition") as StoryStageDefinition
		if def != null and int(def.stage) == int(stage) and def.display_name.strip_edges() != "":
			return def.display_name
	var db: Node = get_node_or_null("/root/ContentDB")
	if db != null and db.has_method("get_stage"):
		var def2: StoryStageDefinition = db.call("get_stage", stage) as StoryStageDefinition
		if def2 != null and def2.display_name.strip_edges() != "":
			return def2.display_name
	return ""


func _on_stage_timeout() -> void:
	_stage_panel.visible = false


func _try_show_next_tutorial() -> void:
	if _control_mode != PlayerController.ControlMode.GAMEPLAY:
		return
	if _tutorials.is_showing():
		return
	if not _tutorials.has_pending():
		return
	var payload: Dictionary = _tutorials.begin_next()
	if payload.is_empty():
		return
	_tutorial_label.text = str(payload.get("text", ""))
	_tutorial_panel.visible = true
	var seconds: float = float(payload.get("seconds", TutorialPrompt.DISPLAY_SECONDS))
	_tutorial_timer.start(seconds)


func _dismiss_tutorial() -> void:
	_tutorial_timer.stop()
	_tutorial_panel.visible = false
	_tutorials.dismiss_active()


func _on_tutorial_timeout() -> void:
	_dismiss_tutorial()
	_try_show_next_tutorial()


func _on_tutorial_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_dismiss_tutorial()
		_try_show_next_tutorial()
		_tutorial_panel.accept_event()


func _audio_play_sfx(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_sfx"):
		ad.call("play_sfx", sound_id)
