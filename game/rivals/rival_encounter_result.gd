class_name RivalEncounterResult
extends RefCounted
## Final resolved encounter result for presentation / Dating (MODULE 06).

var rival_id: StringName = &""
var outcome: GameTypes.RivalCompetitionOutcome = GameTypes.RivalCompetitionOutcome.PLAYER_WIN
var victory_grade: GameTypes.VictoryGrade = GameTypes.VictoryGrade.CLOSE
var competition_type: GameTypes.CompetitionType = GameTypes.CompetitionType.SLAP
var authority_delta: int = 0
var heroic_defeat_triggered: bool = false
var concession_used: bool = false
var competition_override_used: bool = false
