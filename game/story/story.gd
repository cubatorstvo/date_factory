extends Node
## Lightweight Story / Stage Framework (MODULE 11).
## Autoload name: Story. Persistent stage lives in GameState.
## Event-driven — no _process. Does not grant XP/money/authority/locations.

signal stage_completed(completed_stage: GameTypes.GameStage)
signal stage_started(new_stage: GameTypes.GameStage)
signal stage_objective_changed(progress: StoryStageProgress)
signal feature_unlocked(feature: StoryTypes.StoryFeature)

var _advancing: bool = false
var _signals_connected: bool = false


func _ready() -> void:
	_connect_signals()
	stage_objective_changed.emit(get_current_progress())
	DfLog.info("MODULE_11", "Story ready")


func _connect_signals() -> void:
	if _signals_connected:
		return
	var rel: Node = get_node_or_null("/root/Relationships")
	if rel != null and rel.has_signal("girl_completed"):
		if not rel.is_connected("girl_completed", _on_girl_completed):
			rel.connect("girl_completed", _on_girl_completed)
	var rivals: Node = get_node_or_null("/root/RivalEncounters")
	if rivals != null and rivals.has_signal("encounter_won"):
		if not rivals.is_connected("encounter_won", _on_encounter_won):
			rivals.connect("encounter_won", _on_encounter_won)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_signal("state_reset") and not gs.is_connected("state_reset", _on_state_reset):
			gs.connect("state_reset", _on_state_reset)
		if gs.has_signal("stage_changed") and not gs.is_connected("stage_changed", _on_stage_changed):
			gs.connect("stage_changed", _on_stage_changed)
	_signals_connected = true


func get_current_definition() -> StoryStageDefinition:
	var db: Node = get_node_or_null("/root/ContentDB")
	var gs: Node = get_node_or_null("/root/GameState")
	if db == null or gs == null:
		return null
	var stage: GameTypes.GameStage = gs.call("get_stage") as GameTypes.GameStage
	return db.call("get_stage", stage) as StoryStageDefinition


func get_current_progress() -> StoryStageProgress:
	var progress: StoryStageProgress = StoryStageProgress.new()
	var def: StoryStageDefinition = get_current_definition()
	var gs: Node = get_node_or_null("/root/GameState")
	if def == null or gs == null:
		return progress
	progress.stage = def.stage
	progress.display_name = def.display_name
	progress.story_girl_id = def.story_girl_id
	progress.story_rival_id = def.story_rival_id
	progress.rival_required = def.requires_story_rival
	progress.completion_mode = def.completion_mode
	if String(def.story_rival_id) != "":
		progress.rival_defeated = bool(gs.call("is_rival_defeated", def.story_rival_id))
	else:
		progress.rival_defeated = not def.requires_story_rival
	if String(def.story_girl_id) != "":
		progress.girl_completed = bool(gs.call("is_girl_conquered", def.story_girl_id))
	else:
		progress.girl_completed = false
	progress.external_milestone_complete = bool(
		gs.call("get_story_flag", StoryIds.FLAG_WORLD_EXPANSION_COMPLETE)
	)
	progress.is_complete = _is_definition_complete(def)
	return progress


func reconcile_current_stage() -> bool:
	return _try_complete_current_stage()


func complete_world_expansion() -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	var stage: GameTypes.GameStage = gs.call("get_stage") as GameTypes.GameStage
	if stage != GameTypes.GameStage.STAGE_6:
		return false
	if not bool(gs.call("get_story_flag", StoryIds.FLAG_WORLD_EXPANSION_COMPLETE)):
		gs.call("set_story_flag", StoryIds.FLAG_WORLD_EXPANSION_COMPLETE, true)
	return _try_complete_current_stage()


func is_feature_unlocked(feature: StoryTypes.StoryFeature) -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	var stage: int = int(gs.call("get_stage"))
	return stage >= int(get_feature_unlock_stage(feature))


func get_feature_unlock_stage(feature: StoryTypes.StoryFeature) -> GameTypes.GameStage:
	match feature:
		StoryTypes.StoryFeature.SOCIAL_ACCESS:
			return GameTypes.GameStage.STAGE_1
		StoryTypes.StoryFeature.PUBLIC_CITY_ACCESS:
			return GameTypes.GameStage.STAGE_2
		StoryTypes.StoryFeature.SALARY_MINE:
			return GameTypes.GameStage.STAGE_3
		StoryTypes.StoryFeature.MEDIA_ATTENTION:
			return GameTypes.GameStage.STAGE_4
		StoryTypes.StoryFeature.LABORATORY:
			return GameTypes.GameStage.STAGE_5
		StoryTypes.StoryFeature.WORLD_EXPANSION:
			return GameTypes.GameStage.STAGE_6
		StoryTypes.StoryFeature.FINAL_DATE:
			return GameTypes.GameStage.FINALE
	return GameTypes.GameStage.FINALE


func get_story_girl_gate(girl_id: StringName) -> StoryTypes.StoryGirlGate:
	if not StoryIds.is_story_girl(girl_id):
		return StoryTypes.StoryGirlGate.NOT_STORY_GIRL
	var def: StoryStageDefinition = get_current_definition()
	if def == null:
		return StoryTypes.StoryGirlGate.WRONG_STAGE
	if girl_id != def.story_girl_id:
		return StoryTypes.StoryGirlGate.WRONG_STAGE
	if def.requires_story_rival:
		var gs: Node = get_node_or_null("/root/GameState")
		if gs == null:
			return StoryTypes.StoryGirlGate.RIVAL_REQUIRED
		if String(def.story_rival_id) == "" or not bool(gs.call("is_rival_defeated", def.story_rival_id)):
			return StoryTypes.StoryGirlGate.RIVAL_REQUIRED
	return StoryTypes.StoryGirlGate.AVAILABLE


func get_story_rival_gate(rival_id: StringName) -> StoryTypes.StoryRivalGate:
	if not StoryIds.is_story_rival(rival_id):
		return StoryTypes.StoryRivalGate.NOT_STORY_RIVAL
	var def: StoryStageDefinition = get_current_definition()
	if def == null:
		return StoryTypes.StoryRivalGate.WRONG_STAGE
	if rival_id != def.story_rival_id:
		return StoryTypes.StoryRivalGate.WRONG_STAGE
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and bool(gs.call("is_rival_defeated", rival_id)):
		return StoryTypes.StoryRivalGate.ALREADY_DEFEATED
	return StoryTypes.StoryRivalGate.AVAILABLE


func should_story_girl_be_present(girl_id: StringName) -> bool:
	if not StoryIds.is_story_girl(girl_id):
		return false
	var def: StoryStageDefinition = get_current_definition()
	if def == null:
		return false
	return def.story_girl_id == girl_id


func should_story_rival_be_present(rival_id: StringName) -> bool:
	if not StoryIds.is_story_rival(rival_id):
		return false
	var def: StoryStageDefinition = get_current_definition()
	if def == null:
		return false
	if def.story_rival_id != rival_id:
		return false
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	return not bool(gs.call("is_rival_defeated", rival_id))


func get_girl_gate_message(gate: StoryTypes.StoryGirlGate) -> String:
	match gate:
		StoryTypes.StoryGirlGate.RIVAL_REQUIRED:
			return "Сначала разберись с её текущим ухажёром."
		StoryTypes.StoryGirlGate.WRONG_STAGE:
			return "Эта линия пока недоступна."
	return ""


func _on_girl_completed(girl_id: StringName, _result: RelationshipDateResult) -> void:
	var def: StoryStageDefinition = get_current_definition()
	if def == null:
		return
	if girl_id != def.story_girl_id:
		return
	_try_complete_current_stage()


func _on_encounter_won(result: RivalEncounterResult) -> void:
	if result == null:
		return
	var def: StoryStageDefinition = get_current_definition()
	if def == null:
		return
	if result.rival_id != def.story_rival_id:
		return
	_try_complete_current_stage()


func _on_state_reset() -> void:
	stage_objective_changed.emit(get_current_progress())


func _on_stage_changed(_new_stage: GameTypes.GameStage, _previous_stage: GameTypes.GameStage) -> void:
	if _advancing:
		# Gameplay advance emits started/objective after advance_stage returns (spec §14).
		return
	# restore_stage / non-gameplay path: refresh only, no replay.
	stage_objective_changed.emit(get_current_progress())


func _try_complete_current_stage() -> bool:
	if _advancing:
		return false
	var def: StoryStageDefinition = get_current_definition()
	if def == null:
		return false
	if not _is_definition_complete(def):
		stage_objective_changed.emit(get_current_progress())
		return false
	if def.completion_mode == StoryTypes.StageCompletionMode.NONE:
		stage_objective_changed.emit(get_current_progress())
		return false
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	var current: GameTypes.GameStage = gs.call("get_stage") as GameTypes.GameStage
	var next_stage: GameTypes.GameStage = def.next_stage
	if next_stage == current:
		stage_objective_changed.emit(get_current_progress())
		return false
	_advancing = true
	stage_completed.emit(current)
	var ok: bool = bool(gs.call("advance_stage", next_stage))
	if ok:
		stage_started.emit(next_stage)
		_emit_newly_unlocked_features(current, next_stage)
		stage_objective_changed.emit(get_current_progress())
	_advancing = false
	if not ok:
		stage_objective_changed.emit(get_current_progress())
		return false
	return true


func _is_definition_complete(def: StoryStageDefinition) -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null or def == null:
		return false
	match def.completion_mode:
		StoryTypes.StageCompletionMode.NONE:
			return false
		StoryTypes.StageCompletionMode.EXTERNAL_MILESTONE:
			return bool(gs.call("get_story_flag", StoryIds.FLAG_WORLD_EXPANSION_COMPLETE))
		StoryTypes.StageCompletionMode.GIRL_COMPLETED:
			if String(def.story_girl_id) == "":
				return false
			if not bool(gs.call("is_girl_conquered", def.story_girl_id)):
				return false
			if def.requires_story_rival:
				if String(def.story_rival_id) == "":
					return false
				if not bool(gs.call("is_rival_defeated", def.story_rival_id)):
					return false
			return true
	return false


func _emit_newly_unlocked_features(
	previous_stage: GameTypes.GameStage,
	new_stage: GameTypes.GameStage,
) -> void:
	var features: Array[StoryTypes.StoryFeature] = [
		StoryTypes.StoryFeature.SOCIAL_ACCESS,
		StoryTypes.StoryFeature.PUBLIC_CITY_ACCESS,
		StoryTypes.StoryFeature.SALARY_MINE,
		StoryTypes.StoryFeature.MEDIA_ATTENTION,
		StoryTypes.StoryFeature.LABORATORY,
		StoryTypes.StoryFeature.WORLD_EXPANSION,
		StoryTypes.StoryFeature.FINAL_DATE,
	]
	var prev_i: int = int(previous_stage)
	var next_i: int = int(new_stage)
	for feature in features:
		var unlock_i: int = int(get_feature_unlock_stage(feature))
		if prev_i < unlock_i and next_i >= unlock_i:
			feature_unlocked.emit(feature)
