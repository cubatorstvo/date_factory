class_name Interactable
extends Area3D
## World interactable: outline shader on meshes, thicker/brighter on focus.

const OUTLINE_SHADER: Shader = preload("res://shaders/interact_outline.gdshader")
const IDLE_WIDTH: float = 0.016
const FOCUS_WIDTH: float = 0.042
const IDLE_COLOR := Color(0.43, 0.91, 1.0, 0.72)
const FOCUS_COLOR := Color(1.0, 0.30, 0.55, 1.0)
const DETAIL_MESH_NAMES: Array[String] = [
	"EyeL", "EyeR", "PupilL", "PupilR", "BrowL", "BrowR", "Nose", "Mouth",
]

@export var display_name: String = "Объект"
@export var action_label: String = "Использовать"
@export var action_id: StringName = &""
@export var payload: Dictionary = {}

signal interacted(by: Node)

var _focused: bool = false
var _punch_time: float = 0.0
var _base_scale := Vector3.ONE
var _outline_mats: Array[ShaderMaterial] = []


func _ready() -> void:
	_base_scale = scale
	call_deferred("_setup_outlines")


func _process(delta: float) -> void:
	if _punch_time <= 0.0:
		return
	_punch_time = maxf(_punch_time - delta, 0.0)
	var pulse := 1.0 + sin(_punch_time * PI * 12.0) * 0.12 * (_punch_time / 0.16)
	scale = _base_scale * pulse
	if _punch_time <= 0.0:
		scale = _base_scale


func set_focused(focused: bool) -> void:
	if _focused == focused:
		return
	_focused = focused
	_apply_outline_state()


func get_prompt() -> String:
	return "%s [%s]" % [display_name, action_label]


func on_interact(by: Node) -> void:
	_punch_time = 0.16
	Sfx.play(&"click")
	interacted.emit(by)
	if action_id != &"":
		InteractionRouter.route(action_id, self, by, payload)


func _setup_outlines() -> void:
	_outline_mats.clear()
	_strip_legacy_markers(self)
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(self, meshes)
	for mi in meshes:
		var outline := _attach_outline(mi)
		if outline:
			_outline_mats.append(outline)
	_apply_outline_state()


func _apply_outline_state() -> void:
	var width := FOCUS_WIDTH if _focused else IDLE_WIDTH
	var color := FOCUS_COLOR if _focused else IDLE_COLOR
	for mat in _outline_mats:
		if mat == null:
			continue
		mat.set_shader_parameter("outline_width", width)
		mat.set_shader_parameter("outline_color", color)


func _attach_outline(mi: MeshInstance3D) -> ShaderMaterial:
	var base: Material = mi.material_override
	if base == null:
		base = mi.get_active_material(0)
	if base == null:
		base = StandardMaterial3D.new()
	# Duplicate so shared girl/prop materials don't fight each other.
	var owned: Material = base.duplicate()
	mi.material_override = owned
	var outline := ShaderMaterial.new()
	outline.shader = OUTLINE_SHADER
	outline.set_shader_parameter("outline_width", IDLE_WIDTH)
	outline.set_shader_parameter("outline_color", IDLE_COLOR)
	if owned is BaseMaterial3D:
		(owned as BaseMaterial3D).next_pass = outline
	elif owned is ShaderMaterial:
		(owned as ShaderMaterial).next_pass = outline
	else:
		return null
	return outline


func _collect_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	for child in node.get_children():
		if child is Label3D:
			continue
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			if not _is_detail_mesh(mi):
				out.append(mi)
		_collect_meshes(child, out)


func _is_detail_mesh(mi: MeshInstance3D) -> bool:
	return DETAIL_MESH_NAMES.has(str(mi.name))


func _strip_legacy_markers(node: Node) -> void:
	for child in node.get_children():
		if str(child.name).begins_with("FocusMarker"):
			child.queue_free()
			continue
		_strip_legacy_markers(child)
