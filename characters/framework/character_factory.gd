class_name CharacterFactory
extends RefCounted
## Static helpers for spawning CharacterActor instances (MODULE 04). Not an autoload.

const ACTOR_SCENE_PATH: String = "res://characters/framework/character_actor.tscn"


static func create(
	appearance_profile_id: StringName,
	content_id: StringName = &"",
	parent: Node = null
) -> CharacterActor:
	var packed: PackedScene = load(ACTOR_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("[CharacterFactory] failed to load %s" % ACTOR_SCENE_PATH)
		return null
	var actor: CharacterActor = packed.instantiate() as CharacterActor
	if actor == null:
		push_error("[CharacterFactory] character_actor.tscn root is not CharacterActor")
		return null
	if content_id != &"":
		actor.content_id = content_id
	if parent != null:
		parent.add_child(actor)
	var applied: bool = actor.apply_appearance(appearance_profile_id)
	if not applied:
		push_warning(
			"[CharacterFactory] apply_appearance failed for %s" % String(appearance_profile_id)
		)
	return actor
