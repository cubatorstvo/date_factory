class_name FirstCloneActor
extends Node3D
## Thin physical first-clone presentation (MODULE 17).
## No AI, navigation, stats, inventory, or dating logic.

var _character: CharacterActor = null


func _ready() -> void:
	if _character == null:
		ensure_character()


func get_character_actor() -> CharacterActor:
	return _character


func ensure_character() -> CharacterActor:
	if _character != null and is_instance_valid(_character):
		return _character
	var existing: CharacterActor = get_node_or_null("CharacterActor") as CharacterActor
	if existing != null:
		_character = existing
		return _character
	var profile_id: StringName = FirstCloneTypes.resolve_clone_appearance_id()
	_character = CharacterFactory.create(profile_id, &"first_clone", self)
	if _character != null:
		_character.name = "CharacterActor"
		_character.position = Vector3.ZERO
	return _character


func set_visible_presence(on: bool) -> void:
	visible = on
	if _character != null and is_instance_valid(_character):
		if _character.has_method("set_character_visible"):
			_character.call("set_character_visible", on)
		else:
			_character.visible = on
