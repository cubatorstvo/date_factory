extends CharacterBody3D
## Runtime humanoid animation binder with deterministic Skeleton3D sampling.


signal alias_finished(alias: StringName)

@export var alias_library: AnimationLibrary
@export var library_name: StringName = &"df_aliases"
@export var autoplay_alias: StringName = &"idle"
@export var label_text: String = ""

var _ap: AnimationPlayer
var _skeleton: Skeleton3D
var _current_alias: String = ""
var _current_animation: Animation
var _animation_time: float = 0.0
var _is_seated: bool = false


func _ready() -> void:
	_ap = _ensure_animation_player()
	_skeleton = _find_skeleton(self)
	if alias_library != null and not _ap.has_animation_library(library_name):
		_ap.add_animation_library(library_name, alias_library)
	if String(autoplay_alias) != "" and has_alias(String(autoplay_alias)):
		play_alias(String(autoplay_alias))


func _process(delta: float) -> void:
	if not is_instance_valid(_skeleton) or _current_animation == null:
		return
	_animation_time += delta
	var sample_time := minf(_animation_time, _current_animation.length)
	_apply_pose(_current_animation, sample_time)
	if _current_animation.loop_mode != Animation.LOOP_NONE:
		if _current_animation.length > 0.0 and _animation_time >= _current_animation.length:
			_animation_time = fmod(_animation_time, _current_animation.length)
		return
	if _animation_time < _current_animation.length:
		return
	var finished_alias := _current_alias
	_current_animation = null
	alias_finished.emit(StringName(finished_alias))
	if finished_alias == "sit" or finished_alias == "sit_enter":
		_is_seated = true
		if has_alias("sit_idle"):
			play_alias("sit_idle")
	elif finished_alias == "stand" or finished_alias == "sit_exit":
		_is_seated = false
		if has_alias("idle"):
			play_alias("idle")
	elif finished_alias == "gesture" or finished_alias == "react":
		play_alias("sit_idle" if _is_seated and has_alias("sit_idle") else "idle")


func has_alias(alias: String) -> bool:
	if alias_library != null and alias_library.has_animation(StringName(alias)):
		return true
	if not is_instance_valid(_ap):
		return false
	return _ap.has_animation(_lib_key(alias))


func list_aliases() -> PackedStringArray:
	var out: PackedStringArray = []
	for alias in [
		"idle",
		"walk",
		"run",
		"approach",
		"turn",
		"sit",
		"sit_enter",
		"sit_idle",
		"seated_gesture",
		"stand",
		"sit_exit",
		"gesture",
		"react",
	]:
		if has_alias(alias):
			out.append(alias)
	return out


func play_alias(alias: String) -> bool:
	var animation := _get_animation(alias)
	if animation == null or not is_instance_valid(_skeleton):
		return false
	_current_alias = alias
	_current_animation = animation
	_animation_time = 0.0
	if alias in ["sit", "sit_enter", "sit_idle", "seated_gesture"]:
		_is_seated = true
	elif alias in ["stand", "sit_exit", "idle", "walk", "run", "approach"]:
		_is_seated = false
	_apply_pose(_current_animation, 0.0)
	return true


func get_alias_length(alias: String) -> float:
	var animation := _get_animation(alias)
	return animation.length if animation != null else 0.0


func get_current_alias() -> String:
	return _current_alias


func get_display_name() -> String:
	if label_text != "":
		return label_text
	return name


func is_seated() -> bool:
	return _is_seated


func _get_animation(alias: String) -> Animation:
	if alias_library != null and alias_library.has_animation(StringName(alias)):
		return alias_library.get_animation(StringName(alias))
	if is_instance_valid(_ap) and _ap.has_animation(_lib_key(alias)):
		return _ap.get_animation(_lib_key(alias))
	return null


func _apply_pose(animation: Animation, sample_time: float) -> void:
	for track_index in animation.get_track_count():
		if not animation.track_is_enabled(track_index):
			continue
		var track_path := String(animation.track_get_path(track_index))
		if not track_path.contains(":"):
			continue
		var bone_name := track_path.get_slice(":", 1)
		var bone_index := _skeleton.find_bone(bone_name)
		if bone_index < 0:
			continue
		match animation.track_get_type(track_index):
			Animation.TYPE_POSITION_3D:
				_skeleton.set_bone_pose_position(
					bone_index,
					animation.position_track_interpolate(track_index, sample_time)
				)
			Animation.TYPE_ROTATION_3D:
				_skeleton.set_bone_pose_rotation(
					bone_index,
					animation.rotation_track_interpolate(track_index, sample_time)
				)
			Animation.TYPE_SCALE_3D:
				_skeleton.set_bone_pose_scale(
					bone_index,
					animation.scale_track_interpolate(track_index, sample_time)
				)


func _lib_key(alias: String) -> StringName:
	return StringName("%s/%s" % [String(library_name), alias])


func _ensure_animation_player() -> AnimationPlayer:
	var visual := get_node_or_null("Visual") as Node
	if visual != null:
		var existing := visual.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if existing != null:
			return existing
		var created := AnimationPlayer.new()
		created.name = "AnimationPlayer"
		visual.add_child(created)
		return created
	var root_player := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if root_player != null:
		return root_player
	var fallback := AnimationPlayer.new()
	fallback.name = "AnimationPlayer"
	add_child(fallback)
	return fallback


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null
