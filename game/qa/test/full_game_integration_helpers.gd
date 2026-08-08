class_name FullGameIntegrationHelpers
extends RefCounted
## MODULE 27 Wave C — test-only helpers for full-game integration harness.
## Uses production owner APIs + official RivalFakeCompetitionRunner seam.
## Does NOT set Stage / story flags / teleport past owners.


var gs: Node = null
var story: Node = null
var rel: Node = null
var dc: Node = null
var gd: Node = null
var re: Node = null
var day: Node = null
var media: Node = null
var overload: Node = null
var fc: Node = null
var ci: Node = null
var lge: Node = null
var world: Node = null
var ss: Node = null
var fake_runner: RivalFakeCompetitionRunner = null

var _ok_cb: Callable = Callable()
var _date_id_seq: int = 27000
var stage_history: Array[int] = []
var auth_history: Array[int] = []


const SUCCESS_APPROACH: Dictionary = {
	StoryIds.GIRL_NEIGHBOR: &"discovery_approach_neighbor_admit",
	StoryIds.GIRL_ACTRESS: &"discovery_approach_actress_ask_road",
	StoryIds.GIRL_MINE_BOSS: &"discovery_approach_mine_boss_ask_deeper",
	StoryIds.GIRL_MAGAZINE_EDITOR: &"discovery_approach_magazine_editor_wrong_chair",
	StoryIds.GIRL_SCIENTIST: &"discovery_approach_scientist_body_count",
	StoryIds.GIRL_PRESIDENT: &"discovery_approach_president_outgrown_country",
}

const FAILURE_APPROACH: Dictionary = {
	StoryIds.GIRL_NEIGHBOR: &"discovery_approach_neighbor_style",
	StoryIds.GIRL_ACTRESS: &"discovery_approach_actress_buy_carpet",
	StoryIds.GIRL_MINE_BOSS: &"discovery_approach_mine_boss_safer_look",
	StoryIds.GIRL_MAGAZINE_EDITOR: &"discovery_approach_magazine_editor_move_everything",
	StoryIds.GIRL_SCIENTIST: &"discovery_approach_scientist_buy_body",
	StoryIds.GIRL_PRESIDENT: &"discovery_approach_president_self_declare",
}

const STORY_RIVAL_FOR_GIRL: Dictionary = {
	StoryIds.GIRL_ACTRESS: StoryIds.RIVAL_ACTRESS,
	StoryIds.GIRL_MINE_BOSS: StoryIds.RIVAL_MINE_BOSS,
	StoryIds.GIRL_MAGAZINE_EDITOR: StoryIds.RIVAL_MAGAZINE_EDITOR,
	StoryIds.GIRL_SCIENTIST: StoryIds.RIVAL_SCIENTIST,
	StoryIds.GIRL_PRESIDENT: StoryIds.RIVAL_PRESIDENT,
}


func bind_autoloads(tree: SceneTree) -> void:
	var root: Node = tree.root
	gs = root.get_node("/root/GameState")
	story = root.get_node("/root/Story")
	rel = root.get_node("/root/Relationships")
	dc = root.get_node("/root/DatingCore")
	gd = root.get_node("/root/GirlDiscovery")
	re = root.get_node("/root/RivalEncounters")
	day = root.get_node("/root/GameDay")
	media = root.get_node("/root/Media")
	overload = root.get_node("/root/DatingOverload")
	fc = root.get_node("/root/FirstClone")
	ci = root.get_node("/root/CloneIncremental")
	lge = root.get_node("/root/LateGameExpansion")
	world = root.get_node("/root/World")
	ss = root.get_node("/root/SaveSystem")


func set_ok_callback(cb: Callable) -> void:
	_ok_cb = cb


func _ok(cond: bool, label: String) -> void:
	if _ok_cb.is_valid():
		_ok_cb.call(cond, label)


func attach_fake_runner() -> void:
	fake_runner = RivalFakeCompetitionRunner.new()
	fake_runner.attach(re)
	fake_runner.auto_submit = true
	fake_runner.set_forced(
		GameTypes.RivalCompetitionOutcome.PLAYER_WIN,
		GameTypes.VictoryGrade.CLOSE,
	)


func restore_runner() -> void:
	if fake_runner != null:
		fake_runner.restore_production_runner()
		fake_runner = null


func boost_discovery_stats() -> void:
	gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 2)
	gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.APPEARANCE, 2)
	gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.CAPITAL, 2)
	gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.AURA, 2)


func ensure_saveable_world() -> bool:
	if world == null:
		_ok(false, "World missing for save")
		return false
	if world.has_method("ensure_host"):
		world.call("ensure_host")
	var player: Node = null
	if world.has_method("get_player"):
		player = world.call("get_player") as Node
	if player == null:
		_ok(false, "player missing for save")
		return false
	if String(world.get("current_location_id")) == "":
		if world.has_method("request_travel"):
			world.call("request_travel", &"apartment")
	if player.has_method("enter_gameplay"):
		player.call("enter_gameplay")
	if re.has_method("force_clear_session"):
		re.call("force_clear_session")
	if dc.has_method("force_clear_session"):
		dc.call("force_clear_session")
	if gd.has_method("force_clear_attempt"):
		gd.call("force_clear_attempt")
	var can: bool = bool(ss.call("can_save_now"))
	_ok(can, "can_save_now")
	return can


func reset_clean() -> void:
	gs.call("reset_for_new_game")
	if dc.has_method("force_clear_session"):
		dc.call("force_clear_session")
	if re.has_method("force_clear_session"):
		re.call("force_clear_session")
	if gd.has_method("force_clear_attempt"):
		gd.call("force_clear_attempt")
	if rel.has_method("set_auto_apply_enabled"):
		rel.call("set_auto_apply_enabled", false)
	if rel.has_method("clear_applied_date_ids"):
		rel.call("clear_applied_date_ids")
	if fc.has_method("set_instant_for_test"):
		fc.call("set_instant_for_test", true)
	if ci.has_method("set_realtime_simulation"):
		ci.call("set_realtime_simulation", false)
	if world != null and "current_location_id" in world:
		world.set("current_location_id", &"apartment")
	if fake_runner != null:
		fake_runner.reset_counts()
		fake_runner.auto_submit = true
		fake_runner.set_forced(
			GameTypes.RivalCompetitionOutcome.PLAYER_WIN,
			GameTypes.VictoryGrade.CLOSE,
		)
	stage_history.clear()
	auth_history.clear()
	_record_stage("reset")
	auth_history.append(int(gs.call("get_authority")))


func connect_stage_tracker() -> void:
	if gs.has_signal("stage_changed") and not gs.is_connected("stage_changed", _on_stage_changed):
		gs.connect("stage_changed", _on_stage_changed)


func _on_stage_changed(new_stage: GameTypes.GameStage, _prev: GameTypes.GameStage) -> void:
	var s: int = int(new_stage)
	if stage_history.is_empty() or stage_history[stage_history.size() - 1] != s:
		stage_history.append(s)


func _record_stage(_tag: String) -> void:
	var s: int = int(gs.call("get_stage"))
	if stage_history.is_empty() or stage_history[stage_history.size() - 1] != s:
		stage_history.append(s)


func stage() -> int:
	return int(gs.call("get_stage"))


func assert_stage(expected: int, label: String) -> void:
	_ok(stage() == expected, "%s (got %s)" % [label, stage()])


func assert_stage_monotonic() -> void:
	var ok_mono: bool = true
	var prev: int = -1
	for s in stage_history:
		if prev >= 0 and int(s) < prev:
			ok_mono = false
			break
		if prev >= 0 and int(s) > prev + 1:
			ok_mono = false
			break
		prev = int(s)
	_ok(ok_mono, "stage order never skips/reverses: %s" % str(stage_history))


func assert_auth_ladder_prefix(expected_after_wins: Array[int], label: String) -> void:
	_ok(auth_history.size() >= expected_after_wins.size(), "%s auth history len" % label)
	var ok_auth: bool = true
	for i in range(expected_after_wins.size()):
		if i >= auth_history.size() or auth_history[i] != expected_after_wins[i]:
			ok_auth = false
			break
	_ok(ok_auth, "%s auth ladder %s vs %s" % [label, str(expected_after_wins), str(auth_history)])


func discover_girl(girl_id: StringName, approach_id: StringName) -> Dictionary:
	var disc: Dictionary = gd.call("discover_girl", girl_id) as Dictionary
	if not bool(disc.get("ok", false)) and not bool(gs.call("is_girl_discovered", girl_id)):
		return disc
	if bool(gs.call("has_girl_contact", girl_id)):
		return {"ok": true, "reason": &"ALREADY_CONTACT", "approach": approach_id}
	var begin: Dictionary = gd.call("begin_attempt", girl_id) as Dictionary
	if not bool(begin.get("ok", false)):
		return begin
	var sel: Dictionary = gd.call("select_approach", approach_id) as Dictionary
	return sel


func discover_success(girl_id: StringName) -> bool:
	var approach: StringName = SUCCESS_APPROACH.get(girl_id, &"") as StringName
	if String(approach) == "":
		_ok(false, "no success approach for %s" % String(girl_id))
		return false
	var res: Dictionary = discover_girl(girl_id, approach)
	var ok: bool = bool(res.get("ok", false)) and (
		res.get("reason", &"") == &"SUCCESS"
		or res.get("reason", &"") == &"ALREADY_CONTACT"
		or bool(gs.call("has_girl_contact", girl_id))
	)
	_ok(ok, "discover SUCCESS %s" % String(girl_id))
	return ok


func discover_failure(girl_id: StringName) -> bool:
	var approach: StringName = FAILURE_APPROACH.get(girl_id, &"") as StringName
	if String(approach) == "":
		_ok(false, "no failure approach for %s" % String(girl_id))
		return false
	boost_discovery_stats()
	var res: Dictionary = discover_girl(girl_id, approach)
	var ok: bool = bool(res.get("ok", false)) and res.get("reason", &"") == &"FAILURE"
	_ok(ok, "discover FAILURE %s" % String(girl_id))
	_ok(not bool(gs.call("has_girl_contact", girl_id)), "no contact after failure %s" % String(girl_id))
	return ok


func make_date_result(girl_id: StringName, delta: int) -> DatingResult:
	var r: DatingResult = DatingResult.new()
	_date_id_seq += 1
	r.date_id = _date_id_seq
	r.girl_id = girl_id
	r.date_delta = delta
	var a: StringName = StringName("date_event_fg_%s_a" % _date_id_seq)
	var b: StringName = StringName("date_event_fg_%s_b" % _date_id_seq)
	var c: StringName = StringName("date_event_fg_%s_c" % _date_id_seq)
	r.central_event_ids = [a, b, c]
	return r


func conquer_girl(girl_id: StringName, label: String = "") -> bool:
	var tag: String = label if label != "" else String(girl_id)
	if not bool(gs.call("has_girl_contact", girl_id)):
		if not discover_success(girl_id):
			return false
	gs.call("set_girl_date_cooldown_days_remaining", girl_id, 0)
	var applied: RelationshipDateResult = rel.call(
		"apply_date_result", make_date_result(girl_id, 5)
	) as RelationshipDateResult
	var ok: bool = applied != null and applied.ok and (
		applied.newly_conquered or bool(gs.call("is_girl_conquered", girl_id))
	)
	_ok(ok, "conquer %s via Relationships" % tag)
	_record_stage("after_conquer_%s" % tag)
	return ok


func apply_partial_date(girl_id: StringName, delta: int) -> RelationshipDateResult:
	gs.call("set_girl_date_cooldown_days_remaining", girl_id, 0)
	return rel.call("apply_date_result", make_date_result(girl_id, delta)) as RelationshipDateResult


func _pick_competition(rival_id: StringName) -> GameTypes.CompetitionType:
	var available: Array = re.call("get_available_competitions", rival_id) as Array
	if available.is_empty():
		return GameTypes.CompetitionType.SLAP
	return available[0] as GameTypes.CompetitionType


func force_rival_outcome(
	rival_id: StringName,
	outcome: GameTypes.RivalCompetitionOutcome,
	label: String = "",
) -> bool:
	var tag: String = label if label != "" else String(rival_id)
	if fake_runner == null:
		_ok(false, "fake runner missing for %s" % tag)
		return false
	re.call("force_clear_session")
	fake_runner.set_forced(outcome, GameTypes.VictoryGrade.CLOSE)
	var start: Dictionary = re.call(
		"start_encounter",
		rival_id,
		GameTypes.RivalEncounterInitiator.PLAYER,
	) as Dictionary
	if not bool(start.get("ok", false)):
		_ok(false, "start_encounter %s (%s)" % [tag, str(start.get("reason", &""))])
		return false
	var ctype: GameTypes.CompetitionType = _pick_competition(rival_id)
	var choose: Dictionary = re.call("choose_competition", ctype) as Dictionary
	var ok: bool = bool(choose.get("ok", false))
	_ok(ok, "rival %s outcome=%s" % [tag, int(outcome)])
	auth_history.append(int(gs.call("get_authority")))
	_record_stage("after_rival_%s" % tag)
	return ok


func win_rival(rival_id: StringName, label: String = "") -> bool:
	return force_rival_outcome(rival_id, GameTypes.RivalCompetitionOutcome.PLAYER_WIN, label)


func lose_rival(rival_id: StringName, label: String = "") -> bool:
	return force_rival_outcome(rival_id, GameTypes.RivalCompetitionOutcome.PLAYER_LOSS, label)


func drive_media_to_overload() -> bool:
	_ok(bool(story.call("is_feature_unlocked", StoryTypes.StoryFeature.MEDIA_ATTENTION)), "MEDIA_ATTENTION unlocked")
	var poses: Dictionary = {
		MediaContent.PHOTO_PROFILE: &"pose_media_profile_normal",
		MediaContent.PHOTO_CHAIR: &"pose_media_chair_sit",
		MediaContent.PHOTO_COVER: &"pose_media_cover_stand",
	}
	var session_ok: bool = bool(media.call("complete_photo_session", poses))
	_ok(session_ok, "photo session complete")
	_ok(int(media.call("get_attention")) == MediaContent.ARTICLE_ATTENTION, "article attention 15")
	var photos: Array[StringName] = [
		MediaContent.PHOTO_PROFILE,
		MediaContent.PHOTO_CHAIR,
		MediaContent.PHOTO_COVER,
	]
	for pid in photos:
		if int(media.call("get_attention")) >= MediaContent.OVERLOAD_READY_ATTENTION:
			break
		if not bool(media.call("can_publish_photo_today")):
			day.call("advance_day")
		var pub: MediaPublishResult = media.call("publish_photo", pid) as MediaPublishResult
		_ok(pub != null and pub.ok, "publish %s" % String(pid))
	if overload.has_method("_ensure_started_from_media"):
		overload.call("_ensure_started_from_media")
	var started: bool = bool(overload.call("is_started"))
	_ok(started, "DatingOverload started")
	_ok(int(media.call("get_attention")) >= MediaContent.OVERLOAD_READY_ATTENTION, "attention>=45")
	_ok(int(media.call("get_incoming_offer_count")) >= MediaContent.OVERLOAD_READY_OFFERS, "offers>=3")
	return started


func drive_overload_recognition() -> bool:
	if bool(overload.call("is_problem_recognized")):
		return true
	day.call("advance_day")
	day.call("advance_day")
	var candidates: Array[StringName] = [
		&"girl_public_sculpture",
		&"girl_appearance_flash",
		&"girl_cafe_receipt_notes",
	]
	for gid in candidates:
		if bool(overload.call("is_problem_recognized")):
			break
		if not bool(gs.call("has_girl_contact", gid)):
			gs.call("mark_girl_discovered", gid)
			gs.call("add_girl_contact", gid)
		apply_partial_date(gid, 0)
	var recognized: bool = bool(overload.call("is_problem_recognized"))
	_ok(recognized, "overload problem_recognized")
	return recognized


func commit_first_clone_work() -> bool:
	if world != null and "current_location_id" in world:
		world.set("current_location_id", &"laboratory")
	var avail: int = int(fc.call("get_machine_availability"))
	_ok(avail == int(FirstCloneTypes.MachineAvailability.AVAILABLE), "FirstClone machine available")
	var cal: bool = bool(fc.call("complete_calibration_for_test"))
	_ok(cal, "FirstClone calibration")
	var assigned: bool = bool(fc.call("assign_work"))
	_ok(assigned, "FirstClone assign_work")
	_ok(int(gs.call("get_total_clones")) >= 1, "clone count >= 1")
	return assigned


func run_president_xp_bridge(target_xp: int = 10, budget_sec: float = 420.0) -> bool:
	if ci.has_method("set_realtime_simulation"):
		ci.call("set_realtime_simulation", false)
	# Clear backlog so dating clones grant XP.
	var guard: int = 0
	while int(overload.call("get_backlog_count")) > 0 and guard < 64:
		overload.call("fulfill_oldest_demand_by_clone")
		guard += 1
	if int(gs.call("get_free_clones")) > 0:
		ci.call("assign_one_to_work")
	var elapsed: float = 0.0
	while elapsed < budget_sec and int(gs.call("get_experience")) < target_xp:
		ci.call("advance_simulation_for_test", 1.0)
		elapsed += 1.0
		if int(gs.call("get_free_clones")) > 0:
			# Prefer dating after first worker exists.
			if int(gs.call("get_clones_working")) < 1:
				ci.call("assign_one_to_work")
			else:
				ci.call("assign_one_to_dating")
	var xp: int = int(gs.call("get_experience"))
	_ok(xp >= target_xp, "president XP bridge xp=%s in %.0fs" % [xp, elapsed])
	return xp >= target_xp


func run_stage6_reach(budget_sec: float = 520.0) -> bool:
	if ci.has_method("set_realtime_simulation"):
		ci.call("set_realtime_simulation", false)
	var guard: int = 0
	while int(overload.call("get_backlog_count")) > 0 and guard < 64:
		overload.call("fulfill_oldest_demand_by_clone")
		guard += 1
	if ci.has_method("assign_all_free_to_dating"):
		ci.call("assign_all_free_to_dating")
	else:
		while int(gs.call("get_free_clones")) > 0:
			ci.call("assign_one_to_dating")
	var elapsed: float = 0.0
	while elapsed < budget_sec and int(gs.call("get_world_reach")) < LateGameTypes.WORLD_REACH_MAX:
		ci.call("advance_simulation_for_test", 1.0)
		elapsed += 1.0
		if int(gs.call("get_free_clones")) > 0:
			ci.call("assign_one_to_dating")
		for ev in [
			int(LateGameTypes.OptionalEvent.CUSTOMS),
			int(LateGameTypes.OptionalEvent.WORLD_ROUTE),
			int(LateGameTypes.OptionalEvent.LAST_CONTINENT),
		]:
			if bool(lge.call("is_optional_event_available", ev)):
				lge.call("complete_optional_event", ev)
	var reach: int = int(gs.call("get_world_reach"))
	_ok(reach >= LateGameTypes.WORLD_REACH_MAX, "Reach100 got=%s in %.0fs" % [reach, elapsed])
	_record_stage("after_reach100")
	return reach >= LateGameTypes.WORLD_REACH_MAX
