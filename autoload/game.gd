extends Node
## Game facade: owns module APIs, boot, new game, save/load.

const SAVE_PATH := "user://save_slot_1.json"

var economy: EconomyAPI
var inventory: InventoryAPI
var girls: GirlsAPI
var dating: DatingAPI
var facility: FacilityAPI
var clones: ClonesAPI
var staff: StaffAPI
var upgrades: UpgradesAPI
var events: EventsAPI
var quests: QuestsAPI
var names: NamesAPI
var save: SaveService
var city: Node
var crises: CrisesAPI
var trait_influence: TraitInfluenceAPI
var time: TimeAPI

var stage_id: StringName = &"stage_1"
var postgame: bool = false
var tutorial_done: bool = false
var total_successful_dates: int = 0
var run_started: bool = false

@onready var _modules_root: Node = $Modules


func _ready() -> void:
	get_tree().root.theme = ThemeFactory.build()
	_bind_modules()
	_wire_modules()


func _bind_modules() -> void:
	economy = _modules_root.get_node("Economy") as EconomyAPI
	inventory = _modules_root.get_node("Inventory") as InventoryAPI
	girls = _modules_root.get_node("Girls") as GirlsAPI
	dating = _modules_root.get_node("Dating") as DatingAPI
	facility = _modules_root.get_node("Facility") as FacilityAPI
	clones = _modules_root.get_node("Clones") as ClonesAPI
	staff = _modules_root.get_node("Staff") as StaffAPI
	upgrades = _modules_root.get_node("Upgrades") as UpgradesAPI
	events = _modules_root.get_node("Events") as EventsAPI
	quests = _modules_root.get_node("Quests") as QuestsAPI
	names = _modules_root.get_node("Names") as NamesAPI
	save = _modules_root.get_node("Save") as SaveService
	city = _modules_root.get_node("City")
	if _modules_root.has_node("Time"):
		time = _modules_root.get_node("Time") as TimeAPI
	else:
		var TimeScript: Script = load("res://modules/time/time_api.gd") as Script
		time = TimeScript.new() as TimeAPI
		time.name = "Time"
		_modules_root.add_child(time)
	if _modules_root.has_node("Crises"):
		crises = _modules_root.get_node("Crises") as CrisesAPI
	else:
		var CrisisScript: Script = load("res://modules/crises/crises_api.gd") as Script
		crises = CrisisScript.new() as CrisesAPI
		crises.name = "Crises"
		_modules_root.add_child(crises)
	if _modules_root.has_node("TraitInfluence"):
		trait_influence = _modules_root.get_node("TraitInfluence") as TraitInfluenceAPI
	else:
		var InflScript: Script = load("res://modules/girls/trait_influence_api.gd") as Script
		trait_influence = InflScript.new() as TraitInfluenceAPI
		trait_influence.name = "TraitInfluence"
		_modules_root.add_child(trait_influence)


func _wire_modules() -> void:
	# Names before Girls: unlock entries need next_name() during reset.
	for mod in [economy, inventory, names, girls, dating, facility, clones, staff, upgrades, events, quests, city, crises, trait_influence, time]:
		if mod != null and mod.has_method("setup"):
			mod.setup(self)


func new_game() -> void:
	run_started = true
	postgame = false
	tutorial_done = false
	total_successful_dates = 0
	stage_id = &"stage_1"
	economy.reset()
	inventory.reset()
	girls.reset()
	dating.reset()
	facility.reset()
	clones.reset()
	staff.reset()
	upgrades.reset()
	events.reset()
	if crises != null:
		crises.reset()
	if trait_influence != null:
		trait_influence.reset()
	quests.reset_for_stage(stage_id)
	names.reset()
	if city != null and city.has_method("reset"):
		city.reset()
	if time != null:
		time.reset()
	facility.unlock_stage(stage_id)
	EventBus.stage_changed.emit(stage_id)
	## reset_for_stage → tip_current(): toast matches HUD primary_text.


func continue_or_new() -> void:
	if save.has_save():
		load_game()
	else:
		new_game()


func advance_stage(next_id: StringName) -> void:
	if stage_id == next_id:
		return
	stage_id = next_id
	facility.unlock_stage(next_id)
	quests.reset_for_stage(next_id)
	if girls != null:
		girls.try_unlock_by_progress()
	EventBus.stage_changed.emit(next_id)
	EventBus.toast("Новая стадия: %s" % str(next_id), &"story")


func start_postgame() -> void:
	postgame = true
	if facility != null:
		facility.set_flag("finale_complete", true)
		facility.set_flag("postgame_open", true)
	EventBus.postgame_started.emit()
	EventBus.toast("Фабрика автоматизирована. Бесконечный режим открыт.", &"story")


func to_dict() -> Dictionary:
	return {
		"stage_id": str(stage_id),
		"postgame": postgame,
		"tutorial_done": tutorial_done,
		"total_successful_dates": total_successful_dates,
		"economy": economy.to_dict(),
		"inventory": inventory.to_dict(),
		"girls": girls.to_dict(),
		"dating": dating.to_dict(),
		"facility": facility.to_dict(),
		"clones": clones.to_dict(),
		"staff": staff.to_dict(),
		"upgrades": upgrades.to_dict(),
		"events": events.to_dict(),
		"crises": crises.to_dict() if crises != null else {},
		"trait_influence": trait_influence.to_dict() if trait_influence != null else {},
		"quests": quests.to_dict(),
		"names": names.to_dict(),
		"city": city.to_dict(),
		"time": time.to_dict() if time != null else {},
	}


func from_dict(data: Dictionary) -> void:
	run_started = true
	stage_id = StringName(str(data.get("stage_id", "stage_1")))
	postgame = bool(data.get("postgame", false))
	tutorial_done = bool(data.get("tutorial_done", false))
	total_successful_dates = int(data.get("total_successful_dates", 0))
	economy.from_dict(data.get("economy", {}))
	inventory.from_dict(data.get("inventory", {}))
	girls.from_dict(data.get("girls", {}))
	dating.from_dict(data.get("dating", {}))
	facility.from_dict(data.get("facility", {}))
	clones.from_dict(data.get("clones", {}))
	staff.from_dict(data.get("staff", {}))
	upgrades.from_dict(data.get("upgrades", {}))
	events.from_dict(data.get("events", {}))
	if crises != null:
		crises.from_dict(data.get("crises", {}))
	if trait_influence != null:
		trait_influence.from_dict(data.get("trait_influence", {}))
	quests.from_dict(data.get("quests", {}))
	names.from_dict(data.get("names", {}))
	city.from_dict(data.get("city", {}))
	if time != null:
		time.from_dict(data.get("time", {}))
	facility.unlock_stage(stage_id)
	EventBus.stage_changed.emit(stage_id)


func save_game() -> void:
	save.write_save(to_dict())
	EventBus.toast("Игра сохранена", &"info")


func load_game() -> void:
	var data: Dictionary = save.read_save()
	if data.is_empty():
		new_game()
		return
	from_dict(data)
	EventBus.toast("Игра загружена", &"info")


## Test-only helper. Shipping Continue / New Game / quick save-load never call this.
## Writes only user://save_slot_qa_full_access.json via FullAccessQaProfile.
func load_full_access_qa_profile() -> void:
	FullAccessQaProfile.regenerate_and_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quick_save"):
		save_game()
	elif event.is_action_pressed("quick_load"):
		load_game()
