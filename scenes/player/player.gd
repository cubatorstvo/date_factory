extends CharacterBody3D
## First-person controller with interaction ray, carry, and responsive movement feel.

const UiEscapeScript := preload("res://core/ui_escape.gd")

@export var move_speed: float = 5.0
@export var mouse_sens: float = 0.0025
@export var gravity: float = 20.0
@export var acceleration: float = 14.0
@export var deceleration: float = 18.0
@export var sprint_multiplier: float = 1.45
@export var sprint_fov_punch: float = 8.0
@export var head_bob: bool = true
@export var head_bob_intensity: float = 0.045
@export var head_bob_frequency: float = 10.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/RayCast3D
@onready var carry_anchor: Node3D = $Head/CarryAnchor

var _pitch: float = 0.0
var _focus: Interactable = null
var _phone_open: bool = false
var _date_lock: bool = false
var _camera_base_position: Vector3 = Vector3.ZERO
var _carry_base_position: Vector3 = Vector3.ZERO
var _base_fov: float = 75.0
var _bob_time: float = 0.0
var _land_bob: float = 0.0
var _shake: float = 0.0
var _footstep_time: float = 0.0
var _was_on_floor: bool = false


func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	EventBus.notify.connect(_on_notify)
	Game.dating.date_ui_open.connect(_on_date_open)
	Game.dating.date_ui_close.connect(_on_date_close)
	_camera_base_position = camera.position
	_carry_base_position = carry_anchor.position
	_base_fov = camera.fov
	_read_settings()
	# Origin at feet (capsule center is +0.9); slight lift avoids floor embed.
	global_position = Vector3(0, 0.05, 2.5)


func _on_date_open(_p: Dictionary) -> void:
	_date_lock = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_date_close() -> void:
	_date_lock = false
	if not _phone_open:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _force_free_controls() -> void:
	## Dismiss overlays only — never teleport / never open pause.
	UiEscapeScript.dismiss_overlays(get_tree())
	_phone_open = false
	_date_lock = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_notify(message: String, kind: StringName) -> void:
	if kind == &"ui" and message == "PHONE_TOGGLE":
		_toggle_phone()


func _toggle_phone() -> void:
	if _date_lock:
		return
	_phone_open = not _phone_open
	var ui := get_tree().get_first_node_in_group("phone_ui")
	if ui and ui.has_method("set_open"):
		ui.set_open(_phone_open)
	if _phone_open:
		Game.quests.on_phone_opened()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _phone_open else Input.MOUSE_MODE_CAPTURED


func _can_look() -> bool:
	return (not _date_lock) and (not _phone_open) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


func _apply_look(event: InputEventMouseMotion) -> void:
	if head == null:
		return
	rotate_y(-event.relative.x * mouse_sens)
	var y_sign := -1.0 if _invert_y_enabled() else 1.0
	_pitch = clampf(_pitch + event.relative.y * mouse_sens * y_sign, deg_to_rad(-85), deg_to_rad(85))
	head.rotation.x = _pitch


func _input(event: InputEvent) -> void:
	# Look must run in _input so fullscreen HUD/crosshair cannot eat motion.
	if event is InputEventMouseMotion and _can_look():
		_apply_look(event)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if (not _phone_open) and (not _date_lock) and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	# Esc is owned by PauseMenu (close overlays first, then pause).
	# Player only handles gameplay actions here.
	if event.is_action_pressed("ui_cancel"):
		return
	if _date_lock:
		return
	if event.is_action_pressed("phone"):
		_toggle_phone()
		get_viewport().set_input_as_handled()
		return
	if _phone_open:
		return
	if event.is_action_pressed("interact"):
		_try_interact()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return
	_sync_overlay_state()
	_read_settings()

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if _date_lock:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		_update_camera_feel(delta, false)
		return

	var input := _move_vector()
	var speed: float = move_speed * (1.0 + float(Game.upgrades.effect_value("move_speed")))
	var sprinting := Input.is_key_pressed(KEY_SHIFT) and input.length_squared() > 0.01 and not _phone_open
	if sprinting:
		speed *= sprint_multiplier
	if _phone_open:
		# Phone open: still allow slow strafe so player never feels physically stuck.
		speed *= 0.35
	var direction := transform.basis * Vector3(input.x, 0, input.y)
	if direction.length_squared() > 0.0001:
		direction = direction.normalized()
	var blend := 1.0 - exp(-delta * (acceleration if direction.length_squared() > 0.0 else deceleration))
	velocity.x = lerpf(velocity.x, direction.x * speed, blend)
	velocity.z = lerpf(velocity.z, direction.z * speed, blend)
	move_and_slide()

	if is_on_floor() and not _was_on_floor:
		_land_bob = 0.075
	_was_on_floor = is_on_floor()
	var moving := Vector2(velocity.x, velocity.z).length_squared() > 0.08 and is_on_floor()
	_update_camera_feel(delta, moving, sprinting)
	_update_footsteps(delta, moving)
	_update_focus()
	_update_carry_visual()


func _move_vector() -> Vector2:
	# Prefer InputMap; fall back to physical WASD if map is empty/broken.
	var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if v.length_squared() > 0.0:
		return v
	var x := 0.0
	var y := 0.0
	if Input.is_physical_key_pressed(KEY_A):
		x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		y += 1.0
	return Vector2(x, y)


func _read_settings() -> void:
	var settings := get_node_or_null("/root/SettingsService")
	if settings == null:
		return
	var sensitivity: Variant = settings.get("mouse_sens")
	var fov_value: Variant = settings.get("fov")
	var bob_enabled: Variant = settings.get("head_bob")
	if sensitivity != null:
		mouse_sens = 0.0025 * float(sensitivity)
	if fov_value != null:
		_base_fov = float(fov_value)
	if bob_enabled != null:
		head_bob = bool(bob_enabled)


func _invert_y_enabled() -> bool:
	var settings := get_node_or_null("/root/SettingsService")
	if settings == null:
		return false
	var value: Variant = settings.get("invert_y")
	return bool(value) if value != null else false


func _camera_shake_strength() -> float:
	var settings := get_node_or_null("/root/SettingsService")
	if settings == null:
		return 1.0
	var value: Variant = settings.get("camera_shake")
	return clampf(float(value), 0.0, 1.0) if value != null else 1.0


func _motion_effects_enabled() -> bool:
	var settings := get_node_or_null("/root/SettingsService")
	if settings == null:
		return true
	var value: Variant = settings.get("motion_effects")
	return bool(value) if value != null else true


func _camera_shake_enabled() -> bool:
	return _motion_effects_enabled() and _camera_shake_strength() > 0.01


func add_shake(amount: float) -> void:
	if not _date_lock and _camera_shake_enabled():
		_shake = maxf(_shake, amount * _camera_shake_strength())


func _update_camera_feel(delta: float, moving: bool, sprinting: bool = false) -> void:
	if camera == null or not is_instance_valid(camera):
		return
	var motion_enabled := _motion_effects_enabled()
	var bob := Vector3.ZERO
	var bob_strength := head_bob_intensity
	var settings := get_node_or_null("/root/SettingsService")
	if settings != null:
		var configured_bob: Variant = settings.get("head_bob_intensity")
		if configured_bob != null:
			bob_strength = float(configured_bob)
	if head_bob and moving and motion_enabled:
		_bob_time += delta * head_bob_frequency * (1.2 if sprinting else 1.0)
		bob = Vector3(sin(_bob_time * 0.5) * bob_strength * 0.45, absf(sin(_bob_time)) * bob_strength, 0.0)
	_land_bob = move_toward(_land_bob, 0.0, delta * (0.3 if motion_enabled else 2.0))
	var landing := Vector3(0.0, -_land_bob, 0.0) if motion_enabled else Vector3.ZERO
	_shake = move_toward(_shake, 0.0, delta * (1.8 if motion_enabled else 8.0))
	var shake_offset := Vector3.ZERO
	if _shake > 0.0 and _camera_shake_enabled() and not _date_lock:
		shake_offset = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * _shake
	camera.position = _camera_base_position + bob + landing + shake_offset
	var sprint_punch := sprint_fov_punch if sprinting and motion_enabled else 0.0
	camera.fov = lerpf(camera.fov, _base_fov + sprint_punch, 1.0 - exp(-delta * 9.0))
	if carry_anchor and is_instance_valid(carry_anchor):
		var carry_bob := Vector3(-bob.x * 1.7, -bob.y * 0.45, 0.0) if motion_enabled else Vector3.ZERO
		carry_anchor.position = _carry_base_position + carry_bob + Vector3(_pitch * 0.018, 0.0, 0.0)
		carry_anchor.rotation.x = lerpf(carry_anchor.rotation.x, -_pitch * 0.08, 1.0 - exp(-delta * 10.0))


func _update_footsteps(delta: float, moving: bool) -> void:
	if not moving:
		_footstep_time = 0.0
		return
	_footstep_time -= delta
	if _footstep_time <= 0.0:
		Sfx.play(&"step")
		_footstep_time = 0.38


func _sync_overlay_state() -> void:
	var phone := get_tree().get_first_node_in_group("phone_ui")
	if phone and is_instance_valid(phone) and (not _phone_open) and phone.visible:
		if phone.has_method("force_close"):
			phone.call("force_close")
		else:
			phone.visible = false
	var date_root := get_tree().get_first_node_in_group("date_ui")
	if date_root and is_instance_valid(date_root):
		if (not _date_lock) and date_root.visible and Game.dating.active_manual.is_empty():
			date_root.visible = false
	# Don't steal mouse while any modal/pause is up.
	var pause := get_tree().get_first_node_in_group("pause_ui")
	if pause == null:
		pause = get_tree().current_scene.find_child("PauseMenu", true, false) if get_tree().current_scene else null
	if (pause != null and bool(pause.visible)) or UiEscapeScript.any_overlay_open(get_tree()):
		return
	if (not _phone_open) and (not _date_lock) and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _update_focus() -> void:
	if _focus and is_instance_valid(_focus):
		_focus.set_focused(false)
	_focus = null
	if _phone_open or _date_lock:
		EventBus.interaction_hint.emit("")
		return
	if ray == null or not is_instance_valid(ray):
		EventBus.interaction_hint.emit("")
		return
	if ray.is_colliding():
		var col: Object = ray.get_collider()
		if col is Interactable:
			_focus = col as Interactable
		elif col is Node:
			var n := col as Node
			if is_instance_valid(n):
				var p: Node = n.get_parent()
				if p is Interactable:
					_focus = p as Interactable
	var hint := ""
	if _focus and is_instance_valid(_focus):
		_focus.set_focused(true)
		hint = _focus.get_prompt()
	EventBus.interaction_hint.emit(hint)


func _try_interact() -> void:
	if _focus and is_instance_valid(_focus):
		_focus.on_interact(self)
		add_shake(0.018)


func _update_carry_visual() -> void:
	if carry_anchor == null or not is_instance_valid(carry_anchor):
		return
	for c in carry_anchor.get_children():
		c.queue_free()
	if Game.inventory.carried_item == &"":
		return
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.2, 0.2, 0.2)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	var g: Dictionary = ContentDB.gift(Game.inventory.carried_item)
	var col: Array = g.get("color", [1, 1, 1])
	mat.albedo_color = Color(col[0], col[1], col[2])
	mesh.material_override = mat
	carry_anchor.add_child(mesh)
