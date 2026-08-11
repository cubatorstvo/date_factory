class_name GalleryFixtures
extends RefCounted
## Gallery-only helpers for visual playtest.
## May drive story via FullGameIntegrationHelpers or open UI shells for screenshots.
## Do not call forbidden stage cheats from playthrough_driver — only from GALLERY FIXTURE ONLY methods.


const HELPERS_PATH: String = "res://game/qa/test/full_game_integration_helpers.gd"
const CLONE_TERMINAL_UI: String = "res://game/clone_incremental/clone_terminal_ui.tscn"
const GLOBAL_TERMINAL_UI: String = "res://game/late_game/global_expansion_terminal_ui.tscn"
const PROGRESSION_SCENE: String = "res://ui/progression/progression_ui.tscn"
const DATING_SCENE: String = "res://ui/dating/dating_ui.tscn"
const PAUSE_SCENE: String = "res://ui/frontend/pause_menu.tscn"
const RIVAL_UI_SCENE: String = "res://ui/rivals/rival_encounter_ui.tscn"

const MINIGAME_SCENES: Dictionary = {
	"slap": "res://minigames/slap/slap_minigame.tscn",
	"dance": "res://minigames/dance/dance_minigame.tscn",
	"sigma": "res://minigames/sigma/sigma_minigame.tscn",
	"money": "res://minigames/money/money_minigame.tscn",
}

const MINIGAME_COMP_TYPES: Dictionary = {
	"slap": GameTypes.CompetitionType.SLAP,
	"dance": GameTypes.CompetitionType.DANCE,
	"sigma": GameTypes.CompetitionType.SIGMA,
	"money": GameTypes.CompetitionType.MONEY,
}


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func make_helpers(host: Node) -> FullGameIntegrationHelpers:
	var script: GDScript = load(HELPERS_PATH) as GDScript
	if script == null:
		push_error("[GalleryFixtures] helpers script missing")
		return null
	var helpers: FullGameIntegrationHelpers = script.new() as FullGameIntegrationHelpers
	if helpers == null:
		return null
	var tree: SceneTree = host.get_tree() if host != null else _tree()
	if tree == null:
		return null
	helpers.bind_autoloads(tree)
	helpers.set_ok_callback(Callable(self, "_helpers_ok"))
	helpers.attach_fake_runner()
	return helpers


func _helpers_ok(cond: bool, label: String) -> void:
	if not cond:
		print("[GalleryFixtures] helper note FAIL: %s" % label)
	else:
		print("[GalleryFixtures] helper ok: %s" % label)


func prepare_new_game_world() -> bool:
	var ok: bool = FrontendSaveApi.start_new_game()
	if not ok:
		return false
	var tree: SceneTree = _tree()
	if tree == null:
		return false
	var world: Node = tree.root.get_node_or_null("/root/World")
	if world == null:
		return false
	if world.has_method("ensure_host"):
		world.call("ensure_host")
	var player: Node = null
	if world.has_method("get_player"):
		player = world.call("get_player") as Node
	if player != null and player.has_method("enter_gameplay"):
		player.call("enter_gameplay")
	return true


func get_world() -> Node:
	var tree: SceneTree = _tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("/root/World")


func get_player() -> Node:
	var world: Node = get_world()
	if world == null:
		return null
	if world.has_method("get_player"):
		return world.call("get_player") as Node
	return null


func travel_if_available(location_id: StringName) -> bool:
	var world: Node = get_world()
	if world == null:
		return false
	if world.has_method("is_location_available"):
		var available: bool = bool(world.call("is_location_available", location_id))
		if not available:
			return false
	if world.has_method("request_travel"):
		var result: Variant = world.call("request_travel", location_id)
		return int(result) == int(WorldTypes.WorldTravelResult.SUCCESS)
	return false


func look_player(yaw_deg: float, pitch_deg: float) -> bool:
	var player: Node = get_player()
	if player == null or not player.has_method("apply_pose_dict"):
		return false
	var pos: Vector3 = Vector3.ZERO
	if player is Node3D:
		pos = (player as Node3D).global_position
	var pose: Dictionary = {
		"position": [pos.x, pos.y, pos.z],
		"yaw": deg_to_rad(yaw_deg),
		"pitch": deg_to_rad(pitch_deg),
	}
	return bool(player.call("apply_pose_dict", pose))


func open_phone() -> PhoneJournal:
	var world: Node = get_world()
	if world == null:
		return null
	var player: Node = get_player()
	if world.has_method("open_phone_journal"):
		var opened: bool = bool(world.call("open_phone_journal", player))
		if not opened:
			return null
	if world.has_method("get_phone_journal"):
		return world.call("get_phone_journal") as PhoneJournal
	return null


func set_phone_tab(phone: PhoneJournal, tab: PhoneJournal.PhoneTab) -> void:
	if phone == null:
		return
	if phone.has_method("set_tab"):
		phone.set_tab(tab)
		return
	var captions: Dictionary = {
		PhoneJournal.PhoneTab.STATUS: "ПРОКАЧКА",
		PhoneJournal.PhoneTab.STORY: "СЮЖЕТ",
		PhoneJournal.PhoneTab.GIRLS: "ДЕВУШКИ",
		PhoneJournal.PhoneTab.MEDIA: "МЕДИА",
		PhoneJournal.PhoneTab.CLONES: "КЛОНЫ",
	}
	var want: String = str(captions.get(tab, ""))
	if want.is_empty():
		return
	_press_button_with_text(phone, want)


func _press_button_with_text(root: Node, text: String) -> bool:
	if root is Button:
		var btn: Button = root as Button
		if btn.text == text and btn.visible:
			btn.pressed.emit()
			return true
	for child: Node in root.get_children():
		if _press_button_with_text(child, text):
			return true
	return false


func open_pause_menu(host: Node) -> PauseMenu:
	if host == null:
		return null
	var packed: PackedScene = load(PAUSE_SCENE) as PackedScene
	var menu: PauseMenu = null
	if packed != null:
		menu = packed.instantiate() as PauseMenu
	if menu == null:
		return null
	host.add_child(menu)
	if menu.has_method("open_from_pause"):
		menu.open_from_pause()
	return menu


func open_progression_ui(host: Node) -> CanvasLayer:
	if host == null:
		return null
	var packed: PackedScene = load(PROGRESSION_SCENE) as PackedScene
	if packed == null:
		return null
	var ui: CanvasLayer = packed.instantiate() as CanvasLayer
	if ui == null:
		return null
	host.add_child(ui)
	if ui.has_method("open"):
		ui.call("open", get_player(), Callable())
	return ui


func open_clone_terminal(host: Node) -> CanvasLayer:
	# GALLERY FIXTURE ONLY — instance terminal UI shell.
	if host == null:
		return null
	var packed: PackedScene = load(CLONE_TERMINAL_UI) as PackedScene
	if packed == null:
		return null
	var layer: CanvasLayer = packed.instantiate() as CanvasLayer
	if layer == null:
		return null
	host.add_child(layer)
	if layer.has_method("open"):
		layer.call("open", get_player(), Callable())
	return layer


func open_global_terminal(host: Node) -> CanvasLayer:
	# GALLERY FIXTURE ONLY — instance global expansion terminal UI shell.
	if host == null:
		return null
	var packed: PackedScene = load(GLOBAL_TERMINAL_UI) as PackedScene
	if packed == null:
		return null
	var layer: CanvasLayer = packed.instantiate() as CanvasLayer
	if layer == null:
		return null
	host.add_child(layer)
	if layer.has_method("open"):
		layer.call("open", get_player(), Callable())
	return layer


func open_rival_choose(host: Node, rival_id: StringName = StoryIds.RIVAL_ACTRESS) -> RivalEncounterUI:
	# GALLERY FIXTURE ONLY — start encounter + choose UI without resolving.
	if host == null:
		return null
	var tree: SceneTree = _tree()
	if tree == null:
		return null
	var re: Node = tree.root.get_node_or_null("/root/RivalEncounters")
	if re == null:
		return null
	if re.has_method("force_clear_session"):
		re.call("force_clear_session")
	var start: Dictionary = re.call(
		"start_encounter",
		rival_id,
		GameTypes.RivalEncounterInitiator.PLAYER,
	) as Dictionary
	if not bool(start.get("ok", false)):
		return null
	var ui: RivalEncounterUI = RivalEncounterUI.create()
	host.add_child(ui)
	ui.open_choose(get_player(), false)
	return ui


func instance_minigame_shell(host: Node, kind: String) -> Node:
	# GALLERY FIXTURE ONLY — instance minigame HUD without playing through.
	if host == null or not MINIGAME_SCENES.has(kind):
		return null
	var path: String = str(MINIGAME_SCENES[kind])
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return null
	var node: Node = packed.instantiate()
	if node == null:
		return null
	var req: RivalCompetitionRequest = RivalCompetitionRequest.new()
	req.rival_id = StoryIds.RIVAL_ACTRESS
	req.competition_type = MINIGAME_COMP_TYPES.get(kind, GameTypes.CompetitionType.SLAP) as GameTypes.CompetitionType
	req.player_level = 2
	req.rival_level = 2
	req.initiator = GameTypes.RivalEncounterInitiator.PLAYER
	req.context = GameTypes.RivalEncounterContext.WORLD
	host.add_child(node)
	if node.has_method("setup"):
		if kind == "money":
			node.call("setup", req, true, 42, null, -1)
		else:
			node.call("setup", req, true, {}, 42)
	return node


func open_discovery_modal(host: Node) -> GirlActor:
	# GALLERY FIXTURE ONLY — spawn neighbor GirlActor and open approach choices.
	if host == null:
		return null
	var actor: GirlActor = GirlActor.new()
	actor.girl_id = StoryIds.GIRL_NEIGHBOR
	host.add_child(actor)
	var tree: SceneTree = _tree()
	if tree != null:
		var gd: Node = tree.root.get_node_or_null("/root/GirlDiscovery")
		if gd != null:
			gd.call("discover_girl", StoryIds.GIRL_NEIGHBOR)
	var player: Node = get_player()
	if player != null:
		actor.interact(player)
	return actor


func try_open_dating_ui(host: Node) -> CanvasLayer:
	# GALLERY FIXTURE ONLY — start a date if contact exists, then open DatingUI.
	if host == null:
		return null
	var tree: SceneTree = _tree()
	if tree == null:
		return null
	var gs: Node = tree.root.get_node_or_null("/root/GameState")
	var dc: Node = tree.root.get_node_or_null("/root/DatingCore")
	if gs == null or dc == null:
		return null
	if not bool(gs.call("has_girl_contact", StoryIds.GIRL_NEIGHBOR)):
		return null
	if gs.has_method("set_girl_date_cooldown_days_remaining"):
		gs.call("set_girl_date_cooldown_days_remaining", StoryIds.GIRL_NEIGHBOR, 0)
	var req: DatingStartRequest = DatingStartRequest.new()
	req.girl_id = StoryIds.GIRL_NEIGHBOR
	var start: Dictionary = dc.call("start_date", req) as Dictionary
	if not bool(start.get("ok", false)):
		return null
	var packed: PackedScene = load(DATING_SCENE) as PackedScene
	if packed == null:
		return null
	var ui: CanvasLayer = packed.instantiate() as CanvasLayer
	if ui == null:
		return null
	host.add_child(ui)
	if ui.has_method("open_for_active_date"):
		ui.call("open_for_active_date")
	return ui


## GALLERY FIXTURE ONLY — drive production story ladder for late visual states.
func gallery_drive_to_stage4(helpers: FullGameIntegrationHelpers) -> bool:
	if helpers == null:
		return false
	helpers.boost_discovery_stats()
	if not helpers.conquer_girl(StoryIds.GIRL_NEIGHBOR, "gallery_neighbor"):
		return false
	if not helpers.win_rival(StoryIds.RIVAL_ACTRESS, "gallery_actress_rival"):
		return false
	if not helpers.conquer_girl(StoryIds.GIRL_ACTRESS, "gallery_actress"):
		return false
	if not helpers.win_rival(StoryIds.RIVAL_MINE_BOSS, "gallery_mine_rival"):
		return false
	if not helpers.conquer_girl(StoryIds.GIRL_MINE_BOSS, "gallery_mine"):
		return false
	if not helpers.win_rival(StoryIds.RIVAL_MAGAZINE_EDITOR, "gallery_editor_rival"):
		return false
	if not helpers.conquer_girl(StoryIds.GIRL_MAGAZINE_EDITOR, "gallery_editor"):
		return false
	return helpers.stage() == int(GameTypes.GameStage.STAGE_4)


## GALLERY FIXTURE ONLY
func gallery_drive_media_lab(helpers: FullGameIntegrationHelpers) -> bool:
	if helpers == null:
		return false
	helpers.drive_media_to_overload()
	helpers.drive_overload_recognition()
	if not helpers.win_rival(StoryIds.RIVAL_SCIENTIST, "gallery_scientist_rival"):
		return false
	if not helpers.conquer_girl(StoryIds.GIRL_SCIENTIST, "gallery_scientist"):
		return false
	return helpers.stage() == int(GameTypes.GameStage.STAGE_5)


## GALLERY FIXTURE ONLY
func gallery_drive_stage6_finale(helpers: FullGameIntegrationHelpers) -> bool:
	if helpers == null:
		return false
	helpers.commit_first_clone_work()
	helpers.run_president_xp_bridge(10, 420.0)
	if not helpers.win_rival(StoryIds.RIVAL_PRESIDENT, "gallery_president_rival"):
		return false
	if not helpers.conquer_girl(StoryIds.GIRL_PRESIDENT, "gallery_president"):
		return false
	if helpers.stage() != int(GameTypes.GameStage.STAGE_6):
		return false
	helpers.run_stage6_reach(520.0)
	return helpers.stage() == int(GameTypes.GameStage.FINALE)


func dismiss_blocking_overlays(host: Node) -> void:
	# Best-effort: close OK/Далее dialogs and leftover choice UIs before composition shots.
	if host == null:
		return
	var tree: SceneTree = host.get_tree()
	if tree == null:
		return
	_press_button_with_text(tree.root, "OK")
	_press_button_with_text(tree.root, "Ок")
	# Do not press Далее — FinalDateUI uses it for legitimate flow.
	var gd: Node = tree.root.get_node_or_null("/root/GirlDiscovery")
	if gd != null and gd.has_method("force_clear_attempt"):
		gd.call("force_clear_attempt")
	var re: Node = tree.root.get_node_or_null("/root/RivalEncounters")
	if re != null and re.has_method("force_clear_session"):
		re.call("force_clear_session")
	var dc: Node = tree.root.get_node_or_null("/root/DatingCore")
	if dc != null and dc.has_method("force_clear_session"):
		dc.call("force_clear_session")


func dismiss_accept_dialogs(root: Node) -> void:
	if root == null:
		return
	if root is AcceptDialog:
		(root as AcceptDialog).hide()
	for child: Node in root.get_children():
		dismiss_accept_dialogs(child)


func free_ui(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node.has_method("close"):
		node.call("close")
	elif node.has_method("close_ui"):
		node.call("close_ui")
	elif node.has_method("hide_menu"):
		node.call("hide_menu")
	if is_instance_valid(node):
		node.queue_free()
