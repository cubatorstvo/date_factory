class_name DateTypes
extends RefCounted

enum DateMoveKind {
	BASE,
	UNLOCKABLE,
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

enum LocationPreferenceMode {
	NEUTRAL,
	THEMATIC,
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
		_:
			return "?"


static func knowledge_glyph(knowledge: TagKnowledge) -> String:
	match knowledge:
		TagKnowledge.POSITIVE:
			return "🟢"
		TagKnowledge.NEGATIVE:
			return "🔴"
		_:
			return "⚪"


static func knowledge_label(knowledge: TagKnowledge) -> String:
	match knowledge:
		TagKnowledge.POSITIVE:
			return "POSITIVE"
		TagKnowledge.NEGATIVE:
			return "NEGATIVE"
		_:
			return "UNKNOWN"
