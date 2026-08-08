extends CanvasLayer
## Save / Load slot panel — MODULE24 §§56–58.
class_name SaveLoadPanel

enum Mode { SAVE, LOAD }

signal closed
signal action_finished(ok: bool)

const THEME_PATH: String = "res://ui/theme/date_factory_theme.tres"
const BODY_FONT_SIZE: int = 18
const TITLE_FONT_SIZE: int = 26

var _mode: Mode = Mode.LOAD
var _on_closed: Callable = Callable()
var _root: Control = null
var _status_label: Label = null
var _confirm_host: Control = null
var _cards_host: VBoxContainer = null


func open_save(on_closed: Callable = Callable()) -> void:
	_mode = Mode.SAVE
	_open(on_closed)


func open_load(on_closed: Callable = Callable()) -> void:
	_mode = Mode.LOAD
	_open(on_closed)


func _open(on_closed: Callable) -> void:
	_on_closed = on_closed
	layer = 54
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_refresh_cards()
	visible = true


func close() -> void:
	visible = false
	var cb: Callable = _on_closed
	_on_closed = Callable()
	closed.emit()
	if cb.is_valid():
		cb.call()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		if _confirm_host != null and _confirm_host.visible:
			_hide_confirm()
		else:
			_audio_ui(AudioIds.UI_BACK)
			close()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_apply_theme(_root)
	UiScaleHelper.apply_to_control(_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.04, 0.05, 0.07, 0.78)
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 560)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "СОХРАНИТЬ" if _mode == Mode.SAVE else "ЗАГРУЗИТЬ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	vbox.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	_cards_host = VBoxContainer.new()
	_cards_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_host.add_theme_constant_override("separation", 10)
	scroll.add_child(_cards_host)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	vbox.add_child(_status_label)

	var back := Button.new()
	back.text = "Назад"
	back.pressed.connect(func() -> void:
		_audio_ui(AudioIds.UI_BACK)
		close()
	)
	vbox.add_child(back)

	_confirm_host = Control.new()
	_confirm_host.visible = false
	_confirm_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_confirm_host)


func _refresh_cards() -> void:
	if _cards_host == null:
		return
	for child in _cards_host.get_children():
		child.queue_free()
	var slots: Array[SaveTypes.Slot] = (
		FrontendSaveApi.MANUAL_SLOTS if _mode == Mode.SAVE else FrontendSaveApi.LOAD_SLOTS
	)
	for slot in slots:
		_cards_host.add_child(_make_card(slot))


func _make_card(slot: SaveTypes.Slot) -> PanelContainer:
	var meta: SaveSlotMetadata = FrontendSaveApi.get_slot_metadata(slot)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(500, 0)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_box)
	var title := Label.new()
	title.text = FrontendSaveApi.slot_title(slot)
	title.add_theme_font_size_override("font_size", 20)
	text_box.add_child(title)
	var body := Label.new()
	body.text = FrontendSaveApi.format_metadata_card(meta)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	text_box.add_child(body)

	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	row.add_child(actions)

	if _mode == Mode.SAVE:
		var save_btn := Button.new()
		save_btn.text = "Сохранить"
		var bound_slot: SaveTypes.Slot = slot
		var exists_valid: bool = meta != null and meta.exists and meta.valid
		save_btn.pressed.connect(func() -> void:
			_on_save_pressed(bound_slot, exists_valid)
		)
		actions.add_child(save_btn)
	else:
		var load_btn := Button.new()
		load_btn.text = "Загрузить"
		var can_load: bool = meta != null and meta.valid
		load_btn.disabled = not can_load
		var bound_slot2: SaveTypes.Slot = slot
		load_btn.pressed.connect(func() -> void:
			_on_load_pressed(bound_slot2)
		)
		actions.add_child(load_btn)

	if meta != null and meta.exists:
		var del_btn := Button.new()
		del_btn.text = "Удалить"
		var bound_slot3: SaveTypes.Slot = slot
		del_btn.pressed.connect(func() -> void:
			_confirm(
				"Удалить сохранение?",
				func() -> void:
					var ok: bool = FrontendSaveApi.delete_slot(bound_slot3)
					_status_label.text = "Удалено" if ok else "Не удалось удалить"
					_refresh_cards()
					_audio_ui(AudioIds.UI_CLICK if ok else AudioIds.UI_DENIED)
			)
		)
		actions.add_child(del_btn)
	return card


func _on_save_pressed(slot: SaveTypes.Slot, overwrite: bool) -> void:
	if overwrite:
		_confirm(
			"Перезаписать сохранение?",
			func() -> void:
				_do_save(slot)
		)
	else:
		_do_save(slot)


func _do_save(slot: SaveTypes.Slot) -> void:
	var ok: bool = FrontendSaveApi.save_slot(slot)
	if ok:
		_status_label.text = "ИГРА СОХРАНЕНА"
		_audio_ui(AudioIds.UI_CLICK)
	else:
		_status_label.text = "Не удалось сохранить игру."
		_audio_ui(AudioIds.UI_DENIED)
	_refresh_cards()
	action_finished.emit(ok)


func _on_load_pressed(slot: SaveTypes.Slot) -> void:
	var gameplay_active: bool = _is_gameplay_active()
	if gameplay_active:
		_confirm(
			"Загрузить сохранение?\nНесохранённый прогресс будет потерян.",
			func() -> void:
				_do_load(slot)
		)
	else:
		_do_load(slot)


func _do_load(slot: SaveTypes.Slot) -> void:
	var ok: bool = FrontendSaveApi.load_slot(slot)
	if ok:
		_status_label.text = "Загрузка выполнена"
		_audio_ui(AudioIds.UI_CLICK)
		action_finished.emit(true)
		close()
	else:
		_status_label.text = "Не удалось загрузить сохранение."
		_audio_ui(AudioIds.UI_DENIED)
		action_finished.emit(false)


func _is_gameplay_active() -> bool:
	var world: Node = get_node_or_null("/root/World")
	if world == null:
		return false
	if world.has_method("get_current_location"):
		return world.call("get_current_location") != null
	return false


func _confirm(message: String, on_yes: Callable) -> void:
	_hide_confirm()
	_confirm_host.visible = true
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	_confirm_host.add_child(dim)
	var confirm_center := CenterContainer.new()
	confirm_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_host.add_child(confirm_center)
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(420, 160)
	confirm_center.add_child(box)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	box.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	var lab := Label.new()
	lab.text = message
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lab)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)
	var yes := Button.new()
	yes.text = "Да"
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect(func() -> void:
		_hide_confirm()
		if on_yes.is_valid():
			on_yes.call()
	)
	row.add_child(yes)
	var no := Button.new()
	no.text = "Нет"
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(_hide_confirm)
	row.add_child(no)


func _hide_confirm() -> void:
	if _confirm_host == null:
		return
	for child in _confirm_host.get_children():
		child.queue_free()
	_confirm_host.visible = false


func _apply_theme(control: Control) -> void:
	if ResourceLoader.exists(THEME_PATH):
		var theme_res: Resource = load(THEME_PATH)
		if theme_res is Theme:
			control.theme = theme_res as Theme


func _audio_ui(sound_id: StringName) -> void:
	var audio: Node = get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_ui"):
		audio.call("play_ui", sound_id)
