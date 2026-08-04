class_name DatePresentationController
extends Node
## Smooth, reusable camera choreography for date presentation scenes.

signal shot_changed(shot: StringName)

const SHOTS: Dictionary = {
	&"arrival": {"position": Vector3(4.8, 2.2, 3.8), "look": Vector3(-0.5, 1.0, 2.3), "fov": 54.0},
	&"wide": {"position": Vector3(5.8, 2.8, 3.7), "look": Vector3(0.0, 1.0, -0.2), "fov": 52.0},
	&"two_shot": {"position": Vector3(4.8, 1.8, 0.0), "look": Vector3(0.0, 1.15, 0.0), "fov": 47.0},
	&"girl_close": {"position": Vector3(1.7, 1.6, 0.75), "look": Vector3(0.0, 1.35, -1.15), "fov": 45.0},
	&"hero_close": {"position": Vector3(-1.7, 1.6, -0.75), "look": Vector3(0.0, 1.35, 1.15), "fov": 45.0},
	&"result": {"position": Vector3(5.0, 2.5, 3.0), "look": Vector3(0.0, 1.0, -0.2), "fov": 48.0},
}

var current_shot: StringName = &""
var _camera: Camera3D
var _origin: Vector3 = Vector3.ZERO
var _tween: Tween


func setup(camera: Camera3D, origin: Vector3) -> void:
	_camera = camera
	_origin = origin


func move_to(shot: StringName, duration: float = 0.8) -> void:
	if _camera == null or not is_instance_valid(_camera):
		return
	if not SHOTS.has(shot):
		push_warning("Unknown date camera shot: %s" % shot)
		return
	var spec: Dictionary = SHOTS[shot]
	var local_position: Vector3 = spec.get("position", Vector3.ZERO)
	var local_look: Vector3 = spec.get("look", Vector3.ZERO)
	var target_transform := Transform3D(Basis.IDENTITY, _origin + local_position)
	target_transform = target_transform.looking_at(_origin + local_look, Vector3.UP)
	var target_fov: float = float(spec.get("fov", 50.0))
	if _tween != null:
		_tween.kill()
	if duration <= 0.01:
		_camera.global_transform = target_transform
		_camera.fov = target_fov
	else:
		_tween = create_tween().set_parallel(true)
		_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(_camera, "global_transform", target_transform, duration)
		_tween.tween_property(_camera, "fov", target_fov, duration)
	current_shot = shot
	shot_changed.emit(shot)


func react(_emotion: StringName) -> void:
	move_to(&"girl_close", 0.48)
