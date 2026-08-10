extends CanvasLayer
class_name ApartmentFridgeMenu
## Food and drink picker opened by the apartment refrigerator.

signal serving_selected(item_id: StringName)
signal closed

const CATALOG_SCRIPT: String = (
	"res://world/locations/apartment/apartment_fridge_catalog.gd"
)

@onready var _root: Control = %Root
@onready var _food_list: VBoxContainer = %FoodList
@onready var _drink_list: VBoxContainer = %DrinkList
@onready var _money_label: Label = %MoneyLabel
@onready var _status_label: Label = %StatusLabel
@onready var _purchase_confirmation: ConfirmationDialog = %PurchaseConfirmation

var _player: Node = null
var _closing: bool = false
var _pending_purchase_id: StringName = &""
var _catalog: GDScript = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 55
	_catalog = load(CATALOG_SCRIPT) as GDScript
	_purchase_confirmation.confirmed.connect(_confirm_purchase)
	%CloseButton.pressed.connect(close)
	var game_state: Node = _game_state()
	if game_state != null and game_state.has_signal("money_changed"):
		game_state.connect("money_changed", _on_money_changed)
	_refresh()


func open(player: Node) -> void:
	_player = player
	UiScaleHelper.apply_to_control(_root)
	_refresh()
	visible = true
	if _player != null and _player.has_method("enter_modal_ui"):
		_player.call("enter_modal_ui")


func close() -> void:
	if _closing:
		return
	_closing = true
	if _purchase_confirmation.visible:
		_purchase_confirmation.hide()
	visible = false
	if _player != null and is_instance_valid(_player) and _player.has_method("enter_gameplay"):
		_player.call("enter_gameplay")
	closed.emit()
	queue_free()


func _refresh() -> void:
	if not is_node_ready() or _catalog == null:
		return
	_rebuild_list(_food_list, &"food")
	_rebuild_list(_drink_list, &"drink")
	_update_money_label()


func _rebuild_list(list: VBoxContainer, category: StringName) -> void:
	for child: Node in list.get_children():
		list.remove_child(child)
		child.queue_free()
	var rows: Array = _catalog.call("get_player_items", _game_state(), category) as Array
	for value: Variant in rows:
		var row: Dictionary = value as Dictionary
		var item_id: StringName = row.get("id", &"")
		var unlocked: bool = bool(row.get("unlocked", false))
		var price: int = int(row.get("price", 0))
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 58.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if unlocked:
			button.text = str(row.get("name", ""))
		else:
			button.text = "%s\n%d ₽" % [str(row.get("name", "")), price]
			button.modulate = Color(0.62, 0.62, 0.62, 1.0)
			button.tooltip_text = "Закрыто — нажмите, чтобы купить"
		button.pressed.connect(_on_item_pressed.bind(item_id))
		list.add_child(button)


func _on_item_pressed(item_id: StringName) -> void:
	if _catalog == null:
		return
	var definition: Dictionary = _catalog.call("get_definition", item_id)
	if definition.is_empty():
		return
	if bool(_catalog.call("is_unlocked", _game_state(), item_id)):
		serving_selected.emit(item_id)
		close()
		return
	_pending_purchase_id = item_id
	var item_name: String = str(definition.get("name", ""))
	var price: int = int(definition.get("price", 0))
	_purchase_confirmation.dialog_text = "Точно купить «%s» за %d ₽?" % [
		item_name,
		price,
	]
	_purchase_confirmation.popup_centered()


func _confirm_purchase() -> void:
	if _catalog == null or _pending_purchase_id == &"":
		return
	var definition: Dictionary = _catalog.call("get_definition", _pending_purchase_id)
	var result: Dictionary = _catalog.call(
		"try_purchase",
		_game_state(),
		_pending_purchase_id
	)
	if bool(result.get("ok", false)):
		_set_status("Куплено: %s" % str(definition.get("name", "")), false)
		_pending_purchase_id = &""
		_refresh()
		return
	if str(result.get("reason", "")) == "money":
		_set_status(
			"Недостаточно денег. Нужно %d ₽." % int(result.get("price", 0)),
			true
		)
	else:
		_set_status("Покупка сейчас недоступна.", true)


func _on_money_changed(_new_value: int, _delta: int) -> void:
	_update_money_label()


func _update_money_label() -> void:
	var game_state: Node = _game_state()
	var money: int = 0
	if game_state != null and game_state.has_method("get_money"):
		money = int(game_state.call("get_money"))
	_money_label.text = "Деньги: %d ₽" % money


func _set_status(message: String, is_error: bool) -> void:
	_status_label.text = message
	_status_label.modulate = (
		Color(1.0, 0.48, 0.42, 1.0)
		if is_error
		else Color(0.58, 0.9, 0.66, 1.0)
	)


func _game_state() -> Node:
	return get_node_or_null("/root/GameState")


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _purchase_confirmation.visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
