class_name LocalAmbiencePlayer
extends Node
## Scene-local ambience loop on Ambience bus (MODULE 23 §10).
## Lives on the location instance so travel frees the previous player (no duplicates).

const DEFAULT_STREAM: String = "res://assets/audio/ambience/factory_hum.ogg"
const BUS_NAME: StringName = &"Ambience"
const NODE_NAME: String = "LocalAmbience"
## Industrial / signal locations only. City/cafe/apartment intentionally skipped (no asset).
const LOCATION_VOLUME_DB: Dictionary = {
	&"salary_mine": -8.0,
	&"laboratory": -8.0,
	&"production_area": -7.0,
	&"final_location": -12.0,
}

@export var stream_path: String = DEFAULT_STREAM
@export var volume_db: float = -8.0
@export var autoplay: bool = true

var _player: AudioStreamPlayer = null


## Attach one LocalAmbience under a WorldLocation when the id maps to industrial ambience.
static func ensure_on_location(location: Node) -> void:
	if location == null or not is_instance_valid(location):
		return
	if location.get_node_or_null(NODE_NAME) != null:
		return
	var loc_id: StringName = &""
	if "location_id" in location:
		loc_id = location.get("location_id") as StringName
	if not LOCATION_VOLUME_DB.has(loc_id):
		return
	var node: LocalAmbiencePlayer = LocalAmbiencePlayer.new()
	node.name = NODE_NAME
	node.volume_db = float(LOCATION_VOLUME_DB[loc_id])
	location.add_child(node)


func _ready() -> void:
	if autoplay:
		start_ambience()


func _exit_tree() -> void:
	stop_ambience()


func start_ambience() -> void:
	_ensure_player()
	if _player == null or _player.stream == null:
		return
	if not _player.playing:
		_player.play()


func stop_ambience() -> void:
	if _player != null and is_instance_valid(_player) and _player.playing:
		_player.stop()


func is_playing() -> bool:
	return _player != null and is_instance_valid(_player) and _player.playing


func _ensure_player() -> void:
	if _player != null and is_instance_valid(_player):
		_apply_bus_and_volume()
		return
	var existing: Node = get_node_or_null("AmbienceStream")
	if existing is AudioStreamPlayer:
		_player = existing as AudioStreamPlayer
	else:
		_player = AudioStreamPlayer.new()
		_player.name = "AmbienceStream"
		add_child(_player)
	_apply_bus_and_volume()
	if _player.stream != null:
		return
	if stream_path.strip_edges() == "" or not ResourceLoader.exists(stream_path):
		return
	var loaded: Resource = load(stream_path)
	if not (loaded is AudioStream):
		return
	var audio: AudioStream = (loaded as AudioStream).duplicate()
	_enable_loop(audio)
	_player.stream = audio


func _apply_bus_and_volume() -> void:
	if _player == null:
		return
	_player.bus = String(BUS_NAME)
	_player.volume_db = volume_db


func _enable_loop(audio: AudioStream) -> void:
	if audio is AudioStreamOggVorbis:
		(audio as AudioStreamOggVorbis).loop = true
	elif audio is AudioStreamWAV:
		(audio as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
