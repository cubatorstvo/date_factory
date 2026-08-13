class_name PhoneJournal
extends Control
## Phone journal presentation shell (MODULE 08–21 logic, MODULE 22 five-tab UI).
## Girls tab can open DateInvitePanel when Relationships.can_start_date. No formula changes.

signal opened()
signal closed()

const CHOICE_CARD_SCENE: String = "res://ui/common/choice_card.tscn"
const BODY_LABEL_SCENE: String = "res://ui/common/body_label.tscn"
const INVITE_PANEL_SCENE: String = "res://ui/phone/date_invite_panel.tscn"

enum PhoneTab {
	STATUS,
	STORY,
	GIRLS,
	MEDIA,
	CLONES,
}

@onready var _list: ItemList = %GirlsList
@onready var _detail: RichTextLabel = %GirlDetail
@onready var _invite_date_btn: Button = %InviteDateButton
@onready var _title: Label = %TitleLabel
@onready var _close_btn: Button = %CloseButton
@onready var _progression_badge: Label = %ProgressionBadge
@onready var _progression_host: Control = %ProgressionHost
var _player: Node = null
var _invite_panel: Control = null
var _invite_girl_id: StringName = &""
var _is_open: bool = false
var _listed_ids: Array[StringName] = []
var _active_tab: PhoneTab = PhoneTab.GIRLS
var _embedded_progression: CanvasLayer = null

const PROGRESSION_SCENE: String = "res://ui/progression/progression_ui.tscn"

@onready var _top_bar_label: Label = %TopBarLabel
var _status_api_text: String = ""
@onready var _tab_bar: HBoxContainer = %TabBar
var _tab_buttons: Dictionary = {}
var _tab_pages: Dictionary = {}

@onready var _status_section: VBoxContainer = %StatusSection
@onready var _status_label: Label = %StatusLabel
@onready var _story_section: VBoxContainer = %StorySection
@onready var _story_title: Label = %StoryTitle
@onready var _story_label: Label = %StoryLabel
@onready var _girls_section: HSplitContainer = %GirlsSection

@onready var _salary_section: VBoxContainer = %SalarySection
@onready var _salary_title: Label = %SalaryTitle
@onready var _salary_stats: Label = %SalaryStats
@onready var _salary_advance_btn: Button = %SalaryAdvanceButton
@onready var _salary_pending_hint: Label = %SalaryPendingHint
@onready var _salary_feedback: Label = %SalaryFeedback
var _salary_signals_connected: bool = false
@onready var _late_rates_label: Label = %LateRatesLabel

@onready var _media_section: VBoxContainer = %MediaSection
@onready var _media_title: Label = %MediaTitle
@onready var _media_attention_block: VBoxContainer = %AttentionBlock
@onready var _media_attention: Label = %MediaAttention
@onready var _media_attention_bar: ProgressBar = %AttentionBar
@onready var _media_attention_markers: Label = %AttentionMarkers
@onready var _media_pre_session: Label = %MediaPreSession
@onready var _media_photos_block: VBoxContainer = %PhotosBlock
@onready var _media_photos_title: Label = %PhotosTitle
@onready var _media_photo_rows_host: VBoxContainer = %PhotoRows
var _media_photo_rows: Dictionary = {}
@onready var _media_incoming_block: VBoxContainer = %IncomingBlock
@onready var _media_incoming_title: Label = %IncomingTitle
@onready var _media_incoming_list: VBoxContainer = %IncomingList
@onready var _media_feed_block: VBoxContainer = %FeedBlock
@onready var _media_feed_title: Label = %FeedTitle
@onready var _media_feed_label: Label = %FeedLabel
var _media_signals_connected: bool = false

@onready var _overload_section: VBoxContainer = %OverloadSection
@onready var _overload_title: Label = %OverloadTitle
@onready var _overload_summary: Label = %OverloadSummary
@onready var _overload_demand_list: VBoxContainer = %DemandList
@onready var _overload_boost_btn: Button = %BoostButton
@onready var _overload_boost_hint: Label = %BoostHint
var _overload_signals_connected: bool = false
var _realization_pending: bool = false
var _realization_presented: bool = false
@onready var _realization_dialog: AcceptDialog = %RealizationDialog
var _player_mode_connected: bool = false

@onready var _clone_section: VBoxContainer = %CloneSection
@onready var _clone_title: Label = %CloneTitle
@onready var _clone_stats: Label = %CloneStats
@onready var _clone_footer: Label = %CloneFooter
var _clone_signals_connected: bool = false


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UiScaleHelper.apply_to_control(self)
	_wire_scene()
	_build_photo_rows()
	_connect_salary_signals()
	_connect_media_signals()
	_connect_overload_signals()
	_connect_clone_signals()


func open(player: Node = null) -> void:
	_player = player
	if _player == null:
		var tree: SceneTree = get_tree()
		if tree != null:
			_player = tree.get_first_node_in_group("player")
	if _player != null and _player.has_method("enter_modal_ui"):
		_player.call("enter_modal_ui")
	_clear_salary_feedback()
	_ensure_player_mode_hook()
	refresh()
	visible = true
	_is_open = true
	opened.emit()
	_try_present_realization(true)


func close() -> void:
	if not _is_open and not visible:
		return
	if _invite_panel != null and is_instance_valid(_invite_panel) and _invite_panel.has_method("close"):
		_invite_panel.call("close")
	_teardown_embedded_progression()
	_audio_play_ui(AudioIds.UI_BACK)
	visible = false
	_is_open = false
	if _player != null and _player.has_method("enter_gameplay"):
		_player.call("enter_gameplay")
	closed.emit()
	call_deferred("_try_present_realization", false)


func is_open() -> bool:
	return _is_open


func get_listed_girl_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for gid in _listed_ids:
		out.append(gid)
	return out


func get_detail_text() -> String:
	if _detail == null:
		return ""
	return String(_detail.text)


func select_girl_by_id(girl_id: StringName) -> bool:
	for i in range(_listed_ids.size()):
		if _listed_ids[i] == girl_id:
			_set_active_tab(PhoneTab.GIRLS)
			_list.select(i)
			_show_detail(girl_id)
			return true
	return false


func set_tab(tab: PhoneTab) -> void:
	_set_active_tab(tab)


func refresh() -> void:
	_refresh_tab_visibility()
	_refresh_top_bar()
	_refresh_progression_badge()
	_refresh_status_section()
	_refresh_story_section()
	_refresh_list()
	_refresh_media_section()
	_refresh_overload_section()
	_refresh_clone_section()
	_refresh_salary_section()
	_show_active_tab()


func get_status_text() -> String:
	# Regression API: MODULE14 resource lines + STATUS characteristics body.
	var parts: PackedStringArray = PackedStringArray()
	if _status_api_text.strip_edges() != "":
		parts.append(_status_api_text)
	if _status_label != null and String(_status_label.text).strip_edges() != "":
		parts.append(String(_status_label.text))
	return "\n".join(parts)


func get_story_text() -> String:
	if _story_label == null:
		return ""
	return String(_story_label.text)


func has_salary_section_visible() -> bool:
	return _salary_section != null and _salary_section.visible


func is_salary_advance_controls_visible() -> bool:
	return _salary_advance_btn != null and _salary_advance_btn.visible


func is_salary_advance_enabled() -> bool:
	return _salary_advance_btn != null and _salary_advance_btn.visible and not _salary_advance_btn.disabled


func get_salary_stats_text() -> String:
	if _salary_stats == null:
		return ""
	return String(_salary_stats.text)


func get_salary_feedback_text() -> String:
	if _salary_feedback == null:
		return ""
	return String(_salary_feedback.text)


func has_media_section_visible() -> bool:
	return _is_media_unlocked()


func get_media_attention_text() -> String:
	if _media_attention == null:
		return ""
	return String(_media_attention.text)


func get_media_feed_text() -> String:
	if _media_feed_label == null:
		return ""
	return String(_media_feed_label.text)


func get_media_pre_session_text() -> String:
	if _media_pre_session == null:
		return ""
	return String(_media_pre_session.text)


func has_overload_section_visible() -> bool:
	return _overload_section != null and _overload_section.visible


func get_overload_summary_text() -> String:
	if _overload_summary == null:
		return ""
	return String(_overload_summary.text)


func get_overload_demand_row_count() -> int:
	if _overload_demand_list == null:
		return 0
	return _overload_demand_list.get_child_count()


func is_overload_boost_visible() -> bool:
	return _overload_boost_btn != null and _overload_boost_btn.visible


func is_overload_boost_enabled() -> bool:
	return (
		_overload_boost_btn != null
		and _overload_boost_btn.visible
		and not _overload_boost_btn.disabled
	)


func get_overload_boost_button_text() -> String:
	if _overload_boost_btn == null:
		return ""
	return String(_overload_boost_btn.text)


func was_realization_presented() -> bool:
	return _realization_presented


func has_clone_section_visible() -> bool:
	return _is_clones_unlocked()


func get_clone_stats_text() -> String:
	if _clone_stats == null:
		return ""
	return String(_clone_stats.text)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause") or event.is_action_pressed("phone"):
		if _invite_panel != null and _invite_panel.visible and _invite_panel.has_method("close"):
			_invite_panel.call("close")
			get_viewport().set_input_as_handled()
			return
		close()
		get_viewport().set_input_as_handled()


func _wire_scene() -> void:
	_close_btn.pressed.connect(close)
	_list.item_selected.connect(_on_item_selected)
	if _invite_date_btn != null:
		_invite_date_btn.pressed.connect(_on_invite_date_pressed)
	_tab_buttons = {
		PhoneTab.STATUS: %StatusTab,
		PhoneTab.STORY: %StoryTab,
		PhoneTab.GIRLS: %GirlsTab,
		PhoneTab.MEDIA: %MediaTab,
		PhoneTab.CLONES: %ClonesTab,
	}
	_tab_pages = {
		PhoneTab.STATUS: _status_section,
		PhoneTab.STORY: _story_section,
		PhoneTab.GIRLS: _girls_section,
		PhoneTab.MEDIA: _media_section,
		PhoneTab.CLONES: _clone_section,
	}
	for tab_value: int in _tab_buttons.keys():
		var tab: PhoneTab = tab_value as PhoneTab
		var button: Button = _tab_buttons[tab_value] as Button
		button.pressed.connect(_set_active_tab.bind(tab))
	_salary_advance_btn.pressed.connect(_on_salary_advance_pressed)
	_overload_boost_btn.pressed.connect(_on_overload_feed_boost_pressed)
	_set_active_tab(PhoneTab.GIRLS)
	_refresh_progression_badge()


func _refresh_progression_badge() -> void:
	if _progression_badge == null:
		return
	var points: int = 0
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("get_upgrade_points"):
		points = int(gs.call("get_upgrade_points"))
	_progression_badge.visible = points > 0
	if points > 0:
		_progression_badge.text = str(points)


func _ensure_embedded_progression() -> void:
	if _has_embedded_progression():
		if _embedded_progression.has_method("refresh_embedded"):
			_embedded_progression.call("refresh_embedded")
		return
	if _progression_host == null:
		return
	var packed: PackedScene = load(PROGRESSION_SCENE) as PackedScene
	if packed == null:
		push_error("[PhoneJournal] progression scene missing")
		return
	var layer: CanvasLayer = packed.instantiate() as CanvasLayer
	if layer == null:
		return
	add_child(layer)
	_embedded_progression = layer
	if layer.has_method("embed_into"):
		layer.call("embed_into", _progression_host, _player)
		if layer.has_signal("purchase_notified"):
			layer.connect("purchase_notified", _on_embedded_purchase_notified)
	else:
		_embedded_progression = null
		layer.queue_free()


func _on_embedded_purchase_notified(_message: String) -> void:
	_refresh_progression_badge()
	_request_status_refresh()


func _has_embedded_progression() -> bool:
	return _embedded_progression != null and is_instance_valid(_embedded_progression)


func _teardown_embedded_progression() -> void:
	if not _has_embedded_progression():
		_embedded_progression = null
		return
	var layer: CanvasLayer = _embedded_progression
	_embedded_progression = null
	if layer.has_method("close"):
		layer.call("close")
	elif is_instance_valid(layer):
		layer.queue_free()


func _build_photo_rows() -> void:
	_media_photo_rows.clear()
	var packed: PackedScene = load(CHOICE_CARD_SCENE) as PackedScene
	if packed == null:
		return
	for photo_id: StringName in MediaContent.SHOT_IDS:
		var card: ChoiceCard = packed.instantiate() as ChoiceCard
		if card == null:
			continue
		card.configure(MediaContent.photo_title(photo_id), "", "Опубликовать")
		var captured_id: StringName = photo_id
		card.chosen.connect(func() -> void: _on_media_publish_pressed(captured_id))
		_media_photo_rows_host.add_child(card)
		_media_photo_rows[photo_id] = {
			"row": card,
			"label": card.title_label,
			"gain": card.detail_label,
			"button": card.action_button,
		}


func _set_active_tab(tab: PhoneTab) -> void:
	var requested: PhoneTab = tab
	var denied: bool = false
	if tab == PhoneTab.MEDIA and not _is_media_unlocked():
		tab = PhoneTab.STATUS
		denied = requested == PhoneTab.MEDIA
	if tab == PhoneTab.CLONES and not _is_clones_unlocked():
		tab = PhoneTab.STATUS
		denied = denied or requested == PhoneTab.CLONES
	var changed: bool = tab != _active_tab
	_active_tab = tab
	for key in _tab_buttons.keys():
		var t: PhoneTab = key as PhoneTab
		var btn: Button = _tab_buttons[key] as Button
		if btn == null:
			continue
		btn.set_pressed_no_signal(t == _active_tab)
	_show_active_tab()
	if denied and _is_open:
		_audio_play_ui(AudioIds.UI_DENIED)
	elif changed and _is_open:
		_audio_play_ui(AudioIds.UI_CLICK)


func _show_active_tab() -> void:
	for key in _tab_pages.keys():
		var page: Control = _tab_pages[key] as Control
		if page == null:
			continue
		page.visible = (key as PhoneTab) == _active_tab
	if _active_tab == PhoneTab.STATUS and _is_open:
		_ensure_embedded_progression()


func _refresh_tab_visibility() -> void:
	var media_on: bool = _is_media_unlocked()
	var clones_on: bool = _is_clones_unlocked()
	var media_btn: Button = _tab_buttons.get(PhoneTab.MEDIA) as Button
	var clones_btn: Button = _tab_buttons.get(PhoneTab.CLONES) as Button
	if media_btn != null:
		media_btn.visible = media_on
	if clones_btn != null:
		clones_btn.visible = clones_on
	if _active_tab == PhoneTab.MEDIA and not media_on:
		_active_tab = PhoneTab.STATUS
	if _active_tab == PhoneTab.CLONES and not clones_on:
		_active_tab = PhoneTab.STATUS
	for key in _tab_buttons.keys():
		var btn: Button = _tab_buttons[key] as Button
		if btn != null:
			btn.set_pressed_no_signal((key as PhoneTab) == _active_tab)


func _is_media_unlocked() -> bool:
	var media: Node = get_node_or_null("/root/Media")
	if media != null and media.has_method("is_feature_unlocked"):
		return bool(media.call("is_feature_unlocked"))
	var story: Node = get_node_or_null("/root/Story")
	if story != null and story.has_method("is_feature_unlocked"):
		return bool(story.call("is_feature_unlocked", StoryTypes.StoryFeature.MEDIA_ATTENTION))
	return false


func _is_clones_unlocked() -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("get_total_clones"):
		return int(gs.call("get_total_clones")) >= 1
	return false


func _make_label(text: String = "") -> Label:
	var packed: PackedScene = load(BODY_LABEL_SCENE) as PackedScene
	if packed == null:
		return null
	var label: Label = packed.instantiate() as Label
	if label != null:
		label.text = text
	return label


func _connect_salary_signals() -> void:
	if _salary_signals_connected:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_signal("money_changed") and not gs.is_connected("money_changed", _on_money_changed_salary):
			gs.connect("money_changed", _on_money_changed_salary)
		if gs.has_signal("authority_changed") and not gs.is_connected("authority_changed", _on_authority_changed_salary):
			gs.connect("authority_changed", _on_authority_changed_salary)
	var salary: Node = get_node_or_null("/root/SalaryMine")
	if salary != null:
		if salary.has_signal("salary_period_opened") and not salary.is_connected("salary_period_opened", _on_salary_period_opened):
			salary.connect("salary_period_opened", _on_salary_period_opened)
		if salary.has_signal("salary_pending_changed") and not salary.is_connected("salary_pending_changed", _on_salary_pending_changed):
			salary.connect("salary_pending_changed", _on_salary_pending_changed)
		if salary.has_signal("salary_claimed") and not salary.is_connected("salary_claimed", _on_salary_claimed):
			salary.connect("salary_claimed", _on_salary_claimed)
	var prog: Node = get_node_or_null("/root/Progression")
	if prog != null and prog.has_signal("perk_purchased") and not prog.is_connected("perk_purchased", _on_perk_purchased_salary):
		prog.connect("perk_purchased", _on_perk_purchased_salary)
	var story: Node = get_node_or_null("/root/Story")
	if story != null and story.has_signal("feature_unlocked") and not story.is_connected("feature_unlocked", _on_feature_unlocked_salary):
		story.connect("feature_unlocked", _on_feature_unlocked_salary)
	if story != null and story.has_signal("stage_objective_changed") and not story.is_connected("stage_objective_changed", _on_story_objective_changed):
		story.connect("stage_objective_changed", _on_story_objective_changed)
	if story != null and story.has_signal("stage_started") and not story.is_connected("stage_started", _on_story_stage_started):
		story.connect("stage_started", _on_story_stage_started)
	if gs != null:
		if gs.has_signal("experience_changed") and not gs.is_connected("experience_changed", _on_experience_changed_status):
			gs.connect("experience_changed", _on_experience_changed_status)
		if gs.has_signal("upgrade_points_changed") and not gs.is_connected("upgrade_points_changed", _on_upgrade_points_changed_status):
			gs.connect("upgrade_points_changed", _on_upgrade_points_changed_status)
		if gs.has_signal("characteristic_changed") and not gs.is_connected("characteristic_changed", _on_characteristic_changed_status):
			gs.connect("characteristic_changed", _on_characteristic_changed_status)
	var day_node: Node = get_node_or_null("/root/GameDay")
	if day_node != null and day_node.has_signal("day_advanced") and not day_node.is_connected("day_advanced", _on_day_advanced_status):
		day_node.connect("day_advanced", _on_day_advanced_status)
	_salary_signals_connected = true


func _on_money_changed_salary(_new_value: int, _delta: int) -> void:
	_request_status_refresh()
	_request_salary_refresh()


func _on_authority_changed_salary(_new_value: int, _delta: int) -> void:
	_request_status_refresh()
	_request_salary_refresh()


func _on_experience_changed_status(_new_value: int, _delta: int) -> void:
	_request_status_refresh()
	_request_story_refresh()


func _on_upgrade_points_changed_status(_new_value: int, _delta: int) -> void:
	_request_status_refresh()
	_refresh_progression_badge()


func _on_characteristic_changed_status(
	_characteristic: GameTypes.PlayerCharacteristic,
	_new_value: int,
	_previous_value: int
) -> void:
	_request_status_refresh()


func _on_day_advanced_status(_new_day: int) -> void:
	_request_status_refresh()
	_request_media_refresh()
	_request_overload_refresh()
	_request_clone_refresh()
	_request_salary_refresh()
	_request_story_refresh()


func _on_story_objective_changed(_progress: StoryStageProgress) -> void:
	_request_story_refresh()
	_request_list_refresh()


func _on_story_stage_started(_stage: GameTypes.GameStage) -> void:
	_request_story_refresh()
	_request_clone_refresh()
	_refresh_tab_visibility()
	_show_active_tab()


func _request_status_refresh() -> void:
	if _is_open:
		_refresh_top_bar()
		_refresh_status_section()


func _request_story_refresh() -> void:
	if _is_open:
		_refresh_story_section()


func _refresh_top_bar() -> void:
	var day_value: int = 1
	var day_node: Node = get_node_or_null("/root/GameDay")
	if day_node != null and day_node.has_method("get_current_day"):
		day_value = int(day_node.call("get_current_day"))
	var money_value: int = 0
	var authority_value: int = 0
	var experience_value: int = 0
	var upgrade_points_value: int = 0
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		money_value = int(gs.call("get_money"))
		authority_value = int(gs.call("get_authority"))
		experience_value = int(gs.call("get_experience"))
		upgrade_points_value = int(gs.call("get_upgrade_points"))
	if _top_bar_label != null:
		_top_bar_label.text = "День %d · %s · Авторитет %d · Покоренных сердец %d · Баллы %d" % [
			day_value,
			UiNumberFormat.format_money(money_value),
			authority_value,
			experience_value,
			upgrade_points_value,
		]
	var api_lines: PackedStringArray = PackedStringArray()
	api_lines.append("День: %d" % day_value)
	api_lines.append("Деньги: %d" % money_value)
	api_lines.append("Авторитет: %d" % authority_value)
	api_lines.append("Покоренных сердец: %d" % experience_value)
	api_lines.append("Баллы прокачки: %d" % upgrade_points_value)
	_status_api_text = "\n".join(api_lines)


func _refresh_status_section() -> void:
	if _status_label == null:
		return
	var muscle: int = 0
	var appearance: int = 0
	var capital: int = 0
	var aura: int = 0
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_method("get_muscle"):
			muscle = int(gs.call("get_muscle"))
		if gs.has_method("get_appearance"):
			appearance = int(gs.call("get_appearance"))
		if gs.has_method("get_capital"):
			capital = int(gs.call("get_capital"))
		if gs.has_method("get_aura"):
			aura = int(gs.call("get_aura"))
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Мышца %d" % muscle)
	lines.append("Внешность %d" % appearance)
	lines.append("Капитал %d" % capital)
	lines.append("Аура %d" % aura)
	_status_label.text = "\n".join(lines)
	_refresh_late_rates_on_status(gs)


func _refresh_late_rates_on_status(gs: Node) -> void:
	if _late_rates_label == null:
		return
	var money_rate: float = 0.0
	var dating_rate: float = 0.0
	if gs != null:
		if gs.has_method("get_money_per_minute"):
			money_rate = float(gs.call("get_money_per_minute"))
		if gs.has_method("get_dates_per_minute"):
			dating_rate = float(gs.call("get_dates_per_minute"))
	var show_rates: bool = money_rate > 0.0 or dating_rate > 0.0
	_late_rates_label.visible = show_rates
	if show_rates:
		_late_rates_label.text = "Денег/мин: %s\nСвиданий/мин: %s" % [
			_format_clone_money_rate(money_rate),
			_format_clone_date_rate(dating_rate),
		]


func _refresh_story_section() -> void:
	if _story_label == null:
		return
	var story: Node = get_node_or_null("/root/Story")
	if story == null or not story.has_method("get_current_progress"):
		_story_label.text = "—"
		return
	var progress: StoryStageProgress = story.call("get_current_progress") as StoryStageProgress
	if progress == null:
		_story_label.text = "—"
		return
	if progress.stage == GameTypes.GameStage.STAGE_4:
		_story_label.text = _stage4_story_text(progress)
		return
	if progress.stage == GameTypes.GameStage.STAGE_5:
		_story_label.text = _stage5_story_text()
		return
	if progress.stage == GameTypes.GameStage.STAGE_6:
		_story_label.text = _stage6_story_text()
		return
	if progress.stage == GameTypes.GameStage.FINALE:
		_story_label.text = _finale_story_text()
		return
	var stage_name: String = progress.display_name.strip_edges()
	if stage_name == "":
		stage_name = _stage_header_fallback(progress.stage)
	var rival_text: String = "—"
	if String(progress.story_rival_id) != "":
		rival_text = _actor_display_name(progress.story_rival_id, true)
		if progress.rival_defeated:
			rival_text = "%s (побеждён)" % rival_text
	elif not progress.rival_required:
		rival_text = "—"
	var girl_text: String = "—"
	if String(progress.story_girl_id) != "":
		girl_text = _actor_display_name(progress.story_girl_id, false)
		if progress.girl_completed:
			girl_text = "%s (завершена)" % girl_text
	var lines: PackedStringArray = PackedStringArray()
	lines.append(stage_name)
	lines.append("Ухажёр: %s" % rival_text)
	lines.append("Девушка: %s" % girl_text)
	if (
		progress.stage == GameTypes.GameStage.PROLOGUE
		or progress.stage == GameTypes.GameStage.STAGE_1
		or progress.stage == GameTypes.GameStage.STAGE_2
		or progress.stage == GameTypes.GameStage.STAGE_3
	):
		var next_step: String = progress.objective_text.strip_edges()
		if next_step == "":
			next_step = _early_stage_next_step_fallback(progress)
		if next_step != "":
			lines.append("")
			lines.append("Следующий шаг:")
			lines.append(next_step)
	_story_label.text = "\n".join(lines)


func _early_stage_next_step_fallback(progress: StoryStageProgress) -> String:
	if progress == null:
		return ""
	if not progress.rival_defeated and String(progress.story_rival_id) != "":
		return "Сначала разберись с ухажёром."
	if not progress.girl_completed and String(progress.story_girl_id) != "":
		return "Найди сюжетную девушку текущей стадии."
	return ""


func _stage_header_fallback(stage: GameTypes.GameStage) -> String:
	match stage:
		GameTypes.GameStage.PROLOGUE:
			return "Пролог"
		GameTypes.GameStage.STAGE_1:
			return "Стадия 1"
		GameTypes.GameStage.STAGE_2:
			return "Стадия 2"
		GameTypes.GameStage.STAGE_3:
			return "Стадия 3"
		GameTypes.GameStage.STAGE_4:
			return "Стадия 4"
		GameTypes.GameStage.STAGE_5:
			return "Стадия 5"
		GameTypes.GameStage.STAGE_6:
			return "Стадия 6"
		GameTypes.GameStage.FINALE:
			return "Финал"
		_:
			return "Сюжет"


func _stage4_story_text(progress: StoryStageProgress) -> String:
	var overload: Node = get_node_or_null("/root/DatingOverload")
	var recognized: bool = (
		overload != null
		and overload.has_method("is_problem_recognized")
		and bool(overload.call("is_problem_recognized"))
	)
	if recognized and not progress.girl_completed:
		var hunt: PackedStringArray = PackedStringArray()
		hunt.append("СТАДИЯ 4")
		hunt.append("Учёная")
		hunt.append("")
		hunt.append(DatingOverloadTypes.REALIZATION_LINE_1)
		hunt.append(DatingOverloadTypes.REALIZATION_LINE_2)
		hunt.append("")
		hunt.append("Следующий шаг:")
		hunt.append("Найти Учёную у закрытой лаборатории.")
		return "\n".join(hunt)
	return _stage4_media_overload_text(overload)


func _stage5_story_text() -> String:
	var total: int = 0
	var experience: int = 0
	var rival_defeated: bool = false
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_method("get_total_clones"):
			total = int(gs.call("get_total_clones"))
		if gs.has_method("get_experience"):
			experience = int(gs.call("get_experience"))
		if gs.has_method("is_rival_defeated"):
			rival_defeated = bool(gs.call("is_rival_defeated", StoryIds.RIVAL_PRESIDENT))
	var lines: PackedStringArray = PackedStringArray()
	lines.append("СТАДИЯ 5")
	if total < 1:
		lines.append("Лаборатория")
		lines.append("")
		lines.append("Лаборатория открыта.")
		lines.append("Создай первого клона.")
		return "\n".join(lines)
	lines.append("Президент")
	lines.append("")
	if experience < 10:
		lines.append("Покоренных сердец: %d / 10" % experience)
		lines.append("")
		lines.append("Автоматические свидания расширяют твой земной статус.")
	elif not rival_defeated:
		lines.append("Президент инспектирует вход в производственную зону.")
		lines.append("Сначала разберись с её официальным ухажёром.")
	else:
		lines.append("Следующий шаг:")
		lines.append("Познакомиться с Президентом у производственной зоны.")
	return "\n".join(lines)


func _stage6_story_text() -> String:
	var reach: int = 0
	var total: int = 0
	var money_rate: float = 0.0
	var dating_rate: float = 0.0
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_method("get_world_reach"):
			reach = int(gs.call("get_world_reach"))
		if gs.has_method("get_total_clones"):
			total = int(gs.call("get_total_clones"))
		if gs.has_method("get_money_per_minute"):
			money_rate = float(gs.call("get_money_per_minute"))
		if gs.has_method("get_dates_per_minute"):
			dating_rate = float(gs.call("get_dates_per_minute"))
	var lines: PackedStringArray = PackedStringArray()
	lines.append("СТАДИЯ 6")
	lines.append("Мировое расширение")
	lines.append("")
	lines.append("Охват Земли: %d / 100" % reach)
	lines.append("Клоны: %d" % total)
	lines.append("Денег/мин: %s" % _format_clone_money_rate(money_rate))
	lines.append("Свиданий/мин: %s" % _format_clone_date_rate(dating_rate))
	lines.append("")
	lines.append("Следующий шаг:")
	lines.append("Расширять мировой охват.")
	return "\n".join(lines)


func _finale_story_text() -> String:
	var gs_finale: Node = get_node_or_null("/root/GameState")
	var finale_lines: PackedStringArray = PackedStringArray()
	if gs_finale != null and bool(gs_finale.call("is_girl_conquered", StoryIds.GIRL_FINAL_TARGET)):
		finale_lines.append("ФИНАЛ ЗАВЕРШЁН")
		finale_lines.append("")
		finale_lines.append("Последняя: +5")
		var reach_done: int = 100
		if gs_finale.has_method("get_world_reach"):
			reach_done = int(gs_finale.call("get_world_reach"))
		finale_lines.append("Охват Земли: %d" % reach_done)
		finale_lines.append("")
		finale_lines.append("Цель достигнута.")
		return "\n".join(finale_lines)
	if gs_finale != null and bool(gs_finale.call("has_girl_contact", StoryIds.GIRL_FINAL_TARGET)):
		finale_lines.append("Последняя")
		finale_lines.append("Финальное свидание")
		return "\n".join(finale_lines)
	finale_lines.append("ФИНАЛ")
	finale_lines.append("")
	finale_lines.append("Внеземной сигнал обнаружен.")
	finale_lines.append("Земная цель исчерпана.")
	finale_lines.append("Обнаружена романтическая цель вне Земли.")
	finale_lines.append("")
	finale_lines.append("Финальная локация открыта.")
	return "\n".join(finale_lines)


func _stage4_media_overload_text(overload: Node) -> String:
	if overload != null and overload.has_method("is_started") and bool(overload.call("is_started")):
		var during: PackedStringArray = PackedStringArray()
		during.append("СТАДИЯ 4")
		during.append("Медийность")
		var incoming_n: int = 0
		var media_for_count: Node = get_node_or_null("/root/Media")
		if media_for_count != null and media_for_count.has_method("get_incoming_offer_girl_ids"):
			var offers: Array = media_for_count.call("get_incoming_offer_girl_ids") as Array
			incoming_n = offers.size()
		during.append("Входящих встреч: %d" % incoming_n)
		during.append("Лично успеваешь: 1 / день")
		during.append("")
		during.append("Спрос растёт быстрее тебя.")
		return "\n".join(during)
	var lines: PackedStringArray = PackedStringArray()
	lines.append("СТАДИЯ 4")
	lines.append("Медийность")
	var media: Node = get_node_or_null("/root/Media")
	if media != null and media.has_method("is_overload_ready") and bool(media.call("is_overload_ready")):
		lines.append("Спрос растёт быстрее обычного.")
	elif media != null and media.has_method("is_photo_session_completed") and bool(media.call("is_photo_session_completed")):
		lines.append("Публикуй фотографии.")
		lines.append("Входящие предложения растут.")
	else:
		lines.append("Следующий шаг:")
		lines.append("Фотосессия у Редактора")
	return "\n".join(lines)


func _actor_display_name(actor_id: StringName, is_rival: bool) -> String:
	var db: Node = get_node_or_null("/root/ContentDB")
	if db != null:
		if is_rival:
			var rival: RivalDefinition = null
			if db.has_method("try_get_rival"):
				rival = db.call("try_get_rival", actor_id) as RivalDefinition
			elif db.has_method("get_rival"):
				rival = db.call("get_rival", actor_id) as RivalDefinition
			if rival != null and rival.display_name.strip_edges() != "":
				return rival.display_name
		else:
			var girl: GirlDefinition = null
			if db.has_method("try_get_girl"):
				girl = db.call("try_get_girl", actor_id) as GirlDefinition
			elif db.has_method("get_girl"):
				girl = db.call("get_girl", actor_id) as GirlDefinition
			if girl != null and girl.display_name.strip_edges() != "":
				return girl.display_name
	return String(actor_id)


func _on_salary_period_opened(_status: SalaryStatus) -> void:
	_request_salary_refresh()


func _on_salary_pending_changed(_amount: int) -> void:
	_request_salary_refresh()


func _on_salary_claimed(_amount: int, _method: SalaryTypes.ClaimMethod) -> void:
	_request_salary_refresh()


func _on_perk_purchased_salary(_perk_id: StringName, _characteristic: GameTypes.PlayerCharacteristic, _cost: int) -> void:
	_request_salary_refresh()


func _on_feature_unlocked_salary(_feature: StoryTypes.StoryFeature) -> void:
	_request_salary_refresh()
	_request_media_refresh()
	_request_story_refresh()
	_refresh_tab_visibility()
	_show_active_tab()


func _request_salary_refresh() -> void:
	if _is_open:
		_refresh_salary_section()


func _clear_salary_feedback() -> void:
	if _salary_feedback != null:
		_salary_feedback.text = ""


func _refresh_salary_section() -> void:
	if _salary_section == null:
		return
	var story: Node = get_node_or_null("/root/Story")
	var unlocked: bool = false
	if story != null and story.has_method("is_feature_unlocked"):
		unlocked = bool(story.call("is_feature_unlocked", StoryTypes.StoryFeature.SALARY_MINE))
	_salary_section.visible = unlocked
	if not unlocked:
		return
	var salary: Node = get_node_or_null("/root/SalaryMine")
	if salary == null or not salary.has_method("get_status"):
		return
	var status: SalaryStatus = salary.call("get_status") as SalaryStatus
	if status == null:
		return
	var day_suffix: String = ""
	var day_node: Node = get_node_or_null("/root/GameDay")
	if day_node != null and day_node.has_method("get_current_day"):
		day_suffix = " · День %d" % int(day_node.call("get_current_day"))
	_salary_title.text = "ЗАРПЛАТА%s" % day_suffix
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Авторитет: %d" % status.authority)
	lines.append("Разряд: %d" % status.salary_level)
	lines.append("Уровень: %d" % status.salary_level)
	lines.append("За период: %d" % status.gross_per_period)
	lines.append("Накоплено: %d" % status.pending_salary)
	lines.append("Доступно: %s" % UiNumberFormat.format_money(status.pending_salary))
	if status.passive_enabled:
		lines.append("Автоматически: %d / период" % status.passive_per_period)
	_salary_stats.text = "\n".join(lines)
	var show_advance: bool = status.salary_advance_owned
	_salary_advance_btn.visible = show_advance
	_salary_pending_hint.visible = show_advance
	if show_advance:
		_salary_advance_btn.disabled = not status.salary_advance_available
		_salary_pending_hint.text = "Получить %d" % status.pending_salary


func _on_salary_advance_pressed() -> void:
	var salary: Node = get_node_or_null("/root/SalaryMine")
	if salary == null or not salary.has_method("claim_salary_advance"):
		return
	var result: SalaryClaimResult = salary.call("claim_salary_advance") as SalaryClaimResult
	if result == null:
		return
	if result.ok:
		_audio_play_ui(AudioIds.UI_PURCHASE)
		_salary_feedback.text = "Получено удалённо: +%d" % result.amount
	else:
		_audio_play_ui(AudioIds.UI_DENIED)
		_salary_feedback.text = _claim_error_text(result.error)
	_refresh_salary_section()


func _claim_error_text(error: SalaryTypes.ClaimError) -> String:
	match error:
		SalaryTypes.ClaimError.NO_PENDING:
			return "Нет накопленной выплаты"
		SalaryTypes.ClaimError.ADVANCE_ALREADY_USED:
			return "Уже использовано в этом периоде"
		SalaryTypes.ClaimError.PERK_REQUIRED:
			return "Нужен перк"
		SalaryTypes.ClaimError.LOCKED:
			return "Нет накопленной выплаты"
		SalaryTypes.ClaimError.BUSY:
			return "Нет накопленной выплаты"
		_:
			return "Нет накопленной выплаты"


func _connect_media_signals() -> void:
	if _media_signals_connected:
		return
	var media: Node = get_node_or_null("/root/Media")
	if media != null:
		if media.has_signal("attention_changed") and not media.is_connected("attention_changed", _on_media_attention_changed):
			media.connect("attention_changed", _on_media_attention_changed)
		if media.has_signal("photo_session_completed") and not media.is_connected("photo_session_completed", _on_media_photo_session_completed):
			media.connect("photo_session_completed", _on_media_photo_session_completed)
		if media.has_signal("photo_published") and not media.is_connected("photo_published", _on_media_photo_published):
			media.connect("photo_published", _on_media_photo_published)
		if media.has_signal("incoming_offer_added") and not media.is_connected("incoming_offer_added", _on_media_incoming_offer_added):
			media.connect("incoming_offer_added", _on_media_incoming_offer_added)
		if media.has_signal("incoming_offer_read") and not media.is_connected("incoming_offer_read", _on_media_incoming_offer_read):
			media.connect("incoming_offer_read", _on_media_incoming_offer_read)
		if media.has_signal("feed_changed") and not media.is_connected("feed_changed", _on_media_feed_changed):
			media.connect("feed_changed", _on_media_feed_changed)
		if media.has_signal("overload_ready") and not media.is_connected("overload_ready", _on_media_overload_ready):
			media.connect("overload_ready", _on_media_overload_ready)
	_media_signals_connected = true


func _on_media_attention_changed(_new_value: int, _delta: int) -> void:
	_request_media_refresh()
	_request_story_refresh()


func _on_media_photo_session_completed() -> void:
	_request_media_refresh()
	_request_story_refresh()
	_request_list_refresh()


func _on_media_photo_published(_photo_id: StringName, _attention_gained: int) -> void:
	_request_media_refresh()
	_request_story_refresh()
	_request_list_refresh()


func _on_media_incoming_offer_added(_girl_id: StringName) -> void:
	_request_media_refresh()
	_request_list_refresh()


func _on_media_incoming_offer_read(_girl_id: StringName) -> void:
	_request_media_refresh()


func _on_media_feed_changed() -> void:
	_request_media_refresh()


func _on_media_overload_ready() -> void:
	_request_media_refresh()
	_request_story_refresh()
	_request_overload_refresh()


func _connect_overload_signals() -> void:
	if _overload_signals_connected:
		return
	var overload: Node = get_node_or_null("/root/DatingOverload")
	if overload != null:
		if overload.has_signal("overload_started") and not overload.is_connected("overload_started", _on_overload_started):
			overload.connect("overload_started", _on_overload_started)
		if overload.has_signal("backlog_changed") and not overload.is_connected("backlog_changed", _on_overload_backlog_changed):
			overload.connect("backlog_changed", _on_overload_backlog_changed)
		if overload.has_signal("personal_capacity_changed") and not overload.is_connected("personal_capacity_changed", _on_overload_capacity_changed):
			overload.connect("personal_capacity_changed", _on_overload_capacity_changed)
		if overload.has_signal("feed_boost_used") and not overload.is_connected("feed_boost_used", _on_overload_feed_boost_used):
			overload.connect("feed_boost_used", _on_overload_feed_boost_used)
		if overload.has_signal("problem_recognized") and not overload.is_connected("problem_recognized", _on_overload_problem_recognized):
			overload.connect("problem_recognized", _on_overload_problem_recognized)
		if overload.has_signal("demand_fulfilled") and not overload.is_connected("demand_fulfilled", _on_overload_demand_fulfilled):
			overload.connect("demand_fulfilled", _on_overload_demand_fulfilled)
		if overload.has_method("is_problem_recognized") and bool(overload.call("is_problem_recognized")):
			_realization_pending = true
	_overload_signals_connected = true


func _connect_clone_signals() -> void:
	if _clone_signals_connected:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_signal("clone_counts_changed") and not gs.is_connected("clone_counts_changed", _on_clone_counts_changed):
		gs.connect("clone_counts_changed", _on_clone_counts_changed)
	if gs != null and gs.has_signal("late_rates_changed") and not gs.is_connected("late_rates_changed", _on_late_rates_changed):
		gs.connect("late_rates_changed", _on_late_rates_changed)
	if gs != null and gs.has_signal("world_reach_changed") and not gs.is_connected("world_reach_changed", _on_world_reach_changed):
		gs.connect("world_reach_changed", _on_world_reach_changed)
	_clone_signals_connected = true


func _on_clone_counts_changed(_total: int, _working: int, _dating: int, _free: int) -> void:
	_request_clone_refresh()
	_request_story_refresh()
	_refresh_tab_visibility()
	_show_active_tab()


func _on_late_rates_changed(_money_per_minute: float, _dates_per_minute: float) -> void:
	_request_clone_refresh()
	_request_status_refresh()
	_request_story_refresh()


func _on_world_reach_changed(_new_value: int, _delta: int) -> void:
	_request_story_refresh()
	_request_clone_refresh()


func _request_clone_refresh() -> void:
	if _is_open:
		_refresh_clone_section()
		_refresh_tab_visibility()
		_show_active_tab()


func _refresh_clone_section() -> void:
	if _clone_section == null:
		return
	var total: int = 0
	var working: int = 0
	var dating: int = 0
	var free: int = 0
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_method("get_total_clones"):
			total = int(gs.call("get_total_clones"))
		if gs.has_method("get_clones_working"):
			working = int(gs.call("get_clones_working"))
		if gs.has_method("get_clones_dating"):
			dating = int(gs.call("get_clones_dating"))
		if gs.has_method("get_free_clones"):
			free = int(gs.call("get_free_clones"))
	if total < 1:
		if _clone_stats != null:
			_clone_stats.text = ""
		if _clone_footer != null:
			_clone_footer.text = ""
		return
	var money_rate: float = 0.0
	var dating_rate: float = 0.0
	var reach: int = 0
	var stage: int = 0
	if gs != null:
		if gs.has_method("get_money_per_minute"):
			money_rate = float(gs.call("get_money_per_minute"))
		if gs.has_method("get_dates_per_minute"):
			dating_rate = float(gs.call("get_dates_per_minute"))
		if gs.has_method("get_world_reach"):
			reach = int(gs.call("get_world_reach"))
		if gs.has_method("get_stage"):
			stage = int(gs.call("get_stage"))
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Всего: %d" % total)
	lines.append("Свободно: %d" % free)
	lines.append("Работают: %d" % working)
	lines.append("На свиданиях: %d" % dating)
	lines.append("Денег/мин: %s" % _format_clone_money_rate(money_rate))
	lines.append("Свиданий/мин: %s" % _format_clone_date_rate(dating_rate))
	if stage >= int(GameTypes.GameStage.STAGE_6):
		lines.append("Охват Земли %d / 100" % reach)
	_clone_stats.text = "\n".join(lines)
	if _clone_footer != null:
		var footer: PackedStringArray = PackedStringArray()
		footer.append("Управление клонами — через терминал лаборатории.")
		if stage >= int(GameTypes.GameStage.STAGE_6):
			footer.append("Глобальные улучшения — в производственной зоне.")
		_clone_footer.text = "\n".join(footer)


func _format_clone_money_rate(value: float) -> String:
	return UiNumberFormat.format_rate(value, 1)


func _format_clone_date_rate(value: float) -> String:
	return UiNumberFormat.format_rate(value, 2)


func _on_overload_started() -> void:
	_request_overload_refresh()
	_request_story_refresh()


func _on_overload_backlog_changed(_backlog_count: int) -> void:
	_request_overload_refresh()


func _on_overload_capacity_changed() -> void:
	_request_overload_refresh()


func _on_overload_feed_boost_used() -> void:
	_request_overload_refresh()
	_request_media_refresh()


func _on_overload_demand_fulfilled(_request_id: int) -> void:
	_request_overload_refresh()


func _on_overload_problem_recognized() -> void:
	_realization_pending = true
	_request_overload_refresh()
	_request_story_refresh()
	if not _is_open:
		_try_present_realization(false)


func _request_overload_refresh() -> void:
	if _is_open:
		_refresh_overload_section()


func _refresh_overload_section() -> void:
	if _overload_section == null:
		return
	var overload: Node = get_node_or_null("/root/DatingOverload")
	var active: bool = false
	if overload != null and overload.has_method("is_started"):
		active = bool(overload.call("is_started"))
	_overload_section.visible = active
	if not active:
		if _overload_boost_btn != null:
			_overload_boost_btn.visible = false
		if _overload_boost_hint != null:
			_overload_boost_hint.visible = false
		return
	var status: DatingOverloadStatus = null
	if overload.has_method("get_status"):
		status = overload.call("get_status") as DatingOverloadStatus
	if status == null:
		return
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Личная пропускная способность:")
	lines.append("%d / %d сегодня" % [status.capacity_used_today, status.capacity_per_day])
	lines.append("Сегодня можно лично посетить: %d" % status.capacity_per_day)
	lines.append("Сегодня уже посещено: %d/%d" % [status.capacity_used_today, status.capacity_per_day])
	lines.append("")
	lines.append("Невыполненный спрос: %d" % status.backlog_count)
	lines.append("Завершено запросов: %d" % status.fulfilled_count)
	_overload_summary.text = "\n".join(lines)
	_refresh_overload_demand_rows(overload)
	var recognized: bool = status.problem_recognized
	if recognized:
		_overload_boost_btn.visible = false
		_overload_boost_hint.visible = false
	else:
		_overload_boost_btn.visible = true
		_overload_boost_hint.visible = true
		if status.feed_boost_available:
			_overload_boost_btn.text = "Поднять волну"
			_overload_boost_btn.disabled = false
			_overload_boost_hint.text = "+5 внимания\nСледующий день: +1 входящий запрос"
		else:
			_overload_boost_btn.text = "Волна поднята"
			_overload_boost_btn.disabled = true
			_overload_boost_hint.text = "Доступно завтра"


func _refresh_overload_demand_rows(overload: Node) -> void:
	if _overload_demand_list == null:
		return
	for child in _overload_demand_list.get_children():
		_overload_demand_list.remove_child(child)
		child.queue_free()
	var sorted: Array[DatingDemandEntry] = []
	if overload.has_method("get_backlog_entries_sorted"):
		sorted = overload.call("get_backlog_entries_sorted") as Array[DatingDemandEntry]
	if sorted.is_empty():
		var empty: Label = _make_label("Нет активных запросов")
		if empty != null:
			_overload_demand_list.add_child(empty)
		return
	var packed: PackedScene = load(CHOICE_CARD_SCENE) as PackedScene
	if packed == null:
		return
	var day_node: Node = get_node_or_null("/root/GameDay")
	var current_day: int = 1
	if day_node != null and day_node.has_method("get_current_day"):
		current_day = int(day_node.call("get_current_day"))
	for entry in sorted:
		var e: DatingDemandEntry = entry as DatingDemandEntry
		if e == null:
			continue
		var status_text: String = ""
		if e.status == DatingOverloadTypes.DatingDemandStatus.OVERDUE:
			status_text = "ПРОСРОЧЕНО"
		else:
			status_text = "СЕГОДНЯ"
		var time_text: String = ""
		var slot_time: String = DatingOverloadTypes.slot_display_time(e.slot)
		if e.status == DatingOverloadTypes.DatingDemandStatus.OVERDUE:
			var day_delta: int = current_day - e.appointment_day
			if day_delta <= 1:
				time_text = "Вчера · %s" % slot_time
			else:
				time_text = "%d дн. назад · %s" % [day_delta, slot_time]
		else:
			time_text = slot_time
		var card: ChoiceCard = packed.instantiate() as ChoiceCard
		if card == null:
			continue
		card.configure(
			_actor_display_name(e.girl_id, false),
			"%s · %s" % [status_text, time_text],
			"Открыть"
		)
		var captured_id: StringName = e.girl_id
		card.chosen.connect(func() -> void: select_girl_by_id(captured_id))
		_overload_demand_list.add_child(card)


func _on_overload_feed_boost_pressed() -> void:
	var overload: Node = get_node_or_null("/root/DatingOverload")
	if overload == null or not overload.has_method("use_feed_boost"):
		return
	if _overload_boost_btn != null and _overload_boost_btn.disabled:
		_audio_play_ui(AudioIds.UI_DENIED)
		return
	_audio_play_sfx(AudioIds.MEDIA_FEED_BOOST)
	overload.call("use_feed_boost")
	_refresh_overload_section()
	_request_media_refresh()
	_request_story_refresh()


func _ensure_player_mode_hook() -> void:
	if _player_mode_connected:
		return
	if _player == null:
		var tree: SceneTree = get_tree()
		if tree != null:
			_player = tree.get_first_node_in_group("player")
	if _player == null:
		return
	if _player.has_signal("control_mode_changed") and not _player.is_connected("control_mode_changed", _on_player_control_mode_changed):
		_player.connect("control_mode_changed", _on_player_control_mode_changed)
		_player_mode_connected = true


func _on_player_control_mode_changed(mode: Variant) -> void:
	if int(mode) == int(PlayerController.ControlMode.GAMEPLAY):
		_try_present_realization(false)


func _try_present_realization(from_phone_open: bool) -> void:
	if _realization_presented:
		return
	var overload: Node = get_node_or_null("/root/DatingOverload")
	if overload == null or not overload.has_method("is_problem_recognized"):
		return
	if not bool(overload.call("is_problem_recognized")):
		return
	_realization_pending = true
	if not from_phone_open:
		if _is_open:
			return
		if _player != null and _player.has_method("get_control_mode"):
			var mode: Variant = _player.call("get_control_mode")
			if int(mode) != int(PlayerController.ControlMode.GAMEPLAY):
				return
	_show_realization_dialog()


func _show_realization_dialog() -> void:
	if _realization_presented:
		return
	if _realization_dialog == null:
		push_warning("[PhoneJournal] realization dialog scene node is missing")
		return
	var text: String = "%s\n\n%s\n\n%s" % [
		DatingOverloadTypes.REALIZATION_LINE_1,
		DatingOverloadTypes.REALIZATION_LINE_2,
		DatingOverloadTypes.REALIZATION_LINE_3,
	]
	_realization_dialog.dialog_text = text
	_realization_presented = true
	_realization_pending = false
	_realization_dialog.popup_centered()


func _request_media_refresh() -> void:
	if _is_open:
		_refresh_media_section()
		_refresh_tab_visibility()
		_show_active_tab()


func _request_list_refresh() -> void:
	if _is_open:
		_refresh_list()


func _refresh_media_section() -> void:
	if _media_section == null:
		return
	var unlocked: bool = _is_media_unlocked()
	if not unlocked:
		return
	var media: Node = get_node_or_null("/root/Media")
	if media == null:
		return
	var attention: int = 0
	if media.has_method("get_attention"):
		attention = int(media.call("get_attention"))
	_media_attention.text = "Внимание: %d / %d" % [attention, MediaContent.ATTENTION_MAX]
	if _media_attention_bar != null:
		_media_attention_bar.value = float(attention)
	var session_done: bool = bool(media.call("is_photo_session_completed"))
	_media_pre_session.visible = not session_done
	if not session_done:
		_media_pre_session.text = "Фотосессия доступна у Редактора."
	_media_photos_block.visible = session_done
	_media_incoming_block.visible = session_done
	_media_feed_block.visible = session_done
	if not session_done:
		return
	_refresh_media_photos(media)
	_refresh_media_incoming(media)
	_refresh_media_feed(media)


func _refresh_media_photos(media: Node) -> void:
	var can_today: bool = bool(media.call("can_publish_photo_today"))
	for photo_id in MediaContent.SHOT_IDS:
		if not _media_photo_rows.has(photo_id):
			continue
		var row_data: Dictionary = _media_photo_rows[photo_id] as Dictionary
		var row: VBoxContainer = row_data.get("row") as VBoxContainer
		var btn: Button = row_data.get("button") as Button
		var name_lbl: Label = row_data.get("label") as Label
		var gain_lbl: Label = row_data.get("gain") as Label
		if row == null or btn == null or name_lbl == null:
			continue
		var prepared: bool = bool(media.call("is_photo_prepared", photo_id))
		if not prepared:
			row.visible = false
			continue
		row.visible = true
		name_lbl.text = MediaContent.photo_title(photo_id)
		var published: bool = bool(media.call("is_photo_published", photo_id))
		var gain: int = 0
		if media.has_method("get_photo_attention_value"):
			gain = int(media.call("get_photo_attention_value", photo_id))
		if gain_lbl != null:
			if gain > 0 and not published:
				gain_lbl.text = "%s внимания" % UiNumberFormat.format_signed(gain)
				gain_lbl.visible = true
			else:
				gain_lbl.visible = false
		if published:
			btn.text = "Опубликовано"
			btn.disabled = true
		elif not can_today:
			btn.text = "Сегодня публикация уже была."
			btn.disabled = true
		else:
			btn.text = "Опубликовать"
			btn.disabled = false


func _refresh_media_incoming(media: Node) -> void:
	if _media_incoming_list == null:
		return
	for child in _media_incoming_list.get_children():
		_media_incoming_list.remove_child(child)
		child.queue_free()
	var offer_ids: Array = media.call("get_incoming_offer_girl_ids") as Array
	if offer_ids.is_empty():
		var empty: Label = _make_label("Пока нет входящих")
		if empty != null:
			_media_incoming_list.add_child(empty)
		return
	var packed: PackedScene = load(CHOICE_CARD_SCENE) as PackedScene
	if packed == null:
		return
	for entry in offer_ids:
		var girl_id: StringName = entry as StringName
		var is_read: bool = bool(media.call("is_offer_read", girl_id))
		var card: ChoiceCard = packed.instantiate() as ChoiceCard
		if card == null:
			continue
		card.configure(
			_actor_display_name(girl_id, false),
			"READ" if is_read else "NEW",
			"Открыть"
		)
		var captured_id: StringName = girl_id
		card.chosen.connect(func() -> void: _on_media_open_offer_pressed(captured_id))
		_media_incoming_list.add_child(card)


func _refresh_media_feed(media: Node) -> void:
	if _media_feed_label == null:
		return
	var feed_ids: Array = media.call("get_feed_event_ids") as Array
	var lines: PackedStringArray = PackedStringArray()
	var i: int = feed_ids.size() - 1
	while i >= 0:
		var event_id: StringName = feed_ids[i] as StringName
		var line: String = _format_media_feed_event(event_id)
		if line != "":
			lines.append("• %s" % line)
		i -= 1
	if lines.is_empty():
		_media_feed_label.text = "Пока пусто"
	else:
		_media_feed_label.text = "\n".join(lines)


func _format_media_feed_event(event_id: StringName) -> String:
	if event_id == MediaContent.FEED_ARTICLE_EDITOR:
		return MediaContent.ARTICLE_HEADLINE
	var event_str: String = String(event_id)
	if event_str.begins_with("feed_photo_"):
		var photo_id: StringName = StringName(event_str.substr("feed_photo_".length()))
		var title: String = MediaContent.photo_title(photo_id)
		if title == "":
			if OS.is_debug_build() or OS.has_feature("editor"):
				push_warning("[PhoneJournal] unknown media photo feed: %s" % event_str)
			return ""
		return "Фото: %s" % title
	if event_str.begins_with("feed_inbound_"):
		var girl_id: StringName = StringName(event_str.substr("feed_inbound_".length()))
		var display: String = _actor_display_name(girl_id, false)
		return "Новое сообщение: %s" % display
	if OS.is_debug_build() or OS.has_feature("editor"):
		push_warning("[PhoneJournal] unknown media feed event: %s" % event_str)
	return ""


func _on_media_publish_pressed(photo_id: StringName) -> void:
	var media: Node = get_node_or_null("/root/Media")
	if media == null or not media.has_method("publish_photo"):
		return
	var result: MediaPublishResult = media.call("publish_photo", photo_id) as MediaPublishResult
	if result == null:
		return
	if result.ok:
		_audio_play_sfx(AudioIds.MEDIA_PUBLISH)
	else:
		_audio_play_ui(AudioIds.UI_DENIED)
	_refresh_media_section()
	_request_story_refresh()
	if result.ok:
		_refresh_list()


func _on_media_open_offer_pressed(girl_id: StringName) -> void:
	var media: Node = get_node_or_null("/root/Media")
	if media != null and media.has_method("mark_offer_read"):
		media.call("mark_offer_read", girl_id)
	_audio_play_ui(AudioIds.UI_CLICK)
	_audio_play_sfx(AudioIds.MEDIA_INCOMING)
	select_girl_by_id(girl_id)
	_refresh_media_section()


func _audio_play_ui(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_ui"):
		ad.call("play_ui", sound_id)


func _audio_play_sfx(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_sfx"):
		ad.call("play_sfx", sound_id)


func _refresh_list() -> void:
	_listed_ids.clear()
	if _list != null:
		_list.clear()
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	var discovered: Array = gs.call("get_discovered_girl_ids") as Array
	if discovered.is_empty():
		_detail.text = "Пока нет записей."
		_refresh_invite_cta(StringName())
		return
	var ordered: Array[StringName] = _sorted_girl_ids(discovered, gs)
	var gd: Node = get_node_or_null("/root/GirlDiscovery")
	for gid in ordered:
		_listed_ids.append(gid)
		var display: String = _actor_display_name(gid, false)
		if display == String(gid) and gd != null:
			var def: GirlDefinition = gd.call("get_girl_definition", gid) as GirlDefinition
			if def != null and def.display_name.strip_edges() != "":
				display = def.display_name
		var status: String = _girl_list_status(gs, gid)
		_list.add_item("%s — %s" % [display, status])
	if _list.get_selected_items().is_empty():
		_list.select(0)
		_show_detail(_listed_ids[0])


func _sorted_girl_ids(discovered: Array, gs: Node) -> Array[StringName]:
	var catalog: Array[StringName] = []
	var db: Node = get_node_or_null("/root/ContentDB")
	if db != null and db.has_method("list_girls"):
		var girls: Array = db.call("list_girls") as Array
		for g in girls:
			var def: GirlDefinition = g as GirlDefinition
			if def != null:
				catalog.append(def.id)
	var discovered_set: Dictionary = {}
	for entry in discovered:
		discovered_set[entry as StringName] = true
	var story_girl: StringName = &""
	var story: Node = get_node_or_null("/root/Story")
	if story != null and story.has_method("get_current_progress"):
		var progress: StoryStageProgress = story.call("get_current_progress") as StoryStageProgress
		if progress != null:
			story_girl = progress.story_girl_id
	var out: Array[StringName] = []
	var seen: Dictionary = {}
	if story_girl != &"" and bool(discovered_set.get(story_girl, false)):
		out.append(story_girl)
		seen[story_girl] = true
	# Contacted in catalog order.
	for gid in catalog:
		if seen.has(gid):
			continue
		if not bool(discovered_set.get(gid, false)):
			continue
		if bool(gs.call("has_girl_contact", gid)):
			out.append(gid)
			seen[gid] = true
	# Discovered without contact in catalog order.
	for gid in catalog:
		if seen.has(gid):
			continue
		if bool(discovered_set.get(gid, false)):
			out.append(gid)
			seen[gid] = true
	# Any discovered ids missing from catalog (tests / extras), preserve discovery order.
	for entry in discovered:
		var gid2: StringName = entry as StringName
		if seen.has(gid2):
			continue
		out.append(gid2)
		seen[gid2] = true
	return out


func _girl_list_status(gs: Node, girl_id: StringName) -> String:
	if girl_id == StoryIds.GIRL_FINAL_TARGET:
		if bool(gs.call("is_girl_conquered", girl_id)):
			return "+5"
		if bool(gs.call("has_girl_contact", girl_id)):
			return "Контакт"
		return "Сигнал"
	if bool(gs.call("has_girl_contact", girl_id)):
		var rel: int = int(gs.call("get_girl_relationship", girl_id))
		if rel != 0 or bool(gs.call("is_girl_conquered", girl_id)):
			return UiNumberFormat.format_signed(rel)
		return "Номер получен"
	return "Номера нет"


func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _listed_ids.size():
		return
	_show_detail(_listed_ids[index])


func _show_detail(girl_id: StringName) -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	var gd: Node = get_node_or_null("/root/GirlDiscovery")
	var db: Node = get_node_or_null("/root/ContentDB")
	if gs == null or gd == null:
		_detail.text = ""
		_refresh_invite_cta(StringName())
		return
	var def: GirlDefinition = gd.call("get_girl_definition", girl_id) as GirlDefinition
	var span: int = 5
	if def != null:
		var raw_span: int = int(def.relationship_span)
		if raw_span == 5 or raw_span == 10:
			span = raw_span
	var lines: PackedStringArray = PackedStringArray()
	var name: String = String(girl_id)
	if def != null and def.display_name.strip_edges() != "":
		name = def.display_name
	lines.append("[b]%s[/b]" % name)
	if girl_id == StoryIds.GIRL_FINAL_TARGET:
		if bool(gs.call("is_girl_conquered", girl_id)):
			lines.append("Отношения: %+d" % span)
			lines.append("Статус: цель достигнута")
		elif bool(gs.call("has_girl_contact", girl_id)):
			lines.append("Статус: контакт установлен")
			lines.append("Финальное свидание")
		else:
			lines.append("Статус: сигнал обнаружен")
		_detail.text = "\n".join(lines)
		_refresh_invite_cta(girl_id)
		return
	var has_contact: bool = bool(gs.call("has_girl_contact", girl_id))
	if has_contact:
		lines.append("Статус: Номер получен")
	else:
		lines.append("Статус: Номера нет")
	var rel: int = int(gs.call("get_girl_relationship", girl_id))
	lines.append("Отношения: %+d / %d" % [rel, span])
	if bool(gs.call("is_girl_conquered", girl_id)):
		lines.append("Отношения завершены")
	if has_contact:
		var date_cd: int = int(gs.call("get_girl_date_cooldown_days_remaining", girl_id))
		if date_cd > 0:
			lines.append("Следующее свидание: через %d дн." % date_cd)
		else:
			lines.append("Следующее свидание: доступно")
	else:
		var disc_cd: int = int(gs.call("get_girl_retry_days_remaining", girl_id))
		if disc_cd > 0:
			lines.append("Повторное знакомство: через %d дн." % disc_cd)
	lines.append("")
	lines.append("[b]Наблюдения[/b]")
	var known: Array = gs.call("get_known_girl_clue_indices", girl_id) as Array
	if known.is_empty():
		lines.append("Пока нет наблюдений")
	elif def != null:
		for k in known:
			var idx: int = int(k)
			if idx >= 0 and idx < def.clue_notes.size():
				lines.append("- %s" % def.clue_notes[idx])
	lines.append("")
	if bool(gs.call("is_primary_trait_revealed", girl_id)) and def != null and db != null:
		var trait_def: PrimaryTraitDefinition = db.call("get_primary_trait", def.primary_trait) as PrimaryTraitDefinition
		if trait_def != null:
			lines.append("[b]Основная черта:[/b] %s" % trait_def.display_name)
			lines.append("Нравится: %s" % _format_tags(trait_def.liked_tags))
			lines.append("Не нравится: %s" % _format_tags(trait_def.disliked_tags))
		else:
			lines.append("Характер: ?")
	else:
		lines.append("Характер: ?")
	lines.append("")
	if bool(gs.call("is_secondary_trait_revealed", girl_id)) and def != null and db != null:
		var sec_def: SecondaryTraitDefinition = db.call("get_secondary_trait", def.secondary_trait) as SecondaryTraitDefinition
		if sec_def != null:
			lines.append("[b]Доп. черта:[/b] %s" % sec_def.display_name)
			if sec_def.description.strip_edges() != "":
				lines.append(sec_def.description)
		else:
			lines.append("Доп. черта: ?")
	else:
		lines.append("Доп. черта: ?")
	lines.append("")
	lines.append("[b]Известные реакции[/b]")
	var reactions: Dictionary = gs.call("get_girl_known_reactions", girl_id) as Dictionary
	if reactions.is_empty():
		lines.append("Пока нет наблюдений")
	else:
		for source_key in reactions.keys():
			var source_id: StringName = source_key as StringName
			var reaction: int = int(reactions[source_key])
			var label: String = _resolve_reaction_source_label(source_id)
			if label == "":
				continue
			lines.append("%s %s" % [_reaction_text(reaction), label])
	_detail.text = "\n".join(lines)
	_refresh_invite_cta(girl_id)

func _refresh_invite_cta(girl_id: StringName) -> void:
	_invite_girl_id = girl_id
	if _invite_date_btn == null:
		return
	_invite_date_btn.visible = false
	_invite_date_btn.disabled = true
	_invite_date_btn.text = "Позвать на свидание"
	if girl_id == StringName() or girl_id == StoryIds.GIRL_FINAL_TARGET:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null or not bool(gs.call("has_girl_contact", girl_id)):
		return
	var rel: Node = get_node_or_null("/root/Relationships")
	if rel == null or not rel.has_method("can_start_date"):
		_invite_date_btn.visible = true
		_invite_date_btn.text = "Недоступно"
		return
	if bool(rel.call("can_start_date", girl_id)):
		_invite_date_btn.visible = true
		_invite_date_btn.disabled = false
		return
	var cooldown_days: int = int(gs.call("get_girl_date_cooldown_days_remaining", girl_id))
	if cooldown_days > 0:
		_invite_date_btn.visible = true
		_invite_date_btn.text = "через %d дн." % cooldown_days
		return
	if rel.has_method("get_date_availability"):
		var avail: Dictionary = rel.call("get_date_availability", girl_id) as Dictionary
		var msg: String = str(avail.get("message", "")).strip_edges()
		if msg != "":
			_invite_date_btn.visible = true
			_invite_date_btn.text = msg


func _on_invite_date_pressed() -> void:
	if _invite_girl_id == StringName():
		return
	var panel: Control = _ensure_invite_panel()
	if panel == null:
		return
	_audio_play_ui(AudioIds.UI_CLICK)
	panel.call("open", _invite_girl_id, self, _player)


func _ensure_invite_panel() -> Control:
	if _invite_panel != null and is_instance_valid(_invite_panel):
		return _invite_panel
	var packed: PackedScene = load(INVITE_PANEL_SCENE) as PackedScene
	if packed == null:
		push_error("[PhoneJournal] date_invite_panel scene missing")
		return null
	var inst: Node = packed.instantiate()
	if inst == null or not (inst is Control) or not inst.has_method("open"):
		if inst != null:
			inst.free()
		return null
	add_child(inst)
	_invite_panel = inst as Control
	return _invite_panel


func _format_tags(tags: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for tag in tags:
		parts.append(_action_tag_label(int(tag)))
	return ", ".join(parts)


func _action_tag_label(tag_value: int) -> String:
	match tag_value:
		int(GameTypes.ActionTag.CARE):
			return "Забота"
		int(GameTypes.ActionTag.VULNERABILITY):
			return "Уязвимость"
		int(GameTypes.ActionTag.SIMPLICITY):
			return "Простота"
		int(GameTypes.ActionTag.PRESTIGE):
			return "Престиж"
		int(GameTypes.ActionTag.CONTROL):
			return "Контроль"
		int(GameTypes.ActionTag.DOMINANCE):
			return "Доминирование"
		int(GameTypes.ActionTag.RISK):
			return "Риск"
		int(GameTypes.ActionTag.CONFLICT):
			return "Конфликт"
		int(GameTypes.ActionTag.SPONTANEITY):
			return "Спонтанность"
		int(GameTypes.ActionTag.ABSURDITY):
			return "Абсурд"
		int(GameTypes.ActionTag.ORIGINALITY):
			return "Оригинальность"
		int(GameTypes.ActionTag.OBSESSION):
			return "Одержимость"
		_:
			return "действие"


func _reaction_text(reaction: int) -> String:
	match reaction:
		-1:
			return "[-1]"
		0:
			return "[0]"
		1:
			return "[+1]"
	return "[%d]" % reaction


func _resolve_reaction_source_label(source_id: StringName) -> String:
	var db: Node = get_node_or_null("/root/ContentDB")
	if db != null:
		if db.has_method("find_dating_greeting"):
			var greeting: DatingGreetingDefinition = db.call("find_dating_greeting", source_id) as DatingGreetingDefinition
			if greeting != null and greeting.label.strip_edges() != "":
				return greeting.label
		if source_id == &"dating_greeting_silence":
			return "Ничего не говорить"
		if db.has_method("find_dating_action"):
			var action: DatingActionDefinition = db.call("find_dating_action", source_id) as DatingActionDefinition
			if action != null and action.label.strip_edges() != "":
				return action.label
		if String(source_id).begins_with("date_event_") and db.has_method("get_dating_event"):
			var ev: DatingEventDefinition = db.call("get_dating_event", source_id) as DatingEventDefinition
			if ev != null:
				var title: String = ev.title.strip_edges()
				return title if title != "" else String(ev.id)
	var gd: Node = get_node_or_null("/root/GirlDiscovery")
	if gd != null:
		var approach: DiscoveryApproachDefinition = gd.call("find_discovery_approach", source_id) as DiscoveryApproachDefinition
		if approach != null and approach.label.strip_edges() != "":
			return approach.label
	if OS.is_debug_build() or OS.has_feature("editor"):
		push_warning("[PhoneJournal] unresolved reaction source: %s" % String(source_id))
	return ""
