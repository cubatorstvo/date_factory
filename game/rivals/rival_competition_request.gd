class_name RivalCompetitionRequest
extends RefCounted
## Typed request handed to future MODULE 07 minigames (MODULE 06).

var rival_id: StringName = &""
var competition_type: GameTypes.CompetitionType = GameTypes.CompetitionType.SLAP
var player_level: int = 0
var rival_level: int = 0
var initiator: GameTypes.RivalEncounterInitiator = GameTypes.RivalEncounterInitiator.PLAYER
var context: GameTypes.RivalEncounterContext = GameTypes.RivalEncounterContext.WORLD
