class_name DateTypes
extends RefCounted

enum DateMoveKind {
	BASE,
	CHARACTERISTIC,
	LOCAL,
	OUTFIT,
}

enum DateMoveSource {
	CHARACTERISTIC,
	OUTFIT,
	VENUE,
}

enum DateMoveSourceState {
	POSITIVE,
	UNKNOWN,
	NEGATIVE,
	BLOCKED,
	USED,
}

enum DatePhase {
	OPENING,
	CORE,
	CLOSING,
}

enum TagKnowledge {
	UNKNOWN,
	POSITIVE,
	NEGATIVE,
}

enum ValidationSeverity {
	ERROR,
	WARNING,
}

enum MoveAvailability {
	AVAILABLE,
	LOCKED,
	USED,
}

const CHARACTERISTIC_STAT_ORDER: Array[StringName] = [&"muscle", &"appearance", &"capital", &"aura"]
const CHARACTERISTIC_LEVELS: Array[int] = [1, 3, 5]


static func phase_name(phase: DatePhase) -> String:
	match phase:
		DatePhase.OPENING:
			return "OPENING"
		DatePhase.CORE:
			return "CORE"
		DatePhase.CLOSING:
			return "CLOSING"
		_:
			return "?"


static func move_kind_name(kind: DateMoveKind) -> String:
	match kind:
		DateMoveKind.BASE:
			return "BASE"
		DateMoveKind.CHARACTERISTIC:
			return "CHARACTERISTIC"
		DateMoveKind.LOCAL:
			return "LOCAL"
		DateMoveKind.OUTFIT:
			return "OUTFIT"
		_:
			return "?"


static func source_name(source: DateMoveSource) -> String:
	match source:
		DateMoveSource.CHARACTERISTIC:
			return "Характеристика"
		DateMoveSource.OUTFIT:
			return "Одежда"
		DateMoveSource.VENUE:
			return "Место свидания"
		_:
			return "?"


static func source_state_name(state: DateMoveSourceState) -> String:
	match state:
		DateMoveSourceState.POSITIVE:
			return "POSITIVE"
		DateMoveSourceState.UNKNOWN:
			return "UNKNOWN"
		DateMoveSourceState.NEGATIVE:
			return "NEGATIVE"
		DateMoveSourceState.USED:
			return "USED"
		_:
			return "BLOCKED"


static func knowledge_label(knowledge: TagKnowledge) -> String:
	match knowledge:
		TagKnowledge.POSITIVE:
			return "POSITIVE"
		TagKnowledge.NEGATIVE:
			return "NEGATIVE"
		_:
			return "UNKNOWN"


static func availability_name(state: MoveAvailability) -> String:
	match state:
		MoveAvailability.LOCKED:
			return "LOCKED"
		MoveAvailability.USED:
			return "USED"
		_:
			return "AVAILABLE"


static func effective_stat(base_stat: int, outfit: Outfit, stat_id: StringName) -> int:
	var bonus: int = 0
	if outfit != null:
		bonus = outfit.bonus_for(stat_id)
	return mini(maxi(base_stat, 0) + bonus, 5)


static func characteristic_sort_key(move: DateMove) -> int:
	if move == null or move.unlock_requirement == null:
		return 999
	var stat_index: int = CHARACTERISTIC_STAT_ORDER.find(move.unlock_requirement.stat_id)
	if stat_index < 0:
		stat_index = 9
	var level_index: int = CHARACTERISTIC_LEVELS.find(move.unlock_requirement.required_level)
	if level_index < 0:
		level_index = 9
	return stat_index * 10 + level_index
