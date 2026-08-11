extends Node
## Scene-first UI contract: production surfaces load, expose required nodes, and
## controller scripts do not construct Control trees directly.

const SCENE_REQUIREMENTS: Dictionary = {
	"res://ui/frontend/title_menu.tscn": ["Root", "Root/SafeMargin/Center/Panel"],
	"res://ui/frontend/pause_menu.tscn": ["Root", "Root/SafeMargin/MainPanel/Panel"],
	"res://ui/frontend/settings_panel.tscn": ["Root"],
	"res://ui/frontend/save_load_panel.tscn": ["Root"],
	"res://ui/hud/game_hud.tscn": ["ScaleRoot", "ScaleRoot/GameplayRoot"],
	"res://ui/phone/phone_journal.tscn": ["SafeMargin"],
	"res://ui/progression/progression_ui.tscn": ["Root"],
	"res://ui/rivals/rival_encounter_ui.tscn": ["Root"],
	"res://ui/dating/dating_ui.tscn": [
		"Root",
		"Root/Panel",
		"Root/Panel/Margin/VBox/ChoiceScroll/Choices",
		"Root/Panel/Margin/VBox/InputHint",
	],
	"res://minigames/slap/slap_minigame.tscn": ["Root"],
	"res://minigames/dance/dance_minigame.tscn": ["Root"],
	"res://minigames/sigma/sigma_minigame.tscn": ["Root"],
	"res://minigames/money/money_minigame.tscn": ["Root"],
	"res://game/final_date/final_date_ui.tscn": ["Root"],
	"res://game/clone_incremental/clone_terminal_ui.tscn": ["Root"],
	"res://game/late_game/global_expansion_terminal_ui.tscn": ["Root"],
	"res://game/first_clone/first_clone_assignment_ui.tscn": ["Root"],
	"res://game/first_clone/clone_calibration_minigame.tscn": ["Root"],
	"res://game/media/media_photo_session.tscn": ["Root"],
	"res://game/salary/salary_cycle_overlay.tscn": ["Root/Progress", "Root/Result"],
	"res://game/girls/girl_modal.tscn": ["Root"],
	"res://game/dating/date_venue_picker.tscn": ["Root"],
	"res://game/day/day_advance_overlay.tscn": ["Root/Fade", "Root/DayLabel"],
	"res://world/persistent_ui.tscn": ["GameHUD", "PhoneJournal"],
	"res://presentation/vfx/screen_flash.tscn": ["Flash"],
}

const CONTROLLER_PATHS: Array[String] = [
	"res://ui/frontend/title_menu.gd",
	"res://ui/frontend/pause_menu.gd",
	"res://ui/frontend/settings_panel.gd",
	"res://ui/frontend/save_load_panel.gd",
	"res://ui/hud/game_hud.gd",
	"res://ui/phone/phone_journal.gd",
	"res://ui/progression/progression_ui.gd",
	"res://ui/rivals/rival_encounter_ui.gd",
	"res://ui/dating/dating_ui.gd",
	"res://game/final_date/final_date_ui.gd",
	"res://game/clone_incremental/clone_terminal_ui.gd",
	"res://game/late_game/global_expansion_terminal_ui.gd",
	"res://game/first_clone/clone_calibration_minigame.gd",
	"res://game/media/media_photo_session.gd",
	"res://game/rivals/rival_competition_runner.gd",
	"res://game/salary/salary_station.gd",
	"res://game/girls/girl_actor.gd",
	"res://game/dating/date_venue_interactable.gd",
	"res://game/day/day_advance_interactable.gd",
]

const FORBIDDEN_UI_CONSTRUCTORS: Array[String] = [
	"Control.new(",
	"CanvasLayer.new(",
	"PanelContainer.new(",
	"MarginContainer.new(",
	"VBoxContainer.new(",
	"HBoxContainer.new(",
	"GridContainer.new(",
	"ScrollContainer.new(",
	"Label.new(",
	"Button.new(",
	"ColorRect.new(",
	"ProgressBar.new(",
	"RichTextLabel.new(",
	"ItemList.new(",
]

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_test_scene_contracts()
	_test_compact_dating_contract()
	_test_controller_sources()
	if _failed == 0:
		print("UI_SCENE_CONTRACT: ALL PASS (%d)" % _passed)
	else:
		print("UI_SCENE_CONTRACT: FAIL passed=%d failed=%d" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func _test_scene_contracts() -> void:
	for scene_path: String in SCENE_REQUIREMENTS:
		var packed: PackedScene = load(scene_path) as PackedScene
		_ok(packed != null, "%s loads as PackedScene" % scene_path)
		if packed == null:
			continue
		var instance: Node = packed.instantiate()
		_ok(instance != null, "%s instantiates" % scene_path)
		if instance == null:
			continue
		var required_paths: Array = SCENE_REQUIREMENTS.get(scene_path, []) as Array
		for node_path_value: Variant in required_paths:
			var node_path: NodePath = NodePath(str(node_path_value))
			_ok(instance.get_node_or_null(node_path) != null, "%s has %s" % [scene_path, node_path])
		instance.free()


func _test_compact_dating_contract() -> void:
	var packed: PackedScene = load("res://ui/dating/dating_ui.tscn") as PackedScene
	if packed == null:
		return
	var instance: CanvasLayer = packed.instantiate() as CanvasLayer
	if instance == null:
		return
	var root: Control = instance.get_node_or_null("Root") as Control
	var dim: ColorRect = instance.get_node_or_null("Root/Dim") as ColorRect
	var panel: PanelContainer = instance.get_node_or_null("Root/Panel") as PanelContainer
	var hint: Label = instance.get_node_or_null(
		"Root/Panel/Margin/VBox/InputHint"
	) as Label
	_ok(root != null and root.mouse_filter == Control.MOUSE_FILTER_IGNORE, "dating root preserves camera mouse motion")
	_ok(dim != null and not dim.visible, "dating UI has no fullscreen dim")
	_ok(panel != null and panel.anchor_right <= 0.401, "dating panel leaves screen center clear")
	_ok(panel != null and panel.anchor_bottom - panel.anchor_top <= 0.63, "dating panel stays compact vertically")
	_ok(hint != null and hint.text.contains("1–4") and hint.text.contains("E"), "dating input hint present")
	instance.free()


func _test_controller_sources() -> void:
	for script_path: String in CONTROLLER_PATHS:
		var source: String = FileAccess.get_file_as_string(script_path)
		_ok(not source.is_empty(), "%s source readable" % script_path)
		for constructor: String in FORBIDDEN_UI_CONSTRUCTORS:
			_ok(not source.contains(constructor), "%s avoids %s" % [script_path, constructor])


func _ok(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		return
	_failed += 1
	push_error("[UI_SCENE_CONTRACT] %s" % label)
