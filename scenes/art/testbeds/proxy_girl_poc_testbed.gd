extends Node3D
## Proxy Girl POC technical testbed — keys 1-7 for the seven required aliases.

const ALIASES: PackedStringArray = [
	"idle",
	"walk",
	"run",
	"sit_enter",
	"sit_idle",
	"seated_gesture",
	"sit_exit",
]

var _girl: Node
var _status: Label
var _side_cam: Camera3D
var _front_cam: Camera3D


func _ready() -> void:
	_girl = get_node_or_null("GirlProxyPOC")
	_status = get_node_or_null("UI/Status") as Label
	_front_cam = get_node_or_null("CamFront") as Camera3D
	_side_cam = get_node_or_null("CamSide") as Camera3D
	_frame_cameras()
	if _front_cam != null:
		_front_cam.current = true
	_play("idle")


func _frame_cameras() -> void:
	## Character faces -Z; CamFront on -Z looking toward origin.
	var aim := Vector3(0.0, 0.95, 0.0)
	if _front_cam != null:
		_front_cam.global_position = Vector3(0.0, 1.05, -2.6)
		_front_cam.look_at(aim, Vector3.UP)
	if _side_cam != null:
		_side_cam.global_position = Vector3(2.4, 1.05, 0.0)
		_side_cam.look_at(aim, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		match k.keycode:
			KEY_1:
				_play("idle")
			KEY_2:
				_play("walk")
			KEY_3:
				_play("run")
			KEY_4:
				_play("sit_enter")
			KEY_5:
				_play("sit_idle")
			KEY_6:
				_play("seated_gesture")
			KEY_7:
				_play("sit_exit")
			KEY_F:
				_use_front()
			KEY_S:
				_use_side()


func _play(alias: String) -> void:
	if _girl != null and _girl.has_method("play_alias"):
		_girl.call("play_alias", alias)
	if _status != null:
		_status.text = "GirlProxyPOC | alias=%s | 1-7 anim | F front | S side" % alias


func _use_front() -> void:
	if _front_cam != null:
		_front_cam.current = true


func _use_side() -> void:
	if _side_cam != null:
		_side_cam.current = true
