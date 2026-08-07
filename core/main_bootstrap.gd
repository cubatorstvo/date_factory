extends Node
## MODULE 00/01 entry bootstrap. Routes into FPS test world for now.

const FPS_TEST_SCENE := "res://world/test/player_fps_test.tscn"


func _ready() -> void:
	call_deferred("_boot")


func _boot() -> void:
	_ensure_slap_competition_host()
	_enter_fps_test()


func _ensure_slap_competition_host() -> void:
	var root: Window = get_tree().root
	if root.get_node_or_null("SlapCompetitionHost") != null:
		return
	var host_script: Script = load("res://minigames/slap/slap_competition_host.gd") as Script
	if host_script == null:
		DfLog.error("MODULE_07A", "Missing SlapCompetitionHost script")
		return
	var host: Node = host_script.new() as Node
	host.name = "SlapCompetitionHost"
	root.add_child(host)
	DfLog.info("MODULE_07A", "SlapCompetitionHost attached to root")


func _enter_fps_test() -> void:
	DfLog.info("MODULE_01", "Boot -> FPS test world")
	var err: Error = get_tree().change_scene_to_file(FPS_TEST_SCENE)
	if err != OK:
		DfLog.error("MODULE_01", "Failed to load FPS test scene: %s" % err)
