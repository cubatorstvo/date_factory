class_name WorldTypes
extends RefCounted
## World access / travel enums (MODULE 12).


enum WorldAccessStatus {
	AVAILABLE = 0,
	LOCKED_STORY = 1,
	UNKNOWN_LOCATION = 2,
	SCENE_MISSING = 3,
}


enum WorldTravelResult {
	SUCCESS = 0,
	LOCKED = 1,
	UNKNOWN_LOCATION = 2,
	SCENE_MISSING = 3,
	SPAWN_MISSING = 4,
	BUSY = 5,
	NO_PLAYER = 6,
	LOAD_FAILED = 7,
}
