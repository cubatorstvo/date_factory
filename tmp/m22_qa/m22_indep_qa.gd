extends Node
## Independent MODULE 22 UI/UX QA (not product code). Evidence under tmp/m22_qa.
## Run windowed:
## Godot --path <repo> --quit-after 180 res://tmp/m22_qa/m22_indep_qa.tscn

const OUT := "res://tmp/m22_qa"

var _tech_id_patterns: Array[String] = [
	"perk_",
	"girl_",
	"STAGE_",
	"MEDIA_ATTENTION",
]

var _world: Node = null
var _gs: Node = null
var _story: Node = null
var _media: Node = null
var _rels: Node = null
var _dating: Node = null
var _rivals: Node = null
var _fc: Node = null
var _ci: Node = null
var _late: Node = null
var _failed: int = 0
var _passed: int = 0
var _lines: PackedStringArray = PackedStringArray()
var _tech_hits: PackedStringArray = PackedStringArray()


func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_world = get_node("/root/World")
	_gs = get_node("/root/GameState")
	_story = get_node("/root/Story")
	_media = get_node("/root/Media")
	_rels = get_node("/root/Relationships")
	_dating = get_node("/root/DatingCore")
	_rivals = get_node("/root/RivalEncounters")
	_fc = get_node("/root/FirstClone")
	_ci = get_node("/root/CloneIncremental")
	_late = get_node("/root/LateGameExpansion")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await get_tree().process_frame
	if _ci != null and _ci.has_method("set_realtime_simulation"):
		_ci.call("set_realtime_simulation", false)
	_world.call("set_auto_reset_on_state_reset_for_test", false)
	await _run()
	print("M22_INDEP_QA: DONE passed=%s failed=%s" % [_passed, _failed])
	for line in _lines:
		print(line)
	var f := FileAccess.open(ProjectSettings.globalize_path("%s/m22_indep_qa_report.txt" % OUT), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(_lines))
		f.close()
	await get_tree().create_timer(0.35).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		_lines.append("PASS: %s" % label)
	else:
		_failed += 1
		_lines.append("FAIL: %s" % label)
		push_error("[M22_INDEP_QA] FAIL: %s" % label)


func _log(msg: String) -> void:
	_lines.append("INFO: %s" % msg)
	print("M22_INDEP_QA: %s" % msg)


func _run() -> void:
	var vs: Vector2i = DisplayServer.window_get_size()
	_log("window_size=%sx%s (prefer 1280x720)" % [vs.x, vs.y])

	# --- 1) Boot apartment + GameHUD ---
	_gs.call("reset_for_new_game")
	await get_tree().process_frame
	_ok(int(_world.call("reset_to_start")) == 0, "reset_to_start SUCCESS")
	_ok(String(_world.get("current_location_id")) == "apartment", "boot location apartment")
	var hud: GameHUD = _world.call("get_game_hud") as GameHUD
	_ok(hud != null, "get_game_hud non-null")
	_ok(_count_game_hud() == 1, "exactly one GameHUD after boot (got %d)" % _count_game_hud())
	var phone: PhoneJournal = _world.call("get_phone_journal") as PhoneJournal
	_ok(phone != null, "PhoneJournal persistent present")
	_ok(_count_named_persistent("PhoneJournal") == 1, "exactly one PhoneJournal")

	_gs.call("add_money", 12400)
	_gs.call("add_authority", 3)
	_gs.call("add_experience", 2)
	await get_tree().process_frame
	var money_lab: Label = _find_label(hud, "MoneyLabel")
	var auth_lab: Label = _find_label(hud, "AuthorityLabel")
	var xp_lab: Label = _find_label(hud, "ExperienceLabel")
	var up_lab: Label = _find_label(hud, "PointsLabel")
	_ok(money_lab != null and money_lab.text == "$ 12.4K", "HUD money compact got=%s" % (money_lab.text if money_lab else "null"))
	_ok(auth_lab != null and auth_lab.text == "АВТОРИТЕТ 3", "HUD authority")
	_ok(xp_lab != null and xp_lab.text == "ОПЫТНОСТЬ 2", "HUD experience")
	_ok(up_lab != null and up_lab.text == "БАЛЛЫ 2", "HUD points")
	var gameplay_root: CanvasItem = hud.get_node_or_null("ScaleRoot/GameplayRoot") as CanvasItem
	_ok(gameplay_root != null and gameplay_root.visible, "HUD visible GAMEPLAY")
	await _shot_look(Vector3(0.0, 1.6, 2.5), Vector3(0.0, 1.4, 0.0), "%s/01_apartment_hud.png" % OUT)

	# Formatter examples (same as MODULE 22 smoke)
	_ok(UiNumberFormat.format_compact(12400) == "12.4K", "format_compact 12400")
	_ok(UiNumberFormat.format_compact(1250000) == "1.25M", "format_compact 1.25M")
	_ok(UiNumberFormat.format_compact(1000000000) == "1B", "format_compact 1B")
	_ok(UiNumberFormat.format_money(120) == "$ 120", "format_money 120")
	_ok(UiNumberFormat.format_signed(1) == "+1", "format_signed +1")

	# Edge: HUD hide MODAL_UI → return GAMEPLAY
	var player: PlayerController = _world.call("get_player") as PlayerController
	_ok(player != null, "player present")
	if player != null:
		player.enter_modal_ui()
		await get_tree().process_frame
		_ok(gameplay_root != null and not gameplay_root.visible, "HUD hidden MODAL_UI")
		player.enter_gameplay()
		await get_tree().process_frame
		_ok(gameplay_root != null and gameplay_root.visible, "HUD returns GAMEPLAY")
		_ok(int(player.get_control_mode()) == int(PlayerController.ControlMode.GAMEPLAY), "control mode GAMEPLAY")

	# Travel no-dupe HUD
	_ok(int(_world.call("request_travel", &"apartment", &"spawn_default")) == 0, "travel apartment no-dupe")
	await get_tree().process_frame
	_ok(_count_game_hud() == 1, "exactly one GameHUD after travel")
	_ok(_world.call("get_game_hud") == hud, "same GameHUD instance")

	# --- 2) Phone tabs prologue ---
	phone = _world.call("get_phone_journal") as PhoneJournal
	phone.open(player)
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(phone.is_open(), "phone open prologue")
	if gameplay_root != null:
		_ok(not gameplay_root.visible, "HUD hidden while phone open")
	var tabs0: Dictionary = _phone_tab_visibility(phone)
	_ok(bool(tabs0.get("STATUS", false)), "prologue STATUS visible")
	_ok(bool(tabs0.get("STORY", false)), "prologue STORY visible")
	_ok(bool(tabs0.get("GIRLS", false)), "prologue GIRLS visible")
	_ok(not bool(tabs0.get("MEDIA", false)), "prologue MEDIA hidden")
	_ok(not bool(tabs0.get("CLONES", false)), "prologue CLONES hidden")
	_scan_tech_ids(phone, "phone_prologue")
	_scan_tech_ids(hud, "hud_prologue")
	await _set_phone_tab(phone, PhoneJournal.PhoneTab.STATUS)
	await _shot_ui("%s/02_phone_status.png" % OUT)
	await _set_phone_tab(phone, PhoneJournal.PhoneTab.STORY)
	await _shot_ui("%s/03_phone_story.png" % OUT)
	await _set_phone_tab(phone, PhoneJournal.PhoneTab.GIRLS)
	await _shot_ui("%s/04_phone_girls.png" % OUT)
	var status_txt: String = phone.get_status_text()
	var story_txt: String = phone.get_story_text()
	_ok(not status_txt.contains("STAGE_"), "status text no STAGE_ id")
	_ok(not story_txt.contains("MEDIA_ATTENTION"), "story text no MEDIA_ATTENTION")
	phone.close()
	await get_tree().process_frame
	_ok(not phone.is_open(), "phone closed")
	if player != null:
		player.enter_gameplay()
	await get_tree().process_frame
	_ok(gameplay_root == null or gameplay_root.visible, "HUD visible after phone close")

	# --- 3) Progression UI ---
	var loc: Node = _world.call("get_current_location") as Node
	var prog: Node = null
	if loc != null:
		prog = loc.find_child("ProgressionSelfAssessment", true, false)
		if prog == null:
			prog = loc.find_child("ProgressionInteractable", true, false)
	_ok(prog != null, "ProgressionSelfAssessment present")
	if prog != null and player != null:
		prog.call("_open_modal", player)
		await get_tree().process_frame
		await get_tree().process_frame
		var modal: CanvasLayer = get_tree().root.find_child("ProgressionUI", true, false) as CanvasLayer
		if modal == null:
			# scripted layer may use class script root name
			for n in get_tree().root.get_children():
				if n is CanvasLayer and n.get_script() != null:
					var sp: String = str(n.get_script().resource_path)
					if sp.ends_with("progression_ui.gd"):
						modal = n as CanvasLayer
						break
		_ok(modal != null and modal.visible, "Progression UI open")
		if gameplay_root != null:
			_ok(not gameplay_root.visible, "HUD hidden during Progression")
		_scan_tech_ids(modal, "progression_ui")
		await _shot_ui("%s/05_progression_ui.png" % OUT)
		if modal != null and modal.has_method("close"):
			modal.call("close")
		await get_tree().process_frame
		if player != null:
			player.enter_gameplay()
		await get_tree().process_frame
		_ok(gameplay_root == null or gameplay_root.visible, "HUD after Progression close")

	# Edge: reset + restore_stage persistence-style cycle (no disk save API)
	_gs.call("add_money", 500)
	var money_before: int = int(_gs.call("get_money"))
	_ok(money_before >= 500, "money seeded before reset")
	_gs.call("reset_for_new_game")
	await get_tree().process_frame
	_ok(int(_gs.call("get_money")) == 0, "reset_for_new_game clears money")
	_gs.call("restore_stage", GameTypes.GameStage.PROLOGUE)
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.PROLOGUE), "restore_stage PROLOGUE")
	_ok(int(_world.call("reset_to_start")) == 0, "reset_to_start after restore")
	await get_tree().process_frame
	hud = _world.call("get_game_hud") as GameHUD
	_ok(hud != null and _count_game_hud() == 1, "HUD single after reset cycle")
	player = _world.call("get_player") as PlayerController
	phone = _world.call("get_phone_journal") as PhoneJournal
	gameplay_root = hud.get_node_or_null("ScaleRoot/GameplayRoot") as CanvasItem if hud != null else null

	# --- 4) Media unlock tabs ---
	_log("ASSISTED: STAGE_4 media unlock")
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_4)
	await get_tree().process_frame
	_ok(bool(_media.call("is_feature_unlocked")), "MEDIA feature unlocked STAGE_4")
	phone.open(player)
	await get_tree().process_frame
	var tabs4: Dictionary = _phone_tab_visibility(phone)
	_ok(bool(tabs4.get("MEDIA", false)), "STAGE_4 MEDIA visible")
	_ok(not bool(tabs4.get("CLONES", false)), "STAGE_4 CLONES still hidden")
	await _set_phone_tab(phone, PhoneJournal.PhoneTab.MEDIA)
	_scan_tech_ids(phone, "phone_media")
	var att: String = phone.get_media_attention_text()
	_ok(not att.contains("MEDIA_ATTENTION"), "media attention text no MEDIA_ATTENTION got=%s" % att)
	phone.close()
	await get_tree().process_frame
	if player != null:
		player.enter_gameplay()

	# --- 5) Dating UI seed ---
	_log("ASSISTED: dating UI via girl_neighbor contact")
	var girl_id: StringName = &"girl_neighbor"
	_gs.call("add_girl_contact", girl_id)
	_gs.call("set_girl_date_cooldown_days_remaining", girl_id, 0)
	var def: GirlDefinition = get_node("/root/ContentDB").call("try_get_girl", girl_id) as GirlDefinition
	_ok(def != null, "girl_neighbor def")
	if def != null:
		var req := DatingStartRequest.new()
		req.girl_id = girl_id
		req.location_id = def.default_date_location_id
		var greetings: Array[StringName] = []
		for gid in def.dating_greeting_ids:
			greetings.append(gid)
		req.greeting_ids = greetings
		req.farewell_id = def.dating_farewell_id
		var start: Dictionary = _rels.call("start_date_with_history", req) as Dictionary
		_ok(bool(start.get("ok", false)), "start_date ok err=%s" % str(start.get("error", &"")))
		if bool(start.get("ok", false)):
			var packed: PackedScene = load("res://ui/dating/dating_ui.tscn") as PackedScene
			var dating_ui: CanvasLayer = packed.instantiate() as CanvasLayer
			dating_ui.name = "DatingUI"
			get_tree().root.add_child(dating_ui)
			dating_ui.call("open_for_active_date")
			if player != null:
				player.enter_modal_ui()
			await get_tree().process_frame
			await get_tree().process_frame
			_ok(dating_ui.visible, "DatingUI visible")
			if gameplay_root != null:
				_ok(not gameplay_root.visible, "HUD hidden during DatingUI")
			_scan_tech_ids(dating_ui, "dating_ui")
			await _shot_ui("%s/06_dating_ui.png" % OUT)
			if dating_ui.has_method("close_ui"):
				dating_ui.call("close_ui")
			dating_ui.queue_free()
			if _dating != null and _dating.has_method("force_clear_session"):
				_dating.call("force_clear_session")
			await get_tree().process_frame
			if player != null:
				player.enter_gameplay()

	# --- 6) Rival choose UI seed ---
	_log("ASSISTED: rival choose UI")
	var rival_id: StringName = &"rival_actress"
	if get_node("/root/ContentDB").call("try_get_rival", rival_id) == null:
		rival_id = &"rival_city_tracksuit"
	_gs.call("add_authority", 50)
	var enc: Dictionary = _rivals.call(
		"start_encounter",
		rival_id,
		GameTypes.RivalEncounterInitiator.PLAYER,
		GameTypes.RivalEncounterContext.WORLD
	) as Dictionary
	_ok(bool(enc.get("ok", false)), "rival start_encounter ok reason=%s" % str(enc.get("reason", enc.get("error", &""))))
	if bool(enc.get("ok", false)):
		var rui: RivalEncounterUI = RivalEncounterUI.create()
		get_tree().root.add_child(rui)
		rui.open_choose(player, false)
		await get_tree().process_frame
		await get_tree().process_frame
		_ok(rui.visible, "RivalEncounterUI choose visible")
		_scan_tech_ids(rui, "rival_choose")
		await _shot_ui("%s/07_rival_choose.png" % OUT)
		rui.close()
		if _rivals.has_method("force_clear_session"):
			_rivals.call("force_clear_session")
		await get_tree().process_frame
		if player != null:
			player.enter_gameplay()

	# --- 7) Clone terminal ---
	_log("ASSISTED: STAGE_5 + first clone + Clone Terminal")
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_5)
	_gs.call("mark_girl_conquered", &"girl_scientist")
	_gs.call("mark_dating_overload_problem_recognized")
	await get_tree().process_frame
	_ok(bool(_story.call("is_feature_unlocked", StoryTypes.StoryFeature.LABORATORY)), "LABORATORY unlocked")
	_ok(int(_world.call("request_travel", &"laboratory", &"spawn_default")) == 0, "travel laboratory")
	await get_tree().process_frame
	await get_tree().process_frame
	player = _world.call("get_player") as PlayerController
	hud = _world.call("get_game_hud") as GameHUD
	gameplay_root = hud.get_node_or_null("ScaleRoot/GameplayRoot") as CanvasItem if hud != null else null
	if _fc.has_method("set_instant_for_test"):
		_fc.call("set_instant_for_test", true)
	if int(_gs.call("get_total_clones")) == 0:
		_ok(bool(_fc.call("start_sequence", null)), "first clone start_sequence")
		_ok(bool(_fc.call("complete_calibration_for_test")), "complete_calibration_for_test")
		_ok(bool(_fc.call("assign_work")), "assign_work")
		await get_tree().process_frame
	_ok(int(_gs.call("get_total_clones")) >= 1, "total_clones>=1")
	phone = _world.call("get_phone_journal") as PhoneJournal
	phone.open(player)
	await get_tree().process_frame
	var tabs5: Dictionary = _phone_tab_visibility(phone)
	_ok(bool(tabs5.get("CLONES", false)), "CLONES tab visible after first clone")
	phone.close()
	await get_tree().process_frame
	if player != null:
		player.enter_gameplay()
	loc = _world.call("get_current_location") as Node
	var terminal: Node = null
	if loc != null:
		terminal = loc.find_child("CloneTerminalInteractable", true, false)
	_ok(terminal != null, "CloneTerminalInteractable present")
	if terminal != null:
		terminal.call("_open_modal", player)
		await get_tree().process_frame
		await get_tree().process_frame
		var cterm: Node = get_tree().root.find_child("CloneTerminalUI", true, false)
		_ok(cterm != null, "CloneTerminalUI open")
		if gameplay_root != null:
			_ok(not gameplay_root.visible, "HUD hidden Clone Terminal")
		_scan_tech_ids(cterm, "clone_terminal")
		await _shot_ui("%s/08_clone_terminal.png" % OUT)
		if cterm != null and cterm.has_method("close"):
			cterm.call("close")
		elif cterm != null:
			cterm.queue_free()
		await get_tree().process_frame
		if player != null:
			player.enter_gameplay()

	# --- 8) Global terminal (optional if seedable) ---
	_log("ASSISTED: STAGE_6 global terminal")
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_6)
	if _gs.has_method("set_world_reach"):
		_gs.call("set_world_reach", 20)
	await get_tree().process_frame
	var travel_prod: int = int(_world.call("request_travel", &"production_area", &"spawn_default"))
	if travel_prod != 0:
		travel_prod = int(_world.call("request_travel", &"laboratory", &"spawn_default"))
		_log("production_area travel failed; fallback lab code=%s" % travel_prod)
	_ok(travel_prod == 0, "travel production_area/lab STAGE_6")
	await get_tree().process_frame
	await get_tree().process_frame
	player = _world.call("get_player") as PlayerController
	hud = _world.call("get_game_hud") as GameHUD
	gameplay_root = hud.get_node_or_null("ScaleRoot/GameplayRoot") as CanvasItem if hud != null else null
	loc = _world.call("get_current_location") as Node
	var gterm_i: Node = null
	if loc != null:
		gterm_i = loc.find_child("GlobalExpansionTerminalInteractable", true, false)
	_ok(gterm_i != null, "GlobalExpansionTerminalInteractable present loc=%s" % String(_world.get("current_location_id")))
	if gterm_i != null:
		gterm_i.call("_open_modal", player)
		await get_tree().process_frame
		await get_tree().process_frame
		var gterm: Node = get_tree().root.find_child("GlobalExpansionTerminalUI", true, false)
		_ok(gterm != null, "GlobalExpansionTerminalUI open")
		_scan_tech_ids(gterm, "global_terminal")
		await _shot_ui("%s/09_global_terminal.png" % OUT)
		if gterm != null and gterm.has_method("close"):
			gterm.call("close")
		elif gterm != null:
			gterm.queue_free()
		if player != null:
			player.enter_gameplay()
	else:
		_log("GlobalExpansionTerminalInteractable missing — skipped shot")

	# Final invariants
	_ok(_count_game_hud() == 1, "final exactly one GameHUD")
	_ok(_count_named_persistent("PhoneJournal") == 1, "final exactly one PhoneJournal")
	_ok(_tech_hits.is_empty(), "no technical IDs in scanned UI labels hits=%s" % ",".join(_tech_hits))
	if not _tech_hits.is_empty():
		for h in _tech_hits:
			_log("TECH_HIT %s" % h)

	# MODULE 23 absence (filesystem probe from harness)
	_ok(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://audio")), "no res://audio (M23)")
	_ok(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://sfx")), "no res://sfx (M23)")
	_ok(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://vfx")), "no res://vfx (M23)")
	_ok(not ResourceLoader.exists("res://docs/modules/MODULE_23_AUDIO.md"), "no MODULE_23 doc file as product audio start")

	_log("summary passed=%s failed=%s tech_hits=%s" % [_passed, _failed, _tech_hits.size()])


func _phone_tab_visibility(phone: PhoneJournal) -> Dictionary:
	var out: Dictionary = {}
	var buttons: Dictionary = phone.get("_tab_buttons") as Dictionary
	for key in buttons.keys():
		var btn: Button = buttons[key] as Button
		var name: String = ""
		match int(key):
			int(PhoneJournal.PhoneTab.STATUS):
				name = "STATUS"
			int(PhoneJournal.PhoneTab.STORY):
				name = "STORY"
			int(PhoneJournal.PhoneTab.GIRLS):
				name = "GIRLS"
			int(PhoneJournal.PhoneTab.MEDIA):
				name = "MEDIA"
			int(PhoneJournal.PhoneTab.CLONES):
				name = "CLONES"
			_:
				name = str(key)
		out[name] = btn != null and btn.visible
	return out


func _set_phone_tab(phone: PhoneJournal, tab: PhoneJournal.PhoneTab) -> void:
	if phone.has_method("_set_active_tab"):
		phone.call("_set_active_tab", tab)
	await get_tree().process_frame
	await get_tree().process_frame


func _scan_tech_ids(root: Node, where: String) -> void:
	if root == null:
		return
	_collect_label_hits(root, where)


func _collect_label_hits(node: Node, where: String) -> void:
	if node is Label:
		_check_text((node as Label).text, where, String(node.name))
	elif node is RichTextLabel:
		_check_text((node as RichTextLabel).get_parsed_text(), where, String(node.name))
	elif node is Button:
		_check_text((node as Button).text, where, String(node.name))
	for child in node.get_children():
		_collect_label_hits(child, where)


func _check_text(text: String, where: String, node_name: String) -> void:
	if text.is_empty():
		return
	for pat in _tech_id_patterns:
		if text.contains(pat):
			# Allow Russian words that happen to include latin? patterns are technical.
			# girl_ in internal lists is FAIL for player-facing labels.
			_tech_hits.append("%s/%s contains %s :: %s" % [where, node_name, pat, text.substr(0, 80)])


func _count_game_hud() -> int:
	return _count_named_persistent("GameHUD")


func _count_named_persistent(node_name: String) -> int:
	var n: int = 0
	var host: Node = get_tree().root.get_node_or_null("WorldHost")
	if host == null:
		return 0
	var ui: Node = host.get_node_or_null("PersistentUI")
	if ui == null:
		return 0
	for child in ui.get_children():
		if String(child.name) == node_name:
			n += 1
		elif node_name == "GameHUD" and child is GameHUD:
			n += 1
		elif node_name == "PhoneJournal" and child is PhoneJournal:
			n += 1
	return n


func _find_label(root: Node, node_name: String) -> Label:
	if root == null:
		return null
	if root.name == node_name and root is Label:
		return root as Label
	for child in root.get_children():
		var found: Label = _find_label(child, node_name)
		if found != null:
			return found
	return null


func _shot_look(cam_pos: Vector3, look: Vector3, out_path: String) -> void:
	var cam := Camera3D.new()
	cam.name = "M22QaCam"
	add_child(cam)
	cam.global_position = cam_pos
	cam.look_at(look, Vector3.UP)
	cam.current = true
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_save_viewport(out_path)
	cam.queue_free()
	await get_tree().process_frame


func _shot_ui(out_path: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_save_viewport(out_path)
	await get_tree().process_frame


func _save_viewport(out_path: String) -> void:
	var tex: ViewportTexture = get_viewport().get_texture()
	if tex == null:
		_log("SHOT SKIP no viewport %s" % out_path)
		return
	var img: Image = tex.get_image()
	if img == null:
		_log("SHOT SKIP null image %s" % out_path)
		return
	var err: Error = img.save_png(ProjectSettings.globalize_path(out_path))
	_log("SHOT %s err=%s size=%sx%s" % [out_path, err, img.get_width(), img.get_height()])
