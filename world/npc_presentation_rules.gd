class_name NpcPresentationRules
extends Node
## Presentation-only ordinary NPC visibility for city_hub / cafe (AP1-NPC).
## Does not change content IDs, catalog availability, or cafe geometry.

enum RulesMode {
	CITY,
	CAFE,
}

const CITY_SPAWN_EXCLUSION_M: float = 2.5
const CITY_TRANSITION_EXCLUSION_M: float = 1.2
const CAFE_MAX_ORDINARY_VISIBLE: int = 4
const CAFE_DATE_CLEARANCE_M: float = 2.2
const CAFE_DATE_LOS_RANGE_M: float = 5.0
const CAFE_DATE_LOS_DOT_MIN: float = 0.35
const META_HIDDEN: StringName = &"_npc_presentation_hidden"

@export var mode: RulesMode = RulesMode.CITY

var _ordinary: Array[Node3D] = []
var _intended_hidden: Dictionary = {}
var _last_date_active: bool = false
var _bootstrapped: bool = false


func _ready() -> void:
	call_deferred("_bootstrap")


func _bootstrap() -> void:
	if _bootstrapped:
		return
	_bootstrapped = true
	_collect_ordinary_actors()
	_hook_dating()
	apply_rules()
	set_process(true)


func _process(_delta: float) -> void:
	var date_now: bool = _is_date_active()
	if date_now != _last_date_active:
		_last_date_active = date_now
		apply_rules()
	_enforce_intended()


func apply_rules() -> void:
	# Always refresh: probes / late-spawned ordinary actors must be included.
	_collect_ordinary_actors()
	_intended_hidden.clear()
	match mode:
		RulesMode.CITY:
			_apply_city_rules()
		RulesMode.CAFE:
			_apply_cafe_rules()
	_enforce_intended()


func get_ordinary_actors() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for actor in _ordinary:
		if actor != null and is_instance_valid(actor):
			out.append(actor)
	return out


func count_visible_ordinary() -> int:
	var n: int = 0
	for actor in get_ordinary_actors():
		if is_actor_presentation_visible(actor):
			n += 1
	return n


func is_actor_presentation_visible(actor: Node3D) -> bool:
	return _is_presentation_visible(actor)


func validate_city_spawn_exclusion() -> Array[String]:
	var errors: Array[String] = []
	var spawn: Node3D = _find_player_spawn()
	if spawn == null:
		errors.append("missing PlayerSpawns/spawn_default")
		return errors
	var spawn_pos: Vector3 = spawn.global_position
	for actor in get_ordinary_actors():
		var dist: float = _planar_distance(actor.global_position, spawn_pos)
		if dist < CITY_SPAWN_EXCLUSION_M and _is_presentation_visible(actor):
			errors.append(
				"ordinary NPC %s within %.2fm of spawn (visible)"
				% [actor.get_path(), dist]
			)
	return errors


func validate_cafe_ordinary_cap() -> Array[String]:
	var errors: Array[String] = []
	var visible_n: int = count_visible_ordinary()
	if visible_n > CAFE_MAX_ORDINARY_VISIBLE:
		errors.append("ordinary visible count %d > %d" % [visible_n, CAFE_MAX_ORDINARY_VISIBLE])
	return errors


func validate_cafe_date_clearance() -> Array[String]:
	var errors: Array[String] = []
	if not _is_date_active():
		return errors
	var venue: Node3D = _find_date_venue()
	if venue == null:
		errors.append("missing date venue interaction while date active")
		return errors
	var venue_pos: Vector3 = venue.global_position
	for actor in get_ordinary_actors():
		if _is_exempt_for_active_date(actor):
			continue
		var dist: float = _planar_distance(actor.global_position, venue_pos)
		if dist < CAFE_DATE_CLEARANCE_M and _is_presentation_visible(actor):
			errors.append(
				"ordinary NPC %s within %.2fm of DateVenue during date (visible)"
				% [actor.get_path(), dist]
			)
	return errors


func _hook_dating() -> void:
	var dc: Node = get_node_or_null("/root/DatingCore")
	if dc == null:
		return
	if dc.has_signal("phase_changed") and not dc.is_connected("phase_changed", _on_dating_phase_changed):
		dc.connect("phase_changed", _on_dating_phase_changed)
	if dc.has_signal("date_finished") and not dc.is_connected("date_finished", _on_date_finished):
		dc.connect("date_finished", _on_date_finished)
	if dc.has_signal("arrival_presentation_requested") and not dc.is_connected(
		"arrival_presentation_requested", _on_arrival_presentation
	):
		dc.connect("arrival_presentation_requested", _on_arrival_presentation)


func _on_dating_phase_changed(_phase: Variant) -> void:
	apply_rules()


func _on_date_finished(_result: Variant) -> void:
	call_deferred("apply_rules")


func _on_arrival_presentation(_girl_id: StringName) -> void:
	apply_rules()


func _collect_ordinary_actors() -> void:
	_ordinary.clear()
	var spawns: Node = get_parent()
	if spawns == null:
		return
	for marker in spawns.get_children():
		if marker is StageActorAnchor:
			continue
		if not (marker is Node3D):
			continue
		for child in marker.get_children():
			if child is GirlActor or child is RivalActor:
				var actor: Node3D = child as Node3D
				_ordinary.append(actor)
				if not actor.tree_exited.is_connected(_on_actor_tree_exited):
					actor.tree_exited.connect(_on_actor_tree_exited)


func _on_actor_tree_exited() -> void:
	call_deferred("_refresh_actor_list")


func _refresh_actor_list() -> void:
	_collect_ordinary_actors()
	apply_rules()


func _apply_city_rules() -> void:
	var spawn: Node3D = _find_player_spawn()
	var spawn_pos: Vector3 = Vector3.ZERO
	var has_spawn: bool = spawn != null
	if has_spawn:
		spawn_pos = spawn.global_position
	var transitions: Array[Node3D] = _find_transitions()
	for actor in get_ordinary_actors():
		var hide: bool = false
		if has_spawn:
			var dist_spawn: float = _planar_distance(actor.global_position, spawn_pos)
			if dist_spawn < CITY_SPAWN_EXCLUSION_M:
				hide = true
		if not hide:
			for tr in transitions:
				if _planar_distance(actor.global_position, tr.global_position) < CITY_TRANSITION_EXCLUSION_M:
					hide = true
					break
		_intended_hidden[actor.get_instance_id()] = hide


func _apply_cafe_rules() -> void:
	var date_active: bool = _is_date_active()
	var venue: Node3D = _find_date_venue()
	var venue_pos: Vector3 = Vector3.ZERO
	var venue_forward: Vector3 = Vector3.FORWARD
	var has_venue: bool = venue != null
	if has_venue:
		venue_pos = venue.global_position
		venue_forward = -venue.global_transform.basis.z
		venue_forward.y = 0.0
		if venue_forward.length_squared() > 0.0001:
			venue_forward = venue_forward.normalized()
		else:
			venue_forward = Vector3.FORWARD
	var ranked: Array[Dictionary] = []
	for actor in get_ordinary_actors():
		var hide: bool = false
		if date_active and not _is_exempt_for_active_date(actor) and has_venue:
			var dist_venue: float = _planar_distance(actor.global_position, venue_pos)
			if dist_venue < CAFE_DATE_CLEARANCE_M:
				hide = true
			elif dist_venue < CAFE_DATE_LOS_RANGE_M and _in_date_los(actor.global_position, venue_pos, venue_forward):
				hide = true
		var score: float = 0.0
		if has_venue:
			score = _planar_distance(actor.global_position, venue_pos)
		ranked.append({
			"actor": actor,
			"hide": hide,
			"score": score,
			"path": String(actor.get_path()),
		})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var sa: float = float(a.get("score", 0.0))
		var sb: float = float(b.get("score", 0.0))
		if not is_equal_approx(sa, sb):
			return sa > sb
		return String(a.get("path", "")) < String(b.get("path", ""))
	)
	var kept: int = 0
	for row in ranked:
		var actor2: Node3D = row.get("actor") as Node3D
		if actor2 == null or not is_instance_valid(actor2):
			continue
		var must_hide: bool = bool(row.get("hide", false))
		if must_hide:
			_intended_hidden[actor2.get_instance_id()] = true
			continue
		if kept < CAFE_MAX_ORDINARY_VISIBLE:
			_intended_hidden[actor2.get_instance_id()] = false
			kept += 1
		else:
			_intended_hidden[actor2.get_instance_id()] = true


func _in_date_los(actor_pos: Vector3, venue_pos: Vector3, venue_forward: Vector3) -> bool:
	var to_actor: Vector3 = actor_pos - venue_pos
	to_actor.y = 0.0
	if to_actor.length_squared() < 0.0001:
		return true
	to_actor = to_actor.normalized()
	return to_actor.dot(venue_forward) >= CAFE_DATE_LOS_DOT_MIN


func _is_exempt_for_active_date(actor: Node3D) -> bool:
	if actor is GirlActor:
		var girl_id: StringName = (actor as GirlActor).girl_id
		var active_girl: StringName = _active_date_girl_id()
		if String(active_girl) != "" and girl_id == active_girl:
			return true
	return false


func _active_date_girl_id() -> StringName:
	var dc: Node = get_node_or_null("/root/DatingCore")
	if dc == null or not bool(dc.call("is_date_active")):
		return &""
	var session: Variant = dc.call("get_session")
	if session == null:
		return &""
	if session is DatingSession:
		return (session as DatingSession).girl_id
	if typeof(session) == TYPE_OBJECT and "girl_id" in session:
		return session.get("girl_id") as StringName
	return &""


func _is_date_active() -> bool:
	var dc: Node = get_node_or_null("/root/DatingCore")
	if dc == null:
		return false
	return bool(dc.call("is_date_active"))


func _find_location_root() -> Node:
	var n: Node = self
	while n != null:
		if n is WorldLocation:
			return n
		n = n.get_parent()
	return get_parent()


func _find_player_spawn() -> Node3D:
	var loc: Node = _find_location_root()
	if loc == null:
		return null
	if loc is WorldLocation:
		var ps: PlayerSpawnPoint = (loc as WorldLocation).get_player_spawn(&"spawn_default")
		if ps != null:
			return ps
	var marker: Node = loc.get_node_or_null("PlayerSpawns/spawn_default")
	return marker as Node3D


func _find_date_venue() -> Node3D:
	var loc: Node = _find_location_root()
	if loc == null:
		return null
	var venue_paths: Array[NodePath] = [
		NodePath("Geometry/ApartmentArt/Objects/DiningTable/Interaction"),
		NodePath("Interactables/DateVenue"),
	]:
		var venue: Node = loc.get_node_or_null(venue_path)
		if venue is Node3D:
			return venue as Node3D
	for n in loc.find_children("*", "DateVenueInteractable", true, false):
		if n is Node3D:
			return n as Node3D
	return null


func _find_transitions() -> Array[Node3D]:
	var out: Array[Node3D] = []
	var loc: Node = _find_location_root()
	if loc == null:
		return out
	for n in loc.find_children("*", "WorldTransition", true, false):
		if n is Node3D:
			out.append(n as Node3D)
	return out


func _enforce_intended() -> void:
	for actor in get_ordinary_actors():
		var id: int = actor.get_instance_id()
		var hide: bool = bool(_intended_hidden.get(id, false))
		_set_presentation_hidden(actor, hide)


func _set_presentation_hidden(actor: Node3D, hidden: bool) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	actor.set_meta(META_HIDDEN, hidden)
	var show: bool = not hidden
	# Presentation only: do not queue_free or change content ids.
	if actor.visible != show:
		actor.visible = show
	var character: Node = actor.get_node_or_null("CharacterActor")
	if character != null and character.has_method("set_character_visible"):
		character.call("set_character_visible", show)
	elif character is Node3D:
		(character as Node3D).visible = show
	var col: CollisionShape3D = actor.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col != null:
		col.disabled = hidden
	if "interaction_enabled" in actor:
		# Keep interaction off while presentation-hidden; GirlActor may restore later.
		if hidden:
			actor.set("interaction_enabled", false)


func _is_presentation_visible(actor: Node3D) -> bool:
	if actor == null or not is_instance_valid(actor):
		return false
	if actor.has_meta(META_HIDDEN) and bool(actor.get_meta(META_HIDDEN)):
		return false
	return actor.visible


func _planar_distance(a: Vector3, b: Vector3) -> float:
	var dx: float = a.x - b.x
	var dz: float = a.z - b.z
	return sqrt(dx * dx + dz * dz)
