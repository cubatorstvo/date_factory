extends Node3D
## MODULE 01 smoke interactables for player_fps_test.

@onready var _use: Area3D = $UseTarget
@onready var _disabled: Area3D = $DisabledTarget
@onready var _modal: Area3D = $ModalTarget
@onready var _modal_panel: Control = $ModalLayer/ModalPanel
@onready var _modal_label: Label = $ModalLayer/ModalPanel/VBox/Label

var _player: CharacterBody3D


func _ready() -> void:
	_modal_panel.visible = false
	_use.set("prompt_action", "Использовать")
	_disabled.set("prompt_action", "Недоступно")
	_disabled.set("interaction_enabled", false)
	_modal.set("prompt_action", "Открыть тест UI")
	if _use.has_signal("interacted"):
		_use.connect("interacted", _on_use)
	if _modal.has_signal("interacted"):
		_modal.connect("interacted", _on_modal)
	var close_btn: Button = _modal_panel.find_child("CloseButton", true, false) as Button
	if close_btn != null:
		close_btn.pressed.connect(_close_modal)


func _on_use(_by: Node) -> void:
	DfLog.info("MODULE_01", "UseTarget interacted")


func _on_modal(by: Node) -> void:
	_player = by as CharacterBody3D
	if _player == null:
		return
	_modal_panel.visible = true
	_modal_label.text = "Test MODAL_UI\nClose to return to GAMEPLAY."
	if _player.has_method("enter_modal_ui"):
		_player.call("enter_modal_ui")


func _close_modal() -> void:
	_modal_panel.visible = false
	if _player != null and _player.has_method("enter_gameplay"):
		_player.call("enter_gameplay")
