class_name MorningHeartCard
extends Interactable
## One-shot physical card pickup that unlocks the Hearts HUD row.

const READ_POSITION: Vector3 = Vector3(0.24, -0.20, -0.58)
const READ_ROTATION_DEGREES: Vector3 = Vector3(-58.0, 0.0, -8.0)
const HUD_POSITION: Vector3 = Vector3(-0.58, 0.34, -0.68)
const HUD_ROTATION_DEGREES: Vector3 = Vector3(-64.0, 0.0, -12.0)

@onready var _card: Node3D = $HeartCard
@onready var _collision: CollisionShape3D = $Collision

var _claiming: bool = false


func _ready() -> void:
	prompt_action = "Поднять карточку"
	monitoring = false
	monitorable = true
	_sync_from_state()


func can_interact(player: Node) -> bool:
	return not _claiming and visible and super.can_interact(player)


func _on_interact(player: Node) -> void:
	if _claiming or not (player is PlayerController):
		return
	var controller: PlayerController = player as PlayerController
	var camera: Camera3D = controller.get_camera()
	if camera == null:
		return
	_claiming = true
	interaction_enabled = false
	_collision.disabled = true
	controller.enter_modal_ui()
	_card.reparent(camera, true)
	var read_tween: Tween = create_tween()
	read_tween.set_parallel(true)
	read_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	read_tween.tween_property(_card, "position", READ_POSITION, 0.55)
	read_tween.tween_property(
		_card,
		"rotation_degrees",
		READ_ROTATION_DEGREES,
		0.55
	)
	await read_tween.finished
	await get_tree().create_timer(1.15).timeout
	var hud_tween: Tween = create_tween()
	hud_tween.set_parallel(true)
	hud_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	hud_tween.tween_property(_card, "position", HUD_POSITION, 0.65)
	hud_tween.tween_property(
		_card,
		"rotation_degrees",
		HUD_ROTATION_DEGREES,
		0.65
	)
	hud_tween.tween_property(_card, "scale", Vector3.ONE * 0.16, 0.65)
	await hud_tween.finished
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		gs.call("set_story_flag", StoryIds.FLAG_HEART_CARD_CLAIMED, true)
	_card.queue_free()
	visible = false
	controller.enter_gameplay()


func _sync_from_state() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	var claimed: bool = false
	if gs != null:
		claimed = bool(gs.call("get_story_flag", StoryIds.FLAG_HEART_CARD_CLAIMED))
	visible = not claimed
	interaction_enabled = not claimed
	_collision.disabled = claimed
