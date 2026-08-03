class_name NamesAPI
extends Node
## Built-in funny names + optional Twitch nick pool.

signal twitch_status(connected: bool, detail: String)

var pool: PackedStringArray = PackedStringArray()
var used: Dictionary = {}
var twitch_channel: String = ""
var twitch_connected: bool = false
var twitch_nicks: PackedStringArray = PackedStringArray()
var _cursor: int = 0


func setup(_game: Node) -> void:
	ContentDB.ensure_loaded()
	reset()


func reset() -> void:
	pool = ContentDB.builtin_names.duplicate()
	used.clear()
	_cursor = 0
	twitch_connected = false
	twitch_nicks = PackedStringArray()


func set_twitch_channel(channel: String) -> void:
	twitch_channel = channel.strip_edges()
	if twitch_channel.is_empty():
		twitch_connected = false
		twitch_status.emit(false, "Отключено")
		return
	# Optional integration: without live IRC we simulate a connected pool
	# so gameplay never depends on network. Real chat can replace inject_nicks().
	twitch_connected = true
	if twitch_nicks.is_empty():
		twitch_nicks = PackedStringArray(["TwitchFan1", "ChatGoblin", "SubLord", "EmoteOnly", "HypeTrain"])
	twitch_status.emit(true, "Канал: %s (локальный пул ников)" % twitch_channel)
	EventBus.toast("Twitch-имена активны для канала %s" % twitch_channel, &"twitch")


func inject_nicks(nicks: PackedStringArray) -> void:
	twitch_nicks = nicks
	twitch_connected = not nicks.is_empty()


func next_name() -> String:
	var source: PackedStringArray = pool
	if twitch_connected and twitch_nicks.size() > 0:
		source = twitch_nicks
	if source.is_empty():
		return "Аноним"
	for _i in range(source.size()):
		var n: String = _sanitize(str(source[_cursor % source.size()]))
		_cursor += 1
		if not used.has(n) or used.size() >= source.size():
			used[n] = true
			return n
	return _sanitize(str(source[randi() % source.size()]))


func peek_name() -> String:
	var source: PackedStringArray = twitch_nicks if twitch_connected and twitch_nicks.size() > 0 else pool
	if source.is_empty():
		return "Аноним"
	return _sanitize(str(source[_cursor % source.size()]))


func _sanitize(n: String) -> String:
	n = n.strip_edges()
	if n.length() > 18:
		n = n.substr(0, 15) + "..."
	if n.is_empty():
		return "Аноним"
	return n


func to_dict() -> Dictionary:
	return {
		"twitch_channel": twitch_channel,
		"twitch_connected": twitch_connected,
		"used": used.duplicate(),
		"_cursor": _cursor,
	}


func from_dict(data: Dictionary) -> void:
	twitch_channel = str(data.get("twitch_channel", ""))
	twitch_connected = bool(data.get("twitch_connected", false))
	used = data.get("used", {}) as Dictionary
	_cursor = int(data.get("_cursor", 0))
	if twitch_connected and not twitch_channel.is_empty():
		set_twitch_channel(twitch_channel)
