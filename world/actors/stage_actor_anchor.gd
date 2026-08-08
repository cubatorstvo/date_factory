class_name StageActorAnchor
extends Marker3D
## Spawns GirlActor/RivalActor when story stage matches (MODULE 14A glue).
## No polling. Listens to stage/encounter signals only.

enum ActorKind {
	GIRL,
	RIVAL,
}

const GIRL_ACTOR_SCENE: String = "res://game/girls/girl_actor.tscn"
const RIVAL_ACTOR_SCENE: String = "res://game/rivals/rival_actor.tscn"

@export var actor_kind: ActorKind = ActorKind.GIRL
@export var content_id: StringName = &""
@export var story_stage: GameTypes.GameStage = GameTypes.GameStage.PROLOGUE
@export var requires_overload_recognized: bool = false

var _spawned: Node3D = null


func _ready() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_signal("stage_changed") and not gs.is_connected("stage_changed", _on_stage_changed):
			gs.connect("stage_changed", _on_stage_changed)
		if gs.has_signal("state_reset") and not gs.is_connected("state_reset", _on_state_reset):
			gs.connect("state_reset", _on_state_reset)
	var story: Node = get_node_or_null("/root/Story")
	if story != null and story.has_signal("stage_started"):
		if not story.is_connected("stage_started", _on_story_stage_started):
			story.connect("stage_started", _on_story_stage_started)
	var encounters: Node = get_node_or_null("/root/RivalEncounters")
	if encounters != null and encounters.has_signal("encounter_won"):
		if not encounters.is_connected("encounter_won", _on_encounter_won):
			encounters.connect("encounter_won", _on_encounter_won)
	var overload: Node = get_node_or_null("/root/DatingOverload")
	if overload != null and overload.has_signal("problem_recognized"):
		if not overload.is_connected("problem_recognized", _on_problem_recognized):
			overload.connect("problem_recognized", _on_problem_recognized)
	_refresh_spawn()


func _on_state_reset() -> void:
	_refresh_spawn()


func _on_problem_recognized() -> void:
	_refresh_spawn()


func _on_stage_changed(_new_stage: GameTypes.GameStage, _previous_stage: GameTypes.GameStage) -> void:
	_refresh_spawn()


func _on_story_stage_started(_new_stage: GameTypes.GameStage) -> void:
	_refresh_spawn()


func _on_encounter_won(result: RivalEncounterResult) -> void:
	if result == null:
		return
	if actor_kind != ActorKind.RIVAL:
		return
	if result.rival_id != content_id:
		return
	# RivalActor owns short departure then queue_free; do not free here.
	if _spawned != null and is_instance_valid(_spawned):
		if not _spawned.tree_exited.is_connected(_on_spawned_tree_exited):
			_spawned.tree_exited.connect(_on_spawned_tree_exited)
	else:
		_spawned = null


func _on_spawned_tree_exited() -> void:
	_spawned = null


func _refresh_spawn() -> void:
	if _should_spawn():
		_ensure_spawned()
	else:
		_clear_spawned()


func _should_spawn() -> bool:
	if String(content_id) == "":
		return false
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	var current: GameTypes.GameStage = gs.call("get_stage") as GameTypes.GameStage
	if current != story_stage:
		return false
	if actor_kind == ActorKind.RIVAL:
		if bool(gs.call("is_rival_defeated", content_id)):
			return false
	if requires_overload_recognized:
		var overload: Node = get_node_or_null("/root/DatingOverload")
		if overload == null or not overload.has_method("is_problem_recognized"):
			return false
		if not bool(overload.call("is_problem_recognized")):
			return false
	return true


func _ensure_spawned() -> void:
	if _spawned != null and is_instance_valid(_spawned):
		return
	var inst: Node = _instantiate_actor()
	if inst == null:
		push_error("[StageActorAnchor] failed to spawn %s" % String(content_id))
		return
	if actor_kind == ActorKind.GIRL:
		if inst is GirlActor:
			(inst as GirlActor).girl_id = content_id
		else:
			inst.set("girl_id", content_id)
	else:
		if inst is RivalActor:
			(inst as RivalActor).rival_id = content_id
		else:
			inst.set("rival_id", content_id)
	inst.name = "Spawned_%s" % String(content_id)
	add_child(inst)
	if inst is Node3D:
		(inst as Node3D).transform = Transform3D.IDENTITY
	_spawned = inst as Node3D


func _clear_spawned() -> void:
	if _spawned != null and is_instance_valid(_spawned):
		_spawned.queue_free()
	_spawned = null


func _instantiate_actor() -> Node:
	var path: String = GIRL_ACTOR_SCENE if actor_kind == ActorKind.GIRL else RIVAL_ACTOR_SCENE
	if ResourceLoader.exists(path):
		var packed: PackedScene = load(path) as PackedScene
		if packed != null:
			return packed.instantiate()
	# Prefab missing: construct class instance directly.
	if actor_kind == ActorKind.GIRL:
		return GirlActor.new()
	return RivalActor.new()
