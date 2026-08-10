class_name GameHUD
extends CanvasLayer
## Persistent presentation HUD (MODULE 22). Event-driven; no gameplay formulas.

const NOTIFY_SECONDS: float = 2.2
const STAGE_SECONDS: float = 3.0
const NOTIFY_SLIDE_PX: float = 56.0
const NOTIFY_SLIDE_SEC: float = 0.18
const NOTIFY_HOST_OFFSET_TOP: float = -130.0
const NOTIFY_HOST_OFFSET_BOTTOM: float = -20.0
const REACH_MILESTONES: Array[int] = [25, 50, 75, 100]
const STAGE0_OBJECTIVE_FALLBACK: String = "Познакомься с соседкой."
const MOVE_EVIDENCE_THRESHOLD: float = 0.35
## Meaningful look after the card is readable (ignores tiny capture jitter).
const LOOK_EVIDENCE_PIXELS: float = 48.0
## Do not count look until FIRST_MOVEMENT has been on-screen in GAMEPLAY.
const LOOK_ARM_DELAY_MS: int = 550
## Reject single-frame cursor-capture / warp spikes.
const LOOK_WARP_REJECT_PIXELS: float = 140.0

const FEATURE_COPY := {
	int(StoryTypes.StoryFeature.SOCIAL_ACCESS): "ОТКРЫТО: СОЦИАЛЬНЫЙ ДОСТУП",
	int(StoryTypes.StoryFeature.PUBLIC_CITY_ACCESS): "Открыт новый район города",
	int(StoryTypes.StoryFeature.SALARY_MINE): "ОТКРЫТО: ЗАРПЛАТНАЯ ШАХТА",
	int(StoryTypes.StoryFeature.MEDIA_ATTENTION): "ОТКРЫТО: МЕДИЙНОЕ ВНИМАНИЕ",
	int(StoryTypes.StoryFeature.LABORATORY): "ОТКРЫТО: ЛАБОРАТОРИЯ",
	int(StoryTypes.StoryFeature.WORLD_EXPANSION): "ОТКРЫТО: МИРОВОЕ РАСШИРЕНИЕ",
	int(StoryTypes.StoryFeature.FINAL_DATE): "ОТКРЫТО: ФИНАЛЬНОЕ СВИДАНИЕ",
}

@onready var _scale_root: Control = %ScaleRoot
@onready var _gameplay_root: Control = %GameplayRoot
@onready var _money_label: Label = %MoneyLabel
@onready var _authority_label: Label = %AuthorityLabel
@onready var _experience_label: Label = %ExperienceLabel
@onready var _points_label: Label = %PointsLabel
@onready var _crosshair: Control = %Crosshair
@onready var _objective_panel: PanelContainer = %ObjectivePanel
@onready var _objective_title: Label = %ObjectiveTitle
@onready var _objective_body: Label = %ObjectiveBody
@onready var _notify_host: MarginContainer = %NotifyHost
@onready var _notify_panel: PanelContainer = %NotifyPanel
@onready var _notify_label: Label = %NotifyLabel
@onready var _stage_panel: PanelContainer = %StageCard
@onready var _stage_title: Label = %StageTitle
@onready var _stage_subtitle: Label = %StageSubtitle
@onready var _tutorial_panel: PanelContainer = %TutorialPanel
@onready var _tutorial_label: Label = %TutorialLabel
@onready var _notify_timer: Timer = %NotifyTimer
@onready var _stage_timer: Timer = %StageTimer
@onready var _tutorial_timer: Timer = %TutorialTimer

var _tutorials: TutorialPrompt = TutorialPrompt.new()
var _player: PlayerController = null
var _control_mode: PlayerController.ControlMode = PlayerController.ControlMode.GAMEPLAY
var _hooks_ready: bool = false
var _notify_showing: bool = false
var _notify_tween: Tween = null
var _pending_group_lines: PackedStringArray = PackedStringArray()
var _group_flush_scheduled: bool = false
var _reach_milestones_fired: Dictionary = {}
var _title_suppressed: bool = false
var _tutorial_evidence_based: bool = false
var _evidence_moved: bool = false
var _evidence_looked: bool = false
var _evidence_interacted: bool = false
var _move_accum: float = 0.0
var _look_accum: float = 0.0
var _look_evidence_armed: bool = false
var _look_arm_after_msec: int = 0


func _ready() -> void:
	layer = 18
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_theme_and_scale()
	_notify_timer.timeout.connect(_on_notify_timeout)
	_stage_timer.timeout.connect(_on_stage_timeout)
	_tutorial_timer.wait_time = TutorialPrompt.DISPLAY_SECONDS
	_tutorial_timer.timeout.connect(_on_tutorial_timeout)
	_refresh_resources()
	_hook_signals()
	_restore_tutorials_from_settings()
	call_deferred("_bind_player")
	_update_visibility()
	_refresh_objective()


func set_title_suppressed(suppressed: bool) -> void:
	## MODULE24: hide gameplay HUD while title menu is active.
	_title_suppressed = suppressed
	_update_visibility()
	if not suppressed:
		_request_controls_onboarding()
		_try_show_next_tutorial()
		_refresh_objective()


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


func get_tutorial_prompt() -> TutorialPrompt:
	return _tutorials


func _apply_theme_and_scale() -> void:
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
		_connect(gs, "girl_contact_added", _on_girl_contact_added)
	var story: Node = get_node_or_null("/root/Story")
	if story != null:
		_connect(story, "feature_unlocked", _on_feature_unlocked)
		_connect(story, "stage_objective_changed", _on_story_objective_changed)
		_connect(story, "stage_started", _on_story_stage_started)
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
	var ss: Node = get_node_or_null("/root/SaveSystem")
	if ss != null:
		_connect(ss, "settings_applied", _on_settings_applied)
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
		_request_controls_onboarding()
		_try_show_next_tutorial()
		_refresh_objective()
		return
	if _player != null and is_instance_valid(_player):
		if _player.control_mode_changed.is_connected(_on_control_mode_changed):
			_player.control_mode_changed.disconnect(_on_control_mode_changed)
		if _player.interaction_succeeded.is_connected(_on_interaction_succeeded):
			_player.interaction_succeeded.disconnect(_on_interaction_succeeded)
	_player = player
	_control_mode = _player.get_control_mode()
	if not _player.control_mode_changed.is_connected(_on_control_mode_changed):
		_player.control_mode_changed.connect(_on_control_mode_changed)
	if not _player.interaction_succeeded.is_connected(_on_interaction_succeeded):
		_player.interaction_succeeded.connect(_on_interaction_succeeded)
	_hide_player_fps_crosshair()
	_bind_phone_signals()
	_update_visibility()
	_request_controls_onboarding()
	_try_show_next_tutorial()
	_refresh_objective()
	call_deferred("_ensure_controls_card_visible")


func _hide_player_fps_crosshair() -> void:
	# GameHUD owns the single gameplay crosshair; Player FpsHud keeps interaction prompt.
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


func _physics_process(delta: float) -> void:
	if not _tutorial_evidence_based:
		return
	if _control_mode != PlayerController.ControlMode.GAMEPLAY:
		return
	if _title_suppressed:
		return
	_update_look_evidence_arm()
	if _player == null or not is_instance_valid(_player):
		return
	if not _evidence_moved:
		var horizontal: Vector3 = Vector3(_player.velocity.x, 0.0, _player.velocity.z)
		var moving_input: bool = (
			Input.is_action_pressed("move_forward")
			or Input.is_action_pressed("move_backward")
			or Input.is_action_pressed("move_left")
			or Input.is_action_pressed("move_right")
		)
		if horizontal.length() > 0.05:
			_move_accum += horizontal.length() * delta
		elif moving_input:
			# Count intentional WASD even when spawn geometry blocks velocity.
			_move_accum += delta
		if _move_accum >= MOVE_EVIDENCE_THRESHOLD:
			_evidence_moved = true
			_refresh_controls_card()


func _unhandled_input(event: InputEvent) -> void:
	if _control_mode != PlayerController.ControlMode.GAMEPLAY:
		return
	if _title_suppressed:
		return
	if not _tutorial_evidence_based:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		_apply_look_relative(motion.relative)
	elif event.is_action_pressed("move_forward") or event.is_action_pressed("move_backward") \
			or event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		# Key press also counts toward movement teaching while velocity accumulates.
		if not _evidence_moved:
			_move_accum += 0.12
			if _move_accum >= MOVE_EVIDENCE_THRESHOLD:
				_evidence_moved = true
				_refresh_controls_card()


func _apply_look_relative(relative: Vector2) -> void:
	# Menu click / capture warp / pre-presentation motion must never clear Мышь.
	if not _can_accept_look_evidence():
		return
	var mag: float = absf(relative.x) + absf(relative.y)
	if mag <= 0.0 or mag >= LOOK_WARP_REJECT_PIXELS:
		return
	_look_accum += mag
	if not _evidence_looked and _look_accum >= LOOK_EVIDENCE_PIXELS:
		_evidence_looked = true
		_refresh_controls_card()


func _begin_look_evidence_gate() -> void:
	## Call when FIRST_MOVEMENT becomes visibly presented; ignore prior/transition look.
	if _evidence_looked:
		return
	_look_accum = 0.0
	_look_evidence_armed = false
	_look_arm_after_msec = Time.get_ticks_msec() + LOOK_ARM_DELAY_MS


func _update_look_evidence_arm() -> void:
	if _evidence_looked or _look_evidence_armed:
		return
	if not _tutorial_evidence_based:
		return
	if _tutorial_panel == null or not _tutorial_panel.visible:
		return
	if Time.get_ticks_msec() < _look_arm_after_msec:
		return
	_look_evidence_armed = true
	_look_accum = 0.0


func _can_accept_look_evidence() -> bool:
	if _evidence_looked:
		return false
	if not _tutorial_evidence_based:
		return false
	if _tutorial_panel == null or not _tutorial_panel.visible:
		return false
	_update_look_evidence_arm()
	return _look_evidence_armed


func _on_control_mode_changed(mode: PlayerController.ControlMode) -> void:
	_control_mode = mode
	_hide_player_fps_crosshair()
	_update_visibility()
	if mode == PlayerController.ControlMode.GAMEPLAY:
		_try_show_next_tutorial()
		_refresh_objective()


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
			_suspend_tutorial()
	else:
		if _notify_showing:
			_notify_panel.visible = true
		_try_show_next_tutorial()


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
	_experience_label.text = "ПОКОРЕННЫХ СЕРДЕЦ %d" % experience
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
		_enqueue_grouped("Покоренных сердец %s" % UiNumberFormat.format_signed(delta))


func _on_upgrade_points_changed(_new_value: int, delta: int) -> void:
	_refresh_resources()
	if delta > 0:
		_enqueue_grouped("Балл прокачки %s" % UiNumberFormat.format_signed(delta))
		_tutorials.request(TutorialPrompt.PromptId.FIRST_UPGRADE_POINT)
		_try_show_next_tutorial()


func _on_stage_changed(new_stage: GameTypes.GameStage, _previous_stage: GameTypes.GameStage) -> void:
	_show_stage_card(new_stage)
	_refresh_objective()
	if new_stage == GameTypes.GameStage.STAGE_6:
		_tutorials.request(TutorialPrompt.PromptId.FIRST_STAGE6)
		_try_show_next_tutorial()


func _on_story_objective_changed(_progress: StoryStageProgress) -> void:
	_refresh_objective()


func _on_story_stage_started(_stage: GameTypes.GameStage) -> void:
	_refresh_objective()


func _on_state_reset() -> void:
	_pending_group_lines = PackedStringArray()
	_group_flush_scheduled = false
	_hide_notification(false)
	_stage_panel.visible = false
	_stage_timer.stop()
	_suspend_tutorial()
	_tutorials.reset_runtime()
	_restore_tutorials_from_settings()
	_reach_milestones_fired.clear()
	_reset_controls_evidence()
	_refresh_resources()
	_refresh_objective()
	call_deferred("_bind_player")


func _on_settings_applied() -> void:
	_restore_tutorials_from_settings()
	_request_controls_onboarding()
	_try_show_next_tutorial()


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


func _on_interaction_succeeded(_target: Area3D) -> void:
	# Always record: Neighbor modal can suspend the card in the same interact call.
	if _tutorials.has_seen(TutorialPrompt.PromptId.FIRST_MOVEMENT):
		return
	if _evidence_interacted:
		return
	_evidence_interacted = true
	if _tutorial_evidence_based:
		_refresh_controls_card()


func _on_girl_contact_added(_girl_id: StringName) -> void:
	_refresh_objective()


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
	## Immediate replace: newest card wins; no pending queue.
	var cleaned: String = text.strip_edges()
	if cleaned == "":
		return
	_notify_label.text = cleaned
	_notify_showing = true
	var gameplay: bool = (
		(not _title_suppressed)
		and _control_mode == PlayerController.ControlMode.GAMEPLAY
	)
	_notify_panel.visible = gameplay
	_notify_timer.start(NOTIFY_SECONDS)
	if gameplay:
		_play_notify_slide_in()


func _play_notify_slide_in() -> void:
	if _notify_tween != null and is_instance_valid(_notify_tween):
		_notify_tween.kill()
	_notify_host.modulate.a = 0.0
	_notify_host.offset_top = NOTIFY_HOST_OFFSET_TOP + NOTIFY_SLIDE_PX
	_notify_host.offset_bottom = NOTIFY_HOST_OFFSET_BOTTOM + NOTIFY_SLIDE_PX
	_notify_tween = create_tween()
	_notify_tween.set_parallel(true)
	_notify_tween.tween_property(_notify_host, "modulate:a", 1.0, NOTIFY_SLIDE_SEC)
	_notify_tween.tween_property(
		_notify_host, "offset_top", NOTIFY_HOST_OFFSET_TOP, NOTIFY_SLIDE_SEC
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_notify_tween.tween_property(
		_notify_host, "offset_bottom", NOTIFY_HOST_OFFSET_BOTTOM, NOTIFY_SLIDE_SEC
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _hide_notification(animate: bool) -> void:
	_notify_showing = false
	_notify_timer.stop()
	if _notify_tween != null and is_instance_valid(_notify_tween):
		_notify_tween.kill()
		_notify_tween = null
	if animate and _notify_panel.visible:
		_notify_tween = create_tween()
		_notify_tween.set_parallel(true)
		_notify_tween.tween_property(_notify_host, "modulate:a", 0.0, NOTIFY_SLIDE_SEC)
		_notify_tween.tween_property(
			_notify_host,
			"offset_top",
			NOTIFY_HOST_OFFSET_TOP + NOTIFY_SLIDE_PX,
			NOTIFY_SLIDE_SEC
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_notify_tween.tween_property(
			_notify_host,
			"offset_bottom",
			NOTIFY_HOST_OFFSET_BOTTOM + NOTIFY_SLIDE_PX,
			NOTIFY_SLIDE_SEC
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_notify_tween.finished.connect(_on_notify_hide_finished, CONNECT_ONE_SHOT)
	else:
		_notify_panel.visible = false
		_notify_host.modulate.a = 1.0
		_notify_host.offset_top = NOTIFY_HOST_OFFSET_TOP
		_notify_host.offset_bottom = NOTIFY_HOST_OFFSET_BOTTOM


func _on_notify_hide_finished() -> void:
	_notify_tween = null
	if _notify_showing:
		return
	_notify_panel.visible = false
	_notify_host.modulate.a = 1.0
	_notify_host.offset_top = NOTIFY_HOST_OFFSET_TOP
	_notify_host.offset_bottom = NOTIFY_HOST_OFFSET_BOTTOM


func _on_notify_timeout() -> void:
	_hide_notification(true)


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


func _request_controls_onboarding() -> void:
	if _tutorials.has_seen(TutorialPrompt.PromptId.FIRST_MOVEMENT):
		return
	_tutorials.request(TutorialPrompt.PromptId.FIRST_MOVEMENT)


func _ensure_controls_card_visible() -> void:
	if _tutorials.has_seen(TutorialPrompt.PromptId.FIRST_MOVEMENT):
		return
	_request_controls_onboarding()
	_try_show_next_tutorial()


func _reset_controls_evidence() -> void:
	_tutorial_evidence_based = false
	_evidence_moved = false
	_evidence_looked = false
	_evidence_interacted = false
	_move_accum = 0.0
	_look_accum = 0.0
	_look_evidence_armed = false
	_look_arm_after_msec = 0


func _try_show_next_tutorial() -> void:
	if _control_mode != PlayerController.ControlMode.GAMEPLAY:
		return
	if _title_suppressed:
		return
	if _tutorials.is_showing():
		return
	if not _tutorials.has_pending():
		return
	# If FIRST_MOVEMENT evidence already complete (e.g. after Neighbor modal), finish silently.
	if (
		_tutorials.peek_pending() == int(TutorialPrompt.PromptId.FIRST_MOVEMENT)
		and _evidence_moved
		and _evidence_looked
		and _evidence_interacted
	):
		var done_payload: Dictionary = _tutorials.begin_next()
		if not done_payload.is_empty():
			_tutorial_evidence_based = true
			_complete_controls_card()
		return
	var payload: Dictionary = _tutorials.begin_next()
	if payload.is_empty():
		return
	var prompt_id: int = int(payload.get("id", -1))
	_tutorial_evidence_based = bool(payload.get("evidence_based", false))
	if _tutorial_evidence_based and prompt_id == int(TutorialPrompt.PromptId.FIRST_MOVEMENT):
		if _evidence_moved and _evidence_looked and _evidence_interacted:
			_complete_controls_card()
			return
		_tutorial_label.text = _tutorials.controls_card_text(
			_evidence_moved, _evidence_looked, _evidence_interacted
		)
		# Gate look only after this presentation is on-screen (not menu/capture warp).
		_begin_look_evidence_gate()
	else:
		_tutorial_label.text = str(payload.get("text", ""))
	_tutorial_panel.visible = _tutorial_label.text.strip_edges() != ""
	_tutorial_timer.stop()
	var seconds: float = float(payload.get("seconds", TutorialPrompt.DISPLAY_SECONDS))
	if seconds > 0.0 and not _tutorial_evidence_based:
		_tutorial_timer.start(seconds)
	_persist_tutorials_to_settings()


func _refresh_controls_card() -> void:
	if not _tutorial_evidence_based:
		return
	if _tutorials.get_active_id() != int(TutorialPrompt.PromptId.FIRST_MOVEMENT):
		return
	if _evidence_moved and _evidence_looked and _evidence_interacted:
		_complete_controls_card()
		return
	var text: String = _tutorials.controls_card_text(
		_evidence_moved, _evidence_looked, _evidence_interacted
	)
	_tutorial_label.text = text
	_tutorial_panel.visible = (
		text.strip_edges() != ""
		and _control_mode == PlayerController.ControlMode.GAMEPLAY
		and not _title_suppressed
	)


func _complete_controls_card() -> void:
	_tutorial_timer.stop()
	_tutorial_panel.visible = false
	_tutorial_evidence_based = false
	_tutorials.complete_active()
	_persist_tutorials_to_settings()
	_try_show_next_tutorial()


func _suspend_tutorial() -> void:
	_tutorial_timer.stop()
	_tutorial_panel.visible = false
	_look_evidence_armed = false
	if _tutorial_evidence_based:
		if _evidence_moved and _evidence_looked and _evidence_interacted:
			_tutorials.complete_active()
			_tutorial_evidence_based = false
			_persist_tutorials_to_settings()
			return
		_tutorials.suspend_active()
		_tutorial_evidence_based = false
	else:
		_tutorials.dismiss_active()


func _on_tutorial_timeout() -> void:
	# Evidence-based cards never idle-timeout.
	if _tutorial_evidence_based:
		return
	_tutorial_panel.visible = false
	_tutorials.dismiss_active()
	_try_show_next_tutorial()


func _restore_tutorials_from_settings() -> void:
	var ss: Node = get_node_or_null("/root/SaveSystem")
	if ss == null or not ss.has_method("get_tutorial_seen_ids"):
		return
	var ids: Array = ss.call("get_tutorial_seen_ids") as Array
	_tutorials.restore_seen_ids(ids)


func _persist_tutorials_to_settings() -> void:
	var ss: Node = get_node_or_null("/root/SaveSystem")
	if ss == null:
		return
	var ids: Array[String] = _tutorials.export_seen_ids()
	var as_array: Array = []
	for item in ids:
		as_array.append(item)
	if ss.has_method("set_tutorial_seen_ids"):
		ss.call("set_tutorial_seen_ids", as_array)
	if ss.has_method("save_settings"):
		ss.call("save_settings")


func _refresh_objective() -> void:
	if _objective_body == null:
		return
	var text: String = _resolve_objective_text()
	_objective_body.text = text
	var show_obj: bool = (
		text.strip_edges() != ""
		and not _title_suppressed
		and _control_mode == PlayerController.ControlMode.GAMEPLAY
	)
	_objective_panel.visible = show_obj


func _resolve_objective_text() -> String:
	var story: Node = get_node_or_null("/root/Story")
	if story == null or not story.has_method("get_current_progress"):
		return STAGE0_OBJECTIVE_FALLBACK
	var progress: StoryStageProgress = story.call("get_current_progress") as StoryStageProgress
	if progress == null:
		return STAGE0_OBJECTIVE_FALLBACK
	# Stage-0 / prologue: meet Neighbor until contact; then Phone-canonical next date line.
	# Read-model: StoryStageProgress.story_girl_id + GameState.has_girl_contact /
	# get_girl_date_cooldown_days_remaining (same copy as Phone girl detail).
	if progress.stage == GameTypes.GameStage.PROLOGUE:
		return _prologue_objective_text(progress)
	var phone_line: String = _objective_from_phone_story()
	if phone_line.strip_edges() != "":
		return phone_line
	var display: String = progress.display_name.strip_edges()
	if display != "":
		return display
	return ""


func _prologue_objective_text(progress: StoryStageProgress) -> String:
	var girl_id: StringName = progress.story_girl_id
	if String(girl_id) == "":
		girl_id = StoryIds.GIRL_NEIGHBOR
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null or not gs.has_method("has_girl_contact"):
		return STAGE0_OBJECTIVE_FALLBACK
	if not bool(gs.call("has_girl_contact", girl_id)):
		return STAGE0_OBJECTIVE_FALLBACK
	# Canonical Phone Girls detail next-step copy (not a parallel quest string).
	var date_cd: int = 0
	if gs.has_method("get_girl_date_cooldown_days_remaining"):
		date_cd = int(gs.call("get_girl_date_cooldown_days_remaining", girl_id))
	if date_cd > 0:
		return "Следующее свидание: через %d дн." % date_cd
	return "Следующее свидание: доступно"


func _objective_from_phone_story() -> String:
	var world: Node = get_node_or_null("/root/World")
	if world == null or not world.has_method("get_phone_journal"):
		return ""
	var phone: Node = world.call("get_phone_journal") as Node
	if phone == null:
		return ""
	# Keep Phone Story label current even while journal is closed.
	if phone.has_method("refresh"):
		phone.call("refresh")
	if not phone.has_method("get_story_text"):
		return ""
	var story_text: String = str(phone.call("get_story_text"))
	return _extract_phone_objective_line(story_text)


func _extract_phone_objective_line(story_text: String) -> String:
	var cleaned: String = story_text.strip_edges()
	if cleaned == "" or cleaned == "—":
		return ""
	var lines: PackedStringArray = cleaned.split("\n")
	var next_idx: int = -1
	for i in range(lines.size()):
		if String(lines[i]).strip_edges() == "Следующий шаг:":
			next_idx = i
			break
	if next_idx >= 0:
		for j in range(next_idx + 1, lines.size()):
			var step: String = String(lines[j]).strip_edges()
			if step != "":
				return step
	# Prefer the first non-header situational line when no explicit next step.
	for i in range(lines.size()):
		var line: String = String(lines[i]).strip_edges()
		if line == "":
			continue
		if line.begins_with("СТАДИЯ") or line == "ФИНАЛ" or line == "ФИНАЛ ЗАВЕРШЁН":
			continue
		if line.begins_with("Ухажёр:") or line.begins_with("Девушка:"):
			continue
		return line
	return ""


func _audio_play_sfx(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_sfx"):
		ad.call("play_sfx", sound_id)
