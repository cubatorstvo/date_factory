extends CanvasLayer
class_name ApartmentFridgeMenu
## Free meal picker opened by the apartment refrigerator.

signal dish_selected(dish_id: StringName)
signal closed

@onready var _root: Control = %Root
var _player: Node = null
var _closing: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 55
	%PizzaButton.pressed.connect(_select_dish.bind(&"pizza"))
	%BurgerButton.pressed.connect(_select_dish.bind(&"burger"))
	%PancakesButton.pressed.connect(_select_dish.bind(&"pancakes"))
	%SteakButton.pressed.connect(_select_dish.bind(&"steak"))
	%CloseButton.pressed.connect(close)


func open(player: Node) -> void:
	_player = player
	UiScaleHelper.apply_to_control(_root)
	visible = true
	if _player != null and _player.has_method("enter_modal_ui"):
		_player.call("enter_modal_ui")


func close() -> void:
	if _closing:
		return
	_closing = true
	visible = false
	if _player != null and is_instance_valid(_player) and _player.has_method("enter_gameplay"):
		_player.call("enter_gameplay")
	closed.emit()
	queue_free()


func _select_dish(dish_id: StringName) -> void:
	dish_selected.emit(dish_id)
	close()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
