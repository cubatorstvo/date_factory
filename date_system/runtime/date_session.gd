class_name DateSession
extends Resource

enum Stage {
	IDLE,
	AWAITING_MOVE,
	SHOWING_EPISODE_RESULT,
	SHOWING_DATE_RESULT,
	COMPLETED,
	ABORTED,
}

@export var session_id: String = ""
@export var seed: int = 0
@export var girl_id: StringName = &""
@export var location_id: StringName = &""
@export var outfit_id: StringName = &""
@export var local_object_ids: Array[StringName] = []
@export var used_local_object_ids: Array[StringName] = []
@export var relationship_before: int = 0
@export var relationship_max: int = 0
@export var girl_trait_applied: bool = false
@export var selected_situation_ids: Array[StringName] = []
@export var current_phase: DateTypes.DatePhase = DateTypes.DatePhase.OPENING
@export var current_episode_index: int = 0
@export var current_candidate_base_move_ids: Array[StringName] = []
@export var current_selected_base_move_ids: Array[StringName] = []
@export var current_selected_base_tag_ids: Array[StringName] = []
@export var current_applicable_unlockable_move_ids: Array[StringName] = []
@export var current_available_unlockable_move_ids: Array[StringName] = []
@export var current_locked_unlockable_move_ids: Array[StringName] = []
@export var current_used_unlockable_move_ids: Array[StringName] = []
@export var current_reserved_unlockable_tag_ids: Array[StringName] = []
@export var current_preferred_base_move_ids: Array[StringName] = []
@export var current_fallback_base_move_ids: Array[StringName] = []
@export var used_unlockable_move_counts: Dictionary = {}
@export var episode_history: Array[DateEpisodeResult] = []
@export var revealed_tags_during_session: Array[StringName] = []
@export var combo_distinct_success_tag_ids: Array[StringName] = []
@export var combo_achieved: bool = false
@export var combo_rewards_earned: int = 0
@export var score_breakdown: DateScoreBreakdown
@export var relationship_after: int = 0
@export var completed: bool = false
@export var stage: Stage = Stage.IDLE
@export var current_selected_move_id: StringName = &""
@export var current_resolved_tag_id: StringName = &""
@export var current_tag_preference: int = 0
@export var current_score_delta: int = 0
@export var current_result_text: String = ""
