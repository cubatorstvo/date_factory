class_name DateRules
extends Resource

@export var opening_episode_count: int = 1
@export var core_episode_count: int = 3
@export var closing_episode_count: int = 1
@export var base_moves_per_episode: int = 3
@export var allow_situation_repeats: bool = false
@export var show_locked_unlockable_moves: bool = true
@export var opening_choice_score: int = 0
@export var core_positive_score: int = 1
@export var core_negative_score: int = -1
@export var closing_positive_score: int = 1
@export var closing_negative_score: int = -1
@export var reveal_tag_after_use: bool = true
@export var reveal_secondary_after_first_completed_date: bool = true
@export var secondary_counted_phases: Array[int] = [int(DateTypes.DatePhase.CORE)]
@export var location_preference_success: int = 1
@export var location_preference_failure: int = -1
@export var apartment_unprepared_penalty: int = -1
@export var apartment_quality_min: int = 0
@export var apartment_quality_max: int = 3


func total_episode_count() -> int:
	return opening_episode_count + core_episode_count + closing_episode_count


func phase_for_episode_index(episode_index: int) -> DateTypes.DatePhase:
	if episode_index < opening_episode_count:
		return DateTypes.DatePhase.OPENING
	if episode_index < opening_episode_count + core_episode_count:
		return DateTypes.DatePhase.CORE
	return DateTypes.DatePhase.CLOSING


func index_in_phase(episode_index: int) -> int:
	if episode_index < opening_episode_count:
		return episode_index
	if episode_index < opening_episode_count + core_episode_count:
		return episode_index - opening_episode_count
	return episode_index - opening_episode_count - core_episode_count
