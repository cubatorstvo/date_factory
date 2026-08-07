class_name GameTypes
extends RefCounted
## Canonical shared enums for Date Factory v2 (MODULE 03).
## Single ownership — do not redefine these in GameState or definitions.


enum PlayerCharacteristic {
	MUSCLE,
	APPEARANCE,
	CAPITAL,
	AURA,
}


enum GameStage {
	PROLOGUE = 0,
	STAGE_1 = 1,
	STAGE_2 = 2,
	STAGE_3 = 3,
	STAGE_4 = 4,
	STAGE_5 = 5,
	STAGE_6 = 6,
	FINALE = 7,
}


enum ActionTag {
	CARE,
	VULNERABILITY,
	SIMPLICITY,
	PRESTIGE,
	CONTROL,
	DOMINANCE,
	RISK,
	CONFLICT,
	SPONTANEITY,
	ABSURDITY,
	ORIGINALITY,
	OBSESSION,
}


enum PrimaryGirlTrait {
	KIND,
	STATUS,
	THRILL_SEEKING,
	STRANGE,
}


enum SecondaryGirlTrait {
	SCANDALOUS,
	CONSISTENT,
	VARIETY_SEEKING,
	DEMANDING,
}


enum DatingEventCategory {
	CONVERSATION,
	SPACE_EVENT,
	GIRL_PROPOSAL,
}


enum CompetitionType {
	SLAP,
	DANCE,
	MONEY,
	SIGMA,
}


enum PerkSection {
	EARLY_COMMON,
	BRANCH_A,
	BRANCH_B,
	LATE_COMMON,
}


enum CharacterBodyType {
	MALE,
	FEMALE,
}


enum RivalEncounterInitiator {
	PLAYER,
	RIVAL,
}


enum RivalEncounterPhase {
	CREATED,
	CHOOSING,
	READY,
	RUNNING,
	RESOLVING,
	FINISHED,
}


enum RivalCompetitionOutcome {
	PLAYER_WIN,
	PLAYER_LOSS,
}


enum VictoryGrade {
	CLOSE,
	CRUSHING,
}


enum RivalEncounterContext {
	WORLD,
	DATE,
	STORY,
}
