class_name Interactable
extends Area3D
## Base world interactable with focus and interaction feedback.

@export var display_name: String = "Объект"
@export var action_label: String = "Использовать"
@export var action_id: StringName = &""
@export var payload: Dictionary = {}

signal interacted(by: Node)

var _focused: bool = false
var _punch_time: float = 0.0
var _base_scale := Vector3.ONE


func _ready() -> void:
	_base_scale = scale


func _process(delta: float) -> void:
	if _punch_time <= 0.0:
		return
	_punch_time = maxf(_punch_time - delta, 0.0)
	var pulse := 1.0 + sin(_punch_time * PI * 12.0) * 0.12 * (_punch_time / 0.16)
	scale = _base_scale * pulse
	if _punch_time <= 0.0:
		scale = _base_scale


func set_focused(focused: bool) -> void:
	if _focused == focused:
		return
	_focused = focused
	var marker := _find_marker()
	if marker == null:
		return
	marker.scale = Vector3.ONE * (1.45 if focused else 1.0)
	var material := marker.material_override as StandardMaterial3D
	if material:
		material.emission_energy_multiplier = 2.0 if focused else 1.0
		material.albedo_color = Color(1.0, 0.95, 0.35) if focused else Color(1.0, 0.85, 0.2)


func get_prompt() -> String:
	return "%s [%s]" % [display_name, action_label]


func on_interact(by: Node) -> void:
	_punch_time = 0.16
	Sfx.play(&"click")
	interacted.emit(by)
	if action_id != &"":
		InteractionRouter.route(action_id, self, by, payload)


func _find_marker() -> MeshInstance3D:
	for child in get_children():
		if child is MeshInstance3D:
			return child as MeshInstance3D
	return null
