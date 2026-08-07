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
var _unlocked_locations: Dictionary = {}
var _story_flags: Dictionary = {}
var _total_clones: int = 0
var _clones_working: int = 0
var _clones_dating: int = 0
var _money_per_minute: float = 0.0
var _dates_per_minute: float = 0.0
var _purchased_perks: Dictionary = {}

const CHAR_MIN: int = 0
const CHAR_MAX: int = 10


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
	_unlocked_locations = {}
	_story_flags = {}
	_total_clones = 0
	_clones_working = 0
	_clones_dating = 0
	_money_per_minute = 0.0
	_dates_per_minute = 0.0
	_purchased_perks = {}
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
	var prev: int = get_girl_relationship(girl_id)
	if prev == value:
		return
	_girl_relationships[girl_id] = value
	girl_relationship_changed.emit(girl_id, value, value - prev)


func add_girl_relationship(girl_id: StringName, delta: int) -> void:
	if not _is_valid_id(girl_id):
		push_error("[GameState] add_girl_relationship empty id")
		return
	if delta == 0:
		return
	var next: int = get_girl_relationship(girl_id) + delta
	_girl_relationships[girl_id] = next
	girl_relationship_changed.emit(girl_id, next, delta)


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
	return "stage=%s money=%s auth=%s xp=%s up=%s chars=%s/%s/%s/%s perks=%s clones=%s/%s/%s free=%s rates=%s/%s rel=%s conquered=%s locs=%s flags=%s" % [
		_stage, _money, _authority, _experience, _upgrade_points,
		_muscle, _appearance, _capital, _aura,
		_purchased_perks.size(),
		_total_clones, _clones_working, _clones_dating, get_free_clones(),
		_money_per_minute, _dates_per_minute,
		_girl_relationships.size(), _conquered_girls.size(),
		_unlocked_locations.size(), _story_flags.size(),
	]


func _is_valid_id(id_value: StringName) -> bool:
	return String(id_value) != ""
