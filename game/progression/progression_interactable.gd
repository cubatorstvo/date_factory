class_name ProgressionInteractable
extends Interactable
## Apartment self-assessment entry to Progression UI (MODULE 14A / MODULE 22).
## Opens coherent perk tree with optional preselected characteristic tab.

const LAYER_INTERACTABLE: int = 4
const MODAL_SCENE: String = "res://ui/progression/progression_ui.tscn"

@export var prompt_text: String = "Самооценка"
@export var characteristic: GameTypes.PlayerCharacteristic = GameTypes.PlayerCharacteristic.MUSCLE

var _modal: CanvasLayer = null


func _ready() -> void:
	prompt_action = prompt_text
	collision_layer = LAYER_INTERACTABLE
	collision_mask = 0
	monitoring = false
	monitorable = true
	_ensure_collision()


func get_interaction_prompt(player: Node) -> String:
	prompt_action = prompt_text
	return super.get_interaction_prompt(player)


func _on_interact(player: Node) -> void:
	_open_modal(player)


func _ensure_collision() -> void:
	var shape_node: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null:
		return
	shape_node = CollisionShape3D.new()
	shape_node.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(1.0, 1.6, 0.4)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 0.8, 0.0)
	add_child(shape_node)


func _open_modal(player: Node) -> void:
	_close_modal(player)
	var packed: PackedScene = load(MODAL_SCENE) as PackedScene
	if packed == null:
		push_error("[ProgressionInteractable] modal scene missing")
		return
	var layer: CanvasLayer = packed.instantiate() as CanvasLayer
	if layer == null:
		return
	add_child(layer)
	_modal = layer
	if layer.has_method("open"):
		layer.call("open", player, Callable(self, "_on_modal_closed"), characteristic)
	else:
		_enter_modal(player)


func _on_modal_closed(player: Node) -> void:
	_modal = null
	_exit_modal(player)


func _close_modal(player: Node) -> void:
	if _modal != null and is_instance_valid(_modal):
		if _modal.has_method("close"):
			_modal.call("close")
		else:
			_modal.queue_free()
	_modal = null
	_exit_modal(player)


func _enter_modal(player: Node) -> void:
	if player != null and player.has_method("enter_modal_ui"):
		player.call("enter_modal_ui")


func _exit_modal(player: Node) -> void:
	if player != null and player.has_method("enter_gameplay"):
		player.call("enter_gameplay")
