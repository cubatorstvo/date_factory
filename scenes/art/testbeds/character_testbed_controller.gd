extends Node3D
## Technical Character Testbed: keys + auto demo for animation aliases.


const ALIASES: PackedStringArray = ["idle", "walk", "run", "sit", "stand", "gesture", "react"]
const DEMO_CYCLE: PackedStringArray = ["idle", "walk", "gesture", "sit", "stand", "react"]
const DEMO_HOLD_SEC := 2.2

var _auto_demo: bool = true
var _demo_index: int = 0
var _hold: float = 0.0
var _status: Label
var _characters: Array[Node] = []


func _ready() -> void:
	_status = get_node_or_null("TechUI/Panel/VBox/Status") as Label
	var chars_root := get_node_or_null("Characters")
	if chars_root != null:
		for c in chars_root.get_children():
			_characters.append(c)
	_play_all("idle")
	_update_status("idle")


func _process(delta: float) -> void:
	if not _auto_demo:
		return
	_hold += delta
	if _hold < DEMO_HOLD_SEC:
		return
	_hold = 0.0
	_demo_index = (_demo_index + 1) % DEMO_CYCLE.size()
	var alias := DEMO_CYCLE[_demo_index]
	_play_all(alias)
	_update_status(alias)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		match k.keycode:
			KEY_1:
				_manual("idle")
			KEY_2:
				_manual("walk")
			KEY_3:
				_manual("run")
			KEY_4:
				_manual("sit")
			KEY_5:
				_manual("stand")
			KEY_6:
				_manual("gesture")
			KEY_7:
				_manual("react")
			KEY_A:
				_auto_demo = true
				_hold = 0.0
				_demo_index = 0
				_play_all(DEMO_CYCLE[0])
				_update_status(DEMO_CYCLE[0])
			KEY_D:
				_auto_demo = false
				_update_status(_current_alias_hint())


func _manual(alias: String) -> void:
	_auto_demo = false
	_play_all(alias)
	_update_status(alias)


func _play_all(alias: String) -> void:
	for c in _characters:
		if c != null and c.has_method("play_alias"):
			c.call("play_alias", alias)


func _current_alias_hint() -> String:
	for c in _characters:
		if c != null and c.has_method("get_current_alias"):
			var a: String = str(c.call("get_current_alias"))
			if a != "":
				return a
	return "idle"


func _update_status(alias: String) -> void:
	if _status == null:
		return
	var names: PackedStringArray = []
	for c in _characters:
		if c != null and c.has_method("get_display_name"):
			names.append(str(c.call("get_display_name")))
		elif c != null:
			names.append(c.name)
	var mode := "AUTO" if _auto_demo else "MANUAL"
	_status.text = "mode=%s | alias=%s | chars=%s" % [mode, alias, ", ".join(names)]
