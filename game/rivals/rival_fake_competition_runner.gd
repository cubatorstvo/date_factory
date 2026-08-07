class_name RivalFakeCompetitionRunner
extends RefCounted
## Test-only competition runner. Forces WIN/LOSS CLOSE/CRUSHING without MODULE 07 gameplay.

var forced_outcome: GameTypes.RivalCompetitionOutcome = GameTypes.RivalCompetitionOutcome.PLAYER_WIN
var forced_grade: GameTypes.VictoryGrade = GameTypes.VictoryGrade.CLOSE
var auto_submit: bool = true
var last_request: RivalCompetitionRequest = null
var request_count: int = 0
var _encounters: Node = null


func attach(encounters: Node) -> void:
	_encounters = encounters
	if _encounters != null and not _encounters.competition_requested.is_connected(_on_competition_requested):
		_encounters.competition_requested.connect(_on_competition_requested)


func detach() -> void:
	if _encounters != null and _encounters.competition_requested.is_connected(_on_competition_requested):
		_encounters.competition_requested.disconnect(_on_competition_requested)
	_encounters = null


func set_forced(
	outcome: GameTypes.RivalCompetitionOutcome,
	grade: GameTypes.VictoryGrade,
) -> void:
	forced_outcome = outcome
	forced_grade = grade


func reset_counts() -> void:
	request_count = 0
	last_request = null


func _on_competition_requested(request: RivalCompetitionRequest) -> void:
	last_request = request
	request_count += 1
	if not auto_submit:
		return
	if _encounters == null:
		return
	var result: RivalCompetitionResult = RivalCompetitionResult.new()
	result.outcome = forced_outcome
	result.victory_grade = forced_grade
	result.debug_score_summary = "fake"
	_encounters.call("submit_competition_result", result)
