class_name RivalEncounterSession
extends RefCounted
## Transient rival encounter session (MODULE 06). Not persisted.

var rival_id: StringName = &""
var rival_definition: RivalDefinition = null
var initiator: GameTypes.RivalEncounterInitiator = GameTypes.RivalEncounterInitiator.PLAYER
var context: GameTypes.RivalEncounterContext = GameTypes.RivalEncounterContext.WORLD
var chosen_competition: GameTypes.CompetitionType = GameTypes.CompetitionType.SLAP
var has_chosen_competition: bool = false
var player_characteristic_level: int = 0
var rival_characteristic_level: int = 0
var phase: GameTypes.RivalEncounterPhase = GameTypes.RivalEncounterPhase.CREATED
var override_used: bool = false
var concession_used: bool = false
var outcome: GameTypes.RivalCompetitionOutcome = GameTypes.RivalCompetitionOutcome.PLAYER_WIN
var has_outcome: bool = false
var victory_grade: GameTypes.VictoryGrade = GameTypes.VictoryGrade.CLOSE
var authority_delta: int = 0
var heroic_defeat_triggered: bool = false
var return_control_mode: int = -1
