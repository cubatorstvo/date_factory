class_name WorldFeatureGate
extends Node3D
## Physical StoryFeature barrier inside a location (MODULE 12).

@export var required_feature: StoryTypes.StoryFeature = StoryTypes.StoryFeature.PUBLIC_CITY_ACCESS
@export var collision_root: NodePath = NodePath("BarrierBody")
@export var visual_root: NodePath = NodePath("BarrierVisual")

var _unlocked: bool = false


func _ready() -> void:
	var story: Node = get_node_or_null("/root/Story")
	if story != null and story.has_signal("feature_unlocked"):
		if not story.is_connected("feature_unlocked", _on_feature_unlocked):
			story.connect("feature_unlocked", _on_feature_unlocked)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_signal("stage_changed"):
		if not gs.is_connected("stage_changed", _on_stage_changed):
			gs.connect("stage_changed", _on_stage_changed)
	refresh()


func is_unlocked() -> bool:
	return _unlocked


func is_barrier_visible() -> bool:
	var visual: Node3D = get_node_or_null(visual_root) as Node3D
	if visual == null:
		return false
	return visual.visible


func is_collision_enabled() -> bool:
	var body: Node = get_node_or_null(collision_root)
	if body == null:
		return false
	if body is StaticBody3D:
		var sb: StaticBody3D = body as StaticBody3D
		if sb.collision_layer == 0:
			return false
		for child in sb.get_children():
			if child is CollisionShape3D and not (child as CollisionShape3D).disabled:
				return true
		return false
	if body is CollisionShape3D:
		return not (body as CollisionShape3D).disabled
	return false


func refresh() -> void:
	_unlocked = _query_unlocked()
	_apply_state()


func _query_unlocked() -> bool:
	var story: Node = get_node_or_null("/root/Story")
	if story == null or not story.has_method("is_feature_unlocked"):
		return false
	return bool(story.call("is_feature_unlocked", required_feature))


func _apply_state() -> void:
	var visual: Node3D = get_node_or_null(visual_root) as Node3D
	if visual != null:
		visual.visible = not _unlocked
	var body: Node = get_node_or_null(collision_root)
	if body is StaticBody3D:
		var sb: StaticBody3D = body as StaticBody3D
		sb.collision_layer = 0 if _unlocked else 1
		sb.collision_mask = 0
		for child in sb.get_children():
			if child is CollisionShape3D:
				(child as CollisionShape3D).disabled = _unlocked
	elif body is CollisionShape3D:
		(body as CollisionShape3D).disabled = _unlocked


func _on_feature_unlocked(_feature: StoryTypes.StoryFeature) -> void:
	refresh()


func _on_stage_changed(_new_stage: GameTypes.GameStage, _prev: GameTypes.GameStage) -> void:
	refresh()
