class_name GameTermRegistry
extends RefCounted

var _terms: Array[GameTerm] = []
var _by_id: Dictionary = {}


static func from_catalog(catalog: DateContentCatalog) -> GameTermRegistry:
	var registry := GameTermRegistry.new()
	registry._ingest_catalog(catalog)
	registry._ingest_system_terms()
	return registry


static var _shared: GameTermRegistry


static func from_shared_catalog() -> GameTermRegistry:
	if _shared == null:
		_shared = from_catalog(load("res://date_system/content/catalog/date_content_catalog.tres") as DateContentCatalog)
	return _shared


func all_terms() -> Array[GameTerm]:
	return _terms.duplicate()


func find_term(term_id: StringName) -> GameTerm:
	return _by_id.get(term_id, null)


func aliases_of(term: GameTerm) -> PackedStringArray:
	return _aliases_of(term)


func find_by_alias(alias: String) -> GameTerm:
	var needle: String = alias.strip_edges().to_lower()
	if needle.is_empty():
		return null
	var best: GameTerm = null
	var best_length: int = -1
	for term in _terms:
		for candidate in _aliases_of(term):
			if candidate != needle:
				continue
			if candidate.length() > best_length:
				best = term
				best_length = candidate.length()
	return best


func duplicate_ids() -> PackedStringArray:
	var seen: Dictionary = {}
	var duplicates: PackedStringArray = PackedStringArray()
	for term in _terms:
		var key: String = String(term.id)
		if seen.has(key):
			duplicates.append(key)
		else:
			seen[key] = true
	return duplicates


func ambiguous_aliases() -> PackedStringArray:
	var owners: Dictionary = {}
	var ambiguous: PackedStringArray = PackedStringArray()
	for term in _terms:
		for alias in _aliases_of(term):
			if alias.is_empty():
				continue
			var owner: String = String(owners.get(alias, ""))
			if owner.is_empty():
				owners[alias] = String(term.id)
			elif owner != String(term.id) and not ambiguous.has(alias):
				ambiguous.append(alias)
	return ambiguous


func _ingest_catalog(catalog: DateContentCatalog) -> void:
	if catalog == null:
		return
	for tag in catalog.tags:
		if tag == null or not _content_enabled(tag):
			continue
		_add_term(tag.id, tag.display_name, tag.description, PackedStringArray(), GameTerm.Category.TAG, GameTerm.Visual.TAG)
	for stat in catalog.progression_stats:
		if stat == null or not _content_enabled(stat):
			continue
		_add_term(stat.id, stat.display_name, stat.description, PackedStringArray(), GameTerm.Category.STAT, GameTerm.Visual.ACCENT)
	for local_object in catalog.local_objects:
		if local_object == null or not _content_enabled(local_object):
			continue
		_add_term(local_object.id, local_object.display_name, local_object.description, PackedStringArray(), GameTerm.Category.LOCAL_OBJECT, GameTerm.Visual.ACCENT)


func _ingest_system_terms() -> void:
	_add_term(&"rating", "Рейтинг", "Глобальный показатель успеха героя. Растёт при достижении максимальных отношений с девушками и от работы Date Factory.", PackedStringArray(["Rating"]), GameTerm.Category.SYSTEM, GameTerm.Visual.ACCENT)
	_add_term(&"relationship", "Отношения", "Прогресс конкретной девушки. Максимальное значение завершает её линию и даёт +1 Рейтинг.", PackedStringArray(), GameTerm.Category.SYSTEM, GameTerm.Visual.ACCENT)
	_add_term(&"city_stage", "Этап города", "Уровень развития домашнего города. Открывает новые знакомства и соперников и сокращает social cooldown.", PackedStringArray(), GameTerm.Category.SYSTEM, GameTerm.Visual.ACCENT)
	_add_term(&"base_move", "Базовый ход", "Обычный вариант действия, случайно доступный в текущей ситуации.", PackedStringArray(["BASE"]), GameTerm.Category.SYSTEM, GameTerm.Visual.ACCENT)
	_add_term(&"unlockable_move", "Открываемый ход", "Дополнительный ситуационный ход, доступность которого зависит от развития героя.", PackedStringArray(["UNLOCKABLE"]), GameTerm.Category.SYSTEM, GameTerm.Visual.ACCENT)
	_add_term(&"local_move", "Локальный ход", "Ход от объекта текущего места свидания. После одного локального хода весь его объект считается использованным до конца свидания.", PackedStringArray(["LOCAL"]), GameTerm.Category.SYSTEM, GameTerm.Visual.ACCENT)
	_add_term(&"combo", "Комбо", "Бонус за три последовательных успешных хода с тремя разными тегами.", PackedStringArray(["КОМБО", "Combo"]), GameTerm.Category.SYSTEM, GameTerm.Visual.ACCENT)
	_add_term(&"outfit", "Одежда", "Текущая одежда героя. Цепочка Casual +0 → Business +1 → Luxury +2; на свидании используется автоматически.", PackedStringArray(), GameTerm.Category.SYSTEM, GameTerm.Visual.ACCENT)
	_add_term(&"date_factory", "Date Factory", "Автоматическая фабрика клонов. Они зарабатывают деньги и ходят на свидания, повышая Рейтинг и охват текущего масштаба.", PackedStringArray(), GameTerm.Category.SYSTEM, GameTerm.Visual.ACCENT)
	_add_term(&"tag", "тег", "Игровой признак хода. Известное предпочтение девушки окрашивает тег и показывает, сработает ход или нет.", PackedStringArray(["теги", "Тег"]), GameTerm.Category.SYSTEM, GameTerm.Visual.ACCENT)


func _add_term(term_id: StringName, display_name: String, description: String, extra_aliases: PackedStringArray, category: GameTerm.Category, visual: GameTerm.Visual) -> void:
	if term_id == &"" or display_name.strip_edges().is_empty():
		return
	var term := GameTerm.new()
	term.id = term_id
	term.display_name = display_name
	term.description = description
	term.aliases = extra_aliases
	term.category = category
	term.visual = visual
	_terms.append(term)
	_by_id[term_id] = term


static func _aliases_of(term: GameTerm) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var seen: Dictionary = {}
	_push_alias(result, seen, term.display_name)
	_push_alias(result, seen, String(term.id))
	for alias in term.aliases:
		_push_alias(result, seen, alias)
	return result


static func _content_enabled(item: Resource) -> bool:
	if item == null:
		return false
	if "enabled" in item:
		return bool(item.get("enabled"))
	return true


static func _push_alias(result: PackedStringArray, seen: Dictionary, alias: String) -> void:
	var needle: String = alias.strip_edges().to_lower()
	if needle.is_empty() or seen.has(needle):
		return
	seen[needle] = true
	result.append(needle)
