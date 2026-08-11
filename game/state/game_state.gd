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
signal clone_upgrade_changed(upgrade_type: int, new_level: int, previous_level: int)
signal world_reach_changed(new_value: int, delta: int)
signal global_upgrade_changed(upgrade_type: int, new_level: int, previous_level: int)
signal media_attention_changed(new_value: int, delta: int)
signal state_reset()
signal state_restored()

## New-game tuning value; intentionally not part of the save payload.
var starting_money: int = 90

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
var _clone_production_upgrade_level: int = 0
var _clone_work_upgrade_level: int = 0
var _clone_dating_upgrade_level: int = 0
var _world_reach: int = 0
var _global_production_upgrade_level: int = 0
var _global_work_upgrade_level: int = 0
var _global_dating_upgrade_level: int = 0
var _purchased_perks: Dictionary = {}
var _defeated_rivals: Dictionary = {}
var _salary_initialized: bool = false
var _salary_period_index: int = 0
var _pending_salary: int = 0
var _salary_manual_cycle_seen: bool = false
var _salary_advance_used_period: int = -1
var _media_photo_session_completed: bool = false
var _media_attention: int = 0
var _media_photo_pose_by_shot: Dictionary = {}
var _media_published_photo_ids: Array[StringName] = []
var _media_last_photo_publish_day: int = -1
var _media_incoming_offer_girl_ids: Array[StringName] = []
var _media_read_offer_girl_ids: Array[StringName] = []
var _media_feed_event_ids: Array[StringName] = []
var _dating_overload_started: bool = false
var _dating_overload_start_day: int = -1
var _dating_overload_next_request_id: int = 1
var _dating_overload_requests: Array = []
var _dating_overload_candidate_cursor: int = 0
var _dating_overload_last_personal_date_day: int = -1
var _dating_overload_personal_dates_completed: int = 0
var _dating_overload_last_feed_boost_day: int = -1
var _dating_overload_boost_pending: bool = false
var _dating_overload_problem_recognized: bool = false

const CHAR_MIN: int = 0
const MEDIA_ATTENTION_MIN: int = 0
const MEDIA_ATTENTION_MAX: int = 100
const CHAR_MAX: int = 10
const RELATIONSHIP_MIN: int = -5
const RELATIONSHIP_MAX: int = 5


func _ready() -> void:
	reset_for_new_game()
	DfLog.info("MODULE_02", "GameState ready")


func reset_for_new_game() -> void:
	_stage = GameTypes.GameStage.PROLOGUE
	_money = maxi(0, starting_money)
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
	_clone_production_upgrade_level = 0
	_clone_work_upgrade_level = 0
	_clone_dating_upgrade_level = 0
	_world_reach = 0
	_global_production_upgrade_level = 0
	_global_work_upgrade_level = 0
	_global_dating_upgrade_level = 0
	_purchased_perks = {}
	_defeated_rivals = {}
	_salary_initialized = false
	_salary_period_index = 0
	_pending_salary = 0
	_salary_manual_cycle_seen = false
	_salary_advance_used_period = -1
	_media_photo_session_completed = false
	_media_attention = 0
	_media_photo_pose_by_shot = {}
	_media_published_photo_ids = []
	_media_last_photo_publish_day = -1
	_media_incoming_offer_girl_ids = []
	_media_read_offer_girl_ids = []
	_media_feed_event_ids = []
	_dating_overload_started = false
	_dating_overload_start_day = -1
	_dating_overload_next_request_id = 1
	_dating_overload_requests = []
	_dating_overload_candidate_cursor = 0
	_dating_overload_last_personal_date_day = -1
	_dating_overload_personal_dates_completed = 0
	_dating_overload_last_feed_boost_day = -1
	_dating_overload_boost_pending = false
	_dating_overload_problem_recognized = false
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


# --- Media / Attention (MODULE 15) ---

func get_media_attention() -> int:
	return _media_attention


func set_media_attention(value: int) -> void:
	var clamped: int = clampi(value, MEDIA_ATTENTION_MIN, MEDIA_ATTENTION_MAX)
	var prev: int = _media_attention
	if prev == clamped:
		return
	_media_attention = clamped
	media_attention_changed.emit(_media_attention, clamped - prev)


## Returns attention after clamp. Attention only grows in MODULE 15 gameplay.
func add_media_attention(amount: int) -> int:
	if amount < 0:
		push_error("[GameState] add_media_attention negative amount: %s" % amount)
		return _media_attention
	if amount == 0:
		return _media_attention
	var prev: int = _media_attention
	var next: int = clampi(prev + amount, MEDIA_ATTENTION_MIN, MEDIA_ATTENTION_MAX)
	var delta: int = next - prev
	if delta == 0:
		return _media_attention
	_media_attention = next
	media_attention_changed.emit(_media_attention, delta)
	return _media_attention


func is_media_photo_session_completed() -> bool:
	return _media_photo_session_completed


## Returns true only the first time.
func mark_media_photo_session_completed() -> bool:
	if _media_photo_session_completed:
		return false
	_media_photo_session_completed = true
	return true


func set_media_photo_pose(shot_id: StringName, pose_id: StringName) -> bool:
	if not _is_valid_id(shot_id) or not _is_valid_id(pose_id):
		push_error("[GameState] set_media_photo_pose empty id")
		return false
	if _media_photo_session_completed:
		push_error("[GameState] set_media_photo_pose rejected after session completion")
		return false
	_media_photo_pose_by_shot[shot_id] = pose_id
	return true


func get_media_photo_pose(shot_id: StringName) -> StringName:
	if not _is_valid_id(shot_id):
		return &""
	return _media_photo_pose_by_shot.get(shot_id, &"") as StringName


func get_media_photo_pose_map() -> Dictionary:
	var out: Dictionary = {}
	for key in _media_photo_pose_by_shot.keys():
		out[key] = _media_photo_pose_by_shot[key]
	return out


func is_media_photo_published(photo_id: StringName) -> bool:
	if not _is_valid_id(photo_id):
		return false
	return _media_published_photo_ids.has(photo_id)


## Ordered unique. Returns true only the first time.
func mark_media_photo_published(photo_id: StringName) -> bool:
	if not _is_valid_id(photo_id):
		push_error("[GameState] mark_media_photo_published empty id")
		return false
	if _media_published_photo_ids.has(photo_id):
		return false
	_media_published_photo_ids.append(photo_id)
	return true


func get_media_published_photo_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for pid in _media_published_photo_ids:
		out.append(pid)
	return out


func get_media_last_photo_publish_day() -> int:
	return _media_last_photo_publish_day


func set_media_last_photo_publish_day(day: int) -> void:
	_media_last_photo_publish_day = day


## Ordered unique. Duplicate rejected.
func append_media_feed_event(event_id: StringName) -> bool:
	if not _is_valid_id(event_id):
		push_error("[GameState] append_media_feed_event empty id")
		return false
	if _media_feed_event_ids.has(event_id):
		return false
	_media_feed_event_ids.append(event_id)
	return true


func get_media_feed_event_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for eid in _media_feed_event_ids:
		out.append(eid)
	return out


func has_media_incoming_offer(girl_id: StringName) -> bool:
	if not _is_valid_id(girl_id):
		return false
	return _media_incoming_offer_girl_ids.has(girl_id)


## Ordered unique. Returns true only the first time.
func add_media_incoming_offer(girl_id: StringName) -> bool:
	if not _is_valid_id(girl_id):
		push_error("[GameState] add_media_incoming_offer empty id")
		return false
	if _media_incoming_offer_girl_ids.has(girl_id):
		return false
	_media_incoming_offer_girl_ids.append(girl_id)
	return true


func get_media_incoming_offer_girl_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for gid in _media_incoming_offer_girl_ids:
		out.append(gid)
	return out


func is_media_offer_read(girl_id: StringName) -> bool:
	if not _is_valid_id(girl_id):
		return false
	return _media_read_offer_girl_ids.has(girl_id)


## Returns true only the first time.
func mark_media_offer_read(girl_id: StringName) -> bool:
	if not _is_valid_id(girl_id):
		push_error("[GameState] mark_media_offer_read empty id")
		return false
	if not _media_incoming_offer_girl_ids.has(girl_id):
		return false
	if _media_read_offer_girl_ids.has(girl_id):
		return false
	_media_read_offer_girl_ids.append(girl_id)
	return true


# --- Dating Overload (MODULE 16) ---

func is_dating_overload_started() -> bool:
	return _dating_overload_started


## Returns true only the first time.
func mark_dating_overload_started(day: int) -> bool:
	if _dating_overload_started:
		return false
	_dating_overload_started = true
	_dating_overload_start_day = day
	return true


func get_dating_overload_start_day() -> int:
	return _dating_overload_start_day


func allocate_dating_demand_request_id() -> int:
	var id: int = _dating_overload_next_request_id
	_dating_overload_next_request_id += 1
	return id


func append_dating_demand(entry: DatingDemandEntry) -> bool:
	if entry == null:
		push_error("[GameState] append_dating_demand null entry")
		return false
	if entry.request_id <= 0:
		push_error("[GameState] append_dating_demand invalid request_id")
		return false
	if not _is_valid_id(entry.girl_id):
		push_error("[GameState] append_dating_demand empty girl_id")
		return false
	for existing in _dating_overload_requests:
		var e: DatingDemandEntry = existing as DatingDemandEntry
		if e != null and e.request_id == entry.request_id:
			push_error("[GameState] append_dating_demand duplicate request_id %s" % entry.request_id)
			return false
	_dating_overload_requests.append(entry)
	return true


## Snapshot copies — caller must not mutate GameState internals.
func get_dating_demand_entries() -> Array:
	var out: Array = []
	for existing in _dating_overload_requests:
		var e: DatingDemandEntry = existing as DatingDemandEntry
		if e != null:
			out.append(e.duplicate_entry())
	return out


func set_dating_demand_status(request_id: int, status: int) -> bool:
	var entry: DatingDemandEntry = _find_dating_demand(request_id)
	if entry == null:
		return false
	entry.status = status as DatingOverloadTypes.DatingDemandStatus
	return true


func mark_dating_demand_fulfilled(request_id: int, day: int) -> bool:
	var entry: DatingDemandEntry = _find_dating_demand(request_id)
	if entry == null:
		return false
	if entry.status == DatingOverloadTypes.DatingDemandStatus.FULFILLED:
		return false
	entry.status = DatingOverloadTypes.DatingDemandStatus.FULFILLED
	entry.fulfilled_day = day
	return true


func get_dating_overload_candidate_cursor() -> int:
	return _dating_overload_candidate_cursor


func set_dating_overload_candidate_cursor(value: int) -> void:
	_dating_overload_candidate_cursor = maxi(0, value)


func get_dating_overload_last_personal_date_day() -> int:
	return _dating_overload_last_personal_date_day


func set_dating_overload_last_personal_date_day(day: int) -> void:
	_dating_overload_last_personal_date_day = day


func get_dating_overload_personal_dates_completed() -> int:
	return _dating_overload_personal_dates_completed


func increment_dating_overload_personal_dates_completed() -> int:
	_dating_overload_personal_dates_completed += 1
	return _dating_overload_personal_dates_completed


func get_dating_overload_last_feed_boost_day() -> int:
	return _dating_overload_last_feed_boost_day


func set_dating_overload_last_feed_boost_day(day: int) -> void:
	_dating_overload_last_feed_boost_day = day


func is_dating_overload_boost_pending() -> bool:
	return _dating_overload_boost_pending


func set_dating_overload_boost_pending(value: bool) -> void:
	_dating_overload_boost_pending = value


func is_dating_overload_problem_recognized() -> bool:
	return _dating_overload_problem_recognized


## Returns true only the first time.
func mark_dating_overload_problem_recognized() -> bool:
	if _dating_overload_problem_recognized:
		return false
	_dating_overload_problem_recognized = true
	return true


func _find_dating_demand(request_id: int) -> DatingDemandEntry:
	for existing in _dating_overload_requests:
		var e: DatingDemandEntry = existing as DatingDemandEntry
		if e != null and e.request_id == request_id:
			return e
	return null


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


# --- World Reach / global upgrades (MODULE 20) ---

const WORLD_REACH_MIN: int = 0
const WORLD_REACH_MAX: int = 100
const GLOBAL_UPGRADE_MAX_LEVEL: int = 3


func get_world_reach() -> int:
	return _world_reach


func set_world_reach(value: int) -> void:
	var clamped: int = clampi(value, WORLD_REACH_MIN, WORLD_REACH_MAX)
	var prev: int = _world_reach
	if prev == clamped:
		return
	_world_reach = clamped
	world_reach_changed.emit(_world_reach, clamped - prev)


func add_world_reach(amount: int) -> int:
	if amount < 0:
		push_error("[GameState] add_world_reach negative amount: %s" % amount)
		return _world_reach
	if amount == 0:
		return _world_reach
	var prev: int = _world_reach
	var next: int = clampi(prev + amount, WORLD_REACH_MIN, WORLD_REACH_MAX)
	var delta: int = next - prev
	if delta == 0:
		return _world_reach
	_world_reach = next
	world_reach_changed.emit(_world_reach, delta)
	return _world_reach


func get_global_production_upgrade_level() -> int:
	return _global_production_upgrade_level


func get_global_work_upgrade_level() -> int:
	return _global_work_upgrade_level


func get_global_dating_upgrade_level() -> int:
	return _global_dating_upgrade_level


func set_global_upgrade_level(upgrade_type: int, level: int) -> bool:
	if level < 0 or level > GLOBAL_UPGRADE_MAX_LEVEL:
		push_error("[GameState] global upgrade level out of range: %s" % level)
		return false
	var prev: int = 0
	match upgrade_type:
		int(LateGameTypes.GlobalUpgradeType.GLOBAL_PRODUCTION):
			prev = _global_production_upgrade_level
			if prev == level:
				return true
			_global_production_upgrade_level = level
		int(LateGameTypes.GlobalUpgradeType.GLOBAL_WORK):
			prev = _global_work_upgrade_level
			if prev == level:
				return true
			_global_work_upgrade_level = level
		int(LateGameTypes.GlobalUpgradeType.GLOBAL_DATING):
			prev = _global_dating_upgrade_level
			if prev == level:
				return true
			_global_dating_upgrade_level = level
		_:
			push_error("[GameState] unknown global upgrade type: %s" % upgrade_type)
			return false
	global_upgrade_changed.emit(upgrade_type, level, prev)
	return true


# --- Clone upgrades (MODULE 18) ---

const CLONE_UPGRADE_MAX_LEVEL: int = 5


func get_clone_production_upgrade_level() -> int:
	return _clone_production_upgrade_level


func get_clone_work_upgrade_level() -> int:
	return _clone_work_upgrade_level


func get_clone_dating_upgrade_level() -> int:
	return _clone_dating_upgrade_level


func set_clone_production_upgrade_level(level: int) -> bool:
	return _set_clone_upgrade_level(CloneIncrementalTypes.UpgradeType.PRODUCTION_SPEED, level)


func set_clone_work_upgrade_level(level: int) -> bool:
	return _set_clone_upgrade_level(CloneIncrementalTypes.UpgradeType.WORK_EFFICIENCY, level)


func set_clone_dating_upgrade_level(level: int) -> bool:
	return _set_clone_upgrade_level(CloneIncrementalTypes.UpgradeType.DATING_EFFICIENCY, level)


func _set_clone_upgrade_level(upgrade_type: int, level: int) -> bool:
	if level < 0 or level > CLONE_UPGRADE_MAX_LEVEL:
		push_error("[GameState] clone upgrade level out of range: %s" % level)
		return false
	var prev: int = 0
	match upgrade_type:
		int(CloneIncrementalTypes.UpgradeType.PRODUCTION_SPEED):
			prev = _clone_production_upgrade_level
			if prev == level:
				return true
			_clone_production_upgrade_level = level
		int(CloneIncrementalTypes.UpgradeType.WORK_EFFICIENCY):
			prev = _clone_work_upgrade_level
			if prev == level:
				return true
			_clone_work_upgrade_level = level
		int(CloneIncrementalTypes.UpgradeType.DATING_EFFICIENCY):
			prev = _clone_dating_upgrade_level
			if prev == level:
				return true
			_clone_dating_upgrade_level = level
		_:
			push_error("[GameState] unknown clone upgrade type: %s" % upgrade_type)
			return false
	clone_upgrade_changed.emit(upgrade_type, level, prev)
	return true


# --- MODULE 24 Save / Load domain API ---

func encode_dating_demand_entry(entry: DatingDemandEntry) -> Dictionary:
	if entry == null:
		return {}
	return {
		"request_id": entry.request_id,
		"girl_id": String(entry.girl_id),
		"created_day": entry.created_day,
		"appointment_day": entry.appointment_day,
		"slot": int(entry.slot),
		"status": int(entry.status),
		"fulfilled_day": entry.fulfilled_day,
	}


func decode_dating_demand_entry(data: Dictionary) -> DatingDemandEntry:
	if data == null or data.is_empty():
		return null
	if not data.has("request_id") or not data.has("girl_id"):
		return null
	if not data.has("created_day") or not data.has("appointment_day"):
		return null
	if not data.has("slot") or not data.has("status") or not data.has("fulfilled_day"):
		return null
	var request_id: int = int(data["request_id"])
	var girl_id: StringName = StringName(str(data["girl_id"]))
	var created_day: int = int(data["created_day"])
	var appointment_day: int = int(data["appointment_day"])
	var slot_i: int = int(data["slot"])
	var status_i: int = int(data["status"])
	var fulfilled_day: int = int(data["fulfilled_day"])
	if request_id <= 0 or String(girl_id) == "":
		return null
	if (
		slot_i != int(DatingOverloadTypes.DatingDemandSlot.EARLY_EVENING)
		and slot_i != int(DatingOverloadTypes.DatingDemandSlot.LATE_EVENING)
	):
		return null
	if (
		status_i != int(DatingOverloadTypes.DatingDemandStatus.WAITING)
		and status_i != int(DatingOverloadTypes.DatingDemandStatus.OVERDUE)
		and status_i != int(DatingOverloadTypes.DatingDemandStatus.FULFILLED)
	):
		return null
	var entry: DatingDemandEntry = DatingDemandEntry.new()
	entry.request_id = request_id
	entry.girl_id = girl_id
	entry.created_day = created_day
	entry.appointment_day = appointment_day
	entry.slot = slot_i as DatingOverloadTypes.DatingDemandSlot
	entry.status = status_i as DatingOverloadTypes.DatingDemandStatus
	entry.fulfilled_day = fulfilled_day
	return entry


func export_save_state() -> Dictionary:
	var characteristics: Dictionary = {
		"muscle": _muscle,
		"appearance": _appearance,
		"capital": _capital,
		"aura": _aura,
	}
	var girls: Dictionary = {
		"relationships": _export_string_int_map(_girl_relationships),
		"conquered": _export_id_set_array(_conquered_girls),
		"discovered": _export_string_name_array(_discovered_girls),
		"contacts": _export_id_set_array(_girl_contacts),
		"known_clues": _export_known_clues(_known_girl_clues),
		"revealed_primary_traits": _export_id_set_array(_revealed_primary_traits),
		"known_reactions": _export_known_reactions(_known_girl_reactions),
		"retry_days_remaining": _export_string_int_map(_girl_retry_days_remaining),
		"date_cooldown_days_remaining": _export_string_int_map(_girl_date_cooldown_days_remaining),
		"played_dating_event_ids": _export_girl_event_history(_girl_played_dating_event_ids),
		"last_date_event_ids": _export_girl_event_history(_girl_last_date_event_ids),
		"revealed_secondary_traits": _export_id_set_array(_revealed_secondary_traits),
	}
	var salary: Dictionary = {
		"initialized": _salary_initialized,
		"period_index": _salary_period_index,
		"pending_salary": _pending_salary,
		"manual_cycle_seen": _salary_manual_cycle_seen,
		"advance_used_period": _salary_advance_used_period,
	}
	var media: Dictionary = {
		"photo_session_completed": _media_photo_session_completed,
		"attention": _media_attention,
		"photo_pose_by_shot": _export_string_string_map(_media_photo_pose_by_shot),
		"published_photo_ids": _export_string_name_array(_media_published_photo_ids),
		"last_photo_publish_day": _media_last_photo_publish_day,
		"incoming_offer_girl_ids": _export_string_name_array(_media_incoming_offer_girl_ids),
		"read_offer_girl_ids": _export_string_name_array(_media_read_offer_girl_ids),
		"feed_event_ids": _export_string_name_array(_media_feed_event_ids),
	}
	var requests: Array = []
	for existing in _dating_overload_requests:
		var e: DatingDemandEntry = existing as DatingDemandEntry
		if e != null:
			requests.append(encode_dating_demand_entry(e))
	var dating_overload: Dictionary = {
		"started": _dating_overload_started,
		"start_day": _dating_overload_start_day,
		"next_request_id": _dating_overload_next_request_id,
		"requests": requests,
		"candidate_cursor": _dating_overload_candidate_cursor,
		"last_personal_date_day": _dating_overload_last_personal_date_day,
		"personal_dates_completed": _dating_overload_personal_dates_completed,
		"last_feed_boost_day": _dating_overload_last_feed_boost_day,
		"boost_pending": _dating_overload_boost_pending,
		"problem_recognized": _dating_overload_problem_recognized,
	}
	var clones: Dictionary = {
		"total": _total_clones,
		"working": _clones_working,
		"dating": _clones_dating,
		"local_upgrade_production": _clone_production_upgrade_level,
		"local_upgrade_work": _clone_work_upgrade_level,
		"local_upgrade_dating": _clone_dating_upgrade_level,
	}
	var late_game: Dictionary = {
		"world_reach": _world_reach,
		"global_upgrade_production": _global_production_upgrade_level,
		"global_upgrade_work": _global_work_upgrade_level,
		"global_upgrade_dating": _global_dating_upgrade_level,
	}
	return {
		"stage": int(_stage),
		"money": _money,
		"authority": _authority,
		"experience": _experience,
		"upgrade_points": _upgrade_points,
		"characteristics": characteristics,
		"purchased_perks": _export_id_set_array(_purchased_perks),
		"defeated_rivals": _export_id_set_array(_defeated_rivals),
		"girls": girls,
		"unlocked_locations": _export_id_set_array(_unlocked_locations),
		"story_flags": _export_story_flags(_story_flags),
		"salary": salary,
		"media": media,
		"dating_overload": dating_overload,
		"clones": clones,
		"late_game": late_game,
	}


func restore_save_state(data: Dictionary) -> bool:
	var decoded: Dictionary = _validate_save_state(data)
	if decoded.is_empty():
		push_error("[GameState] restore_save_state validation failed")
		return false
	_apply_validated_save_state(decoded)
	state_restored.emit()
	return true


func _validate_save_state(data: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	if data == null or data.is_empty():
		return {}
	var required_top: Array[String] = [
		"stage", "money", "authority", "experience", "upgrade_points",
		"characteristics", "purchased_perks", "defeated_rivals", "girls",
		"unlocked_locations", "story_flags", "salary", "media",
		"dating_overload", "clones", "late_game",
	]
	for key in required_top:
		if not data.has(key):
			push_error("[GameState] restore missing key: %s" % key)
			return {}
	var stage_i: int = int(data["stage"])
	if stage_i < int(GameTypes.GameStage.PROLOGUE) or stage_i > int(GameTypes.GameStage.FINALE):
		push_error("[GameState] restore invalid stage: %s" % stage_i)
		return {}
	var money: int = int(data["money"])
	var authority: int = int(data["authority"])
	var experience: int = int(data["experience"])
	var upgrade_points: int = int(data["upgrade_points"])
	if money < 0 or authority < 0 or experience < 0 or upgrade_points < 0:
		push_error("[GameState] restore negative economy")
		return {}
	var chars_raw: Variant = data["characteristics"]
	if typeof(chars_raw) != TYPE_DICTIONARY:
		return {}
	var chars: Dictionary = chars_raw as Dictionary
	for ck in ["muscle", "appearance", "capital", "aura"]:
		if not chars.has(ck):
			return {}
	var muscle: int = int(chars["muscle"])
	var appearance: int = int(chars["appearance"])
	var capital: int = int(chars["capital"])
	var aura: int = int(chars["aura"])
	if (
		muscle < CHAR_MIN or muscle > CHAR_MAX
		or appearance < CHAR_MIN or appearance > CHAR_MAX
		or capital < CHAR_MIN or capital > CHAR_MAX
		or aura < CHAR_MIN or aura > CHAR_MAX
	):
		push_error("[GameState] restore characteristic out of range")
		return {}
	var perks_v: Variant = _decode_string_array(data["purchased_perks"])
	var rivals_v: Variant = _decode_string_array(data["defeated_rivals"])
	var locations_v: Variant = _decode_string_array(data["unlocked_locations"])
	if perks_v == null or rivals_v == null or locations_v == null:
		return {}
	var perks: Array = perks_v as Array
	var rivals: Array = rivals_v as Array
	var locations: Array = locations_v as Array
	var girls_raw: Variant = data["girls"]
	if typeof(girls_raw) != TYPE_DICTIONARY:
		return {}
	var girls_decoded: Dictionary = _validate_girls_block(girls_raw as Dictionary)
	if girls_decoded.is_empty():
		return {}
	var flags_raw: Variant = data["story_flags"]
	if typeof(flags_raw) != TYPE_DICTIONARY:
		return {}
	var story_flags: Dictionary = _decode_story_flags(flags_raw as Dictionary)
	var salary_raw: Variant = data["salary"]
	if typeof(salary_raw) != TYPE_DICTIONARY:
		return {}
	var salary: Dictionary = _validate_salary_block(salary_raw as Dictionary)
	if salary.is_empty():
		return {}
	var media_raw: Variant = data["media"]
	if typeof(media_raw) != TYPE_DICTIONARY:
		return {}
	var media: Dictionary = _validate_media_block(media_raw as Dictionary)
	if media.is_empty():
		return {}
	var overload_raw: Variant = data["dating_overload"]
	if typeof(overload_raw) != TYPE_DICTIONARY:
		return {}
	var overload: Dictionary = _validate_dating_overload_block(overload_raw as Dictionary)
	if overload.is_empty():
		return {}
	var clones_raw: Variant = data["clones"]
	if typeof(clones_raw) != TYPE_DICTIONARY:
		return {}
	var clones: Dictionary = _validate_clones_block(clones_raw as Dictionary)
	if clones.is_empty():
		return {}
	var late_raw: Variant = data["late_game"]
	if typeof(late_raw) != TYPE_DICTIONARY:
		return {}
	var late_game: Dictionary = _validate_late_game_block(late_raw as Dictionary)
	if late_game.is_empty():
		return {}
	out["stage"] = stage_i
	out["money"] = money
	out["authority"] = authority
	out["experience"] = experience
	out["upgrade_points"] = upgrade_points
	out["muscle"] = muscle
	out["appearance"] = appearance
	out["capital"] = capital
	out["aura"] = aura
	out["purchased_perks"] = perks
	out["defeated_rivals"] = rivals
	out["unlocked_locations"] = locations
	out["girls"] = girls_decoded
	out["story_flags"] = story_flags
	out["salary"] = salary
	out["media"] = media
	out["dating_overload"] = overload
	out["clones"] = clones
	out["late_game"] = late_game
	return out


func _apply_validated_save_state(decoded: Dictionary) -> void:
	# Silent atomic replacement — no grant/reward gameplay APIs or signals.
	_stage = decoded["stage"] as GameTypes.GameStage
	_money = int(decoded["money"])
	_authority = int(decoded["authority"])
	_experience = int(decoded["experience"])
	_upgrade_points = int(decoded["upgrade_points"])
	_muscle = int(decoded["muscle"])
	_appearance = int(decoded["appearance"])
	_capital = int(decoded["capital"])
	_aura = int(decoded["aura"])
	_purchased_perks = _ids_to_set(decoded["purchased_perks"] as Array)
	_defeated_rivals = _ids_to_set(decoded["defeated_rivals"] as Array)
	_unlocked_locations = _ids_to_set(decoded["unlocked_locations"] as Array)
	var girls: Dictionary = decoded["girls"] as Dictionary
	_girl_relationships = girls["relationships"] as Dictionary
	_conquered_girls = _ids_to_set(girls["conquered"] as Array)
	_discovered_girls = _to_string_name_array(girls["discovered"] as Array)
	_girl_contacts = _ids_to_set(girls["contacts"] as Array)
	_known_girl_clues = girls["known_clues"] as Dictionary
	_revealed_primary_traits = _ids_to_set(girls["revealed_primary_traits"] as Array)
	_known_girl_reactions = girls["known_reactions"] as Dictionary
	_girl_retry_days_remaining = girls["retry_days_remaining"] as Dictionary
	_girl_date_cooldown_days_remaining = girls["date_cooldown_days_remaining"] as Dictionary
	_girl_played_dating_event_ids = girls["played_dating_event_ids"] as Dictionary
	_girl_last_date_event_ids = girls["last_date_event_ids"] as Dictionary
	_revealed_secondary_traits = _ids_to_set(girls["revealed_secondary_traits"] as Array)
	_story_flags = decoded["story_flags"] as Dictionary
	var salary: Dictionary = decoded["salary"] as Dictionary
	_salary_initialized = bool(salary["initialized"])
	_salary_period_index = int(salary["period_index"])
	_pending_salary = int(salary["pending_salary"])
	_salary_manual_cycle_seen = bool(salary["manual_cycle_seen"])
	_salary_advance_used_period = int(salary["advance_used_period"])
	var media: Dictionary = decoded["media"] as Dictionary
	_media_photo_session_completed = bool(media["photo_session_completed"])
	_media_attention = int(media["attention"])
	_media_photo_pose_by_shot = media["photo_pose_by_shot"] as Dictionary
	_media_published_photo_ids = _to_string_name_array(media["published_photo_ids"] as Array)
	_media_last_photo_publish_day = int(media["last_photo_publish_day"])
	_media_incoming_offer_girl_ids = _to_string_name_array(media["incoming_offer_girl_ids"] as Array)
	_media_read_offer_girl_ids = _to_string_name_array(media["read_offer_girl_ids"] as Array)
	_media_feed_event_ids = _to_string_name_array(media["feed_event_ids"] as Array)
	var overload: Dictionary = decoded["dating_overload"] as Dictionary
	_dating_overload_started = bool(overload["started"])
	_dating_overload_start_day = int(overload["start_day"])
	_dating_overload_next_request_id = int(overload["next_request_id"])
	_dating_overload_requests = overload["requests"] as Array
	_dating_overload_candidate_cursor = int(overload["candidate_cursor"])
	_dating_overload_last_personal_date_day = int(overload["last_personal_date_day"])
	_dating_overload_personal_dates_completed = int(overload["personal_dates_completed"])
	_dating_overload_last_feed_boost_day = int(overload["last_feed_boost_day"])
	_dating_overload_boost_pending = bool(overload["boost_pending"])
	_dating_overload_problem_recognized = bool(overload["problem_recognized"])
	var clones: Dictionary = decoded["clones"] as Dictionary
	_total_clones = int(clones["total"])
	_clones_working = int(clones["working"])
	_clones_dating = int(clones["dating"])
	_clone_production_upgrade_level = int(clones["local_upgrade_production"])
	_clone_work_upgrade_level = int(clones["local_upgrade_work"])
	_clone_dating_upgrade_level = int(clones["local_upgrade_dating"])
	var late_game: Dictionary = decoded["late_game"] as Dictionary
	_world_reach = int(late_game["world_reach"])
	_global_production_upgrade_level = int(late_game["global_upgrade_production"])
	_global_work_upgrade_level = int(late_game["global_upgrade_work"])
	_global_dating_upgrade_level = int(late_game["global_upgrade_dating"])
	# Derived rates are not authoritative; leave until CloneIncremental recalculates.


func _validate_girls_block(girls: Dictionary) -> Dictionary:
	var required: Array[String] = [
		"relationships", "conquered", "discovered", "contacts", "known_clues",
		"revealed_primary_traits", "known_reactions", "retry_days_remaining",
		"date_cooldown_days_remaining", "played_dating_event_ids",
		"last_date_event_ids", "revealed_secondary_traits",
	]
	for key in required:
		if not girls.has(key):
			push_error("[GameState] restore girls missing: %s" % key)
			return {}
	var relationships_v: Variant = _decode_string_int_map(girls["relationships"], RELATIONSHIP_MIN, RELATIONSHIP_MAX)
	if relationships_v == null:
		return {}
	var relationships: Dictionary = relationships_v as Dictionary
	var conquered_v: Variant = _decode_string_array(girls["conquered"])
	var discovered_v: Variant = _decode_string_array(girls["discovered"])
	var contacts_v: Variant = _decode_string_array(girls["contacts"])
	var primary_v: Variant = _decode_string_array(girls["revealed_primary_traits"])
	var secondary_v: Variant = _decode_string_array(girls["revealed_secondary_traits"])
	if conquered_v == null or discovered_v == null or contacts_v == null or primary_v == null or secondary_v == null:
		return {}
	var conquered: Array = conquered_v as Array
	var discovered: Array = discovered_v as Array
	var contacts: Array = contacts_v as Array
	var primary: Array = primary_v as Array
	var secondary: Array = secondary_v as Array
	var known_clues_v: Variant = _decode_known_clues(girls["known_clues"])
	if known_clues_v == null:
		return {}
	var known_clues: Dictionary = known_clues_v as Dictionary
	var known_reactions_v: Variant = _decode_known_reactions(girls["known_reactions"])
	if known_reactions_v == null:
		return {}
	var known_reactions: Dictionary = known_reactions_v as Dictionary
	var retry_v: Variant = _decode_string_int_map(girls["retry_days_remaining"], 0, 999999)
	var cooldown_v: Variant = _decode_string_int_map(girls["date_cooldown_days_remaining"], 0, 999999)
	if retry_v == null or cooldown_v == null:
		return {}
	var retry: Dictionary = retry_v as Dictionary
	var cooldown: Dictionary = cooldown_v as Dictionary
	var played_v: Variant = _decode_girl_event_history(girls["played_dating_event_ids"])
	var last_v: Variant = _decode_girl_event_history(girls["last_date_event_ids"])
	if played_v == null or last_v == null:
		return {}
	var played: Dictionary = played_v as Dictionary
	var last: Dictionary = last_v as Dictionary
	return {
		"relationships": relationships,
		"conquered": conquered,
		"discovered": discovered,
		"contacts": contacts,
		"known_clues": known_clues,
		"revealed_primary_traits": primary,
		"known_reactions": known_reactions,
		"retry_days_remaining": retry,
		"date_cooldown_days_remaining": cooldown,
		"played_dating_event_ids": played,
		"last_date_event_ids": last,
		"revealed_secondary_traits": secondary,
	}


func _validate_salary_block(salary: Dictionary) -> Dictionary:
	for key in ["initialized", "period_index", "pending_salary", "manual_cycle_seen", "advance_used_period"]:
		if not salary.has(key):
			return {}
	var period_index: int = int(salary["period_index"])
	var pending_salary: int = int(salary["pending_salary"])
	var advance_used_period: int = int(salary["advance_used_period"])
	if period_index < 0 or pending_salary < 0:
		return {}
	return {
		"initialized": bool(salary["initialized"]),
		"period_index": period_index,
		"pending_salary": pending_salary,
		"manual_cycle_seen": bool(salary["manual_cycle_seen"]),
		"advance_used_period": advance_used_period,
	}


func _validate_media_block(media: Dictionary) -> Dictionary:
	for key in [
		"photo_session_completed", "attention", "photo_pose_by_shot", "published_photo_ids",
		"last_photo_publish_day", "incoming_offer_girl_ids", "read_offer_girl_ids", "feed_event_ids",
	]:
		if not media.has(key):
			return {}
	var attention: int = int(media["attention"])
	if attention < MEDIA_ATTENTION_MIN or attention > MEDIA_ATTENTION_MAX:
		return {}
	var poses_v: Variant = _decode_string_string_map(media["photo_pose_by_shot"])
	if poses_v == null:
		return {}
	var poses: Dictionary = poses_v as Dictionary
	var published_v: Variant = _decode_string_array(media["published_photo_ids"])
	var incoming_v: Variant = _decode_string_array(media["incoming_offer_girl_ids"])
	var read_offers_v: Variant = _decode_string_array(media["read_offer_girl_ids"])
	var feed_v: Variant = _decode_string_array(media["feed_event_ids"])
	if published_v == null or incoming_v == null or read_offers_v == null or feed_v == null:
		return {}
	var published: Array = published_v as Array
	var incoming: Array = incoming_v as Array
	var read_offers: Array = read_offers_v as Array
	var feed: Array = feed_v as Array
	return {
		"photo_session_completed": bool(media["photo_session_completed"]),
		"attention": attention,
		"photo_pose_by_shot": poses,
		"published_photo_ids": published,
		"last_photo_publish_day": int(media["last_photo_publish_day"]),
		"incoming_offer_girl_ids": incoming,
		"read_offer_girl_ids": read_offers,
		"feed_event_ids": feed,
	}


func _validate_dating_overload_block(block: Dictionary) -> Dictionary:
	for key in [
		"started", "start_day", "next_request_id", "requests", "candidate_cursor",
		"last_personal_date_day", "personal_dates_completed", "last_feed_boost_day",
		"boost_pending", "problem_recognized",
	]:
		if not block.has(key):
			return {}
	var next_request_id: int = int(block["next_request_id"])
	var candidate_cursor: int = int(block["candidate_cursor"])
	var personal_dates_completed: int = int(block["personal_dates_completed"])
	if next_request_id < 1 or candidate_cursor < 0 or personal_dates_completed < 0:
		return {}
	var requests_raw: Variant = block["requests"]
	if typeof(requests_raw) != TYPE_ARRAY:
		return {}
	var requests: Array = []
	var seen_ids: Dictionary = {}
	for item in requests_raw as Array:
		if typeof(item) != TYPE_DICTIONARY:
			return {}
		var entry: DatingDemandEntry = decode_dating_demand_entry(item as Dictionary)
		if entry == null:
			return {}
		if seen_ids.has(entry.request_id):
			return {}
		seen_ids[entry.request_id] = true
		requests.append(entry)
	return {
		"started": bool(block["started"]),
		"start_day": int(block["start_day"]),
		"next_request_id": next_request_id,
		"requests": requests,
		"candidate_cursor": candidate_cursor,
		"last_personal_date_day": int(block["last_personal_date_day"]),
		"personal_dates_completed": personal_dates_completed,
		"last_feed_boost_day": int(block["last_feed_boost_day"]),
		"boost_pending": bool(block["boost_pending"]),
		"problem_recognized": bool(block["problem_recognized"]),
	}


func _validate_clones_block(clones: Dictionary) -> Dictionary:
	for key in [
		"total", "working", "dating",
		"local_upgrade_production", "local_upgrade_work", "local_upgrade_dating",
	]:
		if not clones.has(key):
			return {}
	var total: int = int(clones["total"])
	var working: int = int(clones["working"])
	var dating: int = int(clones["dating"])
	var up_prod: int = int(clones["local_upgrade_production"])
	var up_work: int = int(clones["local_upgrade_work"])
	var up_dating: int = int(clones["local_upgrade_dating"])
	if total < 0 or working < 0 or dating < 0:
		return {}
	if working + dating > total:
		return {}
	if (
		up_prod < 0 or up_prod > CLONE_UPGRADE_MAX_LEVEL
		or up_work < 0 or up_work > CLONE_UPGRADE_MAX_LEVEL
		or up_dating < 0 or up_dating > CLONE_UPGRADE_MAX_LEVEL
	):
		return {}
	return {
		"total": total,
		"working": working,
		"dating": dating,
		"local_upgrade_production": up_prod,
		"local_upgrade_work": up_work,
		"local_upgrade_dating": up_dating,
	}


func _validate_late_game_block(late_game: Dictionary) -> Dictionary:
	for key in [
		"world_reach", "global_upgrade_production", "global_upgrade_work", "global_upgrade_dating",
	]:
		if not late_game.has(key):
			return {}
	var world_reach: int = int(late_game["world_reach"])
	var g_prod: int = int(late_game["global_upgrade_production"])
	var g_work: int = int(late_game["global_upgrade_work"])
	var g_dating: int = int(late_game["global_upgrade_dating"])
	if world_reach < WORLD_REACH_MIN or world_reach > WORLD_REACH_MAX:
		return {}
	if (
		g_prod < 0 or g_prod > GLOBAL_UPGRADE_MAX_LEVEL
		or g_work < 0 or g_work > GLOBAL_UPGRADE_MAX_LEVEL
		or g_dating < 0 or g_dating > GLOBAL_UPGRADE_MAX_LEVEL
	):
		return {}
	return {
		"world_reach": world_reach,
		"global_upgrade_production": g_prod,
		"global_upgrade_work": g_work,
		"global_upgrade_dating": g_dating,
	}


func _export_id_set_array(set_dict: Dictionary) -> Array:
	var out: Array = []
	for key in set_dict.keys():
		out.append(String(key))
	out.sort()
	return out


func _export_string_name_array(values: Array) -> Array:
	var out: Array = []
	for value in values:
		out.append(String(value))
	return out


func _export_string_int_map(src: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key in src.keys():
		out[String(key)] = int(src[key])
	return out


func _export_string_string_map(src: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key in src.keys():
		out[String(key)] = String(src[key])
	return out


func _export_story_flags(src: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key in src.keys():
		out[String(key)] = bool(src[key])
	return out


func _export_known_clues(src: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for girl_key in src.keys():
		var known: Dictionary = src[girl_key] as Dictionary
		var indices: Array = []
		for idx in known.keys():
			indices.append(int(idx))
		indices.sort()
		out[String(girl_key)] = indices
	return out


func _export_known_reactions(src: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for girl_key in src.keys():
		var by_source: Dictionary = src[girl_key] as Dictionary
		var mapped: Dictionary = {}
		for source_key in by_source.keys():
			mapped[String(source_key)] = int(by_source[source_key])
		out[String(girl_key)] = mapped
	return out


func _export_girl_event_history(src: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for girl_key in src.keys():
		var stored: Array = src[girl_key] as Array
		var ids: Array = []
		for eid in stored:
			ids.append(String(eid))
		out[String(girl_key)] = ids
	return out


func _decode_string_array(raw: Variant) -> Variant:
	if typeof(raw) != TYPE_ARRAY:
		return null
	var out: Array = []
	for item in raw as Array:
		var s: String = str(item)
		if s == "":
			return null
		out.append(s)
	return out


func _decode_string_int_map(raw: Variant, min_v: int, max_v: int) -> Variant:
	if typeof(raw) != TYPE_DICTIONARY:
		return null
	var out: Dictionary = {}
	for key in (raw as Dictionary).keys():
		var sid: String = str(key)
		if sid == "":
			return null
		var value: int = int((raw as Dictionary)[key])
		if value < min_v or value > max_v:
			return null
		out[StringName(sid)] = value
	return out


func _decode_string_string_map(raw: Variant) -> Variant:
	if typeof(raw) != TYPE_DICTIONARY:
		return null
	var out: Dictionary = {}
	for key in (raw as Dictionary).keys():
		var sk: String = str(key)
		var sv: String = str((raw as Dictionary)[key])
		if sk == "" or sv == "":
			return null
		out[StringName(sk)] = StringName(sv)
	return out


func _decode_story_flags(raw: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key in raw.keys():
		var sid: String = str(key)
		if sid == "":
			continue
		if bool(raw[key]):
			out[StringName(sid)] = true
	return out


func _decode_known_clues(raw: Variant) -> Variant:
	if typeof(raw) != TYPE_DICTIONARY:
		return null
	var out: Dictionary = {}
	for girl_key in (raw as Dictionary).keys():
		var gid: String = str(girl_key)
		if gid == "":
			return null
		var indices_raw: Variant = (raw as Dictionary)[girl_key]
		if typeof(indices_raw) != TYPE_ARRAY:
			return null
		var known: Dictionary = {}
		for idx in indices_raw as Array:
			var clue_index: int = int(idx)
			if clue_index < 0:
				return null
			known[clue_index] = true
		out[StringName(gid)] = known
	return out


func _decode_known_reactions(raw: Variant) -> Variant:
	if typeof(raw) != TYPE_DICTIONARY:
		return null
	var out: Dictionary = {}
	for girl_key in (raw as Dictionary).keys():
		var gid: String = str(girl_key)
		if gid == "":
			return null
		var by_source_raw: Variant = (raw as Dictionary)[girl_key]
		if typeof(by_source_raw) != TYPE_DICTIONARY:
			return null
		var by_source: Dictionary = {}
		for source_key in (by_source_raw as Dictionary).keys():
			var sid: String = str(source_key)
			if sid == "":
				return null
			var reaction: int = int((by_source_raw as Dictionary)[source_key])
			if reaction != -1 and reaction != 0 and reaction != 1:
				return null
			by_source[StringName(sid)] = reaction
		out[StringName(gid)] = by_source
	return out


func _decode_girl_event_history(raw: Variant) -> Variant:
	if typeof(raw) != TYPE_DICTIONARY:
		return null
	var out: Dictionary = {}
	for girl_key in (raw as Dictionary).keys():
		var gid: String = str(girl_key)
		if gid == "":
			return null
		var ids_raw: Variant = (raw as Dictionary)[girl_key]
		if typeof(ids_raw) != TYPE_ARRAY:
			return null
		var ids: Array[StringName] = []
		for eid in ids_raw as Array:
			var s: String = str(eid)
			if s == "":
				return null
			ids.append(StringName(s))
		out[StringName(gid)] = ids
	return out


func _ids_to_set(ids: Array) -> Dictionary:
	var out: Dictionary = {}
	for item in ids:
		var sid: StringName = StringName(str(item))
		if String(sid) != "":
			out[sid] = true
	return out


func _to_string_name_array(ids: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	for item in ids:
		out.append(StringName(str(item)))
	return out


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
