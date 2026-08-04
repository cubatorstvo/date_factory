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
## Max vertical ledge the player can step onto while walking (meters).
const STEP_MAX_HEIGHT := 0.5
const STEP_MIN_HEIGHT := 0.05
## Soft vertical resolve rate (m/s). Clears 0.5 m in ~60 ms without a Y snap.
const STEP_LIFT_SPEED := 8.0
## Minimum validation-only forward probe (meters). Never applied as a teleport.
const STEP_PROBE_MIN := 0.12
const STEP_PROBE_PADDING := 0.08
const STEP_HEIGHT_SEARCH_ITERS := 8
@export var max_step_height: float = STEP_MAX_HEIGHT
@export var min_step_height: float = STEP_MIN_HEIGHT
@export var step_lift_speed: float = STEP_LIFT_SPEED

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/RayCast3D
@onready var carry_anchor: Node3D = $Head/CarryAnchor
@onready var _collision_shape: CollisionShape3D = $CollisionShape3D

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
## Remaining vertical step to apply (meters). Y-only; no forward impulse.
var _step_up_remain: float = 0.0


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
	# Help clear tiny geometry seams and stay glued after a step-up.
	floor_snap_length = maxf(floor_snap_length, 0.22)
	floor_max_angle = deg_to_rad(50.0)
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
	# Re-capture only on button_up. Doing this on press eats GUI clicks while
	# shop/barber/elevator/etc. have the cursor visible but _phone_open/_date_lock false.
	if event is InputEventMouseButton and (not event.pressed) and event.button_index == MOUSE_BUTTON_LEFT:
		if _ui_owns_mouse():
			return
		if (not _phone_open) and (not _date_lock) and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()


func _ui_owns_mouse() -> bool:
	return UiEscapeScript.any_overlay_open(get_tree())


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

	if _step_up_remain > 0.0:
		# Kinematic step lift owns vertical motion; do not fight it with gravity.
		velocity.y = 0.0
	elif not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if _date_lock:
		velocity.x = 0.0
		velocity.z = 0.0
		_step_up_remain = 0.0
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
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.length_squared() < 0.01 and direction.length_squared() > 0.0:
		horizontal = direction

	# Pre-lift so this frame's horizontal slide can clear the lip (Y only).
	var grounded_like := is_on_floor() or _step_up_remain > 0.0
	if grounded_like and _step_up_remain <= 0.0:
		var needed: float = _query_step_up_height(horizontal)
		if needed >= min_step_height:
			_step_up_remain = needed
	if _step_up_remain > 0.0:
		_apply_step_lift(delta)

	var saved_snap: float = floor_snap_length
	if _step_up_remain > 0.0:
		# Snap would pull back onto the lower floor while rising.
		floor_snap_length = 0.0
	move_and_slide()
	floor_snap_length = saved_snap

	if is_on_floor() or _step_up_remain > 0.0:
		var needed_after: float = _query_step_up_height(horizontal)
		if needed_after >= min_step_height:
			_step_up_remain = maxf(_step_up_remain, needed_after)
	if _step_up_remain <= 0.0 and is_on_floor():
		apply_floor_snap()

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


func _capsule_radius() -> float:
	if _collision_shape == null or _collision_shape.shape == null:
		return 0.35
	var shape: Shape3D = _collision_shape.shape
	if shape is CapsuleShape3D:
		return (shape as CapsuleShape3D).radius
	if shape is SphereShape3D:
		return (shape as SphereShape3D).radius
	if shape is CylinderShape3D:
		return (shape as CylinderShape3D).radius
	return 0.35


func _apply_step_lift(delta: float) -> void:
	## Continuous vertical-only resolve. Never adds forward motion.
	if _step_up_remain <= 0.0:
		return
	var speed: float = step_lift_speed if step_lift_speed > 0.0 else STEP_LIFT_SPEED
	var lift: float = minf(_step_up_remain, speed * delta)
	# Absorb micro-remainders so the camera does not crawl the last millimeters.
	if _step_up_remain - lift < 0.012:
		lift = _step_up_remain
	var hit: KinematicCollision3D = move_and_collide(Vector3(0.0, lift, 0.0))
	if hit != null:
		_step_up_remain = 0.0
		return
	_step_up_remain = maxf(_step_up_remain - lift, 0.0)
	velocity.y = 0.0


func _step_probe_vector(flat_dir: Vector3) -> Vector3:
	## Probe must clear the capsule lip in the *test* pose so the down-cast
	## samples the ledge top — but this distance is never written to position.
	var dist: float = maxf(STEP_PROBE_MIN, _capsule_radius() + STEP_PROBE_PADDING)
	return flat_dir * dist


func _is_horizontal_step_blocked(flat: Vector3) -> bool:
	## True when wish horizontal hits a non-walkable face (curb lip / wall).
	var probe: Vector3 = _step_probe_vector(flat)
	for i in get_slide_collision_count():
		var col: KinematicCollision3D = get_slide_collision(i)
		if col == null:
			continue
		var n: Vector3 = col.get_normal()
		# Skip walkable floors/slopes; keep steep ledges / walls / curb lips.
		if n.y >= 0.7:
			continue
		if flat.dot(-n) < 0.1:
			continue
		return true
	if is_on_wall():
		return true
	return test_move(global_transform, probe)


func _step_height_is_valid(height: float, probe: Vector3) -> bool:
	## Validation only: raise → short forward probe → down-cast for walkable ledge.
	var start: Transform3D = global_transform
	var up := Vector3(0.0, height, 0.0)
	if test_move(start, up):
		return false
	var raised: Transform3D = start.translated(up)
	if test_move(raised, probe):
		return false
	var ahead: Transform3D = raised.translated(probe)
	var down := Vector3(0.0, -(height + 0.2), 0.0)
	var params := PhysicsTestMotionParameters3D.new()
	params.from = ahead
	params.motion = down
	params.margin = maxf(safe_margin, 0.02)
	var result := PhysicsTestMotionResult3D.new()
	if not PhysicsServer3D.body_test_motion(get_rid(), params, result):
		return false
	if result.get_collision_normal().y < 0.55:
		return false
	var climbed: float = height + result.get_travel().y
	if climbed < min_step_height or climbed > max_step_height + 0.05:
		return false
	return true


func _query_step_up_height(horizontal: Vector3) -> float:
	## Binary-search the smallest clearance height that lets existing horizontal motion continue.
	if max_step_height <= 0.0:
		return 0.0
	var flat := Vector3(horizontal.x, 0.0, horizontal.z)
	if flat.length_squared() < 0.01:
		return 0.0
	flat = flat.normalized()
	if not _is_horizontal_step_blocked(flat):
		return 0.0
	var probe: Vector3 = _step_probe_vector(flat)
	if test_move(global_transform, Vector3(0.0, max_step_height, 0.0)):
		return 0.0

	var lo: float = min_step_height
	var hi: float = max_step_height
	var best: float = 0.0
	for _i in STEP_HEIGHT_SEARCH_ITERS:
		var mid: float = (lo + hi) * 0.5
		if _step_height_is_valid(mid, probe):
			best = mid
			hi = mid
		else:
			lo = mid
	if best >= min_step_height and _step_height_is_valid(best, probe):
		return best
	if _step_height_is_valid(max_step_height, probe):
		return max_step_height
	return 0.0


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
	# Vertical-slice presentation: keep carried gift off-camera (no pink debug cube).
	return
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.08, 0.14, 0.08)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	var g: Dictionary = ContentDB.gift(Game.inventory.carried_item)
	var col: Array = g.get("color", [0.75, 0.55, 0.35])
	mat.albedo_color = Color(float(col[0]) * 0.7, float(col[1]) * 0.75, float(col[2]) * 0.55)
	mesh.material_override = mat
	mesh.position = Vector3(0.12, -0.05, -0.25)
	carry_anchor.add_child(mesh)
