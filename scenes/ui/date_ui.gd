extends Control
## Manual dating overlay. Observation → interpretation (hypothesis).

@onready var title: Label = $Panel/VBox/Title
@onready var hints: Label = $Panel/VBox/Hints
@onready var phase_label: Label = $Panel/VBox/Phase
@onready var emotion_label: Label = $Panel/VBox/Emotion
@onready var buttons: VBoxContainer = $Panel/VBox/Buttons

var _prompt_label: Label
var _coach_label: Label
var _feedback_label: Label
const GIFT_ICON_DIR := "res://assets/ui/gifts/placeholders/"

var _gift_btn: Button
var _finish_btn: Button
var _gift_list: ItemList
var _result_panel: PanelContainer
var _result_label: RichTextLabel
var _result_close_btn: Button
var _result_gift_btn: Button
var _gift_popup: PanelContainer
var _gift_grid: GridContainer
var _gift_select_btn: Button
var _gift_close_btn: Button
var _gift_tooltip: Label
var _selected_gift_id: StringName = &""
var _gift_for_result: bool = false
var _showing_result: bool = false
var _last_result: Dictionary = {}


func _ready() -> void:
	add_to_group("date_ui")
	title.add_theme_font_size_override("font_size", 26)
	phase_label.add_theme_font_size_override("font_size", 18)
	emotion_label.add_theme_font_size_override("font_size", 18)
	emotion_label.add_theme_color_override("font_color", Color("#F2BD69"))
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dim := get_node_or_null("Dim") as ColorRect
	if dim:
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := get_node_or_null("Panel") as Control
	if panel:
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		_configure_panel_layout(panel)
	_ensure_prompt_label()
	_ensure_coach_labels()
	_ensure_date_actions()
	Game.dating.date_ui_open.connect(_open)
	Game.dating.date_ui_close.connect(_close)
	Game.dating.date_phase.connect(_on_phase)
	EventBus.notify.connect(_on_notify)
	EventBus.date_finished.connect(_on_date_finished)


func _ensure_prompt_label() -> void:
	if _prompt_label != null and is_instance_valid(_prompt_label):
		return
	var vbox := get_node_or_null("Panel/VBox") as VBoxContainer
	if vbox == null:
		return
	_prompt_label = Label.new()
	_prompt_label.name = "Prompt"
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_prompt_label)
	vbox.move_child(_prompt_label, phase_label.get_index() + 1)


func _ensure_coach_labels() -> void:
	var vbox := get_node_or_null("Panel/VBox") as VBoxContainer
	if vbox == null:
		return
	if _coach_label == null or not is_instance_valid(_coach_label):
		_coach_label = Label.new()
		_coach_label.name = "Coach"
		_coach_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_coach_label.add_theme_font_size_override("font_size", 14)
		_coach_label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
		vbox.add_child(_coach_label)
		vbox.move_child(_coach_label, phase_label.get_index())
	if _feedback_label == null or not is_instance_valid(_feedback_label):
		_feedback_label = Label.new()
		_feedback_label.name = "Feedback"
		_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_feedback_label.add_theme_font_size_override("font_size", 13)
		_feedback_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
		vbox.add_child(_feedback_label)
		vbox.move_child(_feedback_label, emotion_label.get_index() + 1)


func _ensure_date_actions() -> void:
	var vbox := get_node_or_null("Panel/VBox") as VBoxContainer
	if vbox == null:
		return
	if _gift_btn == null or not is_instance_valid(_gift_btn):
		_gift_btn = Button.new()
		_gift_btn.name = "GiftBtn"
		_gift_btn.text = "Подарить подарок"
		_gift_btn.visible = false
		_gift_btn.custom_minimum_size = Vector2(0, 40)
		_gift_btn.focus_mode = Control.FOCUS_NONE
		_gift_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		_gift_btn.pressed.connect(_on_gift_pressed)
		vbox.add_child(_gift_btn)
	if _gift_list == null or not is_instance_valid(_gift_list):
		_gift_list = ItemList.new()
		_gift_list.name = "GiftList"
		_gift_list.visible = false
		_gift_list.custom_minimum_size = Vector2(0, 90)
		_gift_list.focus_mode = Control.FOCUS_NONE
		_gift_list.gui_input.connect(_on_gift_list_gui_input)
		vbox.add_child(_gift_list)
	if _finish_btn == null or not is_instance_valid(_finish_btn):
		_finish_btn = Button.new()
		_finish_btn.name = "FinishBtn"
		_finish_btn.text = "Завершить свидание"
		_finish_btn.visible = false
		_finish_btn.focus_mode = Control.FOCUS_NONE
		_finish_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		_finish_btn.pressed.connect(func(): Game.dating.finish_manual())
		vbox.add_child(_finish_btn)
	# Keep gift controls above dialogue choices so they are never clipped under answers.
	if buttons != null and _gift_btn != null and is_instance_valid(_gift_btn):
		vbox.move_child(_gift_btn, buttons.get_index())
	if _gift_btn != null and is_instance_valid(_gift_btn) and _gift_list != null and is_instance_valid(_gift_list):
		vbox.move_child(_gift_list, _gift_btn.get_index() + 1)


func _on_gift_pressed() -> void:
	if not Game.dating.can_give_date_gift():
		EventBus.toast("Нужен подарок в инвентаре (купи в магазине до свидания)", &"warn")
		return
	_gift_for_result = false
	_open_gift_inventory()


func _on_gift_list_gui_input(event: InputEvent) -> void:
	## Legacy ItemList path kept as fallback.
	if _gift_list == null:
		return
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or mb.pressed:
		return
	var index: int = _gift_list.get_item_at_position(mb.position, true)
	if index < 0:
		return
	var gid := StringName(str(_gift_list.get_item_metadata(index)))
	if Game.dating.give_date_gift(gid):
		_gift_list.visible = false
		_refresh_action_buttons()


func _refresh_action_buttons() -> void:
	var active: bool = not Game.dating.active_manual.is_empty()
	var done: bool = bool(Game.dating.active_manual.get("phases_done", false))
	var gift_given: bool = bool(Game.dating.active_manual.get("gift_given", false))
	if _finish_btn:
		_finish_btn.visible = done and not _showing_result
	if _gift_btn:
		## Always show during an active date until a gift is given (visible above answers).
		_gift_btn.visible = active and (not _showing_result) and (not gift_given)
		var can_gift: bool = Game.dating.can_give_date_gift()
		_gift_btn.disabled = not can_gift
		_gift_btn.text = "Подарить подарок" if can_gift else "Подарить подарок (нет в инвентаре)"
	if _gift_list and (not active or gift_given or _showing_result):
		_gift_list.visible = false
	if _result_gift_btn:
		_result_gift_btn.visible = _showing_result


func _close() -> void:
	if _showing_result:
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := get_node_or_null("Panel") as Control
	if panel and visible:
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_property(panel, "modulate:a", 0.0, 0.18)
		tween.tween_property(panel, "scale", Vector2(0.98, 0.98), 0.18)
		await tween.finished
	if _showing_result:
		return
	visible = false
	if buttons:
		for c in buttons.get_children():
			c.queue_free()


func _on_notify(message: String, kind: StringName) -> void:
	if kind != &"date_fx":
		return
	if message.begins_with("DATE_EMOTION:"):
		var emo := message.trim_prefix("DATE_EMOTION:")
		emotion_label.text = "Реакция: %s" % _emo_ru(emo)
		_spawn_reaction_vfx(emo)
		_pulse_emotion()
	elif message == "DATE_CHOICE_DONE":
		_show_choice_feedback()


func _emo_ru(emo: String) -> String:
	match emo:
		"delighted":
			return "в восторге"
		"happy":
			return "довольна"
		"annoyed":
			return "раздражена"
		_:
			return "нейтрально"


func _on_date_finished(result: Dictionary) -> void:
	_show_result_panel(result)


func _ensure_result_panel() -> void:
	if _result_panel != null and is_instance_valid(_result_panel):
		return
	_result_panel = PanelContainer.new()
	_result_panel.name = "ResultPanel"
	_result_panel.visible = false
	_result_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_result_panel.anchor_left = 0.24
	_result_panel.anchor_top = 0.16
	_result_panel.anchor_right = 0.76
	_result_panel.anchor_bottom = 0.84
	_result_panel.offset_left = 0.0
	_result_panel.offset_top = 0.0
	_result_panel.offset_right = 0.0
	_result_panel.offset_bottom = 0.0
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_result_panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	var title_lbl := Label.new()
	title_lbl.name = "ResultTitle"
	title_lbl.text = "Итог свидания"
	title_lbl.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title_lbl)
	_result_label = RichTextLabel.new()
	_result_label.name = "ResultBody"
	_result_label.bbcode_enabled = true
	_result_label.fit_content = true
	_result_label.scroll_active = true
	_result_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_result_label.custom_minimum_size = Vector2(0, 240)
	vbox.add_child(_result_label)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	vbox.add_child(actions)
	_result_gift_btn = Button.new()
	_result_gift_btn.name = "ResultGift"
	_result_gift_btn.text = "Подарок"
	_result_gift_btn.focus_mode = Control.FOCUS_NONE
	_result_gift_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	_result_gift_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_result_gift_btn.pressed.connect(_on_result_gift_pressed)
	actions.add_child(_result_gift_btn)
	_result_close_btn = Button.new()
	_result_close_btn.name = "ResultClose"
	_result_close_btn.text = "Продолжить"
	_result_close_btn.focus_mode = Control.FOCUS_NONE
	_result_close_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	_result_close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_result_close_btn.pressed.connect(_dismiss_result_panel)
	actions.add_child(_result_close_btn)
	add_child(_result_panel)
	_ensure_gift_popup()


func _ensure_gift_popup() -> void:
	if _gift_popup != null and is_instance_valid(_gift_popup):
		return
	_gift_popup = PanelContainer.new()
	_gift_popup.name = "GiftInventoryPopup"
	_gift_popup.visible = false
	_gift_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	_gift_popup.anchor_left = 0.3
	_gift_popup.anchor_top = 0.2
	_gift_popup.anchor_right = 0.7
	_gift_popup.anchor_bottom = 0.78
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_gift_popup.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	var title_lbl := Label.new()
	title_lbl.text = "Инвентарь подарков"
	title_lbl.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title_lbl)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 220)
	vbox.add_child(scroll)
	_gift_grid = GridContainer.new()
	_gift_grid.columns = 4
	_gift_grid.add_theme_constant_override("h_separation", 8)
	_gift_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_gift_grid)
	_gift_tooltip = Label.new()
	_gift_tooltip.name = "GiftTooltip"
	_gift_tooltip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_gift_tooltip.add_theme_font_size_override("font_size", 13)
	_gift_tooltip.add_theme_color_override("font_color", Color(0.92, 0.88, 0.7))
	_gift_tooltip.text = "Наведи на подарок"
	_gift_tooltip.custom_minimum_size = Vector2(0, 36)
	vbox.add_child(_gift_tooltip)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)
	_gift_select_btn = Button.new()
	_gift_select_btn.text = "Выбрать"
	_gift_select_btn.disabled = true
	_gift_select_btn.focus_mode = Control.FOCUS_NONE
	_gift_select_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	_gift_select_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gift_select_btn.pressed.connect(_on_gift_select_pressed)
	row.add_child(_gift_select_btn)
	_gift_close_btn = Button.new()
	_gift_close_btn.text = "Закрыть"
	_gift_close_btn.focus_mode = Control.FOCUS_NONE
	_gift_close_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	_gift_close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gift_close_btn.pressed.connect(func() -> void:
		if _gift_popup:
			_gift_popup.visible = false
	)
	row.add_child(_gift_close_btn)
	add_child(_gift_popup)


func _gift_icon_texture(gift_id: String) -> Texture2D:
	var path: String = GIFT_ICON_DIR + gift_id + ".png"
	var tex: Texture2D = _load_gift_texture(path)
	if tex != null:
		return tex
	return _load_gift_texture(GIFT_ICON_DIR + "_default.png")


func _load_gift_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	if FileAccess.file_exists(path):
		var img: Image = Image.load_from_file(path)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null


func _owned_gift_entries() -> Array:
	var entries: Array = []
	for gid in Game.inventory.gift_counts.keys():
		var count: int = int(Game.inventory.gift_counts[gid])
		if count <= 0:
			continue
		entries.append({"id": str(gid), "count": count, "carried": false})
	var carried: String = str(Game.inventory.carried_item)
	if carried != "" and not carried.begins_with("food:") and not carried.begins_with("drink:"):
		entries.append({"id": carried, "count": 1, "carried": true})
	return entries


func _open_gift_inventory() -> void:
	_ensure_gift_popup()
	_selected_gift_id = &""
	if _gift_select_btn:
		_gift_select_btn.disabled = true
	if _gift_tooltip:
		_gift_tooltip.text = "Наведи на подарок"
	if _gift_grid:
		for c in _gift_grid.get_children():
			c.queue_free()
	var entries: Array = _owned_gift_entries()
	if entries.is_empty():
		EventBus.toast("В инвентаре нет подарков", &"info")
		if _gift_popup:
			_gift_popup.visible = false
		return
	for entry_v in entries:
		var entry: Dictionary = entry_v
		var gid: String = str(entry.get("id", ""))
		var def: Dictionary = ContentDB.gift(StringName(gid))
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(72, 72)
		btn.focus_mode = Control.FOCUS_NONE
		btn.toggle_mode = true
		btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		var icon: Texture2D = _gift_icon_texture(gid)
		if icon:
			btn.icon = icon
			btn.expand_icon = true
		btn.text = "×%d" % int(entry.get("count", 1))
		if bool(entry.get("carried", false)):
			btn.tooltip_text = "%s (в руках)" % str(def.get("name", gid))
		else:
			btn.tooltip_text = str(def.get("name", gid))
		var desc: String = _gift_description(def, gid)
		btn.mouse_entered.connect(func() -> void:
			if _gift_tooltip:
				_gift_tooltip.text = desc
		)
		var pick_id: StringName = StringName(gid)
		btn.pressed.connect(func() -> void:
			_select_gift_in_popup(pick_id, btn)
		)
		_gift_grid.add_child(btn)
	if _gift_popup:
		_gift_popup.visible = true
		_gift_popup.move_to_front()


func _gift_description(def: Dictionary, gid: String) -> String:
	var name: String = str(def.get("name", gid))
	var tags: Array = def.get("tags", [])
	var parts: PackedStringArray = PackedStringArray()
	for t in tags:
		parts.append(str(t))
	var tag_s: String = ", ".join(parts) if not parts.is_empty() else "обычный"
	var cat: String = str(def.get("category", ""))
	return "%s — %s (кат.: %s, кач.: %.0f)" % [name, tag_s, cat, float(def.get("quality", 0.0))]


func _select_gift_in_popup(gift_id: StringName, chosen: Button) -> void:
	_selected_gift_id = gift_id
	if _gift_select_btn:
		_gift_select_btn.disabled = gift_id == &""
	if _gift_grid:
		for c in _gift_grid.get_children():
			if c is Button:
				(c as Button).button_pressed = c == chosen
	var def: Dictionary = ContentDB.gift(gift_id)
	if _gift_tooltip:
		_gift_tooltip.text = _gift_description(def, str(gift_id))


func _on_gift_select_pressed() -> void:
	if _selected_gift_id == &"":
		return
	var ok: bool = false
	if _gift_for_result:
		ok = Game.dating.give_result_gift(_selected_gift_id)
	else:
		ok = Game.dating.give_date_gift(_selected_gift_id)
	if not ok:
		return
	if _gift_popup:
		_gift_popup.visible = false
	_refresh_action_buttons()
	if _gift_for_result:
		_show_result_panel(Game.dating.last_result)


func _on_result_gift_pressed() -> void:
	_gift_for_result = true
	_open_gift_inventory()


func _fill_result_body(result: Dictionary) -> void:
	var factors: Dictionary = result.get("factors", {})
	var punct: Dictionary = factors.get("punctuality", {})
	var place: Dictionary = factors.get("place", {})
	var outfit_v: Variant = factors.get("outfit", {})
	var gift: Dictionary = factors.get("gift", {})
	var dlg: Dictionary = factors.get("dialogues", {})
	var outfit_label := "casual"
	var outfit_score := ""
	if outfit_v is Dictionary:
		outfit_label = str((outfit_v as Dictionary).get("label", (outfit_v as Dictionary).get("id", "casual")))
		outfit_score = " (%.1f)" % float((outfit_v as Dictionary).get("score", 0.0))
	else:
		outfit_label = str(outfit_v) if str(outfit_v) != "" else "casual"
	var correct: int = int(result.get("correct", dlg.get("correct", 0)))
	var wrong: int = int(result.get("wrong", dlg.get("wrong", 0)))
	var neutral: int = int(result.get("neutral", dlg.get("neutral", 0)))
	var total_dlg: int = correct + wrong + neutral
	var mood: String = str(result.get("mood", result.get("emotion", "neutral")))
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[b]%s[/b]" % str(result.get("grade_name", "итог")))
	lines.append("Связь за свидание %+.0f · всего %.0f" % [
		float(result.get("bond", result.get("relation", 0.0))),
		float(result.get("bond_total", result.get("bond", 0.0))),
	])
	lines.append("+%d$ · +%.1f pop · скандал %.1f" % [
		int(result.get("money", 0)),
		float(result.get("popularity", 0.0)),
		float(result.get("scandal", 0.0)),
	])
	lines.append("Настроение: [b]%s[/b]" % _emo_ru(mood))
	lines.append("Удачные диалоги: [b]%d[/b] / %d" % [correct, total_dlg])
	lines.append("")
	lines.append("[b]Пять факторов[/b]")
	lines.append("• Пунктуальность: %s (%.1f)" % [str(punct.get("label", "—")), float(punct.get("score", 0.0))])
	lines.append("• Место / подготовка: %s (%.1f)" % [
		str(place.get("label", place.get("id", "?"))),
		float(place.get("quality", 0.0)),
	])
	lines.append("• Образ: %s%s" % [outfit_label, outfit_score])
	lines.append("• Подарок: %s" % str(gift.get("label", "без подарка (ок)")))
	lines.append("• Диалоги: %s" % str(dlg.get("label", "%d/%d удачных" % [correct, total_dlg])))
	if _result_label:
		_result_label.text = "\n".join(lines)


func _show_result_panel(result: Dictionary) -> void:
	_ensure_result_panel()
	_last_result = result.duplicate(true)
	_showing_result = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dialog_panel := get_node_or_null("Panel") as Control
	if dialog_panel:
		dialog_panel.visible = false
	if _gift_btn:
		_gift_btn.visible = false
	if _gift_list:
		_gift_list.visible = false
	if _finish_btn:
		_finish_btn.visible = false
	if _result_gift_btn:
		_result_gift_btn.visible = true
		_result_gift_btn.disabled = false
		if bool(result.get("gift_given", false)):
			_result_gift_btn.text = "Подарок вручён"
		else:
			_result_gift_btn.text = "Подарок"
	_fill_result_body(result)
	if _result_panel:
		_result_panel.visible = true
		_result_panel.modulate.a = 0.0
		_result_panel.scale = Vector2(0.96, 0.96)
		_result_panel.pivot_offset = _result_panel.size * 0.5
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(_result_panel, "modulate:a", 1.0, 0.28)
		tween.tween_property(_result_panel, "scale", Vector2.ONE, 0.28)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _dismiss_result_panel() -> void:
	_showing_result = false
	if _result_panel:
		_result_panel.visible = false
	if _gift_popup:
		_gift_popup.visible = false
	var dialog_panel := get_node_or_null("Panel") as Control
	if dialog_panel:
		dialog_panel.visible = true
		dialog_panel.modulate.a = 1.0
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if buttons:
		for c in buttons.get_children():
			c.queue_free()
	# Restore FPS mouse unless another overlay is up.
	var tree := get_tree()
	if tree != null:
		var blocked := false
		for group in ["pause_ui", "phone_ui", "event_ui", "shop_ui", "settings_ui"]:
			var n: Node = tree.get_first_node_in_group(group)
			if n != null and n is CanvasItem and (n as CanvasItem).visible:
				blocked = true
				break
		if not blocked:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _open(payload: Dictionary) -> void:
	var was_visible: bool = visible
	_showing_result = false
	if _result_panel:
		_result_panel.visible = false
	if _gift_popup:
		_gift_popup.visible = false
	var dialog_panel := get_node_or_null("Panel") as Control
	if dialog_panel:
		dialog_panel.visible = true
	_ensure_prompt_label()
	_ensure_coach_labels()
	_ensure_date_actions()
	title.text = "Свидание: %s" % str(payload.get("title", ""))
	var hs: PackedStringArray = PackedStringArray()
	for h in payload.get("hints", []):
		hs.append(str(h))
	while hs.size() > 2:
		hs.remove_at(hs.size() - 1)
	hints.text = "   •   ".join(hs)
	if _prompt_label:
		_prompt_label.text = str(payload.get("prompt", ""))
	if not was_visible:
		emotion_label.text = "Реакция: нейтрально"
		if _feedback_label:
			_feedback_label.text = ""
	_refresh_coach()
	if bool(payload.get("phases_done", false)):
		phase_label.text = "МОЖНО ЗАВЕРШИТЬ"
		for c in buttons.get_children():
			c.queue_free()
	_refresh_action_buttons()
	var panel := get_node_or_null("Panel") as Control
	if panel and not was_visible:
		# Only dim on first open; mid-date refresh must keep dialogue readable.
		panel.modulate.a = 0.0
	elif panel and was_visible:
		panel.modulate.a = 1.0


func show_after_intro() -> void:
	## Called by DateStage right after girl sits — dialogue must appear immediately.
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh_coach()
	# If phase buttons were never built (or cleared), rebuild from live active date.
	if buttons != null and buttons.get_child_count() == 0 and not Game.dating.active_manual.is_empty():
		var opts: Array = Game.dating.active_manual.get("options", [])
		var phase_i: int = int(Game.dating.active_manual.get("phase", 0))
		if not opts.is_empty():
			_on_phase(phase_i, opts)
	var panel := get_node_or_null("Panel") as Control
	if panel:
		panel.visible = true
		_configure_panel_layout(panel)
		panel.pivot_offset = panel.size * 0.5
		panel.modulate.a = 0.0
		panel.scale = Vector2(0.97, 0.97)
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(panel, "modulate:a", 1.0, 0.34)
		tween.tween_property(panel, "scale", Vector2.ONE, 0.34)
	_refresh_action_buttons()
	Sfx.play_ui(&"date_ok")


func _refresh_coach() -> void:
	if _coach_label == null:
		return
	if bool(Game.quests.flags.get("date_hypothesis_taught", false)):
		_coach_label.text = ""
		return
	_coach_label.text = "Наблюдай → выбери реакцию → подтверди догадку повторным сигналом."


func _mark_hypothesis_taught() -> void:
	if bool(Game.quests.flags.get("date_hypothesis_taught", false)):
		return
	Game.quests.flags["date_hypothesis_taught"] = true
	if _coach_label:
		_coach_label.text = ""


func _show_choice_feedback() -> void:
	if _feedback_label == null:
		return
	var choices: Array = Game.dating.active_manual.get("choices", [])
	if choices.is_empty():
		return
	var last: Dictionary = choices[choices.size() - 1]
	var quality: String = str(last.get("quality", "ok"))
	if bool(last.get("confirmed", false)):
		_feedback_label.text = "Черта подтверждена — можно опираться на неё дальше."
	elif bool(last.get("hypothesis", false)):
		_feedback_label.text = "Гипотеза записана. Нужно ещё одно похожее подтверждение."
	elif bool(last.get("rejected", false)):
		_feedback_label.text = "Гипотеза не подтвердилась. Наблюдение остаётся в журнале."
	elif quality == "ok":
		_feedback_label.text = "Нейтрально — связь чуть сдвинулась, знание почти нет."
	else:
		_feedback_label.text = ""
	_mark_hypothesis_taught()


func _on_phase(phase_index: int, options: Array) -> void:
	_ensure_prompt_label()
	_ensure_coach_labels()
	_show_choice_feedback()
	phase_label.text = "НАБЛЮДЕНИЕ %d/3" % (phase_index + 1)
	var prompt := ""
	if not options.is_empty():
		prompt = str(options[0].get("prompt", ""))
	if prompt.is_empty():
		prompt = str(Game.dating.active_manual.get("prompt", ""))
	if _prompt_label:
		_prompt_label.text = prompt
	var tid := str(Game.dating.active_manual.get("target_id", ""))
	if not tid.is_empty():
		var phase_hints: PackedStringArray = Game.dating.profile_hints(tid, true)
		while phase_hints.size() > 2:
			phase_hints.remove_at(phase_hints.size() - 1)
		hints.text = "   •   ".join(phase_hints)
	_refresh_coach()
	for c in buttons.get_children():
		c.queue_free()
	var option_index := 0
	var theme_service := load("res://scenes/ui/chrome/date_factory_theme.gd")
	for o in options:
		var b := Button.new()
		b.text = str(o.get("label", o.get("id", "?")))
		b.custom_minimum_size = Vector2(0, 44)
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		# Mouse-only replies: no keyboard/gamepad focus highlight or arrow cycling.
		b.focus_mode = Control.FOCUS_NONE
		b.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		var oid := str(o.get("id", ""))
		b.pressed.connect(func(): _choose_option(b, oid))
		buttons.add_child(b)
		if theme_service:
			theme_service.bind_button(b)
		b.modulate.a = 0.0
		b.position.x = 20.0
		var reveal := create_tween().set_parallel(true)
		reveal.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		reveal.tween_property(b, "modulate:a", 1.0, 0.2).set_delay(option_index * 0.05)
		reveal.tween_property(b, "position:x", 0.0, 0.2).set_delay(option_index * 0.05)
		option_index += 1
	_refresh_action_buttons()


func _configure_panel_layout(panel: Control) -> void:
	panel.clip_contents = false
	panel.anchor_left = 0.18
	panel.anchor_top = 1.0
	panel.anchor_right = 0.82
	panel.anchor_bottom = 1.0
	panel.offset_left = 0.0
	panel.offset_top = -520.0
	panel.offset_right = 0.0
	panel.offset_bottom = -16.0


func _choose_option(button: Button, option_id: String) -> void:
	button.disabled = true
	button.pivot_offset = button.size * 0.5
	var press := create_tween()
	press.tween_property(button, "scale", Vector2(0.98, 0.98), 0.06)
	press.tween_property(button, "scale", Vector2.ONE, 0.08)
	await press.finished
	Game.dating.choose_manual(option_id)


func _pulse_emotion() -> void:
	emotion_label.pivot_offset = emotion_label.size * 0.5
	var pulse := create_tween()
	pulse.tween_property(emotion_label, "scale", Vector2(1.07, 1.07), 0.1)
	pulse.tween_property(emotion_label, "scale", Vector2.ONE, 0.16)


func _spawn_reaction_vfx(emotion: String) -> void:
	var positive := emotion in ["delighted", "happy", "positive", "love", "amused"]
	var glyph := "♥" if positive else "✦"
	var color := Color("#FF83AC") if positive else Color("#E7B562")
	var origin := emotion_label.global_position + emotion_label.size * 0.5
	for i in range(5):
		var particle := Label.new()
		particle.text = glyph
		particle.add_theme_font_size_override("font_size", 22 + i * 2)
		particle.add_theme_color_override("font_color", color)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle.position = origin + Vector2(-30.0 + i * 15.0, 4.0)
		add_child(particle)
		var drift := Vector2(-42.0 + i * 21.0, -62.0 - i * 9.0)
		var fx := create_tween().set_parallel(true)
		fx.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		fx.tween_property(particle, "position", particle.position + drift, 0.65)
		fx.tween_property(particle, "modulate:a", 0.0, 0.65)
		fx.tween_property(particle, "scale", Vector2(1.35, 1.35), 0.65)
		fx.chain().tween_callback(particle.queue_free)
