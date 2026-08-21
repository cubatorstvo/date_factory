class_name DateRules
extends Resource

@export var opening_episode_count: int = 1
@export var core_episode_count: int = 3
@export var closing_episode_count: int = 1
@export var base_moves_per_episode: int = 3
@export var allow_situation_repeats: bool = false
@export var positive_move_score: int = 1
@export var negative_move_score: int = -1
@export var reveal_tag_after_use: bool = true
@export var combo_required_distinct_success_tags: int = 3
@export var combo_bonus_score: int = 1
@export var combo_max_rewards_per_date: int = 1
@export var apartment_unprepared_penalty: int = -1
@export var min_distinct_base_tags_per_situation: int = 6


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