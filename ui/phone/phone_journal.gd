class_name PhoneJournal
extends Control
## Functional phone journal for discovered girls (MODULE 08)
## + global/story status (MODULE 14A) + salary (MODULE 13) + MEDIA (MODULE 15)
## + Dating Overload section (MODULE 16).
## No Dating CTA / messaging / scheduling / calendar.

signal opened()
signal closed()

var _list: ItemList = null
var _detail: RichTextLabel = null
var _title: Label = null
var _close_btn: Button = null
var _player: Node = null
var _is_open: bool = false
var _listed_ids: Array[StringName] = []

var _status_section: VBoxContainer = null
var _status_label: Label = null
var _story_section: VBoxContainer = null
var _story_title: Label = null
var _story_label: Label = null

var _salary_section: VBoxContainer = null
var _salary_title: Label = null
var _salary_stats: Label = null
var _salary_advance_btn: Button = null
var _salary_pending_hint: Label = null
var _salary_feedback: Label = null
var _salary_signals_connected: bool = false

var _media_section: VBoxContainer = null
var _media_title: Label = null
var _media_attention: Label = null
var _media_pre_session: Label = null
var _media_photos_block: VBoxContainer = null
var _media_photos_title: Label = null
var _media_photo_rows: Dictionary = {}
var _media_incoming_block: VBoxContainer = null
var _media_incoming_title: Label = null
var _media_incoming_list: VBoxContainer = null
var _media_feed_block: VBoxContainer = null
var _media_feed_title: Label = null
var _media_feed_label: Label = null
var _media_signals_connected: bool = false

var _overload_section: VBoxContainer = null
var _overload_title: Label = null
var _overload_summary: Label = null
var _overload_demand_list: VBoxContainer = null
var _overload_boost_btn: Button = null
var _overload_boost_hint: Label = null
var _overload_signals_connected: bool = false
var _realization_pending: bool = false
var _realization_presented: bool = false
var _realization_dialog: AcceptDialog = null
var _player_mode_connected: bool = false


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_connect_salary_signals()
	_connect_media_signals()
	_connect_overload_signals()


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
			_list.select(i)
			_show_detail(girl_id)
			return true
	return false


func refresh() -> void:
	_refresh_status_section()
	_refresh_story_section()
	_refresh_list()
	_refresh_media_section()
	_refresh_overload_section()
	_refresh_salary_section()


func get_status_text() -> String:
	if _status_label == null:
		return ""
	return String(_status_label.text)


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
	return _media_section != null and _media_section.visible


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


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.12, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 40)
	root.add_theme_constant_override("margin_right", 40)
	root.add_theme_constant_override("margin_top", 30)
	root.add_theme_constant_override("margin_bottom", 30)
	add_child(root)
	var vbox := VBoxContainer.new()
	root.add_child(vbox)
	_title = Label.new()
	_title.text = "Телефон — Журнал"
	_title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_title)
	_build_status_section(vbox)
	_build_story_section(vbox)
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(split)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(220, 0)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_item_selected)
	split.add_child(_list)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.fit_content = false
	split.add_child(_detail)
	_build_media_section(vbox)
	_build_overload_section(vbox)
	_build_salary_section(vbox)
	_close_btn = Button.new()
	_close_btn.text = "Закрыть"
	_close_btn.pressed.connect(close)
	vbox.add_child(_close_btn)


func _build_status_section(parent: VBoxContainer) -> void:
	_status_section = VBoxContainer.new()
	_status_section.add_theme_constant_override("separation", 2)
	parent.add_child(_status_section)
	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_section.add_child(_status_label)


func _build_story_section(parent: VBoxContainer) -> void:
	_story_section = VBoxContainer.new()
	_story_section.add_theme_constant_override("separation", 2)
	parent.add_child(_story_section)
	var sep := HSeparator.new()
	_story_section.add_child(sep)
	_story_title = Label.new()
	_story_title.text = "СЮЖЕТ"
	_story_title.add_theme_font_size_override("font_size", 18)
	_story_section.add_child(_story_title)
	_story_label = Label.new()
	_story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story_section.add_child(_story_label)


func _build_media_section(parent: VBoxContainer) -> void:
	_media_section = VBoxContainer.new()
	_media_section.visible = false
	_media_section.add_theme_constant_override("separation", 4)
	parent.add_child(_media_section)
	var sep := HSeparator.new()
	_media_section.add_child(sep)
	_media_title = Label.new()
	_media_title.text = "МЕДИА"
	_media_title.add_theme_font_size_override("font_size", 18)
	_media_section.add_child(_media_title)
	_media_attention = Label.new()
	_media_attention.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_media_section.add_child(_media_attention)
	_media_pre_session = Label.new()
	_media_pre_session.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_media_pre_session.visible = false
	_media_section.add_child(_media_pre_session)
	_media_photos_block = VBoxContainer.new()
	_media_photos_block.visible = false
	_media_photos_block.add_theme_constant_override("separation", 4)
	_media_section.add_child(_media_photos_block)
	_media_photos_title = Label.new()
	_media_photos_title.text = "ФОТОГРАФИИ"
	_media_photos_title.add_theme_font_size_override("font_size", 16)
	_media_photos_block.add_child(_media_photos_title)
	_media_photo_rows.clear()
	for photo_id in MediaContent.SHOT_IDS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		_media_photos_block.add_child(row)
		var name_lbl := Label.new()
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.text = MediaContent.photo_title(photo_id)
		row.add_child(name_lbl)
		var btn := Button.new()
		btn.text = "Опубликовать"
		var captured_id: StringName = photo_id
		btn.pressed.connect(func() -> void: _on_media_publish_pressed(captured_id))
		row.add_child(btn)
		_media_photo_rows[photo_id] = {"row": row, "label": name_lbl, "button": btn}
	_media_incoming_block = VBoxContainer.new()
	_media_incoming_block.visible = false
	_media_incoming_block.add_theme_constant_override("separation", 4)
	_media_section.add_child(_media_incoming_block)
	_media_incoming_title = Label.new()
	_media_incoming_title.text = "ВХОДЯЩИЕ"
	_media_incoming_title.add_theme_font_size_override("font_size", 16)
	_media_incoming_block.add_child(_media_incoming_title)
	_media_incoming_list = VBoxContainer.new()
	_media_incoming_list.add_theme_constant_override("separation", 4)
	_media_incoming_block.add_child(_media_incoming_list)
	_media_feed_block = VBoxContainer.new()
	_media_feed_block.visible = false
	_media_feed_block.add_theme_constant_override("separation", 2)
	_media_section.add_child(_media_feed_block)
	_media_feed_title = Label.new()
	_media_feed_title.text = "ЛЕНТА"
	_media_feed_title.add_theme_font_size_override("font_size", 16)
	_media_feed_block.add_child(_media_feed_title)
	_media_feed_label = Label.new()
	_media_feed_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_media_feed_block.add_child(_media_feed_label)


func _build_overload_section(parent: VBoxContainer) -> void:
	_overload_section = VBoxContainer.new()
	_overload_section.visible = false
	_overload_section.add_theme_constant_override("separation", 4)
	parent.add_child(_overload_section)
	var sep := HSeparator.new()
	_overload_section.add_child(sep)
	_overload_title = Label.new()
	_overload_title.text = "ПЕРЕГРУЗКА"
	_overload_title.add_theme_font_size_override("font_size", 18)
	_overload_section.add_child(_overload_title)
	_overload_summary = Label.new()
	_overload_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_overload_section.add_child(_overload_summary)
	_overload_demand_list = VBoxContainer.new()
	_overload_demand_list.add_theme_constant_override("separation", 6)
	_overload_section.add_child(_overload_demand_list)
	var boost_row := HBoxContainer.new()
	boost_row.add_theme_constant_override("separation", 12)
	_overload_section.add_child(boost_row)
	_overload_boost_btn = Button.new()
	_overload_boost_btn.text = "Поднять волну"
	_overload_boost_btn.visible = false
	_overload_boost_btn.pressed.connect(_on_overload_feed_boost_pressed)
	boost_row.add_child(_overload_boost_btn)
	_overload_boost_hint = Label.new()
	_overload_boost_hint.visible = false
	_overload_boost_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boost_row.add_child(_overload_boost_hint)
	_realization_dialog = AcceptDialog.new()
	_realization_dialog.title = ""
	_realization_dialog.dialog_text = ""
	_realization_dialog.ok_button_text = "ОК"
	add_child(_realization_dialog)


func _build_salary_section(parent: VBoxContainer) -> void:
	_salary_section = VBoxContainer.new()
	_salary_section.visible = false
	_salary_section.add_theme_constant_override("separation", 4)
	parent.add_child(_salary_section)
	var sep := HSeparator.new()
	_salary_section.add_child(sep)
	_salary_title = Label.new()
	_salary_title.text = "ЗАРПЛАТА"
	_salary_title.add_theme_font_size_override("font_size", 18)
	_salary_section.add_child(_salary_title)
	_salary_stats = Label.new()
	_salary_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_salary_section.add_child(_salary_stats)
	var advance_row := HBoxContainer.new()
	advance_row.add_theme_constant_override("separation", 12)
	_salary_section.add_child(advance_row)
	_salary_advance_btn = Button.new()
	_salary_advance_btn.text = "Получить зарплату вперёд"
	_salary_advance_btn.visible = false
	_salary_advance_btn.pressed.connect(_on_salary_advance_pressed)
	advance_row.add_child(_salary_advance_btn)
	_salary_pending_hint = Label.new()
	_salary_pending_hint.visible = false
	advance_row.add_child(_salary_pending_hint)
	_salary_feedback = Label.new()
	_salary_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_salary_section.add_child(_salary_feedback)


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


func _on_upgrade_points_changed_status(_new_value: int, _delta: int) -> void:
	_request_status_refresh()


func _on_day_advanced_status(_new_day: int) -> void:
	_request_status_refresh()
	_request_media_refresh()
	_request_overload_refresh()
	_request_salary_refresh()
	_request_story_refresh()


func _on_story_objective_changed(_progress: StoryStageProgress) -> void:
	_request_story_refresh()


func _on_story_stage_started(_stage: GameTypes.GameStage) -> void:
	_request_story_refresh()


func _request_status_refresh() -> void:
	if _is_open:
		_refresh_status_section()


func _request_story_refresh() -> void:
	if _is_open:
		_refresh_story_section()


func _refresh_status_section() -> void:
	if _status_label == null:
		return
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
	var lines: PackedStringArray = PackedStringArray()
	lines.append("День: %d" % day_value)
	lines.append("Деньги: %d" % money_value)
	lines.append("Авторитет: %d" % authority_value)
	lines.append("Опытность: %d" % experience_value)
	lines.append("Баллы прокачки: %d" % upgrade_points_value)
	_status_label.text = "\n".join(lines)


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
	# STAGE_4: reserved Scientist IDs are not authored yet — MODULE 15 media handoff (§91).
	if progress.stage == GameTypes.GameStage.STAGE_4 and _is_stage4_media_handoff(progress):
		_story_label.text = _stage4_media_handoff_text()
		return
	var stage_name: String = progress.display_name.strip_edges()
	if stage_name == "":
		stage_name = String(GameTypes.GameStage.find_key(int(progress.stage)))
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
	_story_label.text = "\n".join(lines)


func _is_stage4_media_handoff(progress: StoryStageProgress) -> bool:
	var db: Node = get_node_or_null("/root/ContentDB")
	if db == null:
		return true
	var girl_missing: bool = false
	if String(progress.story_girl_id) != "":
		if db.has_method("try_get_girl"):
			girl_missing = db.call("try_get_girl", progress.story_girl_id) == null
		else:
			girl_missing = true
	var rival_missing: bool = false
	if progress.rival_required and String(progress.story_rival_id) != "":
		if db.has_method("try_get_rival"):
			rival_missing = db.call("try_get_rival", progress.story_rival_id) == null
		else:
			rival_missing = true
	return girl_missing or rival_missing


func _stage4_media_handoff_text() -> String:
	var overload: Node = get_node_or_null("/root/DatingOverload")
	if overload != null and overload.has_method("is_problem_recognized") and bool(overload.call("is_problem_recognized")):
		var after: PackedStringArray = PackedStringArray()
		after.append("СТАДИЯ 4")
		after.append("")
		after.append(DatingOverloadTypes.REALIZATION_LINE_1)
		after.append(DatingOverloadTypes.REALIZATION_LINE_2)
		after.append("")
		after.append("Следующий шаг:")
		after.append("Найти способ быть в нескольких местах одновременно.")
		return "\n".join(after)
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
	lines.append("За период: %d" % status.gross_per_period)
	lines.append("Накоплено: %d" % status.pending_salary)
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
		_salary_feedback.text = "Получено удалённо: +%d" % result.amount
	else:
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
	# Do not interrupt an open Phone / dating / rival flow (§107).
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
		return
	var status: DatingOverloadStatus = null
	if overload.has_method("get_status"):
		status = overload.call("get_status") as DatingOverloadStatus
	if status == null:
		return
	var lines: PackedStringArray = PackedStringArray()
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
			_overload_boost_hint.text = "+5 Внимания\nСледующий день: +1 входящий запрос"
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
		var empty := Label.new()
		empty.text = "Нет активных запросов"
		_overload_demand_list.add_child(empty)
		return
	var day_node: Node = get_node_or_null("/root/GameDay")
	var current_day: int = 1
	if day_node != null and day_node.has_method("get_current_day"):
		current_day = int(day_node.call("get_current_day"))
	for entry in sorted:
		var e: DatingDemandEntry = entry as DatingDemandEntry
		if e == null:
			continue
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 1)
		_overload_demand_list.add_child(row)
		var status_lbl := Label.new()
		if e.status == DatingOverloadTypes.DatingDemandStatus.OVERDUE:
			status_lbl.text = "OVERDUE"
		else:
			status_lbl.text = "WAITING"
		row.add_child(status_lbl)
		var time_lbl := Label.new()
		var slot_time: String = DatingOverloadTypes.slot_display_time(e.slot)
		if e.status == DatingOverloadTypes.DatingDemandStatus.OVERDUE:
			var day_delta: int = current_day - e.appointment_day
			if day_delta <= 1:
				time_lbl.text = "Вчера, %s" % slot_time
			else:
				time_lbl.text = "%d дн. назад, %s" % [day_delta, slot_time]
		else:
			time_lbl.text = slot_time
		row.add_child(time_lbl)
		var name_row := HBoxContainer.new()
		name_row.add_theme_constant_override("separation", 8)
		row.add_child(name_row)
		var name_lbl := Label.new()
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.text = _actor_display_name(e.girl_id, false)
		name_row.add_child(name_lbl)
		var open_btn := Button.new()
		open_btn.text = "Открыть контакт"
		var captured_id: StringName = e.girl_id
		open_btn.pressed.connect(func() -> void: select_girl_by_id(captured_id))
		name_row.add_child(open_btn)


func _on_overload_feed_boost_pressed() -> void:
	var overload: Node = get_node_or_null("/root/DatingOverload")
	if overload == null or not overload.has_method("use_feed_boost"):
		return
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
		# Safe world GAMEPLAY only — never interrupt Phone / dating / rival (§107).
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
		_realization_dialog = AcceptDialog.new()
		_realization_dialog.ok_button_text = "ОК"
		add_child(_realization_dialog)
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


func _request_list_refresh() -> void:
	if _is_open:
		_refresh_list()


func _refresh_media_section() -> void:
	if _media_section == null:
		return
	var media: Node = get_node_or_null("/root/Media")
	var unlocked: bool = false
	if media != null and media.has_method("is_feature_unlocked"):
		unlocked = bool(media.call("is_feature_unlocked"))
	_media_section.visible = unlocked
	if not unlocked:
		return
	var attention: int = 0
	if media.has_method("get_attention"):
		attention = int(media.call("get_attention"))
	_media_attention.text = "Внимание: %d / %d" % [attention, MediaContent.ATTENTION_MAX]
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
		var row: HBoxContainer = row_data.get("row") as HBoxContainer
		var btn: Button = row_data.get("button") as Button
		var name_lbl: Label = row_data.get("label") as Label
		if row == null or btn == null or name_lbl == null:
			continue
		var prepared: bool = bool(media.call("is_photo_prepared", photo_id))
		if not prepared:
			row.visible = false
			continue
		row.visible = true
		name_lbl.text = MediaContent.photo_title(photo_id)
		var published: bool = bool(media.call("is_photo_published", photo_id))
		if published:
			btn.text = "Опубликовано"
			btn.disabled = true
		elif not can_today:
			btn.text = "Следующая публикация завтра"
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
		var empty_lbl := Label.new()
		empty_lbl.text = "Пока нет входящих"
		_media_incoming_list.add_child(empty_lbl)
		return
	for entry in offer_ids:
		var girl_id: StringName = entry as StringName
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_media_incoming_list.add_child(row)
		var status_lbl := Label.new()
		var is_read: bool = bool(media.call("is_offer_read", girl_id))
		status_lbl.text = "READ" if is_read else "NEW"
		row.add_child(status_lbl)
		var name_lbl := Label.new()
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.text = _actor_display_name(girl_id, false)
		row.add_child(name_lbl)
		var open_btn := Button.new()
		open_btn.text = "Открыть"
		var captured_id: StringName = girl_id
		open_btn.pressed.connect(func() -> void: _on_media_open_offer_pressed(captured_id))
		row.add_child(open_btn)


func _refresh_media_feed(media: Node) -> void:
	if _media_feed_label == null:
		return
	var feed_ids: Array = media.call("get_feed_event_ids") as Array
	var lines: PackedStringArray = PackedStringArray()
	# Persistent array is oldest→newest; display newest first (§68).
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
	_refresh_media_section()
	_request_story_refresh()
	if result.ok:
		_refresh_list()


func _on_media_open_offer_pressed(girl_id: StringName) -> void:
	var media: Node = get_node_or_null("/root/Media")
	if media != null and media.has_method("mark_offer_read"):
		media.call("mark_offer_read", girl_id)
	select_girl_by_id(girl_id)
	_refresh_media_section()


func _refresh_list() -> void:
	_listed_ids.clear()
	if _list != null:
		_list.clear()
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	var ids: Array = gs.call("get_discovered_girl_ids") as Array
	var gd: Node = get_node_or_null("/root/GirlDiscovery")
	for entry in ids:
		var gid: StringName = entry as StringName
		_listed_ids.append(gid)
		var display: String = String(gid)
		if gd != null:
			var def: GirlDefinition = gd.call("get_girl_definition", gid) as GirlDefinition
			if def != null and def.display_name.strip_edges() != "":
				display = def.display_name
		var has_contact: bool = bool(gs.call("has_girl_contact", gid))
		var status: String = "Номер получен" if has_contact else "Номера нет"
		_list.add_item("%s — %s" % [display, status])
	if _listed_ids.is_empty():
		_detail.text = "Пока нет записей."
	elif _list.get_selected_items().is_empty():
		_list.select(0)
		_show_detail(_listed_ids[0])


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
		return
	var def: GirlDefinition = gd.call("get_girl_definition", girl_id) as GirlDefinition
	var lines: PackedStringArray = PackedStringArray()
	var name: String = String(girl_id)
	if def != null and def.display_name.strip_edges() != "":
		name = def.display_name
	lines.append("[b]%s[/b]" % name)
	var has_contact: bool = bool(gs.call("has_girl_contact", girl_id))
	if has_contact:
		lines.append("Статус: Номер получен")
	else:
		lines.append("Статус: Номера нет")
	var rel: int = int(gs.call("get_girl_relationship", girl_id))
	lines.append("Отношения: %+d / 5" % rel)
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
			lines.append("- %s: %s" % [label, _reaction_text(reaction)])
	_detail.text = "\n".join(lines)


func _format_tags(tags: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for tag in tags:
		parts.append(String(GameTypes.ActionTag.find_key(int(tag))))
	return ", ".join(parts)


func _reaction_text(reaction: int) -> String:
	match reaction:
		-1:
			return "негативная"
		0:
			return "нейтральная"
		1:
			return "позитивная"
	return str(reaction)


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
	# Production UI: skip unresolved technical IDs.
	if OS.is_debug_build() or OS.has_feature("editor"):
		push_warning("[PhoneJournal] unresolved reaction source: %s" % String(source_id))
	return ""
