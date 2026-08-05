extends Node3D
## Semi-transparent district barrier. Metadata: district_id. Group: district_gate.
## Stage 5: low rest opacity, single BarrierMesh slab, label only while focused.


@export var district_id: String = ""
@export var display_name: String = "Барьер района"
@export var barrier_size: Vector3 = Vector3(7.0, 2.8, 0.32)

const REST_ALPHA := 0.12
const FOCUS_ALPHA := 0.24

@onready var _barrier_mesh: MeshInstance3D = $BarrierMesh
@onready var _collision: CollisionShape3D = $StaticBody3D/CollisionShape3D
@onready var _body: StaticBody3D = $StaticBody3D
@onready var _label: Label3D = $ConditionLabel
@onready var _area: Area3D = get_node_or_null("InteractionArea") as Area3D

var _focused: bool = false


func _ready() -> void:
	add_to_group("district_gate")
	if district_id != "":
		set_meta("district_id", district_id)
	elif has_meta("district_id"):
		district_id = str(get_meta("district_id"))
	_apply_barrier_size(barrier_size)
	_style_locked()
	_set_label_visible(false)
	if _area != null:
		if not _area.body_entered.is_connected(_on_body_entered):
			_area.body_entered.connect(_on_body_entered)
		if not _area.body_exited.is_connected(_on_body_exited):
			_area.body_exited.connect(_on_body_exited)


func configure(p_district_id: String, p_display_name: String, p_size: Vector3) -> void:
	district_id = p_district_id
	display_name = p_display_name
	barrier_size = p_size
	set_meta("district_id", p_district_id)
	add_to_group("district_gate")
	_apply_barrier_size(p_size)
	_style_locked()
	_set_label_visible(false)


func set_unlocked(open: bool) -> void:
	visible = not open
	if _collision != null:
		_collision.disabled = open
	if _body != null:
		_body.set_collision_layer_value(1, not open)
		_body.set_collision_mask_value(1, not open)
	if _area != null:
		_area.monitoring = not open
		_area.monitorable = not open
		var acs := _area.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if acs != null:
			acs.disabled = open
	if open:
		_set_label_visible(false)


func show_condition(text: String) -> void:
	if _label != null:
		_label.text = text
	_set_label_visible(true)
	_focused = true
	_style_locked()


func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if body.is_in_group("player") or str(body.name).begins_with("Player"):
		_focused = true
		_set_label_visible(true)
		_style_locked()


func _on_body_exited(body: Node) -> void:
	if body == null:
		return
	if body.is_in_group("player") or str(body.name).begins_with("Player"):
		_focused = false
		_set_label_visible(false)
		_style_locked()


func _set_label_visible(on: bool) -> void:
	if _label == null:
		return
	_label.visible = on
	if on:
		_label.text = display_name


func _apply_barrier_size(size: Vector3) -> void:
	## Single translucent slab only — no second "frame" volume.
	if _barrier_mesh != null:
		var box := BoxMesh.new()
		box.size = size
		_barrier_mesh.mesh = box
		_barrier_mesh.position = Vector3(0.0, size.y * 0.5, 0.0)
	if _collision != null:
		var shape := BoxShape3D.new()
		shape.size = size
		_collision.shape = shape
		_collision.position = Vector3(0.0, size.y * 0.5, 0.0)
	## Strip legacy Stage-5 frame rails if present in old packed instances.
	for child in get_children():
		if child is MeshInstance3D:
			var nm: String = str(child.name)
			if nm == "FrameMesh" or nm.begins_with("FrameRail"):
				child.queue_free()


func _style_locked() -> void:
	var alpha: float = FOCUS_ALPHA if _focused else REST_ALPHA
	if _barrier_mesh == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.40, 0.62, 0.98, alpha)
	mat.emission_enabled = true
	mat.emission = Color(0.30, 0.55, 1.0)
	mat.emission_energy_multiplier = 0.18 if _focused else 0.08
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_barrier_mesh.material_override = mat
