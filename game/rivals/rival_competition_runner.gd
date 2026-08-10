extends Node
## Production Rival competition runner (MODULE 07B–07D).
## Autoload: RivalCompetitionRunner. Registers via RivalEncounters.set_competition_runner.
## competition_requested remains notification-only; this Callable is the sole launch/submit path.
## MODULE 21: run_exhibition_competition reuses Slap/Dance without RivalEncounters persistence.


signal hostile_acquisition_requested(rival_id: StringName)

const SLAP_SCENE: String = "res://minigames/slap/slap_minigame.tscn"
const DANCE_SCENE: String = "res://minigames/dance/dance_minigame.tscn"
const SIGMA_SCENE: String = "res://minigames/sigma/sigma_minigame.tscn"
const MONEY_SCENE: String = "res://minigames/money/money_minigame.tscn"

var _active: CanvasLayer = null
var _busy: bool = false
var _submitted: bool = false
var _hostile_emitted: bool = false
var _player: PlayerController = null
var _return_mode: int = int(PlayerController.ControlMode.GAMEPLAY)
var _current_request: RivalCompetitionRequest = null
var _exhibition_mode: bool = false
var _exhibition_callback: Callable = Callable()
var _exhibition_rival_def: RivalDefinition = null


func get_active_minigame() -> CanvasLayer:
	return _active


func is_busy() -> bool:
	return _busy


func register_as_runner() -> void:
	var encounters: Node = get_node_or_null("/root/RivalEncounters")
	if encounters == null:
		return
	encounters.call("set_competition_runner", run_competition)


func _ready() -> void:
	register_as_runner()
	DfLog.info("MODULE_07D", "RivalCompetitionRunner ready")


func run_competition(request: RivalCompetitionRequest) -> void:
	if request == null:
		push_error("[RivalCompetitionRunner] null request")
		return
	if _busy:
		push_error("[RivalCompetitionRunner] busy; refusing second competition")
		return
	match request.competition_type:
		GameTypes.CompetitionType.SLAP:
			_start_slap(request)
		GameTypes.CompetitionType.DANCE:
			_start_dance(request)
		GameTypes.CompetitionType.SIGMA:
			_start_sigma(request)
		GameTypes.CompetitionType.MONEY:
			_start_money(request)
		_:
			push_error(
				"[RivalCompetitionRunner] unknown competition_type=%s"
				% str(request.competition_type)
			)


## MODULE 21 exhibition seam: same Slap/Dance + control modes, no RivalEncounters submit / Authority / defeat.
func run_exhibition_competition(
	request: RivalCompetitionRequest,
	rival_definition: RivalDefinition,
	result_callback: Callable,
) -> bool:
	if request == null:
		push_error("[RivalCompetitionRunner] exhibition null request")
		return false
	if rival_definition == null:
		push_error("[RivalCompetitionRunner] exhibition null rival_definition")
		return false
	if not result_callback.is_valid():
		push_error("[RivalCompetitionRunner] exhibition invalid result_callback")
		return false
	if _busy:
		push_error("[RivalCompetitionRunner] busy; refusing exhibition competition")
		return false
	match request.competition_type:
		GameTypes.CompetitionType.SLAP, GameTypes.CompetitionType.DANCE:
			pass
		_:
			push_error(
				"[RivalCompetitionRunner] exhibition supports only SLAP/DANCE, got=%s"
				% str(request.competition_type)
			)
			return false
	_exhibition_mode = true
	_exhibition_callback = result_callback
	_exhibition_rival_def = rival_definition
	match request.competition_type:
		GameTypes.CompetitionType.SLAP:
			_start_slap(request)
		GameTypes.CompetitionType.DANCE:
			_start_dance(request)
	if not _busy:
		_clear_exhibition_state()
		return false
	return true


func _clear_exhibition_state() -> void:
	_exhibition_mode = false
	_exhibition_callback = Callable()
	_exhibition_rival_def = null


func _rival_definition_for(request: RivalCompetitionRequest) -> RivalDefinition:
	if _exhibition_mode and _exhibition_rival_def != null:
		return _exhibition_rival_def
	var encounters: Node = get_node_or_null("/root/RivalEncounters")
	if encounters == null:
		return null
	return encounters.call("get_rival_definition", request.rival_id) as RivalDefinition


func _start_slap(request: RivalCompetitionRequest) -> void:
	_busy = true
	_submitted = false
	_hostile_emitted = false
	_current_request = request
	var encounters: Node = get_node("/root/RivalEncounters")
	var is_story: bool = false
	var def: RivalDefinition = _rival_definition_for(request)
	if def != null:
		is_story = def.is_story
	var perks: Dictionary = _snapshot_slap_perks()
	_prepare_player_mode(encounters, Input.MOUSE_MODE_CAPTURED)
	var slap: SlapMinigame = _instantiate_minigame(SLAP_SCENE) as SlapMinigame
	if slap == null:
		_abort_start("slap scene missing or invalid")
		return
	_active = slap
	get_tree().root.add_child(slap)
	slap.setup(request, is_story, perks)
	_set_minigame_duck(true)
	if not _active.match_finished.is_connected(_on_match_finished):
		_active.match_finished.connect(_on_match_finished)


func _start_dance(request: RivalCompetitionRequest) -> void:
	_busy = true
	_submitted = false
	_hostile_emitted = false
	_current_request = request
	var encounters: Node = get_node("/root/RivalEncounters")
	var is_story: bool = false
	var def: RivalDefinition = _rival_definition_for(request)
	if def != null:
		is_story = def.is_story
	var perks: Dictionary = _snapshot_dance_perks()
	_prepare_player_mode(encounters, Input.MOUSE_MODE_CAPTURED)
	var dance: DanceMinigame = _instantiate_minigame(DANCE_SCENE) as DanceMinigame
	if dance == null:
		_abort_start("dance scene missing or invalid")
		return
	_active = dance
	get_tree().root.add_child(dance)
	dance.setup(request, is_story, perks)
	_set_minigame_duck(true)
	if not dance.match_finished.is_connected(_on_match_finished):
		dance.match_finished.connect(_on_match_finished)


func _start_sigma(request: RivalCompetitionRequest) -> void:
	_busy = true
	_submitted = false
	_hostile_emitted = false
	_current_request = request
	var encounters: Node = get_node("/root/RivalEncounters")
	var is_story: bool = false
	var def: RivalDefinition = _rival_definition_for(request)
	if def != null:
		is_story = def.is_story
	var perks: Dictionary = _snapshot_sigma_perks()
	_prepare_player_mode(encounters, Input.MOUSE_MODE_CAPTURED)
	var sigma: SigmaMinigame = _instantiate_minigame(SIGMA_SCENE) as SigmaMinigame
	if sigma == null:
		_abort_start("sigma scene missing or invalid")
		return
	_active = sigma
	get_tree().root.add_child(sigma)
	sigma.setup(request, is_story, perks)
	_set_minigame_duck(true)
	if not sigma.match_finished.is_connected(_on_match_finished):
		sigma.match_finished.connect(_on_match_finished)


func _start_money(request: RivalCompetitionRequest) -> void:
	_busy = true
	_submitted = false
	_hostile_emitted = false
	_current_request = request
	var encounters: Node = get_node("/root/RivalEncounters")
	var is_story: bool = false
	var def: RivalDefinition = _rival_definition_for(request)
	if def != null:
		is_story = def.is_story
	_prepare_player_mode(encounters, Input.MOUSE_MODE_VISIBLE)
	var money: MoneyMinigame = _instantiate_minigame(MONEY_SCENE) as MoneyMinigame
	if money == null:
		_abort_start("money scene missing or invalid")
		return
	_active = money
	get_tree().root.add_child(money)
	money.setup(request, is_story)
	_set_minigame_duck(true)
	if not money.match_finished.is_connected(_on_match_finished):
		money.match_finished.connect(_on_match_finished)


func _instantiate_minigame(scene_path: String) -> CanvasLayer:
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		return null
	return packed.instantiate() as CanvasLayer


func _abort_start(message: String) -> void:
	push_error("[RivalCompetitionRunner] %s" % message)
	_restore_player()
	_cleanup_active()
	_busy = false
	_current_request = null
	if _exhibition_mode:
		_clear_exhibition_state()


func _prepare_player_mode(
	encounters: Node,
	mouse_mode: Input.MouseMode = Input.MOUSE_MODE_CAPTURED,
) -> void:
	_return_mode = int(PlayerController.ControlMode.GAMEPLAY)
	var session: RivalEncounterSession = encounters.call("get_active_session") as RivalEncounterSession
	if session != null and session.return_control_mode >= 0:
		_return_mode = session.return_control_mode
	_player = get_tree().get_first_node_in_group("player") as PlayerController
	if _player != null:
		_player.enter_minigame(mouse_mode)


func _snapshot_slap_perks() -> Dictionary:
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


func _snapshot_dance_perks() -> Dictionary:
	var gs: Node = get_node_or_null("/root/GameState")
	var out: Dictionary = {
		"staged_walk": false,
		"rhythm_in_body": false,
	}
	if gs == null:
		return out
	out["staged_walk"] = bool(gs.call("has_perk", PerkIds.APPEARANCE_STAGED_WALK))
	out["rhythm_in_body"] = bool(gs.call("has_perk", PerkIds.APPEARANCE_RHYTHM_IN_BODY))
	return out


func _snapshot_sigma_perks() -> Dictionary:
	var gs: Node = get_node_or_null("/root/GameState")
	var out: Dictionary = {
		"pocket_mirror": false,
		"control_profile": false,
		"dont_blink": false,
		"silence_longer": false,
		"reverse_pressure": false,
		"atmospheric_influence": false,
	}
	if gs == null:
		return out
	out["pocket_mirror"] = bool(gs.call("has_perk", PerkIds.APPEARANCE_POCKET_MIRROR))
	out["control_profile"] = bool(gs.call("has_perk", PerkIds.APPEARANCE_CONTROL_PROFILE))
	out["dont_blink"] = bool(gs.call("has_perk", PerkIds.AURA_DONT_BLINK_FIRST))
	out["silence_longer"] = bool(gs.call("has_perk", PerkIds.AURA_SILENCE_LONGER))
	out["reverse_pressure"] = bool(gs.call("has_perk", PerkIds.AURA_REVERSE_PRESSURE))
	out["atmospheric_influence"] = bool(gs.call("has_perk", PerkIds.AURA_ATMOSPHERIC_INFLUENCE))
	return out


func _on_match_finished(result: RivalCompetitionResult) -> void:
	if _submitted:
		return
	_submitted = true
	if _exhibition_mode:
		_finish_exhibition(result)
		return
	_maybe_emit_hostile_acquisition(result)
	var encounters: Node = get_node_or_null("/root/RivalEncounters")
	if encounters != null and result != null:
		encounters.call("submit_competition_result", result)
	_restore_player()
	_cleanup_active()
	_busy = false
	_current_request = null


func _finish_exhibition(result: RivalCompetitionResult) -> void:
	var cb: Callable = _exhibition_callback
	_clear_exhibition_state()
	_restore_player()
	_cleanup_active()
	_busy = false
	_current_request = null
	if cb.is_valid() and result != null:
		cb.call(result)


func _maybe_emit_hostile_acquisition(result: RivalCompetitionResult) -> void:
	if _hostile_emitted:
		return
	if result == null or _current_request == null:
		return
	if _current_request.competition_type != GameTypes.CompetitionType.MONEY:
		return
	if result.outcome != GameTypes.RivalCompetitionOutcome.PLAYER_WIN:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null or not bool(gs.call("has_perk", PerkIds.CAPITAL_HOSTILE_ACQUISITION)):
		return
	var encounters: Node = get_node_or_null("/root/RivalEncounters")
	if encounters == null:
		return
	var def: RivalDefinition = encounters.call(
		"get_rival_definition",
		_current_request.rival_id,
	) as RivalDefinition
	if def == null:
		return
	if def.competition_modifier_id != &"money_acquisition":
		return
	_hostile_emitted = true
	hostile_acquisition_requested.emit(_current_request.rival_id)


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
	_set_minigame_duck(false)
	if _active != null and is_instance_valid(_active):
		if _active.match_finished.is_connected(_on_match_finished):
			_active.match_finished.disconnect(_on_match_finished)
		_active.queue_free()
	_active = null


func _set_minigame_duck(active: bool) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("duck_for_minigame"):
		ad.call("duck_for_minigame", active)
