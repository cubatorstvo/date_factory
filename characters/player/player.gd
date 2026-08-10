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
signal interaction_succeeded(target: Area3D)

@export var move_speed: float = 4.5
@export var acceleration: float = 30.0
@export var deceleration: float = 37.5
@export var air_acceleration: float = 8.0
@export var jump_height: float = 1.0
@export var mouse_sensitivity_degrees: float = 0.12
@export var camera_fov: float = 75.0
const MOUSE_SENS_MIN: float = 0.04
const MOUSE_SENS_MAX: float = 0.30
const FOV_MIN: float = 60.0
const FOV_MAX: float = 100.0
@export var interaction_distance: float = 2.5
@export var max_step_height: float = 0.35
@export var max_slope_degrees: float = 45.0
@export var pitch_limit_degrees: float = 89.0

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/Camera
@onready var _interaction: RayCast3D = $CameraPivot/Camera/InteractionQuery
var _camera_feedback: CameraFeedback = null
@onready var _hud: CanvasLayer = $FpsHud
@onready var _prompt_label: Label = $FpsHud/PromptLabel
@onready var _crosshair: ColorRect = $FpsHud/Crosshair
@onready var _pause_overlay: Control = $FpsHud/PauseOverlay
@onready var _debug_label: Label = $FpsHud/DebugLabel

var _mode: ControlMode = ControlMode.GAMEPLAY
var _pitch: float = 0.0
var _minigame_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE
var _was_window_focused: bool = true
var _mode_before_pause: ControlMode = ControlMode.GAMEPLAY


func _ready() -> void:
	add_to_group("player")
	floor_snap_length = 0.2
	floor_max_angle = deg_to_rad(max_slope_degrees)
	up_direction = Vector3.UP
	_camera.fov = camera_fov
	_camera.current = true
	_ensure_camera_feedback()
	if _interaction.has_method("setup"):
		_interaction.call("setup", self, interaction_distance)
	if _interaction.has_signal("target_changed"):
		_interaction.connect("target_changed", _on_interaction_target_changed)
	_pause_overlay.visible = false
	_prompt_label.visible = false
	# Production path: never render debug mode/target overlay.
	if _debug_label != null:
		_debug_label.visible = false
		_debug_label.text = ""
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
	if event.is_action_pressed("phone"):
		_open_phone_journal()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		var sens: float = deg_to_rad(mouse_sensitivity_degrees)
		rotate_y(-motion.relative.x * sens)
		_pitch = clampf(_pitch - motion.relative.y * sens, -deg_to_rad(pitch_limit_degrees), deg_to_rad(pitch_limit_degrees))
		_camera_pivot.rotation.x = _pitch
	if event.is_action_pressed("interact"):
		var target: Area3D = get_interaction_target()
		# Emit teaching evidence before Interactable side effects (Neighbor modal, etc.).
		if (
			target != null
			and target.has_method("can_interact")
			and bool(target.call("can_interact", self))
		):
			interaction_succeeded.emit(target)
		if _interaction.has_method("try_interact"):
			_interaction.call("try_interact")
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	_update_focus_safety()
	if _mode != ControlMode.GAMEPLAY:
		velocity = Vector3.ZERO
		return
	var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	var on_floor: bool = is_on_floor()
	if not on_floor:
		velocity.y -= gravity * delta
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var wish: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var target_h: Vector3 = wish * move_speed
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var rate: float = 0.0
	if on_floor:
		rate = acceleration if wish != Vector3.ZERO else deceleration
	elif wish != Vector3.ZERO:
		rate = air_acceleration
		# No artificial air braking when input is released.
	if rate > 0.0:
		horizontal = horizontal.move_toward(target_h, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if Input.is_action_just_pressed("jump") and on_floor:
		velocity.y = sqrt(2.0 * gravity * jump_height)
	_try_step_up()
	move_and_slide()
	_hide_debug_overlay()


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


func get_camera_feedback() -> CameraFeedback:
	return _camera_feedback


func get_interaction_target() -> Area3D:
	if _interaction.has_method("get_current_target"):
		return _interaction.call("get_current_target") as Area3D
	return null


func get_pose_dict() -> Dictionary:
	var pos: Vector3 = global_position
	return {
		"position": [pos.x, pos.y, pos.z],
		"yaw": rotation.y,
		"pitch": _pitch,
	}


func apply_pose_dict(pose: Dictionary) -> bool:
	if pose.is_empty():
		return false
	var pos_v: Variant = pose.get("position", null)
	var parsed: Vector3 = _parse_pose_position(pos_v)
	if not is_finite(parsed.x) or not is_finite(parsed.y) or not is_finite(parsed.z):
		return false
	var yaw: float = float(pose.get("yaw", 0.0))
	var pitch: float = float(pose.get("pitch", 0.0))
	if not is_finite(yaw) or not is_finite(pitch):
		return false
	pitch = clampf(pitch, -deg_to_rad(pitch_limit_degrees), deg_to_rad(pitch_limit_degrees))
	velocity = Vector3.ZERO
	global_transform = Transform3D(Basis.from_euler(Vector3(0.0, yaw, 0.0)), parsed)
	_pitch = pitch
	if _camera_pivot != null:
		_camera_pivot.rotation.x = _pitch
	enter_gameplay()
	return true


func get_camera_fov() -> float:
	return camera_fov


func set_camera_fov(value: float) -> void:
	camera_fov = clampf(value, FOV_MIN, FOV_MAX)
	if _camera != null:
		_camera.fov = camera_fov
	_ensure_camera_feedback()
	if _camera_feedback != null:
		_camera_feedback.set_baseline_fov(camera_fov)


func get_mouse_sensitivity_degrees() -> float:
	return mouse_sensitivity_degrees


func set_mouse_sensitivity_degrees(value: float) -> void:
	mouse_sensitivity_degrees = clampf(value, MOUSE_SENS_MIN, MOUSE_SENS_MAX)


func _parse_pose_position(pos_v: Variant) -> Vector3:
	if pos_v is Vector3:
		return pos_v as Vector3
	if pos_v is Array:
		var arr: Array = pos_v as Array
		if arr.size() < 3:
			return Vector3(NAN, NAN, NAN)
		return Vector3(float(arr[0]), float(arr[1]), float(arr[2]))
	if pos_v is PackedFloat32Array:
		var pf32: PackedFloat32Array = pos_v as PackedFloat32Array
		if pf32.size() < 3:
			return Vector3(NAN, NAN, NAN)
		return Vector3(pf32[0], pf32[1], pf32[2])
	if pos_v is PackedFloat64Array:
		var pf64: PackedFloat64Array = pos_v as PackedFloat64Array
		if pf64.size() < 3:
			return Vector3(NAN, NAN, NAN)
		return Vector3(float(pf64[0]), float(pf64[1]), float(pf64[2]))
	return Vector3(NAN, NAN, NAN)


func _open_phone_journal() -> void:
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_method("open_phone_journal"):
		world.call("open_phone_journal", self)
		return
	var phone: Node = get_tree().get_first_node_in_group("phone_journal") if get_tree() != null else null
	if phone != null and phone.has_method("open"):
		phone.call("open", self)


func _handle_pause_action() -> void:
	var pause_menu: Node = get_tree().get_first_node_in_group("pause_menu") if get_tree() != null else null
	if pause_menu != null and pause_menu.has_method("handle_pause_action"):
		if bool(pause_menu.call("handle_pause_action")):
			return
	match _mode:
		ControlMode.GAMEPLAY, ControlMode.MINIGAME:
			_mode_before_pause = _mode
			enter_paused()
			_ensure_pause_menu_open()
		ControlMode.PAUSED:
			set_control_mode(_mode_before_pause)
		_:
			pass


func _apply_mode_side_effects() -> void:
	var gameplay: bool = _mode == ControlMode.GAMEPLAY
	var paused: bool = _mode == ControlMode.PAUSED
	get_tree().paused = paused
	process_mode = Node.PROCESS_MODE_ALWAYS if paused else Node.PROCESS_MODE_INHERIT
	if _interaction.has_method("set_query_enabled"):
		_interaction.call("set_query_enabled", gameplay)
	# MODULE24: PauseMenu owns pause UI; keep prototype overlay hidden.
	_pause_overlay.visible = false
	# MODULE 22: GameHUD owns the gameplay crosshair; FpsHud keeps interaction prompt only.
	_crosshair.visible = false
	if not gameplay:
		_prompt_label.visible = false
	match _mode:
		ControlMode.GAMEPLAY:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		ControlMode.MODAL_UI, ControlMode.PAUSED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		ControlMode.MINIGAME:
			Input.mouse_mode = _minigame_mouse_mode
	_hide_debug_overlay()


func _on_interaction_target_changed(target: Area3D) -> void:
	interaction_target_changed.emit(target)
	if _mode != ControlMode.GAMEPLAY:
		_prompt_label.visible = false
		return
	if target == null:
		_prompt_label.visible = false
		_prompt_label.text = ""
		return
	var raw_prompt: String = str(target.call("get_interaction_prompt", self))
	_prompt_label.text = _format_player_prompt(raw_prompt, target)
	_prompt_label.visible = _prompt_label.text.strip_edges() != ""


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
	# Ensure full capsule can occupy the stepped pose before teleporting Y.
	var target: Vector3 = Vector3(
		global_position.x + dir.x * 0.2,
		landing.y + 0.02,
		global_position.z + dir.z * 0.2
	)
	var motion: Vector3 = target - global_position
	if test_move(global_transform, motion):
		return
	global_position = target


func _hide_debug_overlay() -> void:
	if _debug_label == null:
		return
	_debug_label.visible = false
	_debug_label.text = ""


func _format_player_prompt(raw_prompt: String, target: Area3D) -> String:
	var action: String = raw_prompt.strip_edges()
	if action.is_empty():
		return ""
	if action.begins_with("[E]"):
		action = action.substr(3).strip_edges()
	elif action.begins_with("E —"):
		action = action.substr(3).strip_edges()
	elif action.begins_with("E -"):
		action = action.substr(3).strip_edges()
	action = action.strip_edges()
	if action.is_empty() or _looks_like_internal_id(action, target):
		action = "Взаимодействовать"
	return "E — %s" % action


func _looks_like_internal_id(action: String, target: Area3D) -> bool:
	if target != null and action == String(target.name):
		return true
	if action.contains("="):
		return true
	if action.begins_with("mode=") or action.begins_with("target="):
		return true
	# Camel/Pascal node-style ids without spaces (FlavorFridge, ToCity).
	if not action.contains(" ") and not action.contains("—") and not action.contains("-"):
		if action.length() >= 3 and action.findn("_") < 0:
			var has_lower: bool = false
			var has_upper: bool = false
			for i in range(action.length()):
				var ch: String = action.substr(i, 1)
				if ch >= "a" and ch <= "z":
					has_lower = true
				elif ch >= "A" and ch <= "Z":
					has_upper = true
			if has_lower and has_upper:
				return true
	return false


func _on_resume_pressed() -> void:
	if _mode == ControlMode.PAUSED:
		set_control_mode(_mode_before_pause)


func _ensure_pause_menu_open() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var pause_menu: Node = tree.get_first_node_in_group("pause_menu")
	if pause_menu == null:
		var packed: PackedScene = load("res://ui/frontend/pause_menu.tscn") as PackedScene
		if packed != null:
			pause_menu = packed.instantiate()
			tree.root.add_child(pause_menu)
	if pause_menu != null and pause_menu.has_method("open_from_pause"):
		pause_menu.call("open_from_pause")


func _ensure_camera_feedback() -> void:
	if _camera == null:
		_camera_feedback = null
		return
	_camera_feedback = _camera.get_node_or_null("CameraFeedback") as CameraFeedback
	if _camera_feedback != null:
		_camera_feedback.bind_camera(_camera)
		return
	_camera_feedback = CameraFeedback.new()
	_camera_feedback.name = "CameraFeedback"
	_camera.add_child(_camera_feedback)
	_camera_feedback.bind_camera(_camera)
