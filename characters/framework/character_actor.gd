class_name CharacterActor
extends CharacterBody3D
## Reusable humanoid presence actor (MODULE 04).
## Owns collision, visual instance, appearance application, and animation presentation.

const LAYER_WORLD: int = 1
const LAYER_INTERACTABLE: int = 4
const LAYER_CHARACTERS: int = 8

const MALE_CAPSULE_RADIUS: float = 0.32
const MALE_CAPSULE_HEIGHT: float = 1.8
const FEMALE_CAPSULE_RADIUS: float = 0.30
const FEMALE_CAPSULE_HEIGHT: float = 1.75

@export var content_id: StringName = &""
@export var display_name: String = ""

var _appearance_profile_id: StringName = &""
var _visual_instance: Node = null
var _body_type: GameTypes.CharacterBodyType = GameTypes.CharacterBodyType.MALE

@onready var _collision_shape: CollisionShape3D = $Collision
@onready var _visual_root: Node3D = $VisualRoot
@onready var _animation_controller: CharacterAnimationController = $AnimationController
@onready var _interaction_target: Area3D = $InteractionTarget
@onready var _interaction_shape: CollisionShape3D = $InteractionTarget/CollisionShape3D
@onready var _interaction_anchor: Marker3D = $InteractionAnchor
@onready var _look_anchor: Marker3D = $LookAnchor
@onready var _ground_anchor: Marker3D = $GroundAnchor


func _ready() -> void:
	collision_layer = LAYER_CHARACTERS
	collision_mask = LAYER_WORLD
	if _interaction_target != null:
		_interaction_target.collision_layer = LAYER_INTERACTABLE
		_interaction_target.collision_mask = 0
		_interaction_target.monitoring = false
		_interaction_target.monitorable = true
	_apply_capsule_for_body_type(_body_type)
	if _appearance_profile_id != &"" and _visual_instance == null:
		apply_appearance(_appearance_profile_id)


func apply_appearance(profile_id: StringName) -> bool:
	if profile_id == &"":
		push_error("[CharacterActor] apply_appearance empty profile_id")
		return false
	var db: Node = get_node_or_null("/root/ContentDB")
	if db == null:
		push_error("[CharacterActor] ContentDB unavailable")
		return false
	var profile: AppearanceProfileDefinition = db.call("get_appearance_profile", profile_id) as AppearanceProfileDefinition
	if profile == null:
		push_error("[CharacterActor] missing appearance profile: %s" % String(profile_id))
		return false
	if profile.visual_scene == null:
		push_error("[CharacterActor] appearance %s has null visual_scene" % String(profile_id))
		return false

	var visual_root: Node3D = _get_visual_root()
	if visual_root == null:
		push_error("[CharacterActor] VisualRoot missing")
		return false

	_clear_visual(visual_root)
	_visual_instance = profile.visual_scene.instantiate()
	visual_root.add_child(_visual_instance)
	visual_root.scale = Vector3.ONE * maxf(profile.visual_scale, 0.001)
	visual_root.position = Vector3(0.0, profile.vertical_offset, 0.0)
	_apply_modular_variants(_visual_instance, profile)

	_appearance_profile_id = profile_id
	_body_type = profile.body_type
	_apply_capsule_for_body_type(_body_type)
	_update_anchors_for_body_type(_body_type)

	var anim_controller: CharacterAnimationController = _get_animation_controller()
	var anim_player: AnimationPlayer = _ensure_animation_player(_visual_instance)
	if anim_controller != null:
		anim_controller.bind_animation_player(anim_player)
		if String(profile.animation_profile_id) != "":
			var anim_profile: AnimationProfileDefinition = db.call(
				"get_animation_profile", profile.animation_profile_id
			) as AnimationProfileDefinition
			if anim_profile != null:
				anim_controller.apply_animation_profile(anim_profile)
				anim_controller.play_loop(&"idle")
			else:
				push_warning(
					"[CharacterActor] missing animation profile: %s" % String(profile.animation_profile_id)
				)
	return true


func get_appearance_profile_id() -> StringName:
	return _appearance_profile_id


func set_character_visible(visible: bool) -> void:
	var visual_root: Node3D = _get_visual_root()
	if visual_root != null:
		visual_root.visible = visible
	if _collision_shape != null:
		_collision_shape.disabled = not visible
	elif has_node("Collision"):
		(get_node("Collision") as CollisionShape3D).disabled = not visible
	var interaction: Area3D = _get_interaction_target()
	if interaction != null:
		interaction.visible = visible
		var shape: CollisionShape3D = interaction.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if shape != null:
			shape.disabled = not visible


func face_point(world_position: Vector3) -> void:
	var to_target: Vector3 = world_position - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		return
	look_at(global_position + to_target.normalized(), Vector3.UP)


func set_locomotion_speed(speed: float) -> void:
	var anim_controller: CharacterAnimationController = _get_animation_controller()
	if anim_controller != null:
		anim_controller.set_locomotion_speed(speed)


func get_animation_controller() -> CharacterAnimationController:
	return _get_animation_controller()


func _get_visual_root() -> Node3D:
	if _visual_root != null:
		return _visual_root
	return get_node_or_null("VisualRoot") as Node3D


func _get_animation_controller() -> CharacterAnimationController:
	if _animation_controller != null:
		return _animation_controller
	return get_node_or_null("AnimationController") as CharacterAnimationController


func _get_interaction_target() -> Area3D:
	if _interaction_target != null:
		return _interaction_target
	return get_node_or_null("InteractionTarget") as Area3D


func _find_variant_controller(visual: Node) -> CharacterVariantController:
	if visual == null:
		return null
	var queue: Array[Node] = [visual]
	while not queue.is_empty():
		var node: Node = queue.pop_front()
		var typed: CharacterVariantController = node as CharacterVariantController
		if typed != null:
			return typed
		for child in node.get_children():
			queue.append(child)
	return null


func _apply_modular_variants(visual: Node, profile: AppearanceProfileDefinition) -> void:
	if visual == null or profile == null:
		return
	var controller: CharacterVariantController = visual as CharacterVariantController
	if controller == null:
		controller = _find_variant_controller(visual)
	if controller != null:
		controller.apply_from_profile(profile)
		return
	if visual.has_method("apply_variants"):
		visual.call(
			"apply_variants",
			profile.hair_variant,
			profile.hair_color,
			profile.top_variant,
			profile.top_color,
			profile.bottom_variant,
			profile.bottom_color,
			profile.shoes_variant,
			profile.head_accessory,
			profile.neck_accessory,
			profile.hand_accessory
		)


func _clear_visual(visual_root: Node3D) -> void:
	for child in visual_root.get_children():
		visual_root.remove_child(child)
		child.free()
	_visual_instance = null


func _ensure_animation_player(visual: Node) -> AnimationPlayer:
	var existing: AnimationPlayer = visual.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if existing != null:
		return existing
	var host: Node = _find_animation_host(visual)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	host.add_child(player)
	# Tracks are authored relative to the glTF root (host); AP is a child of host.
	player.root_node = NodePath("..")
	return player


func _find_animation_host(visual: Node) -> Node:
	if visual == null:
		return self
	var queue: Array[Node] = [visual]
	while not queue.is_empty():
		var node: Node = queue.pop_front()
		if node.get_node_or_null("Armature") != null or node.get_node_or_null("CharacterArmature") != null:
			return node
		for child in node.get_children():
			queue.append(child)
	return visual


func _apply_capsule_for_body_type(body_type: GameTypes.CharacterBodyType) -> void:
	var radius: float = MALE_CAPSULE_RADIUS
	var height: float = MALE_CAPSULE_HEIGHT
	if body_type == GameTypes.CharacterBodyType.FEMALE:
		radius = FEMALE_CAPSULE_RADIUS
		height = FEMALE_CAPSULE_HEIGHT
	var shape_node: CollisionShape3D = _collision_shape
	if shape_node == null:
		shape_node = get_node_or_null("Collision") as CollisionShape3D
	if shape_node == null:
		return
	var capsule: CapsuleShape3D = shape_node.shape as CapsuleShape3D
	if capsule == null:
		capsule = CapsuleShape3D.new()
		shape_node.shape = capsule
	capsule.radius = radius
	capsule.height = height
	shape_node.position = Vector3(0.0, height * 0.5, 0.0)
	var interaction: Area3D = _get_interaction_target()
	if interaction != null:
		var ishape: CollisionShape3D = interaction.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if ishape != null:
			var icapsule: CapsuleShape3D = ishape.shape as CapsuleShape3D
			if icapsule == null:
				icapsule = CapsuleShape3D.new()
				ishape.shape = icapsule
			icapsule.radius = radius
			icapsule.height = height
			ishape.position = Vector3(0.0, height * 0.5, 0.0)


func _update_anchors_for_body_type(body_type: GameTypes.CharacterBodyType) -> void:
	var height: float = MALE_CAPSULE_HEIGHT
	if body_type == GameTypes.CharacterBodyType.FEMALE:
		height = FEMALE_CAPSULE_HEIGHT
	var interaction_anchor: Marker3D = _interaction_anchor
	if interaction_anchor == null:
		interaction_anchor = get_node_or_null("InteractionAnchor") as Marker3D
	var look_anchor: Marker3D = _look_anchor
	if look_anchor == null:
		look_anchor = get_node_or_null("LookAnchor") as Marker3D
	var ground_anchor: Marker3D = _ground_anchor
	if ground_anchor == null:
		ground_anchor = get_node_or_null("GroundAnchor") as Marker3D
	if interaction_anchor != null:
		interaction_anchor.position = Vector3(0.0, height * 0.55, 0.0)
	if look_anchor != null:
		look_anchor.position = Vector3(0.0, height * 0.92, 0.0)
	if ground_anchor != null:
		ground_anchor.position = Vector3.ZERO
