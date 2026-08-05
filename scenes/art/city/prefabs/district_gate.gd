extends Node3D
## Semi-transparent district barrier. Metadata: district_id. Group: district_gate.


@export var district_id: String = ""
@export var display_name: String = "Барьер района"
@export var barrier_size: Vector3 = Vector3(6.0, 3.2, 0.45)

@onready var _barrier_mesh: MeshInstance3D = $BarrierMesh
@onready var _collision: CollisionShape3D = $StaticBody3D/CollisionShape3D
@onready var _body: StaticBody3D = $StaticBody3D
@onready var _label: Label3D = $ConditionLabel


func _ready() -> void:
	add_to_group("district_gate")
	if district_id != "":
		set_meta("district_id", district_id)
	elif has_meta("district_id"):
		district_id = str(get_meta("district_id"))
	_apply_barrier_size(barrier_size)
	_style_locked()
	if _label != null:
		_label.text = display_name


func configure(p_district_id: String, p_display_name: String, p_size: Vector3) -> void:
	district_id = p_district_id
	display_name = p_display_name
	barrier_size = p_size
	set_meta("district_id", p_district_id)
	add_to_group("district_gate")
	_apply_barrier_size(p_size)
	if _label != null:
		_label.text = p_display_name
	_style_locked()


func set_unlocked(open: bool) -> void:
	visible = not open
	if _collision != null:
		_collision.disabled = open
	if _body != null:
		_body.set_collision_layer_value(1, not open)
		_body.set_collision_mask_value(1, not open)
	var area := get_node_or_null("InteractionArea") as Area3D
	if area != null:
		area.monitoring = not open
		area.monitorable = not open
		var acs := area.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if acs != null:
			acs.disabled = open


func show_condition(text: String) -> void:
	if _label != null:
		_label.text = text


func _apply_barrier_size(size: Vector3) -> void:
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


func _style_locked() -> void:
	if _barrier_mesh == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.55, 0.95, 0.38)
	mat.emission_enabled = true
	mat.emission = Color(0.25, 0.45, 0.9)
	mat.emission_energy_multiplier = 0.55
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_barrier_mesh.material_override = mat
