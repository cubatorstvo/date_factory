class_name GameActionButton
extends VBoxContainer

signal action_resolved(result: ActionResult)

var _action: GameAction
var _label_text: String = ""
var _show_title: bool = true
var _show_meta: bool = true
var _title: Label
var _meta: Label
var _button: Button


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	_title = Label.new()
	_title.add_theme_color_override("font_color", LabUi.TEXT)
	add_child(_title)
	_meta = Label.new()
	_meta.add_theme_color_override("font_color", LabUi.MUTED)
	add_child(_meta)
	_button = LabUi.button("")
	_button.pressed.connect(_on_pressed)
	add_child(_button)
	_apply_label()
	_refresh_view()


func setup(action: GameAction, label: String = "", show_title: bool = true, show_meta: bool = true) -> void:
	_action = action
	_label_text = label
	_show_title = show_title
	_show_meta = show_meta
	if is_node_ready():
		_apply_label()
		_refresh_view()


func _apply_label() -> void:
	if _title == null or _button == null:
		return
	var resolved: String = _label_text
	if resolved.is_empty() and _action != null:
		resolved = GameActionLabels.for_id(_action.id)
	_title.text = resolved
	_title.visible = _show_title
	_button.text = resolved


func refresh() -> void:
	_refresh_view()


func get_action() -> GameAction:
	return _action


func _refresh_view() -> void:
	if _meta == null or _button == null:
		return
	if _action == null:
		_meta.text = ""
		_meta.visible = false
		_button.disabled = true
		_button.tooltip_text = "Действие не задано"
		return
	_meta.visible = _show_meta
	if _show_meta:
		_meta.text = "Деньги: %d\nВремя: %d мин." % [_action.money_cost, _action.time_cost_minutes]
	else:
		_meta.text = ""
	var actions: Variant = _action_service()
	if actions == null:
		_button.disabled = true
		_button.tooltip_text = "ActionService autoload missing"
		return
	var can_run: bool = bool(actions.can_execute(_action))
	_button.disabled = not can_run
	if can_run:
		_button.tooltip_text = ""
	else:
		_button.tooltip_text = str(actions.get_failure_reason(_action))


func _on_pressed() -> void:
	var actions: Variant = _action_service()
	if actions == null or _action == null:
		return
	var result: ActionResult = actions.execute(_action)
	action_resolved.emit(result)


func _action_service() -> Variant:
	var node: Node = get_node_or_null("/root/ActionService")
	if not is_instance_valid(node):
		return null
	return node
