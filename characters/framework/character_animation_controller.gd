class_name CharacterAnimationController
extends Node
## Semantic animation presentation for CharacterActor (MODULE 04 / 23).
## Uses AnimationPlayer + AnimationLibrary aliases from AnimationProfileDefinition.
## Optional semantic aliases remap to existing clips; never blocks gameplay.

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

## MODULE 23 semantic presentation aliases → concrete library clips (in order).
const SEMANTIC_FALLBACKS: Dictionary = {
	&"react_positive": [&"gesture", &"idle"],
	&"react_negative": [&"react", &"idle"],
	&"react_confused": [&"seated_gesture", &"gesture", &"idle"],
	&"victory": [&"gesture", &"idle"],
	&"defeat": [&"react", &"idle"],
	&"gesture_short": [&"gesture", &"idle"],
}

var _player: AnimationPlayer = null
var _current_alias: StringName = &""
var _oneshot_alias: StringName = &""
var _locomotion_speed: float = 0.0
var _bound: bool = false
var _missing_warned: Dictionary = {}


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
	return _resolve_playable_alias(alias) != &""


func play_loop(alias: StringName) -> bool:
	var resolved: StringName = _resolve_playable_alias(alias)
	if resolved == &"":
		_warn_missing_once(alias, "loop")
		return false
	var anim_name: StringName = _library_path_for(resolved)
	if anim_name == &"":
		_warn_missing_once(alias, "loop")
		return false
	_oneshot_alias = &""
	_current_alias = alias
	_player.play(anim_name)
	return true


func play_once(alias: StringName) -> bool:
	var resolved: StringName = _resolve_playable_alias(alias)
	if resolved == &"":
		_warn_missing_once(alias, "oneshot")
		return false
	var anim_name: StringName = _library_path_for(resolved)
	if anim_name == &"":
		_warn_missing_once(alias, "oneshot")
		return false
	_oneshot_alias = alias
	_current_alias = alias
	_player.play(anim_name)
	return true


## Play loop or oneshot based on resolved concrete alias. Safe no-op when missing.
func play_semantic(alias: StringName) -> bool:
	var resolved: StringName = _resolve_playable_alias(alias)
	if resolved == &"":
		return false
	if LOOP_ALIASES.has(resolved):
		return play_loop(alias)
	return play_once(alias)


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


func _resolve_playable_alias(alias: StringName) -> StringName:
	if _player == null or alias == &"":
		return &""
	if _library_path_for(alias) != &"":
		return alias
	var chain: Variant = SEMANTIC_FALLBACKS.get(alias, null)
	if chain is Array:
		for candidate_variant in chain as Array:
			var candidate: StringName = candidate_variant as StringName
			if candidate == &"":
				continue
			if _library_path_for(candidate) != &"":
				return candidate
		# Known semantic alias with no clips: soft-idle if available.
		if _library_path_for(ALIAS_IDLE) != &"":
			return ALIAS_IDLE
		return &""
	return &""


func _library_path_for(alias: StringName) -> StringName:
	if _player == null or alias == &"":
		return &""
	var primary: StringName = StringName("%s/%s" % [String(LIB_PRIMARY), String(alias)])
	if _player.has_animation(primary):
		return primary
	var seated: StringName = StringName("%s/%s" % [String(LIB_SEATED), String(alias)])
	if _player.has_animation(seated):
		return seated
	return &""


func _resolve_animation_name(alias: StringName) -> StringName:
	var resolved: StringName = _resolve_playable_alias(alias)
	if resolved == &"":
		return &""
	return _library_path_for(resolved)


func _warn_missing_once(alias: StringName, kind: String) -> void:
	var key: String = "%s:%s" % [kind, String(alias)]
	if _missing_warned.has(key):
		return
	_missing_warned[key] = true
	# Optional semantic aliases stay quiet; unknown concrete aliases warn once.
	if SEMANTIC_FALLBACKS.has(alias):
		return
	push_warning("[CharacterAnimationController] missing %s alias: %s" % [kind, String(alias)])


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
