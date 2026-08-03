class_name ContentDB
extends RefCounted
## Static catalogs. All gameplay content lives here as data dictionaries.

static var _loaded: bool = false
static var gifts: Dictionary = {}
static var outfits: Dictionary = {}
static var venues: Dictionary = {}
static var girls: Dictionary = {}
static var staff_roles: Dictionary = {}
static var upgrades: Dictionary = {}
static var events: Dictionary = {}
static var stages: Dictionary = {}
static var rooms: Dictionary = {}
static var balance: Dictionary = {}
static var builtin_names: PackedStringArray = PackedStringArray()
static var traits: Dictionary = {}
static var trait_dialogues: Array = []


static func ensure_loaded(force: bool = false) -> void:
	if _loaded and not force:
		return
	balance = ContentPacks.balance()
	gifts = ContentPacks.gifts()
	outfits = ContentPacks.outfits()
	venues = ContentPacks.venues()
	girls = ContentPacks.girls()
	staff_roles = ContentPacks.staff_roles()
	upgrades = ContentPacksProgress.upgrades()
	events = ContentPacksProgress.events()
	stages = ContentPacksProgress.stages()
	rooms = ContentPacks.rooms()
	builtin_names = ContentPacks.builtin_names()
	traits = TraitsContent.traits()
	trait_dialogues = TraitsContent.dialogues()
	_loaded = true


static func gift(id: StringName) -> Dictionary:
	ensure_loaded()
	return gifts.get(str(id), {}).duplicate(true)


static func outfit(id: StringName) -> Dictionary:
	ensure_loaded()
	return outfits.get(str(id), {}).duplicate(true)


static func venue(id: StringName) -> Dictionary:
	ensure_loaded()
	return venues.get(str(id), {}).duplicate(true)


static func girl(id: StringName) -> Dictionary:
	ensure_loaded()
	return girls.get(str(id), {}).duplicate(true)


static func upgrade(id: StringName) -> Dictionary:
	ensure_loaded()
	return upgrades.get(str(id), {}).duplicate(true)


static func event(id: StringName) -> Dictionary:
	ensure_loaded()
	return events.get(str(id), {}).duplicate(true)


static func stage(id: StringName) -> Dictionary:
	ensure_loaded()
	return stages.get(str(id), {}).duplicate(true)


static func room(id: StringName) -> Dictionary:
	ensure_loaded()
	return rooms.get(str(id), {}).duplicate(true)


static func trait_def(id: StringName) -> Dictionary:
	ensure_loaded()
	return traits.get(str(id), {}).duplicate(true)
