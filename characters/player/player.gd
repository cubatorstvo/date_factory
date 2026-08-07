extends CharacterBody3D
## MODULE 01 Player FPS Core: locomotion, look, control modes, pause.
class_name PlayerController

enum ControlMode {
	GAMEPLAY,
	MODAL_UI,
	MINIGAME,
	PAUSED,
}

signal control_mode_changed(mode: ControlMode)
signal interaction_target_changed(target: Area3D)

@export var move_speed: float = 4.5
@export var acceleration: float = 30.0
@export var deceleration: float = 37.5
@export var jump_height: float = 1.0
@export var mouse_sensitivity_degrees: float = 0.12
@export var camera_fov: float = 75.0
@export var interaction_distance: float = 2.5
@export var max_step_height: float = 0.35
@export var max_slope_degrees: float = 45.0
@export var pitch_limit_degrees: float = 89.0

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/Camera
@onready var _interaction: RayCast3D = $CameraPivot/Camera/InteractionQuery
@onready var _hud: CanvasLayer = $FpsHud
@onready var _prompt_label: Label = $FpsHud/PromptLabel
@onready var _crosshair: ColorRect = $FpsHud/Crosshair
@onready var _pause_overlay: Control = $FpsHud/PauseOverlay
@onready var _debug_label: Label = $FpsHud/DebugLabel

var _mode: ControlMode = ControlMode.GAMEPLAY
var _pitch: float = 0.0
var _minigame_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE
var _was_window_focused: bool = true


func _ready() -> void:
	add_to_group("player")
	floor_snap_length = 0.2
	floor_max_angle = deg_to_rad(max_slope_degrees)
	up_direction = Vector3.UP
	_camera.fov = camera_fov
	_camera.current = true
	if _interaction.has_method("setup"):
		_interaction.call("setup", self, interaction_distance)
	if _interaction.has_signal("target_changed"):
		_interaction.connect("target_changed", _on_interaction_target_changed)
	_pause_overlay.visible = false
	_prompt_label.visible = false
	_debug_label.visible = OS.is_debug_build()
	var resume_btn: Button = _pause_overlay.get_node_or_null("Box/ResumeButton") as Button
	if resume_btn != null and not resume_btn.pressed.is_connected(_on_resume_pressed):
		resume_btn.pressed.connect(_on_resume_pressed)
	_apply_mode_side_effects()
	DfLog.info("MODULE_01", "Player ready")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_handle_pause_action()
		get_viewport().set_input_as_handled()
		return
	if _mode != ControlMode.GAMEPLAY:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		var sens: float = deg_to_rad(mouse_sensitivity_degrees)
		rotate_y(-motion.relative.x * sens)
		_pitch = clampf(_pitch - motion.relative.y * sens, -deg_to_rad(pitch_limit_degrees), deg_to_rad(pitch_limit_degrees))
		_camera_pivot.rotation.x = _pitch
	if event.is_action_pressed("interact"):
		if _interaction.has_method("try_interact"):
			_interaction.call("try_interact")
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	_update_focus_safety()
	if _mode != ControlMode.GAMEPLAY:
		velocity = Vector3.ZERO
		return
	var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	if not is_on_floor():
		velocity.y -= gravity * delta
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var wish: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var target_h: Vector3 = wish * move_speed
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var rate: float = acceleration if wish != Vector3.ZERO else deceleration
	horizontal = horizontal.move_toward(target_h, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = sqrt(2.0 * gravity * jump_height)
	_try_step_up()
	move_and_slide()
	_update_debug_label()


func get_control_mode() -> ControlMode:
	return _mode


func set_control_mode(mode: ControlMode) -> void:
	if _mode == mode:
		_apply_mode_side_effects()
		return
	_mode = mode
	_apply_mode_side_effects()
	control_mode_changed.emit(_mode)


func enter_gameplay() -> void:
	set_control_mode(ControlMode.GAMEPLAY)


func enter_modal_ui() -> void:
	set_control_mode(ControlMode.MODAL_UI)


func enter_minigame(mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE) -> void:
	_minigame_mouse_mode = mouse_mode
	set_control_mode(ControlMode.MINIGAME)


func enter_paused() -> void:
	set_control_mode(ControlMode.PAUSED)


func get_camera() -> Camera3D:
	return _camera


func get_interaction_target() -> Area3D:
	if _interaction.has_method("get_current_target"):
		return _interaction.call("get_current_target") as Area3D
	return null


func _handle_pause_action() -> void:
	match _mode:
		ControlMode.GAMEPLAY:
			enter_paused()
		ControlMode.PAUSED:
			enter_gameplay()
		_:
			pass


func _apply_mode_side_effects() -> void:
	var gameplay: bool = _mode == ControlMode.GAMEPLAY
	var paused: bool = _mode == ControlMode.PAUSED
	get_tree().paused = paused
	process_mode = Node.PROCESS_MODE_ALWAYS if paused else Node.PROCESS_MODE_INHERIT
	if _interaction.has_method("set_query_enabled"):
		_interaction.call("set_query_enabled", gameplay)
	_pause_overlay.visible = paused
	_crosshair.visible = gameplay
	if not gameplay:
		_prompt_label.visible = false
	match _mode:
		ControlMode.GAMEPLAY:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		ControlMode.MODAL_UI, ControlMode.PAUSED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		ControlMode.MINIGAME:
			Input.mouse_mode = _minigame_mouse_mode
	_update_debug_label()


func _on_interaction_target_changed(target: Area3D) -> void:
	interaction_target_changed.emit(target)
	if _mode != ControlMode.GAMEPLAY:
		_prompt_label.visible = false
		return
	if target == null:
		_prompt_label.visible = false
		_prompt_label.text = ""
		return
	_prompt_label.text = str(target.call("get_interaction_prompt", self))
	_prompt_label.visible = true


func _update_focus_safety() -> void:
	var focused: bool = DisplayServer.window_is_focused()
	if _was_window_focused and not focused and _mode == ControlMode.GAMEPLAY:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif focused and not _was_window_focused and _mode == ControlMode.GAMEPLAY:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_was_window_focused = focused


func _try_step_up() -> void:
	if not is_on_floor() or velocity.length_squared() < 0.01:
		return
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.length_squared() < 0.0001:
		return
	var dir: Vector3 = horizontal.normalized()
	var from: Vector3 = global_position + Vector3(0.0, 0.05, 0.0)
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var low_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, from + dir * 0.45)
	low_query.collision_mask = collision_mask
	low_query.exclude = [get_rid()]
	var low_hit: Dictionary = space.intersect_ray(low_query)
	if low_hit.is_empty():
		return
	var high_from: Vector3 = global_position + Vector3(0.0, max_step_height, 0.0)
	var high_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(high_from, high_from + dir * 0.45)
	high_query.collision_mask = collision_mask
	high_query.exclude = [get_rid()]
	var high_hit: Dictionary = space.intersect_ray(high_query)
	if not high_hit.is_empty():
		return
	var down_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(high_from + dir * 0.4, high_from + dir * 0.4 + Vector3.DOWN * max_step_height)
	down_query.collision_mask = collision_mask
	down_query.exclude = [get_rid()]
	var down_hit: Dictionary = space.intersect_ray(down_query)
	if down_hit.is_empty():
		return
	var landing: Vector3 = down_hit["position"]
	var lift: float = landing.y - global_position.y
	if lift <= 0.05 or lift > max_step_height:
		return
	global_position.y = landing.y + 0.02


func _update_debug_label() -> void:
	if not _debug_label.visible:
		return
	var target: Area3D = get_interaction_target()
	var target_name: String = "-"
	if target != null:
		target_name = target.name
		if target.has_method("can_interact") and not bool(target.call("can_interact", self)):
			target_name += " (disabled)"
	var mode_name: String = String(ControlMode.find_key(_mode))
	_debug_label.text = "mode=%s target=%s" % [mode_name, target_name]


func _on_resume_pressed() -> void:
	if _mode == ControlMode.PAUSED:
		enter_gameplay()
