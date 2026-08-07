class_name RivalFakeCompetitionRunner
extends RefCounted
## Test-only competition runner. Forces WIN/LOSS CLOSE/CRUSHING without MODULE 07 gameplay.
## Uses RivalEncounters.set_competition_runner (not competition_requested) so production Runner is not double-fired.

var forced_outcome: GameTypes.RivalCompetitionOutcome = GameTypes.RivalCompetitionOutcome.PLAYER_WIN
var forced_grade: GameTypes.VictoryGrade = GameTypes.VictoryGrade.CLOSE
var auto_submit: bool = true
var last_request: RivalCompetitionRequest = null
var request_count: int = 0
var _encounters: Node = null


func attach(encounters: Node) -> void:
	_encounters = encounters
	if _encounters == null:
		return
	_encounters.call("set_competition_runner", run_competition)


func detach() -> void:
	if _encounters != null:
		_encounters.call("clear_competition_runner")
	_encounters = null


func restore_production_runner() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var production: Node = tree.root.get_node_or_null("/root/RivalCompetitionRunner")
	if production == null or _encounters == null:
		return
	if production.has_method("register_as_runner"):
		production.call("register_as_runner")
	else:
		_encounters.call("set_competition_runner", production.run_competition)


func set_forced(
	outcome: GameTypes.RivalCompetitionOutcome,
	grade: GameTypes.VictoryGrade,
) -> void:
	forced_outcome = outcome
	forced_grade = grade


func reset_counts() -> void:
	request_count = 0
	last_request = null


func run_competition(request: RivalCompetitionRequest) -> void:
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
