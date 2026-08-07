class_name MoneyMatch
extends RefCounted
## Headless Money Contest auction FSM (MODULE 07D).
## Does not touch GameState — Minigame commits spend via confirm_player_win_spend.


enum Phase {
	ROUND_INTRO,
	PLAYER_DECISION,
	RIVAL_RESPONSE,
	ROUND_FEEDBACK,
	FINISHED,
}


enum Action {
	STOP,
	RAISE,
	OUTBID,
	BUYOUT,
}


enum Tell {
	CALM,
	LOOKING,
	TENSE,
	LAST,
}


enum Feedback {
	NONE,
	RIVAL_RAISED,
	RIVAL_FOLDED,
	PLAYER_STOPPED,
	BROKE,
}


const DECISION_TIMEOUT: float = 4.0
const BROKE_DELAY: float = 0.50
const INTRO_DURATION: float = 0.20
const RIVAL_RESPONSE_DURATION: float = 0.40
const FOLD_FEEDBACK_DURATION: float = 0.60
const STOP_FEEDBACK_DURATION: float = 0.40
const BROKE_FEEDBACK_DURATION: float = 0.50

const LOT_NAMES: PackedStringArray = [
	"Стул",
	"Тостер",
	"Конус",
	"Пепельница",
	"Чужая кружка",
	"Право занять этот столик",
]


var player_score: int = 0
var rival_score: int = 0
var target_score: int = 3
var is_story: bool = false
var player_capital: int = 0
var rival_capital: int = 0
var starting_money: int = 0
var stake_unit: int = 1
var money_spent_total: int = 0

var current_bid_level: int = 1
var rival_max_level: int = 2
var lot_name: String = ""
var last_lot_name: String = ""

var phase: Phase = Phase.ROUND_INTRO
var phase_time: float = 0.0
var decision_time: float = 0.0
var action_locked: bool = false
var pending_spend_amount: int = 0
var spend_committed_this_resolve: bool = false

var last_tell: Tell = Tell.CALM
var last_feedback: Feedback = Feedback.NONE
var last_feedback_amount: int = 0
var last_rival_bid_level: int = 0

var ended: bool = false
var result: RivalCompetitionResult = null
var submit_count: int = 0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


static func compute_stake_unit(p_starting_money: int, p_target_score: int) -> int:
	if p_target_score <= 0:
		return 1
	return maxi(1, int(floor(float(p_starting_money) / float(p_target_score * 15))))


static func compute_rival_max_level(p_rival_capital: int, variation: int) -> int:
	var raw: int = 2 + int(floor(float(p_rival_capital) / 2.0)) + variation
	return clampi(raw, 2, 7)


static func compute_victory_grade(
	target: int,
	winner_score: int,
	loser_score: int,
) -> GameTypes.VictoryGrade:
	return SlapTiming.compute_victory_grade(target, winner_score, loser_score)


static func tell_for_gap(gap: int) -> Tell:
	if gap >= 3:
		return Tell.CALM
	if gap == 2:
		return Tell.LOOKING
	if gap == 1:
		return Tell.TENSE
	return Tell.LAST


func setup(
	p_player_capital: int,
	p_rival_capital: int,
	p_is_story: bool,
	p_starting_money: int,
	rng_seed: int = -1,
) -> void:
	player_capital = p_player_capital
	rival_capital = p_rival_capital
	is_story = p_is_story
	target_score = 5 if is_story else 3
	starting_money = p_starting_money
	stake_unit = compute_stake_unit(starting_money, target_score)
	money_spent_total = 0
	player_score = 0
	rival_score = 0
	ended = false
	result = null
	submit_count = 0
	last_lot_name = ""
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	if starting_money <= 0:
		_finish_zero_funds()
		return
	_begin_round()


func amount_for_level(level: int) -> int:
	return level * stake_unit


func action_level_delta(action: Action) -> int:
	match action:
		Action.RAISE:
			return 1
		Action.OUTBID:
			return 2
		Action.BUYOUT:
			return 3
		_:
			return 0


func is_action_unlocked(action: Action) -> bool:
	match action:
		Action.STOP:
			return true
		Action.RAISE:
			return true
		Action.OUTBID:
			return player_capital >= 3
		Action.BUYOUT:
			return player_capital >= 6
		_:
			return false


func is_action_affordable(action: Action, current_money: int) -> bool:
	if action == Action.STOP:
		return true
	if not is_action_unlocked(action):
		return false
	var new_level: int = current_bid_level + action_level_delta(action)
	return current_money >= amount_for_level(new_level)


func can_any_raise(current_money: int) -> bool:
	return (
		is_action_affordable(Action.RAISE, current_money)
		or is_action_affordable(Action.OUTBID, current_money)
		or is_action_affordable(Action.BUYOUT, current_money)
	)


func get_tell() -> Tell:
	var gap: int = rival_max_level - current_bid_level
	return tell_for_gap(gap)


func build_result_once() -> RivalCompetitionResult:
	if result == null:
		return null
	submit_count += 1
	return result


func tick(delta: float, current_money: int = 0) -> void:
	if ended or delta <= 0.0:
		return
	match phase:
		Phase.ROUND_INTRO:
			phase_time += delta
			if phase_time >= INTRO_DURATION:
				_enter_player_decision()
		Phase.PLAYER_DECISION:
			_tick_player_decision(delta, current_money)
		Phase.RIVAL_RESPONSE:
			phase_time += delta
			if phase_time >= RIVAL_RESPONSE_DURATION:
				_enter_player_decision()
		Phase.ROUND_FEEDBACK:
			phase_time += delta
			var need: float = _feedback_duration()
			if phase_time >= need:
				_after_round_feedback()
		Phase.FINISHED:
			pass


func try_player_action(action: Action, current_money: int) -> Dictionary:
	var out: Dictionary = {
		"ok": false,
		"needs_spend": 0,
		"awaiting_spend_confirm": false,
	}
	if ended or phase != Phase.PLAYER_DECISION or action_locked:
		return out
	if action == Action.STOP:
		action_locked = true
		_resolve_rival_round_win(Feedback.PLAYER_STOPPED)
		out["ok"] = true
		return out
	if not is_action_unlocked(action):
		return out
	if not is_action_affordable(action, current_money):
		return out
	var new_level: int = current_bid_level + action_level_delta(action)
	var new_amount: int = amount_for_level(new_level)
	action_locked = true
	if new_level > rival_max_level:
		pending_spend_amount = new_amount
		spend_committed_this_resolve = false
		out["ok"] = true
		out["needs_spend"] = new_amount
		out["awaiting_spend_confirm"] = true
		return out
	# Rival counters — no spend.
	var rival_bid: int = mini(new_level + 1, rival_max_level)
	current_bid_level = rival_bid
	last_rival_bid_level = rival_bid
	last_tell = get_tell()
	last_feedback = Feedback.RIVAL_RAISED
	last_feedback_amount = amount_for_level(rival_bid)
	phase = Phase.RIVAL_RESPONSE
	phase_time = 0.0
	out["ok"] = true
	return out


func confirm_player_win_spend(success: bool) -> void:
	## Called by MoneyMinigame after GameState.spend_money for a winning bid.
	if ended:
		return
	if pending_spend_amount <= 0:
		return
	if spend_committed_this_resolve:
		return
	if not success:
		pending_spend_amount = 0
		push_error("[MoneyMatch] spend failed; treating as forced STOP")
		_resolve_rival_round_win(Feedback.BROKE)
		return
	spend_committed_this_resolve = true
	var spent: int = pending_spend_amount
	pending_spend_amount = 0
	money_spent_total += spent
	player_score += 1
	last_feedback = Feedback.RIVAL_FOLDED
	last_feedback_amount = spent
	if _check_match_end():
		return
	phase = Phase.ROUND_FEEDBACK
	phase_time = 0.0


func debug_force_rival_max(level: int) -> void:
	rival_max_level = clampi(level, 2, 7)
	last_tell = get_tell()


func debug_set_current_bid(level: int) -> void:
	current_bid_level = maxi(level, 1)
	last_tell = get_tell()


func debug_win_round_spend(amount: int) -> void:
	## Test helper: award player round with given spend (no GameState).
	if ended:
		return
	money_spent_total += amount
	player_score += 1
	last_feedback = Feedback.RIVAL_FOLDED
	last_feedback_amount = amount
	if _check_match_end():
		return
	phase = Phase.ROUND_FEEDBACK
	phase_time = 0.0


func debug_lose_round() -> void:
	if ended:
		return
	_resolve_rival_round_win(Feedback.PLAYER_STOPPED)


func _finish_zero_funds() -> void:
	ended = true
	phase = Phase.FINISHED
	phase_time = 0.0
	result = RivalCompetitionResult.new()
	result.outcome = GameTypes.RivalCompetitionOutcome.PLAYER_LOSS
	result.victory_grade = GameTypes.VictoryGrade.CRUSHING
	result.debug_score_summary = "MONEY 0 funds"


func _begin_round() -> void:
	if ended:
		return
	var variation: int = rng.randi_range(-1, 1)
	rival_max_level = compute_rival_max_level(rival_capital, variation)
	current_bid_level = 1
	last_rival_bid_level = 1
	pending_spend_amount = 0
	spend_committed_this_resolve = false
	action_locked = false
	lot_name = _pick_lot_name()
	last_lot_name = lot_name
	last_tell = get_tell()
	last_feedback = Feedback.NONE
	last_feedback_amount = 0
	phase = Phase.ROUND_INTRO
	phase_time = 0.0
	decision_time = 0.0


func _pick_lot_name() -> String:
	if LOT_NAMES.is_empty():
		return "Лот"
	var pick: String = LOT_NAMES[rng.randi_range(0, LOT_NAMES.size() - 1)]
	if LOT_NAMES.size() > 1:
		var guard: int = 0
		while pick == last_lot_name and guard < 8:
			pick = LOT_NAMES[rng.randi_range(0, LOT_NAMES.size() - 1)]
			guard += 1
	return pick


func _enter_player_decision() -> void:
	if ended:
		return
	phase = Phase.PLAYER_DECISION
	phase_time = 0.0
	decision_time = 0.0
	action_locked = false
	last_tell = get_tell()


func _tick_player_decision(delta: float, current_money: int) -> void:
	if action_locked:
		return
	decision_time += delta
	if not can_any_raise(current_money):
		if decision_time >= BROKE_DELAY:
			action_locked = true
			_resolve_rival_round_win(Feedback.BROKE)
		return
	if decision_time >= DECISION_TIMEOUT:
		action_locked = true
		_resolve_rival_round_win(Feedback.PLAYER_STOPPED)


func _resolve_rival_round_win(fb: Feedback) -> void:
	rival_score += 1
	last_feedback = fb
	last_feedback_amount = 0
	pending_spend_amount = 0
	if _check_match_end():
		return
	phase = Phase.ROUND_FEEDBACK
	phase_time = 0.0


func _feedback_duration() -> float:
	match last_feedback:
		Feedback.RIVAL_FOLDED:
			return FOLD_FEEDBACK_DURATION
		Feedback.BROKE:
			return BROKE_FEEDBACK_DURATION
		Feedback.PLAYER_STOPPED:
			return STOP_FEEDBACK_DURATION
		_:
			return STOP_FEEDBACK_DURATION


func _after_round_feedback() -> void:
	if ended:
		return
	_begin_round()


func _check_match_end() -> bool:
	if player_score < target_score and rival_score < target_score:
		return false
	ended = true
	phase = Phase.FINISHED
	phase_time = 0.0
	result = RivalCompetitionResult.new()
	if player_score >= target_score:
		result.outcome = GameTypes.RivalCompetitionOutcome.PLAYER_WIN
		result.victory_grade = compute_victory_grade(target_score, player_score, rival_score)
	else:
		result.outcome = GameTypes.RivalCompetitionOutcome.PLAYER_LOSS
		result.victory_grade = compute_victory_grade(target_score, rival_score, player_score)
	result.debug_score_summary = "MONEY %d:%d spent=%d" % [
		player_score,
		rival_score,
		money_spent_total,
	]
	return true
