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


func _wire_modules() -> void:
	# Names before Girls: unlock entries need next_name() during reset.
	for mod in [economy, inventory, names, girls, dating, facility, clones, staff, upgrades, events, quests, city]:
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
	quests.reset_for_stage(stage_id)
	names.reset()
	if city != null and city.has_method("reset"):
		city.reset()
	facility.unlock_stage(stage_id)
	EventBus.stage_changed.emit(stage_id)
	EventBus.toast("Новая жизнь. Квартира. Одно свидание. Что может пойти не так?", &"story")


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
	EventBus.stage_changed.emit(next_id)
	EventBus.toast("Новая стадия: %s" % str(next_id), &"story")


func start_postgame() -> void:
	postgame = true
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
		"quests": quests.to_dict(),
		"names": names.to_dict(),
		"city": city.to_dict(),
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
	quests.from_dict(data.get("quests", {}))
	names.from_dict(data.get("names", {}))
	city.from_dict(data.get("city", {}))
	facility.unlock_stage(stage_id)
	EventBus.stage_changed.emit(stage_id)


func save_game() -> void:
	save.write_save(to_dict())
	EventBus.toast("Игра сохранена", &"info")


func load_game() -> void:
	var data := save.read_save()
	if data.is_empty():
		new_game()
		return
	from_dict(data)
	EventBus.toast("Игра загружена", &"info")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quick_save"):
		save_game()
	elif event.is_action_pressed("quick_load"):
		load_game()
