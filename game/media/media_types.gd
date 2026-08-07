class_name MediaTypes
extends RefCounted
## Shared Media enums / errors (MODULE 15).


enum PublishError {
	OK = 0,
	LOCKED = 1,
	PHOTO_SESSION_REQUIRED = 2,
	UNKNOWN_PHOTO = 3,
	NOT_PREPARED = 4,
	ALREADY_PUBLISHED = 5,
	DAILY_LIMIT = 6,
}


enum SessionPhase {
	INTRO = 0,
	SHOT_1 = 1,
	SHOT_2 = 2,
	SHOT_3 = 3,
	RESULT = 4,
	FINISHED = 5,
}


enum PoseTier {
	BASE = 0,
	STAGED = 1,
	EDITORIAL = 2,
}
