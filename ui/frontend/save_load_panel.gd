extends CanvasLayer
## Save / Load slot panel — MODULE24 §§56–58.
class_name SaveLoadPanel

enum Mode { SAVE, LOAD }

signal closed
signal action_finished(ok: bool)

const SAVE_SLOT_CARD_SCENE: String = "res://ui/common/save_slot_card.tscn"

var _mode: Mode = Mode.LOAD
var _on_closed: Callable = Callable()
@onready var _root: Control = %Root
@onready var _title_label: Label = %TitleLabel
@onready var _status_label: Label = %StatusLabel
@onready var _confirm_dialog: ConfirmationDialogView = %ConfirmationDialog
@onready var _cards_host: VBoxContainer = %CardsHost


func _ready() -> void:
	UiScaleHelper.apply_to_control(_root)
	%BackButton.pressed.connect(func() -> void:
		_audio_ui(AudioIds.UI_BACK)
		close()
	)


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
	_title_label.text = "СОХРАНИТЬ" if _mode == Mode.SAVE else "ЗАГРУЗИТЬ"
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
		if _confirm_dialog.visible:
			_hide_confirm()
		else:
			_audio_ui(AudioIds.UI_BACK)
			close()
		get_viewport().set_input_as_handled()


func _refresh_cards() -> void:
	if _cards_host == null:
		return
	for child in _cards_host.get_children():
		child.queue_free()
	var slots: Array[SaveTypes.Slot] = (
		FrontendSaveApi.MANUAL_SLOTS if _mode == Mode.SAVE else FrontendSaveApi.LOAD_SLOTS
	)
	for slot in slots:
		var card: SaveSlotCard = _make_card(slot)
		if card != null:
			_cards_host.add_child(card)


func _make_card(slot: SaveTypes.Slot) -> SaveSlotCard:
	var meta: SaveSlotMetadata = FrontendSaveApi.get_slot_metadata(slot)
	var packed: PackedScene = load(SAVE_SLOT_CARD_SCENE) as PackedScene
	if packed == null:
		return null
	var card: SaveSlotCard = packed.instantiate() as SaveSlotCard
	if card == null:
		return null
	var exists_valid: bool = meta != null and meta.exists and meta.valid
	card.configure(
		FrontendSaveApi.slot_title(slot),
		FrontendSaveApi.format_metadata_card(meta),
		_mode == Mode.SAVE,
		meta != null and meta.valid,
		meta != null and meta.exists
	)
	var bound_slot: SaveTypes.Slot = slot
	card.save_pressed.connect(func() -> void:
		_on_save_pressed(bound_slot, exists_valid)
	)
	card.load_pressed.connect(func() -> void:
		_on_load_pressed(bound_slot)
	)
	card.delete_pressed.connect(func() -> void:
		_confirm(
			"Удалить сохранение?",
			func() -> void:
				var ok: bool = FrontendSaveApi.delete_slot(bound_slot)
				_status_label.text = "Удалено" if ok else "Не удалось удалить"
				_refresh_cards()
				_audio_ui(AudioIds.UI_CLICK if ok else AudioIds.UI_DENIED)
		)
	)
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
	_confirm_dialog.open(message, on_yes)


func _hide_confirm() -> void:
	_confirm_dialog.close()


func _audio_ui(sound_id: StringName) -> void:
	var audio: Node = get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_ui"):
		audio.call("play_ui", sound_id)
