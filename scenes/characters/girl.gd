class_name GirlCharacter
extends Node3D
## Shared girl actor: face on -Z (Godot forward), hair, live face idle, emotions.
## Mesh lives in girl.tscn — this script only animates and recolors.

const SCENE_PATH := "res://scenes/characters/girl.tscn"

var profile: Dictionary = {}
var emotion: StringName = &"neutral"
var girl_id: String = ""

@onready var _body: MeshInstance3D = $Body
@onready var _head: MeshInstance3D = $Head
@onready var _hair_root: Node3D = $Hair
@onready var _eye_l: MeshInstance3D = $Head/EyeL
@onready var _eye_r: MeshInstance3D = $Head/EyeR
@onready var _pupil_l: MeshInstance3D = $Head/PupilL
@onready var _pupil_r: MeshInstance3D = $Head/PupilR
@onready var _brow_l: MeshInstance3D = $Head/BrowL
@onready var _brow_r: MeshInstance3D = $Head/BrowR
@onready var _nose: MeshInstance3D = $Head/Nose
@onready var _mouth: MeshInstance3D = $Head/Mouth
@onready var _name_label: Label3D = $NameLabel
@onready var _marker: MeshInstance3D = $Marker

var _idle_t: float = 0.0
var _blink_t: float = 2.0
var _blink_amount: float = 0.0
var _breath: float = 0.0
var _sitting: bool = false
var _eye_base_scale: Vector3 = Vector3.ONE


static func instantiate_girl() -> GirlCharacter:
	var packed := load(SCENE_PATH) as PackedScene
	if packed:
		return packed.instantiate() as GirlCharacter
	return GirlCharacter.new()


func _ready() -> void:
	if _eye_l:
		_eye_base_scale = _eye_l.scale
	if profile.is_empty():
		apply_profile({
			"skin": Color(0.95, 0.75, 0.7),
			"hair_style": "bob",
			"hair_color": Color(0.2, 0.12, 0.08),
			"eye_color": Color(0.25, 0.4, 0.55),
		})


func _process(delta: float) -> void:
	_idle_t += delta
	_breath += delta
	if _body:
		var breath := 1.0 + sin(_breath * 2.2) * 0.012
		_body.scale.y = breath * (0.92 if _sitting else 1.0)
	if _head:
		_head.rotation_degrees.y = sin(_idle_t * 0.7) * 2.0
		_head.rotation_degrees.x = sin(_idle_t * 0.45) * 1.2
	_blink_t -= delta
	if _blink_t <= 0.0:
		_blink_amount = 1.0
		_blink_t = randf_range(2.0, 4.5)
	if _blink_amount > 0.0:
		_blink_amount = maxf(0.0, _blink_amount - delta * 8.0)
		var lid := lerpf(1.0, 0.12, clampf(_blink_amount * 2.0, 0.0, 1.0))
		_apply_eye_scale(Vector3(_eye_base_scale.x, _eye_base_scale.y * lid, _eye_base_scale.z))
	else:
		_apply_eye_scale(_eye_base_scale)
	if _pupil_l and _pupil_r:
		var drift := sin(_idle_t * 1.1) * 0.006
		_pupil_l.position.x = -0.045 + drift
		_pupil_r.position.x = 0.045 + drift
	if _marker and _marker.visible:
		_marker.position.y = 2.05 + sin(_idle_t * 4.0) * 0.08
		_marker.rotate_y(delta * 2.0)


func apply_profile(p: Dictionary) -> void:
	profile = p.duplicate(true)
	girl_id = str(p.get("id", girl_id))
	if not is_node_ready():
		await ready
	var skin: Color = _as_color(p.get("skin", p.get("color", Color(0.95, 0.75, 0.7))))
	var hair_c: Color = _as_color(p.get("hair_color", Color(0.18, 0.1, 0.08)))
	var eye_c: Color = _as_color(p.get("eye_color", Color(0.25, 0.4, 0.55)))
	var outfit: Color = _as_color(p.get("outfit_tint", skin.darkened(0.25)))
	if _body:
		_body.material_override = _mat(outfit)
	if _head:
		_head.material_override = _mat(skin.lightened(0.08))
	if _nose:
		_nose.material_override = _mat(skin.darkened(0.05))
	if _pupil_l:
		_pupil_l.material_override = _mat(eye_c)
	if _pupil_r:
		_pupil_r.material_override = _mat(eye_c)
	_rebuild_hair(str(p.get("hair_style", "bob")), hair_c)
	if _name_label:
		_name_label.text = str(p.get("display_name", p.get("name", "")))
	set_emotion(StringName(str(p.get("emotion", "neutral"))))


func apply_from_content(girl_content_id: StringName, display_name: String = "") -> void:
	var def: Dictionary = ContentDB.girl(girl_content_id)
	var col_a: Array = def.get("color", [0.95, 0.75, 0.7])
	var skin := Color(float(col_a[0]), float(col_a[1]), float(col_a[2]))
	var styles := ["bob", "pony", "short", "long", "bun"]
	var style := str(def.get("hair_style", styles[abs(hash(str(girl_content_id))) % styles.size()]))
	var hair: Color = _as_color(def.get("hair_color", skin.darkened(0.55)))
	var eyes: Color = _as_color(def.get("eye_color", Color(0.2, 0.35, 0.5)))
	apply_profile({
		"id": str(girl_content_id),
		"display_name": display_name if display_name != "" else str(def.get("archetype", girl_content_id)),
		"skin": skin,
		"outfit_tint": skin.darkened(0.2),
		"hair_style": style,
		"hair_color": hair,
		"eye_color": eyes,
	})


func set_sitting(sitting: bool) -> void:
	_sitting = sitting


func set_emotion(emo: StringName) -> void:
	emotion = emo
	if _mouth == null:
		return
	match str(emo):
		"happy":
			_mouth.scale = Vector3(1.35, 1.1, 1.0)
			_mouth.position = Vector3(0, -0.1, -0.185)
			_mouth.material_override = _mat(Color(0.92, 0.35, 0.4))
			_set_brows(-12.0, 12.0)
			_eye_base_scale = Vector3.ONE
		"delighted":
			_mouth.scale = Vector3(1.55, 1.35, 1.0)
			_mouth.position = Vector3(0, -0.09, -0.185)
			_mouth.material_override = _mat(Color(1.0, 0.45, 0.5))
			_set_brows(-18.0, 18.0)
			_eye_base_scale = Vector3(1.05, 0.7, 1.0)
		"annoyed", "reject":
			_mouth.scale = Vector3(0.85, 0.9, 1.0)
			_mouth.position = Vector3(0, -0.11, -0.185)
			_mouth.material_override = _mat(Color(0.55, 0.18, 0.22))
			_set_brows(14.0, -14.0)
			_eye_base_scale = Vector3.ONE
		_:
			_mouth.scale = Vector3.ONE
			_mouth.position = Vector3(0, -0.1, -0.185)
			_mouth.material_override = _mat(Color(0.75, 0.28, 0.32))
			_set_brows(0.0, 0.0)
			_eye_base_scale = Vector3.ONE
	_apply_eye_scale(_eye_base_scale)


func face_toward(global_target: Vector3) -> void:
	var flat := Vector3(global_target.x, global_position.y, global_target.z)
	if global_position.distance_to(flat) < 0.05:
		return
	# look_at aims -Z at target — matches face placement on -Z.
	look_at(flat, Vector3.UP)


func set_tutorial_marker(enabled: bool) -> void:
	if _marker == null:
		return
	_marker.visible = enabled


func get_parts() -> Dictionary:
	return {
		"body": _body, "head": _head, "eye_l": _eye_l, "eye_r": _eye_r,
		"mouth": _mouth, "brow": _brow_l, "nose": _nose,
	}


func _apply_eye_scale(s: Vector3) -> void:
	if _eye_l:
		_eye_l.scale = s
	if _eye_r:
		_eye_r.scale = s


func _set_brows(left_z: float, right_z: float) -> void:
	if _brow_l:
		_brow_l.rotation_degrees.z = left_z
	if _brow_r:
		_brow_r.rotation_degrees.z = right_z


func _rebuild_hair(style: String, color: Color) -> void:
	if _hair_root == null:
		return
	for c in _hair_root.get_children():
		c.queue_free()
	match style:
		"pony":
			_hair_piece(0.17, 0.55, Vector3(0, 1.58, 0.02), color)
			_hair_piece(0.06, 1.0, Vector3(0, 1.35, 0.18), color)
		"short":
			_hair_piece(0.16, 0.45, Vector3(0, 1.56, 0.0), color)
		"long":
			_hair_piece(0.18, 0.55, Vector3(0, 1.58, 0.0), color)
			_hair_piece(0.12, 1.3, Vector3(-0.12, 1.2, 0.05), color)
			_hair_piece(0.12, 1.3, Vector3(0.12, 1.2, 0.05), color)
		"bun":
			_hair_piece(0.16, 0.5, Vector3(0, 1.56, 0.0), color)
			_hair_piece(0.09, 1.0, Vector3(0, 1.7, 0.08), color)
		_: # bob
			_hair_piece(0.18, 0.55, Vector3(0, 1.58, 0.0), color)
			_hair_piece(0.15, 0.9, Vector3(0, 1.4, 0.12), color)


func _hair_piece(radius: float, height_ratio: float, pos: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0  # always a true sphere; squash via scale if needed
	mi.mesh = s
	mi.position = pos
	mi.scale = Vector3(1.0, clampf(height_ratio, 0.45, 1.6), 1.0)
	mi.material_override = _mat(color)
	_hair_root.add_child(mi)


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m


func _as_color(v: Variant) -> Color:
	if v is Color:
		return v
	if v is Array and v.size() >= 3:
		return Color(float(v[0]), float(v[1]), float(v[2]))
	if v is Dictionary:
		return Color(float(v.get("r", 1)), float(v.get("g", 1)), float(v.get("b", 1)))
	return Color(0.9, 0.75, 0.7)
