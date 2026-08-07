class_name CharacterAnimationController
extends Node
## Semantic animation presentation for CharacterActor (MODULE 04).
## Uses AnimationPlayer + AnimationLibrary aliases from AnimationProfileDefinition.

signal animation_finished(alias: StringName)

const LIB_PRIMARY: StringName = &"df"
const LIB_SEATED: StringName = &"df_seated"
const ALIAS_IDLE: StringName = &"idle"

const LOOP_ALIASES: Array[StringName] = [
	&"idle",
	&"walk",
	&"run",
	&"approach",
	&"sit_idle",
	&"seated_gesture",
]

var _player: AnimationPlayer = null
var _current_alias: StringName = &""
var _oneshot_alias: StringName = &""
var _locomotion_speed: float = 0.0
var _bound: bool = false


func _ready() -> void:
	set_process(false)


func bind_animation_player(player: AnimationPlayer) -> void:
	if _player != null and _player.animation_finished.is_connected(_on_animation_finished):
		_player.animation_finished.disconnect(_on_animation_finished)
	_player = player
	_current_alias = &""
	_oneshot_alias = &""
	_bound = _player != null
	if _player != null and not _player.animation_finished.is_connected(_on_animation_finished):
		_player.animation_finished.connect(_on_animation_finished)


func apply_animation_profile(profile: AnimationProfileDefinition) -> void:
	if _player == null or profile == null:
		return
	if _player.has_animation_library(LIB_PRIMARY):
		_player.remove_animation_library(LIB_PRIMARY)
	if _player.has_animation_library(LIB_SEATED):
		_player.remove_animation_library(LIB_SEATED)
	if profile.library != null:
		_player.add_animation_library(LIB_PRIMARY, profile.library)
	if profile.seated_library != null:
		_player.add_animation_library(LIB_SEATED, profile.seated_library)
	_current_alias = &""
	_oneshot_alias = &""


func has_animation(alias: StringName) -> bool:
	return _resolve_animation_name(alias) != &""


func play_loop(alias: StringName) -> bool:
	var anim_name: StringName = _resolve_animation_name(alias)
	if anim_name == &"":
		push_warning("[CharacterAnimationController] missing loop alias: %s" % String(alias))
		return false
	_oneshot_alias = &""
	_current_alias = alias
	_player.play(anim_name)
	return true


func play_once(alias: StringName) -> bool:
	var anim_name: StringName = _resolve_animation_name(alias)
	if anim_name == &"":
		push_warning("[CharacterAnimationController] missing oneshot alias: %s" % String(alias))
		return false
	_oneshot_alias = alias
	_current_alias = alias
	_player.play(anim_name)
	return true


func stop_or_return_to_idle() -> void:
	_oneshot_alias = &""
	if has_animation(ALIAS_IDLE):
		play_loop(ALIAS_IDLE)
	elif _player != null:
		_player.stop()
		_current_alias = &""


func get_current_animation_alias() -> StringName:
	return _current_alias


func set_locomotion_speed(speed: float) -> void:
	_locomotion_speed = maxf(speed, 0.0)
	if _oneshot_alias != &"":
		return
	var target: StringName = ALIAS_IDLE
	if _locomotion_speed >= 3.5 and has_animation(&"run"):
		target = &"run"
	elif _locomotion_speed >= 0.2 and has_animation(&"walk"):
		target = &"walk"
	elif has_animation(ALIAS_IDLE):
		target = ALIAS_IDLE
	else:
		return
	if _current_alias != target:
		play_loop(target)


func _resolve_animation_name(alias: StringName) -> StringName:
	if _player == null or alias == &"":
		return &""
	var primary: StringName = StringName("%s/%s" % [String(LIB_PRIMARY), String(alias)])
	if _player.has_animation(primary):
		return primary
	var seated: StringName = StringName("%s/%s" % [String(LIB_SEATED), String(alias)])
	if _player.has_animation(seated):
		return seated
	return &""


func _on_animation_finished(anim_name: StringName) -> void:
	if _oneshot_alias == &"":
		return
	var finished_alias: StringName = _oneshot_alias
	var expected: StringName = _resolve_animation_name(finished_alias)
	if expected != &"" and anim_name != expected:
		return
	_oneshot_alias = &""
	animation_finished.emit(finished_alias)
	if has_animation(ALIAS_IDLE):
		play_loop(ALIAS_IDLE)
