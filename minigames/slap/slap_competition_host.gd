class_name SlapCompetitionHost
extends Node
## Production host: RivalEncounters SLAP → SlapMinigame → submit once (MODULE 07A).
## Disable for MODULE 06 FakeCompetitionRunner self-tests (`enabled = false`).


@export var enabled: bool = true

var _active: SlapMinigame = null
var _busy: bool = false
var _submitted: bool = false
var _player: PlayerController = null
var _return_mode: int = int(PlayerController.ControlMode.GAMEPLAY)


func get_active_minigame() -> SlapMinigame:
	return _active


func is_busy() -> bool:
	return _busy


func _ready() -> void:
	var encounters: Node = get_node_or_null("/root/RivalEncounters")
	if encounters != null and not encounters.competition_requested.is_connected(_on_competition_requested):
		encounters.competition_requested.connect(_on_competition_requested)


func _exit_tree() -> void:
	var encounters: Node = get_node_or_null("/root/RivalEncounters")
	if encounters != null and encounters.competition_requested.is_connected(_on_competition_requested):
		encounters.competition_requested.disconnect(_on_competition_requested)
	_cleanup_active()


func _on_competition_requested(request: RivalCompetitionRequest) -> void:
	if not enabled:
		return
	if request == null:
		return
	if request.competition_type != GameTypes.CompetitionType.SLAP:
		return
	if _busy:
		return
	_start_slap(request)


func _start_slap(request: RivalCompetitionRequest) -> void:
	_busy = true
	_submitted = false
	var encounters: Node = get_node("/root/RivalEncounters")
	var is_story: bool = false
	var def: RivalDefinition = encounters.call("get_rival_definition", request.rival_id) as RivalDefinition
	if def != null:
		is_story = def.is_story
	var perks: Dictionary = _snapshot_perks()
	var session: RivalEncounterSession = encounters.call("get_active_session") as RivalEncounterSession
	_return_mode = int(PlayerController.ControlMode.GAMEPLAY)
	if session != null and session.return_control_mode >= 0:
		_return_mode = session.return_control_mode
	_player = get_tree().get_first_node_in_group("player") as PlayerController
	if _player != null:
		_player.enter_minigame(Input.MOUSE_MODE_CAPTURED)
	_active = SlapMinigame.new()
	get_tree().root.add_child(_active)
	_active.setup(request, is_story, perks)
	if not _active.match_finished.is_connected(_on_match_finished):
		_active.match_finished.connect(_on_match_finished)


func _snapshot_perks() -> Dictionary:
	var gs: Node = get_node_or_null("/root/GameState")
	var out: Dictionary = {
		"no_warmup": false,
		"tough_cheek": false,
		"double_slap": false,
		"counter_argument": false,
		"mass_reserve": false,
		"two_handed": false,
	}
	if gs == null:
		return out
	out["no_warmup"] = bool(gs.call("has_perk", PerkIds.MUSCLE_NO_WARMUP))
	out["tough_cheek"] = bool(gs.call("has_perk", PerkIds.MUSCLE_TOUGH_CHEEK))
	out["double_slap"] = bool(gs.call("has_perk", PerkIds.MUSCLE_DOUBLE_SLAP))
	out["counter_argument"] = bool(gs.call("has_perk", PerkIds.MUSCLE_COUNTER_ARGUMENT))
	out["mass_reserve"] = bool(gs.call("has_perk", PerkIds.MUSCLE_MASS_RESERVE))
	out["two_handed"] = bool(gs.call("has_perk", PerkIds.MUSCLE_TWO_HANDED_ARGUMENT))
	return out


func _on_match_finished(result: RivalCompetitionResult) -> void:
	if _submitted:
		return
	_submitted = true
	var encounters: Node = get_node_or_null("/root/RivalEncounters")
	if encounters != null and result != null:
		encounters.call("submit_competition_result", result)
	_restore_player()
	_cleanup_active()
	_busy = false


func _restore_player() -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as PlayerController
	if _player == null:
		return
	match _return_mode:
		int(PlayerController.ControlMode.MODAL_UI):
			_player.enter_modal_ui()
		int(PlayerController.ControlMode.MINIGAME):
			_player.enter_minigame(Input.MOUSE_MODE_CAPTURED)
		int(PlayerController.ControlMode.PAUSED):
			_player.enter_paused()
		_:
			_player.enter_gameplay()


func _cleanup_active() -> void:
	if _active != null and is_instance_valid(_active):
		if _active.match_finished.is_connected(_on_match_finished):
			_active.match_finished.disconnect(_on_match_finished)
		_active.queue_free()
	_active = null
