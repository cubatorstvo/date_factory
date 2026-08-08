class_name CameraFeedback
extends Node
## Player-local camera presentation impulses (MODULE 23).
## Not an autoload. Hard-capped; restores baseline exactly.


const MAX_ROTATION_DEG: float = 2.0
const MAX_SHAKE_M: float = 0.025
const MAX_FOV_DEG: float = 3.0
const MAX_DURATION_SEC: float = 0.20

var _feedback_scale: float = 1.0
var _camera: Camera3D = null
var _baseline_position: Vector3 = Vector3.ZERO
var _baseline_rotation: Vector3 = Vector3.ZERO
var _baseline_fov: float = 75.0
var _baseline_captured: bool = false

var _rot_remaining: float = 0.0
var _rot_duration: float = 0.0
var _rot_axis: Vector3 = Vector3.RIGHT
var _rot_peak_rad: float = 0.0

var _shake_remaining: float = 0.0
var _shake_duration: float = 0.0
var _shake_amp: float = 0.0

var _fov_remaining: float = 0.0
var _fov_duration: float = 0.0
var _fov_peak_deg: float = 0.0

## Introspection for self-tests (peak magnitudes applied after caps/scale).
var debug_last_rot_deg: float = 0.0
var debug_last_shake_m: float = 0.0
var debug_last_fov_deg: float = 0.0
var debug_last_duration: float = 0.0


func _ready() -> void:
	_bind_camera(get_parent() as Camera3D)


func _process(delta: float) -> void:
	if _camera == null or not _baseline_captured:
		return
	if not _has_active_effect():
		return
	if _rot_remaining > 0.0:
		_rot_remaining = maxf(0.0, _rot_remaining - delta)
	if _shake_remaining > 0.0:
		_shake_remaining = maxf(0.0, _shake_remaining - delta)
	if _fov_remaining > 0.0:
		_fov_remaining = maxf(0.0, _fov_remaining - delta)
	if _has_active_effect():
		_apply_offsets()
	else:
		_restore_baseline()


func bind_camera(camera: Camera3D) -> void:
	_bind_camera(camera)


func impulse_rotation(degrees: float, duration: float, axis: Vector3 = Vector3.RIGHT) -> void:
	if _camera == null or not _baseline_captured:
		return
	if _feedback_scale <= 0.0:
		debug_last_rot_deg = 0.0
		debug_last_duration = 0.0
		return
	var signed_deg: float = clampf(degrees * _feedback_scale, -MAX_ROTATION_DEG, MAX_ROTATION_DEG)
	var dur: float = clampf(duration, 0.0, MAX_DURATION_SEC)
	if is_zero_approx(signed_deg) or dur <= 0.0:
		debug_last_rot_deg = 0.0
		debug_last_duration = 0.0
		return
	var use_axis: Vector3 = axis
	if use_axis.length_squared() < 0.0001:
		use_axis = Vector3.RIGHT
	_rot_axis = use_axis.normalized()
	_rot_peak_rad = deg_to_rad(signed_deg)
	_rot_duration = dur
	_rot_remaining = dur
	debug_last_rot_deg = absf(signed_deg)
	debug_last_duration = dur


func shake(amplitude_m: float, duration: float) -> void:
	if _camera == null or not _baseline_captured:
		return
	if _feedback_scale <= 0.0:
		debug_last_shake_m = 0.0
		return
	var amp: float = minf(absf(amplitude_m) * _feedback_scale, MAX_SHAKE_M)
	var dur: float = clampf(duration, 0.0, MAX_DURATION_SEC)
	if amp <= 0.0 or dur <= 0.0:
		debug_last_shake_m = 0.0
		return
	_shake_amp = amp
	_shake_duration = dur
	_shake_remaining = dur
	debug_last_shake_m = amp
	debug_last_duration = maxf(debug_last_duration, dur)


func fov_pulse(degrees: float, duration: float) -> void:
	if _camera == null or not _baseline_captured:
		return
	if _feedback_scale <= 0.0:
		debug_last_fov_deg = 0.0
		return
	var deg: float = minf(absf(degrees) * _feedback_scale, MAX_FOV_DEG)
	var dur: float = clampf(duration, 0.0, MAX_DURATION_SEC)
	if deg <= 0.0 or dur <= 0.0:
		debug_last_fov_deg = 0.0
		return
	_fov_peak_deg = deg
	_fov_duration = dur
	_fov_remaining = dur
	debug_last_fov_deg = deg
	debug_last_duration = maxf(debug_last_duration, dur)


func set_feedback_scale(scale: float) -> void:
	_feedback_scale = clampf(scale, 0.0, 1.0)


func get_feedback_scale() -> float:
	return _feedback_scale


func is_effect_active() -> bool:
	return _has_active_effect()


func get_baseline_position() -> Vector3:
	return _baseline_position


func get_baseline_rotation() -> Vector3:
	return _baseline_rotation


func get_baseline_fov() -> float:
	return _baseline_fov


## Update FOV baseline when settings change. Pulses restore to this value.
func set_baseline_fov(fov: float) -> void:
	_baseline_fov = fov
	if _camera == null:
		_baseline_captured = false
		return
	_baseline_captured = true
	if _fov_remaining > 0.0:
		_apply_offsets()
	else:
		_camera.fov = _baseline_fov


## Synchronous self-test: caps, exact baseline restore, scale0 zero motion.
static func run_self_test() -> bool:
	var passed: int = 0
	var failed: int = 0
	var cam: Camera3D = Camera3D.new()
	cam.name = "SelfTestCamera"
	cam.position = Vector3(0.1, 0.2, 0.3)
	cam.rotation = Vector3(0.01, -0.02, 0.03)
	cam.fov = 71.5
	var fb: CameraFeedback = CameraFeedback.new()
	fb.name = "CameraFeedback"
	cam.add_child(fb)
	# Orphan tree: force bind + baseline without entering scene tree fully.
	fb.bind_camera(cam)
	var base_pos: Vector3 = cam.position
	var base_rot: Vector3 = cam.rotation
	var base_fov: float = cam.fov

	# Caps
	fb.impulse_rotation(9.0, 1.0)
	if is_equal_approx(fb.debug_last_rot_deg, MAX_ROTATION_DEG) and is_equal_approx(fb.debug_last_duration, MAX_DURATION_SEC):
		passed += 1
	else:
		failed += 1
		push_error("CAMERA_FB_TEST FAIL: rotation/duration caps")
	fb.shake(0.5, 1.0)
	if is_equal_approx(fb.debug_last_shake_m, MAX_SHAKE_M):
		passed += 1
	else:
		failed += 1
		push_error("CAMERA_FB_TEST FAIL: shake cap")
	fb.fov_pulse(12.0, 1.0)
	if is_equal_approx(fb.debug_last_fov_deg, MAX_FOV_DEG):
		passed += 1
	else:
		failed += 1
		push_error("CAMERA_FB_TEST FAIL: fov cap")

	# Drive process to completion and restore baseline exactly.
	var guard: int = 0
	while fb.is_effect_active() and guard < 60:
		fb._process(0.05)
		guard += 1
	fb._process(0.05)
	var restored: bool = (
		cam.position.is_equal_approx(base_pos)
		and cam.rotation.is_equal_approx(base_rot)
		and is_equal_approx(cam.fov, base_fov)
	)
	if restored:
		passed += 1
	else:
		failed += 1
		push_error("CAMERA_FB_TEST FAIL: baseline restore")

	# Scale 0 → zero motion
	cam.position = base_pos
	cam.rotation = base_rot
	cam.fov = base_fov
	fb.set_feedback_scale(0.0)
	if not is_equal_approx(fb.get_feedback_scale(), 0.0):
		failed += 1
		push_error("CAMERA_FB_TEST FAIL: scale setter")
	else:
		passed += 1
	fb.impulse_rotation(1.8, 0.10)
	fb.shake(0.015, 0.10)
	fb.fov_pulse(2.0, 0.18)
	fb._process(0.016)
	var zero_motion: bool = (
		cam.position.is_equal_approx(base_pos)
		and cam.rotation.is_equal_approx(base_rot)
		and is_equal_approx(cam.fov, base_fov)
		and not fb.is_effect_active()
		and is_zero_approx(fb.debug_last_rot_deg)
		and is_zero_approx(fb.debug_last_shake_m)
		and is_zero_approx(fb.debug_last_fov_deg)
	)
	if zero_motion:
		passed += 1
	else:
		failed += 1
		push_error("CAMERA_FB_TEST FAIL: scale0 zero motion")

	# Perfect slap values stay under caps at scale 1
	fb.set_feedback_scale(1.0)
	fb.impulse_rotation(1.8, 0.10)
	fb.shake(0.015, 0.10)
	var slap_ok: bool = (
		is_equal_approx(fb.debug_last_rot_deg, 1.8)
		and is_equal_approx(fb.debug_last_shake_m, 0.015)
		and fb.debug_last_rot_deg <= MAX_ROTATION_DEG + 0.0001
		and fb.debug_last_shake_m <= MAX_SHAKE_M + 0.0001
	)
	if slap_ok:
		passed += 1
	else:
		failed += 1
		push_error("CAMERA_FB_TEST FAIL: perfect slap under caps")

	cam.free()
	if failed == 0:
		print("CAMERA_FB_TEST: ALL PASS (%s)" % passed)
		return true
	print("CAMERA_FB_TEST: FAIL passed=%s failed=%s" % [passed, failed])
	return false


func _bind_camera(camera: Camera3D) -> void:
	_camera = camera
	if _camera == null:
		_baseline_captured = false
		return
	_capture_baseline()


func _capture_baseline() -> void:
	if _camera == null:
		_baseline_captured = false
		return
	_baseline_position = _camera.position
	_baseline_rotation = _camera.rotation
	_baseline_fov = _camera.fov
	_baseline_captured = true


func _has_active_effect() -> bool:
	return _rot_remaining > 0.0 or _shake_remaining > 0.0 or _fov_remaining > 0.0


func _envelope(remaining: float, duration: float) -> float:
	if duration <= 0.0:
		return 0.0
	var t: float = clampf(remaining / duration, 0.0, 1.0)
	# Peak at start, ease to zero.
	return t


func _apply_offsets() -> void:
	var rot_off: Vector3 = Vector3.ZERO
	if _rot_remaining > 0.0:
		var env_r: float = _envelope(_rot_remaining, _rot_duration)
		rot_off = _rot_axis * (_rot_peak_rad * env_r)
	var pos_off: Vector3 = Vector3.ZERO
	if _shake_remaining > 0.0:
		var env_s: float = _envelope(_shake_remaining, _shake_duration)
		var amp: float = _shake_amp * env_s
		pos_off = Vector3(
			randf_range(-amp, amp),
			randf_range(-amp, amp),
			randf_range(-amp, amp),
		)
	var fov_off: float = 0.0
	if _fov_remaining > 0.0:
		var env_f: float = _envelope(_fov_remaining, _fov_duration)
		fov_off = _fov_peak_deg * env_f
	_camera.position = _baseline_position + pos_off
	_camera.rotation = _baseline_rotation + rot_off
	_camera.fov = _baseline_fov + fov_off


func _restore_baseline() -> void:
	if _camera == null or not _baseline_captured:
		return
	_camera.position = _baseline_position
	_camera.rotation = _baseline_rotation
	_camera.fov = _baseline_fov
	_rot_remaining = 0.0
	_shake_remaining = 0.0
	_fov_remaining = 0.0
	_rot_peak_rad = 0.0
	_shake_amp = 0.0
	_fov_peak_deg = 0.0
