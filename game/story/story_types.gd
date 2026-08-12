class_name StoryTypes
extends RefCounted
## Story / stage enums and gate statuses (MODULE 11).


enum StageCompletionMode {
	GIRL_COMPLETED = 0,
	EXTERNAL_MILESTONE = 1,
	NONE = 2,
}

enum StoryFeature {
	SOCIAL_ACCESS = 0,
	PUBLIC_CITY_ACCESS = 1,
	SALARY_MINE = 2,
	MEDIA_ATTENTION = 3,
	LABORATORY = 4,
	WORLD_EXPANSION = 5,
	FINAL_DATE = 6,
	DAY_JOB = 7,
}

enum StoryGirlGate {
	NOT_STORY_GIRL = 0,
	AVAILABLE = 1,
	WRONG_STAGE = 2,
	RIVAL_REQUIRED = 3,
}

enum StoryRivalGate {
	NOT_STORY_RIVAL = 0,
	AVAILABLE = 1,
	WRONG_STAGE = 2,
	ALREADY_DEFEATED = 3,
}

enum ObjectiveState {
	LOCKED = 0,
	ACTIVE = 1,
	COMPLETE = 2,
}
