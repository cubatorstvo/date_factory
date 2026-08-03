class_name Loc
extends RefCounted
## Russian display strings for tags, statuses, and UI labels.


const TAGS := {
	"calm": "спокойствие",
	"cheap": "простые вещи",
	"casual": "повседневность",
	"luxury": "роскошь",
	"media": "медиа",
	"sport": "спорт",
	"tasty": "вкусная еда",
	"fashion": "мода",
	"scandal": "скандал",
	"tech": "технологии",
	"science": "наука",
	"mass": "массовость",
	"space": "космос",
	"sincere": "искренность",
	"cute": "милые вещи",
	"romantic": "романтика",
	"useful": "польза",
	"dark": "мрак",
	"weird": "странности",
	"absurd": "абсурд",
	"chaos": "хаос",
	"order": "порядок",
	"business": "бизнес",
	"active": "активность",
}

const TRAITS := {
	"time": "Пунктуальность",
	"attention": "Внимание",
	"generosity": "Щедрость",
	"thrift": "Экономность",
	"adventure": "Азарт",
	"peace": "Спокойствие",
	"ambition": "Амбиции",
	"humor": "Юмор",
	"punctual": "Пунктуальность",
	"attentive": "Внимательность",
	"calm": "Спокойствие",
	"ambitious": "Амбициозность",
	"daring": "Азартность",
	"witty": "Юмор",
	"generous": "Щедрость",
}

const TIERS := {
	"simple": "простая",
	"medium": "средняя",
	"high": "высокая",
}


static func tag(id: Variant) -> String:
	var key := str(id)
	return str(TAGS.get(key, key))


static func tags_list(arr: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for t in arr:
		parts.append(tag(t))
	return ", ".join(parts)


static func online(v: bool) -> String:
	return "в сети" if v else "не в сети"


static func yes_no(v: bool) -> String:
	return "да" if v else "нет"


static func venue_name(id: Variant) -> String:
	var v: Dictionary = ContentDB.venue(StringName(str(id)))
	if not v.is_empty():
		return str(v.get("name", id))
	return str(id)


static func stage_title(stage_id: Variant) -> String:
	var st: Dictionary = ContentDB.stage(StringName(str(stage_id)))
	return str(st.get("name", stage_id))


static func stage_goal(stage_id: Variant) -> String:
	var st: Dictionary = ContentDB.stage(StringName(str(stage_id)))
	return str(st.get("goal", ""))


static func girl_title(girl_id: Variant) -> String:
	var g: Dictionary = ContentDB.girl(StringName(str(girl_id)))
	if g.is_empty():
		return str(girl_id)
	return str(g.get("archetype", g.get("name", girl_id)))


static func trait_name(id: Variant) -> String:
	var key := str(id)
	if TRAITS.has(key):
		return str(TRAITS[key])
	var t: Dictionary = ContentDB.trait_def(StringName(key))
	return str(t.get("name", key))


static func tier_name(id: Variant) -> String:
	return str(TIERS.get(str(id), id))
