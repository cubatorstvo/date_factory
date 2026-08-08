class_name CloneVisualActor
extends Node3D
## Thin presentation wrapper around CharacterActor (MODULE 19).
## No gameplay collision, interactable, AI, or navigation.

var _character: CharacterActor = null
var _home_global: Transform3D = Transform3D.IDENTITY
var _busy_tween: bool = false


func get_character_actor() -> CharacterActor:
	return _character


func is_busy() -> bool:
	return _busy_tween


func ensure_character(appearance_id: StringName, content_id: StringName = &"clone_visual") -> CharacterActor:
	if _character != null and is_instance_valid(_character):
		if _character.get_appearance_profile_id() != appearance_id:
			_character.apply_appearance(appearance_id)
		_apply_presentation_collision()
		return _character
	var existing: CharacterActor = get_node_or_null("CharacterActor") as CharacterActor
	if existing != null:
		_character = existing
		if _character.get_appearance_profile_id() != appearance_id:
			_character.apply_appearance(appearance_id)
		_apply_presentation_collision()
		return _character
	_character = CharacterFactory.create(appearance_id, content_id, self)
	if _character != null:
		_character.name = "CharacterActor"
		_character.position = Vector3.ZERO
		_apply_presentation_collision()
	return _character


func set_visible_presence(on: bool) -> void:
	visible = on
	if _character != null and is_instance_valid(_character):
		_character.set_character_visible(on)
		_apply_presentation_collision()


func remember_home() -> void:
	_home_global = global_transform


func restore_home() -> void:
	global_transform = _home_global
	visible = true
	if _character != null and is_instance_valid(_character):
		_character.set_character_visible(true)
		_character.set_locomotion_speed(0.0)
		_apply_presentation_collision()
	_busy_tween = false


func tween_to_exit_and_free(exit_global: Vector3, duration: float) -> void:
	if _busy_tween:
		return
	if not is_inside_tree():
		queue_free()
		return
	_busy_tween = true
	if _character != null and is_instance_valid(_character):
		_character.set_locomotion_speed(1.0)
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	tween.tween_property(self, "global_position", exit_global, duration)
	await tween.finished
	if is_instance_valid(self):
		queue_free()


func tween_to_and_restore(exit_global: Vector3, duration: float) -> void:
	if _busy_tween:
		return
	if not is_inside_tree():
		return
	_busy_tween = true
	remember_home()
	if _character != null and is_instance_valid(_character):
		_character.set_locomotion_speed(1.0)
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	tween.tween_property(self, "global_position", exit_global, duration)
	await tween.finished
	if not is_instance_valid(self):
		return
	visible = false
	if _character != null and is_instance_valid(_character):
		_character.set_character_visible(false)
		_character.set_locomotion_speed(0.0)
	await get_tree().create_timer(0.15).timeout
	if not is_instance_valid(self):
		return
	restore_home()


func try_play_alias(alias: StringName) -> void:
	if _character == null or not is_instance_valid(_character):
		return
	var anim: CharacterAnimationController = _character.get_animation_controller()
	if anim == null:
		return
	# Prefer requested alias when present; otherwise idle without noisy warnings.
	if alias != &"idle" and anim.has_animation(alias):
		anim.play_loop(alias)
		return
	anim.play_loop(&"idle")


func _apply_presentation_collision() -> void:
	if _character == null or not is_instance_valid(_character):
		return
	_character.collision_layer = 0
	_character.collision_mask = 0
	var body_shape: CollisionShape3D = _character.get_node_or_null("Collision") as CollisionShape3D
	if body_shape != null:
		body_shape.disabled = true
	var interaction: Area3D = _character.get_node_or_null("InteractionTarget") as Area3D
	if interaction != null:
		interaction.collision_layer = 0
		interaction.collision_mask = 0
		interaction.monitoring = false
		interaction.monitorable = false
		var ishape: CollisionShape3D = interaction.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if ishape != null:
			ishape.disabled = true
