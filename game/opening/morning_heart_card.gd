class_name MorningHeartCard
extends Interactable
## One-shot physical card pickup that unlocks the Hearts HUD row.

const READ_POSITION: Vector3 = Vector3(0.24, -0.20, -0.58)
const READ_ROTATION_DEGREES: Vector3 = Vector3(-58.0, 0.0, -8.0)

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
	var fly_from: Vector2 = _card_screen_position(camera)
	_card.visible = false
	var hud: GameHUD = _find_hud()
	if hud != null:
		await hud.play_heart_card_fly(fly_from)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		gs.call("set_story_flag", StoryIds.FLAG_HEART_CARD_CLAIMED, true)
	_card.queue_free()
	visible = false
	controller.enter_gameplay()


func _find_hud() -> GameHUD:
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_method("get_game_hud"):
		return world.call("get_game_hud") as GameHUD
	return null


func _card_screen_position(camera: Camera3D) -> Vector2:
	if camera == null or _card == null:
		return get_viewport().get_visible_rect().size * 0.5
	return camera.unproject_position(_card.global_position)


func _sync_from_state() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	var claimed: bool = false
	if gs != null:
		claimed = bool(gs.call("get_story_flag", StoryIds.FLAG_HEART_CARD_CLAIMED))
	visible = not claimed
	interaction_enabled = not claimed
	_collision.disabled = claimed
