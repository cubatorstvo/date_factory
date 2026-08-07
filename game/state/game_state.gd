extends Node
## Canonical runtime Game State for Date Factory v2 (MODULE 02).
## Autoload name: GameState. Mutate only through this API.
## Shared enums live in GameTypes (MODULE 03) — do not redefine here.

signal money_changed(new_value: int, delta: int)
signal authority_changed(new_value: int, delta: int)
signal experience_changed(new_value: int, delta: int)
signal upgrade_points_changed(new_value: int, delta: int)
signal characteristic_changed(characteristic: GameTypes.PlayerCharacteristic, new_value: int, previous_value: int)
signal girl_relationship_changed(girl_id: StringName, new_value: int, delta: int)
signal girl_conquered(girl_id: StringName)
signal girl_discovered(girl_id: StringName)
signal girl_contact_added(girl_id: StringName)
signal girl_clue_revealed(girl_id: StringName, clue_index: int)
signal primary_trait_revealed(girl_id: StringName)
signal secondary_trait_revealed(girl_id: StringName)
signal location_unlocked(location_id: StringName)
signal story_flag_changed(flag_id: StringName, value: bool)
signal stage_changed(new_stage: GameTypes.GameStage, previous_stage: GameTypes.GameStage)
signal clone_counts_changed(total: int, working: int, dating: int, free: int)
signal late_rates_changed(money_per_minute: float, dates_per_minute: float)
signal state_reset()

var _stage: GameTypes.GameStage = GameTypes.GameStage.PROLOGUE
var _money: int = 0
var _authority: int = 0
var _experience: int = 0
var _upgrade_points: int = 0
var _muscle: int = 0
var _appearance: int = 0
var _capital: int = 0
var _aura: int = 0
var _girl_relationships: Dictionary = {}
var _conquered_girls: Dictionary = {}
var _discovered_girls: Array[StringName] = []
var _girl_contacts: Dictionary = {}
var _known_girl_clues: Dictionary = {}
var _revealed_primary_traits: Dictionary = {}
var _known_girl_reactions: Dictionary = {}
var _girl_retry_days_remaining: Dictionary = {}
var _girl_date_cooldown_days_remaining: Dictionary = {}
var _girl_played_dating_event_ids: Dictionary = {}
var _girl_last_date_event_ids: Dictionary = {}
var _revealed_secondary_traits: Dictionary = {}
var _unlocked_locations: Dictionary = {}
var _story_flags: Dictionary = {}
var _total_clones: int = 0
var _clones_working: int = 0
var _clones_dating: int = 0
var _money_per_minute: float = 0.0
var _dates_per_minute: float = 0.0
var _purchased_perks: Dictionary = {}
var _defeated_rivals: Dictionary = {}
var _salary_initialized: bool = false
var _salary_period_index: int = 0
var _pending_salary: int = 0
var _salary_manual_cycle_seen: bool = false
var _salary_advance_used_period: int = -1

const CHAR_MIN: int = 0
const CHAR_MAX: int = 10
const RELATIONSHIP_MIN: int = -5
const RELATIONSHIP_MAX: int = 5


func _ready() -> void:
	reset_for_new_game()
	DfLog.info("MODULE_02", "GameState ready")


func reset_for_new_game() -> void:
	_stage = GameTypes.GameStage.PROLOGUE
	_money = 0
	_authority = 0
	_experience = 0
	_upgrade_points = 0
	_muscle = 0
	_appearance = 0
	_capital = 0
	_aura = 0
	_girl_relationships = {}
	_conquered_girls = {}
	_discovered_girls = []
	_girl_contacts = {}
	_known_girl_clues = {}
	_revealed_primary_traits = {}
	_known_girl_reactions = {}
	_girl_retry_days_remaining = {}
	_girl_date_cooldown_days_remaining = {}
	_girl_played_dating_event_ids = {}
	_girl_last_date_event_ids = {}
	_revealed_secondary_traits = {}
	_unlocked_locations = {}
	_story_flags = {}
	_total_clones = 0
	_clones_working = 0
	_clones_dating = 0
	_money_per_minute = 0.0
	_dates_per_minute = 0.0
	_purchased_perks = {}
	_defeated_rivals = {}
	_salary_initialized = false
	_salary_period_index = 0
	_pending_salary = 0
	_salary_manual_cycle_seen = false
	_salary_advance_used_period = -1
	state_reset.emit()


# --- Stage ---

func get_stage() -> GameTypes.GameStage:
	return _stage


func advance_stage(next_stage: GameTypes.GameStage) -> bool:
	if int(next_stage) != int(_stage) + 1:
		push_error("[GameState] advance_stage rejected: %s -> %s" % [_stage, next_stage])
		return false
	if next_stage < GameTypes.GameStage.PROLOGUE or next_stage > GameTypes.GameStage.FINALE:
		push_error("[GameState] advance_stage invalid stage: %s" % next_stage)
		return false
	var prev: GameTypes.GameStage = _stage
	_stage = next_stage
	stage_changed.emit(_stage, prev)
	return true


## Save/Load restore path — bypasses monotonic gameplay rules.
func restore_stage(stage: GameTypes.GameStage) -> void:
	if stage < GameTypes.GameStage.PROLOGUE or stage > GameTypes.GameStage.FINALE:
		push_error("[GameState] restore_stage invalid: %s" % stage)
		return
	var prev: GameTypes.GameStage = _stage
	if prev == stage:
		return
	_stage = stage
	stage_changed.emit(_stage, prev)


# --- Salary state (MODULE 13) ---

func is_salary_initialized() -> bool:
	return _salary_initialized


## Returns true only the first time.
func mark_salary_initialized() -> bool:
	if _salary_initialized:
		return false
	_salary_initialized = true
	return true


func get_salary_period_index() -> int:
	return _salary_period_index


func advance_salary_period_index() -> int:
	_salary_period_index += 1
	return _salary_period_index


func get_pending_salary() -> int:
	return _pending_salary


func add_pending_salary(amount: int) -> void:
	if amount < 0:
		push_error("[GameState] add_pending_salary negative amount: %s" % amount)
		return
	if amount == 0:
		return
	_pending_salary += amount


func take_all_pending_salary() -> int:
	var amount: int = _pending_salary
	_pending_salary = 0
	return amount


func has_seen_manual_salary_cycle() -> bool:
	return _salary_manual_cycle_seen


## Returns true only the first time.
func mark_manual_salary_cycle_seen() -> bool:
	if _salary_manual_cycle_seen:
		return false
	_salary_manual_cycle_seen = true
	return true


func get_salary_advance_used_period() -> int:
	return _salary_advance_used_period


func set_salary_advance_used_period(period_index: int) -> void:
	_salary_advance_used_period = period_index


# --- Money ---

func get_money() -> int:
	return _money


func can_afford(amount: int) -> bool:
	if amount < 0:
		push_error("[GameState] can_afford negative amount: %s" % amount)
		return false
	return _money >= amount


func add_money(amount: int) -> void:
	if amount < 0:
		push_error("[GameState] add_money negative amount: %s" % amount)
		return
	if amount == 0:
		return
	_money += amount
	money_changed.emit(_money, amount)


func spend_money(amount: int) -> bool:
	if amount < 0:
		push_error("[GameState] spend_money negative amount: %s" % amount)
		return false
	if amount == 0:
		return true
	if _money < amount:
		return false
	_money -= amount
	money_changed.emit(_money, -amount)
	return true


# --- Authority ---

func get_authority() -> int:
	return _authority


func add_authority(amount: int) -> void:
	if amount < 0:
		push_error("[GameState] add_authority negative amount: %s" % amount)
		return
	if amount == 0:
		return
	_authority += amount
	authority_changed.emit(_authority, amount)


## Controlled Authority loss. Never goes below 0. Do not use add_authority(-1).
func lose_authority(amount: int) -> int:
	if amount < 0:
		push_error("[GameState] lose_authority negative amount: %s" % amount)
		return 0
	if amount == 0:
		return 0
	var actual: int = mini(amount, _authority)
	if actual == 0:
		return 0
	_authority -= actual
	authority_changed.emit(_authority, -actual)
	return actual


# --- Defeated rivals (MODULE 06) ---

func is_rival_defeated(rival_id: StringName) -> bool:
	if not _is_valid_id(rival_id):
		return false
	return _defeated_rivals.has(rival_id)


## Returns true only the first time. Does not grant Authority reward.
func mark_rival_defeated(rival_id: StringName) -> bool:
	if not _is_valid_id(rival_id):
		push_error("[GameState] mark_rival_defeated empty id")
		return false
	if _defeated_rivals.has(rival_id):
		return false
	_defeated_rivals[rival_id] = true
	return true


# --- Experience / Upgrade Points ---

func get_experience() -> int:
	return _experience


func get_upgrade_points() -> int:
	return _upgrade_points


func add_experience(amount: int) -> void:
	if amount < 0:
		push_error("[GameState] add_experience negative amount: %s" % amount)
		return
	if amount == 0:
		return
	# Atomic invariant: +N experience => +N upgrade_points
	_experience += amount
	_upgrade_points += amount
	experience_changed.emit(_experience, amount)
	upgrade_points_changed.emit(_upgrade_points, amount)


func can_spend_upgrade_points(amount: int) -> bool:
	if amount < 0:
		push_error("[GameState] can_spend_upgrade_points negative: %s" % amount)
		return false
	return _upgrade_points >= amount


func spend_upgrade_points(amount: int) -> bool:
	if amount < 0:
		push_error("[GameState] spend_upgrade_points negative: %s" % amount)
		return false
	if amount == 0:
		return true
	if _upgrade_points < amount:
		return false
	_upgrade_points -= amount
	upgrade_points_changed.emit(_upgrade_points, -amount)
	return true


## Save/Load only — not a gameplay grant path.
func restore_upgrade_points(value: int) -> void:
	if value < 0:
		push_error("[GameState] restore_upgrade_points negative: %s" % value)
		return
	var prev: int = _upgrade_points
	if prev == value:
		return
	_upgrade_points = value
	upgrade_points_changed.emit(_upgrade_points, value - prev)


# --- Characteristics ---

func get_muscle() -> int:
	return _muscle


func get_appearance() -> int:
	return _appearance


func get_capital() -> int:
	return _capital


func get_aura() -> int:
	return _aura


func get_characteristic(characteristic: GameTypes.PlayerCharacteristic) -> int:
	match characteristic:
		GameTypes.PlayerCharacteristic.MUSCLE:
			return _muscle
		GameTypes.PlayerCharacteristic.APPEARANCE:
			return _appearance
		GameTypes.PlayerCharacteristic.CAPITAL:
			return _capital
		GameTypes.PlayerCharacteristic.AURA:
			return _aura
	return 0


## Save/Load / debug restore — not a gameplay grant path.
## Characteristic levels normally rise only via perk purchase (MODULE 05).
func restore_characteristic(characteristic: GameTypes.PlayerCharacteristic, value: int) -> bool:
	if value < CHAR_MIN or value > CHAR_MAX:
		push_error("[GameState] restore_characteristic out of range %s=%s" % [characteristic, value])
		return false
	var prev: int = get_characteristic(characteristic)
	if prev == value:
		return true
	match characteristic:
		GameTypes.PlayerCharacteristic.MUSCLE:
			_muscle = value
		GameTypes.PlayerCharacteristic.APPEARANCE:
			_appearance = value
		GameTypes.PlayerCharacteristic.CAPITAL:
			_capital = value
		GameTypes.PlayerCharacteristic.AURA:
			_aura = value
	characteristic_changed.emit(characteristic, value, prev)
	return true


# --- Purchased perks (MODULE 05) ---

func has_perk(perk_id: StringName) -> bool:
	if not _is_valid_id(perk_id):
		return false
	return _purchased_perks.has(perk_id)


func get_purchased_perk_count() -> int:
	return _purchased_perks.size()


func get_purchased_perk_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for key in _purchased_perks.keys():
		out.append(key as StringName)
	return out


## Save/Load / debug — replaces ownership set without spending points.
func restore_purchased_perks(perk_ids: Array) -> void:
	_purchased_perks = {}
	for entry in perk_ids:
		var perk_id: StringName = entry as StringName
		if not _is_valid_id(perk_id):
			push_error("[GameState] restore_purchased_perks empty id")
			continue
		_purchased_perks[perk_id] = true


## Atomic spend + own + characteristic +1. Called only by Progression.
func _commit_perk_purchase(
	perk_id: StringName,
	characteristic: GameTypes.PlayerCharacteristic,
	cost: int,
) -> bool:
	if not _is_valid_id(perk_id):
		push_error("[GameState] _commit_perk_purchase empty id")
		return false
	if _purchased_perks.has(perk_id):
		return false
	if cost < 0:
		push_error("[GameState] _commit_perk_purchase negative cost: %s" % cost)
		return false
	if _upgrade_points < cost:
		return false
	var prev: int = get_characteristic(characteristic)
	var next: int = prev + 1
	if next > CHAR_MAX:
		push_error("[GameState] _commit_perk_purchase would exceed CHAR_MAX for %s" % characteristic)
		return false
	_upgrade_points -= cost
	_purchased_perks[perk_id] = true
	match characteristic:
		GameTypes.PlayerCharacteristic.MUSCLE:
			_muscle = next
		GameTypes.PlayerCharacteristic.APPEARANCE:
			_appearance = next
		GameTypes.PlayerCharacteristic.CAPITAL:
			_capital = next
		GameTypes.PlayerCharacteristic.AURA:
			_aura = next
		_:
			_purchased_perks.erase(perk_id)
			_upgrade_points += cost
			push_error("[GameState] _commit_perk_purchase unknown characteristic")
			return false
	if cost != 0:
		upgrade_points_changed.emit(_upgrade_points, -cost)
	characteristic_changed.emit(characteristic, next, prev)
	return true


# --- Relationships ---

func get_girl_relationship(girl_id: StringName) -> int:
	if not _is_valid_id(girl_id):
		push_error("[GameState] get_girl_relationship empty id")
		return 0
	return int(_girl_relationships.get(girl_id, 0))


func set_girl_relationship(girl_id: StringName, value: int) -> void:
	if not _is_valid_id(girl_id):
		push_error("[GameState] set_girl_relationship empty id")
		return
	var clamped: int = clampi(value, RELATIONSHIP_MIN, RELATIONSHIP_MAX)
	var prev: int = get_girl_relationship(girl_id)
	if prev == clamped:
		return
	_girl_relationships[girl_id] = clamped
	girl_relationship_changed.emit(girl_id, clamped, clamped - prev)


func add_girl_relationship(girl_id: StringName, delta: int) -> void:
	if not _is_valid_id(girl_id):
		push_error("[GameState] add_girl_relationship empty id")
		return
	if delta == 0:
		return
	var prev: int = get_girl_relationship(girl_id)
	var next: int = clampi(prev + delta, RELATIONSHIP_MIN, RELATIONSHIP_MAX)
	if next == prev:
		return
	_girl_relationships[girl_id] = next
	girl_relationship_changed.emit(girl_id, next, next - prev)


# --- Conquered girls ---

func is_girl_conquered(girl_id: StringName) -> bool:
	if not _is_valid_id(girl_id):
		return false
	return _conquered_girls.has(girl_id)


func mark_girl_conquered(girl_id: StringName) -> bool:
	if not _is_valid_id(girl_id):
		push_error("[GameState] mark_girl_conquered empty id")
		return false
	if _conquered_girls.has(girl_id):
		return false
	_conquered_girls[girl_id] = true
	girl_conquered.emit(girl_id)
	return true


# --- Girl discovery / contacts / clues (MODULE 08) ---

func is_girl_discovered(girl_id: StringName) -> bool:
	if not _is_valid_id(girl_id):
		return false
	return _discovered_girls.has(girl_id)


## Returns true only on first discovery. Ordered unique array for Phone list.
func mark_girl_discovered(girl_id: StringName) -> bool:
	if not _is_valid_id(girl_id):
		push_error("[GameState] mark_girl_discovered empty id")
		return false
	if _discovered_girls.has(girl_id):
		return false
	_discovered_girls.append(girl_id)
	girl_discovered.emit(girl_id)
	return true


func get_discovered_girl_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for gid in _discovered_girls:
		out.append(gid)
	return out


func has_girl_contact(girl_id: StringName) -> bool:
	if not _is_valid_id(girl_id):
		return false
	return _girl_contacts.has(girl_id)


## Contact implies discovered. Returns true only the first time.
func add_girl_contact(girl_id: StringName) -> bool:
	if not _is_valid_id(girl_id):
		push_error("[GameState] add_girl_contact empty id")
		return false
	if _girl_contacts.has(girl_id):
		return false
	if not _discovered_girls.has(girl_id):
		_discovered_girls.append(girl_id)
		girl_discovered.emit(girl_id)
	_girl_contacts[girl_id] = true
	_girl_retry_days_remaining.erase(girl_id)
	girl_contact_added.emit(girl_id)
	return true


func get_girl_contact_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for key in _girl_contacts.keys():
		out.append(key as StringName)
	return out


func is_girl_clue_known(girl_id: StringName, clue_index: int) -> bool:
	if not _is_valid_id(girl_id) or clue_index < 0:
		return false
	if not _known_girl_clues.has(girl_id):
		return false
	var known: Dictionary = _known_girl_clues[girl_id] as Dictionary
	return known.has(clue_index)


func reveal_girl_clue(girl_id: StringName, clue_index: int) -> bool:
	if not _is_valid_id(girl_id):
		push_error("[GameState] reveal_girl_clue empty id")
		return false
	if clue_index < 0:
		push_error("[GameState] reveal_girl_clue negative index")
		return false
	if not _known_girl_clues.has(girl_id):
		_known_girl_clues[girl_id] = {}
	var known: Dictionary = _known_girl_clues[girl_id] as Dictionary
	if known.has(clue_index):
		return false
	known[clue_index] = true
	girl_clue_revealed.emit(girl_id, clue_index)
	return true


func get_known_girl_clue_indices(girl_id: StringName) -> Array[int]:
	var out: Array[int] = []
	if not _is_valid_id(girl_id) or not _known_girl_clues.has(girl_id):
		return out
	var known: Dictionary = _known_girl_clues[girl_id] as Dictionary
	var keys: Array = known.keys()
	keys.sort()
	for k in keys:
		out.append(int(k))
	return out


func is_primary_trait_revealed(girl_id: StringName) -> bool:
	if not _is_valid_id(girl_id):
		return false
	return _revealed_primary_traits.has(girl_id)


func reveal_primary_trait(girl_id: StringName) -> bool:
	if not _is_valid_id(girl_id):
		push_error("[GameState] reveal_primary_trait empty id")
		return false
	if _revealed_primary_traits.has(girl_id):
		return false
	_revealed_primary_traits[girl_id] = true
	primary_trait_revealed.emit(girl_id)
	return true


func record_girl_known_reaction(girl_id: StringName, source_id: StringName, reaction: int) -> bool:
	if not _is_valid_id(girl_id):
		push_error("[GameState] record_girl_known_reaction empty girl id")
		return false
	if not _is_valid_id(source_id):
		push_error("[GameState] record_girl_known_reaction empty source id")
		return false
	if reaction != -1 and reaction != 0 and reaction != 1:
		push_error("[GameState] record_girl_known_reaction invalid reaction %s" % reaction)
		return false
	if not _known_girl_reactions.has(girl_id):
		_known_girl_reactions[girl_id] = {}
	var by_source: Dictionary = _known_girl_reactions[girl_id] as Dictionary
	by_source[source_id] = reaction
	return true


func get_girl_known_reactions(girl_id: StringName) -> Dictionary:
	var out: Dictionary = {}
	if not _is_valid_id(girl_id) or not _known_girl_reactions.has(girl_id):
		return out
	var by_source: Dictionary = _known_girl_reactions[girl_id] as Dictionary
	for key in by_source.keys():
		out[key] = int(by_source[key])
	return out


func get_girl_retry_days_remaining(girl_id: StringName) -> int:
	if not _is_valid_id(girl_id):
		return 0
	return int(_girl_retry_days_remaining.get(girl_id, 0))


func set_girl_retry_days_remaining(girl_id: StringName, days: int) -> void:
	if not _is_valid_id(girl_id):
		push_error("[GameState] set_girl_retry_days_remaining empty id")
		return
	if days <= 0:
		_girl_retry_days_remaining.erase(girl_id)
	else:
		_girl_retry_days_remaining[girl_id] = days


func is_girl_available_for_discovery(girl_id: StringName) -> bool:
	if not _is_valid_id(girl_id):
		return false
	return get_girl_retry_days_remaining(girl_id) <= 0


# --- Date cooldown / event history / secondary reveal (MODULE 10) ---

func get_girl_date_cooldown_days_remaining(girl_id: StringName) -> int:
	if not _is_valid_id(girl_id):
		return 0
	return int(_girl_date_cooldown_days_remaining.get(girl_id, 0))


func set_girl_date_cooldown_days_remaining(girl_id: StringName, days: int) -> void:
	if not _is_valid_id(girl_id):
		push_error("[GameState] set_girl_date_cooldown_days_remaining empty id")
		return
	if days <= 0:
		_girl_date_cooldown_days_remaining.erase(girl_id)
	else:
		_girl_date_cooldown_days_remaining[girl_id] = days


func is_girl_available_for_date(girl_id: StringName) -> bool:
	if not _is_valid_id(girl_id):
		return false
	return get_girl_date_cooldown_days_remaining(girl_id) <= 0


func get_girl_ids_with_date_cooldown() -> Array[StringName]:
	var out: Array[StringName] = []
	for key in _girl_date_cooldown_days_remaining.keys():
		var gid: StringName = key as StringName
		if get_girl_date_cooldown_days_remaining(gid) > 0:
			out.append(gid)
	return out


func get_girl_played_dating_event_ids(girl_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	if not _is_valid_id(girl_id) or not _girl_played_dating_event_ids.has(girl_id):
		return out
	var stored: Array = _girl_played_dating_event_ids[girl_id] as Array
	for eid in stored:
		out.append(eid as StringName)
	return out


func record_girl_played_dating_events(girl_id: StringName, event_ids: Array[StringName]) -> void:
	if not _is_valid_id(girl_id):
		push_error("[GameState] record_girl_played_dating_events empty id")
		return
	var hist: Array[StringName] = get_girl_played_dating_event_ids(girl_id)
	for eid in event_ids:
		if String(eid) == "":
			continue
		if not hist.has(eid):
			hist.append(eid)
	_girl_played_dating_event_ids[girl_id] = hist
	var last: Array[StringName] = []
	for eid2 in event_ids:
		last.append(eid2)
	_girl_last_date_event_ids[girl_id] = last


func clear_girl_played_dating_event_history(girl_id: StringName) -> void:
	if not _is_valid_id(girl_id):
		push_error("[GameState] clear_girl_played_dating_event_history empty id")
		return
	_girl_played_dating_event_ids.erase(girl_id)


func get_girl_last_date_event_ids(girl_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	if not _is_valid_id(girl_id) or not _girl_last_date_event_ids.has(girl_id):
		return out
	var stored: Array = _girl_last_date_event_ids[girl_id] as Array
	for eid in stored:
		out.append(eid as StringName)
	return out


func is_secondary_trait_revealed(girl_id: StringName) -> bool:
	if not _is_valid_id(girl_id):
		return false
	return _revealed_secondary_traits.has(girl_id)


func reveal_secondary_trait(girl_id: StringName) -> bool:
	if not _is_valid_id(girl_id):
		push_error("[GameState] reveal_secondary_trait empty id")
		return false
	if _revealed_secondary_traits.has(girl_id):
		return false
	_revealed_secondary_traits[girl_id] = true
	secondary_trait_revealed.emit(girl_id)
	return true


# --- Locations ---

func is_location_unlocked(location_id: StringName) -> bool:
	if not _is_valid_id(location_id):
		return false
	return _unlocked_locations.has(location_id)


func unlock_location(location_id: StringName) -> bool:
	if not _is_valid_id(location_id):
		push_error("[GameState] unlock_location empty id")
		return false
	if _unlocked_locations.has(location_id):
		return false
	_unlocked_locations[location_id] = true
	location_unlocked.emit(location_id)
	return true


# --- Story flags ---

func get_story_flag(flag_id: StringName) -> bool:
	if not _is_valid_id(flag_id):
		return false
	return bool(_story_flags.get(flag_id, false))


func set_story_flag(flag_id: StringName, value: bool) -> void:
	if not _is_valid_id(flag_id):
		push_error("[GameState] set_story_flag empty id")
		return
	var prev: bool = get_story_flag(flag_id)
	if prev == value:
		return
	if value:
		_story_flags[flag_id] = true
	else:
		_story_flags.erase(flag_id)
	story_flag_changed.emit(flag_id, value)


# --- Clones / late rates ---

func get_total_clones() -> int:
	return _total_clones


func get_clones_working() -> int:
	return _clones_working


func get_clones_dating() -> int:
	return _clones_dating


func get_free_clones() -> int:
	return _total_clones - _clones_working - _clones_dating


func set_clone_counts(total: int, working: int, dating: int) -> bool:
	if total < 0 or working < 0 or dating < 0:
		push_error("[GameState] set_clone_counts negative values")
		return false
	if working + dating > total:
		push_error("[GameState] set_clone_counts invariant fail working+dating>total")
		return false
	if _total_clones == total and _clones_working == working and _clones_dating == dating:
		return true
	_total_clones = total
	_clones_working = working
	_clones_dating = dating
	clone_counts_changed.emit(_total_clones, _clones_working, _clones_dating, get_free_clones())
	return true


func get_money_per_minute() -> float:
	return _money_per_minute


func get_dates_per_minute() -> float:
	return _dates_per_minute


func set_late_rates(money_per_minute: float, dates_per_minute: float) -> bool:
	if money_per_minute < 0.0 or dates_per_minute < 0.0:
		push_error("[GameState] set_late_rates negative")
		return false
	if is_equal_approx(_money_per_minute, money_per_minute) and is_equal_approx(_dates_per_minute, dates_per_minute):
		return true
	_money_per_minute = money_per_minute
	_dates_per_minute = dates_per_minute
	late_rates_changed.emit(_money_per_minute, _dates_per_minute)
	return true


## Debug-only snapshot string.
func debug_dump() -> String:
	if not OS.is_debug_build() and not OS.has_feature("editor"):
		return ""
	return "stage=%s money=%s auth=%s xp=%s up=%s chars=%s/%s/%s/%s perks=%s defeated_rivals=%s clones=%s/%s/%s free=%s rates=%s/%s rel=%s conquered=%s locs=%s flags=%s" % [
		_stage, _money, _authority, _experience, _upgrade_points,
		_muscle, _appearance, _capital, _aura,
		_purchased_perks.size(),
		_defeated_rivals.size(),
		_total_clones, _clones_working, _clones_dating, get_free_clones(),
		_money_per_minute, _dates_per_minute,
		_girl_relationships.size(), _conquered_girls.size(),
		_unlocked_locations.size(), _story_flags.size(),
	]


func _is_valid_id(id_value: StringName) -> bool:
	return String(id_value) != ""
