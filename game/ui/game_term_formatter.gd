class_name GameTermFormatter
extends RefCounted

const META_PREFIX := "game_term:"


static func format_bbcode(text: String, tag_knowledge: Dictionary = {}, registry: GameTermRegistry = null) -> String:
	if text.is_empty():
		return text
	var terms: GameTermRegistry = registry if registry != null else GameTermRegistry.from_shared_catalog()
	if terms == null:
		return text
	var matches: Array[Dictionary] = _collect_matches(text, terms)
	if matches.is_empty():
		return text
	matches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["start"]) > int(b["start"])
	)
	var result: String = text
	for item in matches:
		var start: int = int(item["start"])
		var stop: int = int(item["end"])
		var term: GameTerm = item["term"]
		var matched: String = result.substr(start, stop - start)
		result = result.substr(0, start) + _wrap(term, matched, tag_knowledge) + result.substr(stop)
	return result


static func longest_alias_term(text: String, registry: GameTermRegistry = null) -> GameTerm:
	var terms: GameTermRegistry = registry if registry != null else GameTermRegistry.from_shared_catalog()
	if terms == null or text.strip_edges().is_empty():
		return null
	var matches: Array[Dictionary] = _collect_matches(text, terms)
	if matches.is_empty():
		return null
	matches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_len: int = int(a["end"]) - int(a["start"])
		var b_len: int = int(b["end"]) - int(b["start"])
		if a_len == b_len:
			return int(a["start"]) < int(b["start"])
		return a_len > b_len
	)
	return matches[0]["term"]


static func parse_meta(meta: Variant) -> StringName:
	var raw: String = str(meta)
	if not raw.begins_with(META_PREFIX):
		return &""
	return StringName(raw.substr(META_PREFIX.length()))


static func _collect_matches(text: String, registry: GameTermRegistry) -> Array[Dictionary]:
	var aliases: Array[Dictionary] = []
	for term in registry.all_terms():
		for alias in GameTermRegistry._aliases_of(term):
			aliases.append({"alias": alias, "term": term, "length": alias.length()})
	aliases.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["length"]) > int(b["length"])
	)
	var occupied := PackedByteArray()
	occupied.resize(text.length())
	var lower: String = text.to_lower()
	var matches: Array[Dictionary] = []
	for item in aliases:
		var alias: String = String(item["alias"])
		var term: GameTerm = item["term"]
		var from: int = 0
		while from <= lower.length() - alias.length():
			var idx: int = lower.find(alias, from)
			if idx < 0:
				break
			from = idx + 1
			var stop: int = idx + alias.length()
			if _is_word_char(text, idx - 1) or _is_word_char(text, stop):
				continue
			var start: int = idx
			if start > 0 and stop < text.length() and text.substr(start - 1, 1) == "[" and text.substr(stop, 1) == "]":
				start -= 1
				stop += 1
			if _range_free(occupied, start, stop):
				_mark_range(occupied, start, stop)
				matches.append({"start": start, "end": stop, "term": term})
	return matches


static func _is_word_char(text: String, index: int) -> bool:
	if index < 0 or index >= text.length():
		return false
	var code: int = text.unicode_at(index)
	if code == 95 or (code >= 48 and code <= 57):
		return true
	var ts: TextServer = TextServerManager.get_primary_interface()
	if ts != null and ts.is_valid_letter(code):
		return true
	var ch: String = text.substr(index, 1)
	return ch.to_lower() != ch.to_upper()


static func _range_free(occupied: PackedByteArray, start: int, stop: int) -> bool:
	for i in range(start, stop):
		if occupied[i] != 0:
			return false
	return true


static func _mark_range(occupied: PackedByteArray, start: int, stop: int) -> void:
	for i in range(start, stop):
		occupied[i] = 1


static func _wrap(term: GameTerm, matched: String, tag_knowledge: Dictionary) -> String:
	var inner_text: String = matched
	var open_bracket: String = ""
	var close_bracket: String = ""
	if matched.begins_with("[") and matched.ends_with("]") and matched.length() >= 2:
		inner_text = matched.substr(1, matched.length() - 2)
		open_bracket = "[lb]"
		close_bracket = "[rb]"
	var color: Color = LabUi.ACCENT
	if term.visual == GameTerm.Visual.TAG:
		var knowledge: DateTypes.TagKnowledge = DateTypes.TagKnowledge.UNKNOWN
		var typed: Variant = tag_knowledge.get(term.id, tag_knowledge.get(String(term.id), DateTypes.TagKnowledge.UNKNOWN))
		if typed is DateTypes.TagKnowledge:
			knowledge = typed
		elif typed is int:
			knowledge = typed as DateTypes.TagKnowledge
		color = LabUi.tag_knowledge_color(knowledge)
	var colored: String = "[color=#%s][b]%s%s%s[/b][/color]" % [color.to_html(false), open_bracket, inner_text, close_bracket]
	return "[url=%s%s]%s[/url]" % [META_PREFIX, String(term.id), colored]
