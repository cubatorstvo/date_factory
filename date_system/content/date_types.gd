class_name DateTypes
extends RefCounted

enum DateMoveKind {
	BASE,
	UNLOCKABLE,
	LOCAL,
}

enum DatePhase {
	OPENING,
	CORE,
	CLOSING,
}

enum SecondaryConditionType {
	DISTINCT_SUCCESS_TAGS,
	NO_FAILURES,
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
		DateMoveKind.UNLOCKABLE:
			return "UNLOCKABLE"
		DateMoveKind.LOCAL:
			return "LOCAL"
		_:
			return "?"


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
