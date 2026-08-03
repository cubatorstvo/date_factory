extends CharacterBody3D
## Technical animation binder for art prefabs — aliases idle/walk/run/sit/stand/gesture/react.


@export var alias_library: AnimationLibrary
@export var library_name: StringName = &"df_aliases"
@export var autoplay_alias: StringName = &"idle"
@export var label_text: String = ""

var _ap: AnimationPlayer
var _current_alias: String = ""


func _ready() -> void:
	_ap = _ensure_animation_player()
	if alias_library != null and not _ap.has_animation_library(library_name):
		_ap.add_animation_library(library_name, alias_library)
	if String(autoplay_alias) != "" and has_alias(String(autoplay_alias)):
		play_alias(String(autoplay_alias))


func has_alias(alias: String) -> bool:
	if _ap == null:
		return false
	return _ap.has_animation(_lib_key(alias))


func list_aliases() -> PackedStringArray:
	var out: PackedStringArray = []
	for a in ["idle", "walk", "run", "sit", "stand", "gesture", "react"]:
		if has_alias(a):
			out.append(a)
	return out


func play_alias(alias: String) -> bool:
	if _ap == null or not has_alias(alias):
		return false
	_current_alias = alias
	_ap.play(_lib_key(alias))
	return true


func get_current_alias() -> String:
	return _current_alias


func get_display_name() -> String:
	if label_text != "":
		return label_text
	return name


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
	var root_ap := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if root_ap != null:
		return root_ap
	var fallback := AnimationPlayer.new()
	fallback.name = "AnimationPlayer"
	add_child(fallback)
	return fallback
