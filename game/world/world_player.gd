class_name WorldPlayer
extends CharacterBody3D

const SPEED: float = 6.0
const MOUSE_SENSITIVITY: float = 0.002

var _yaw: float = 0.0
var _pitch: float = 0.0
var _camera: Camera3D


func _ready() -> void:
	add_to_group("world_player")
	_camera = get_node_or_null("Camera3D") as Camera3D


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseMotion):
		return
	var motion: InputEventMouseMotion = event
	_yaw -= motion.relative.x * MOUSE_SENSITIVITY
	_pitch = clampf(_pitch - motion.relative.y * MOUSE_SENSITIVITY, -1.2, 1.2)
	rotation.y = _yaw
	if _camera != null:
		_camera.rotation.x = _pitch


func _physics_process(_delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1.0
	var direction := Vector3(input_dir.x, 0.0, input_dir.y).normalized()
	direction = global_transform.basis * direction
	direction.y = 0.0
	if direction.length() > 0.0:
		direction = direction.normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	if not is_on_floor():
		velocity.y -= 20.0 * _delta
	else:
		velocity.y = 0.0
	move_and_slide()
