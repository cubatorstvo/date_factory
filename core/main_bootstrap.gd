extends Node
## MODULE 00/01 entry bootstrap. Routes into FPS test world for now.

const FPS_TEST_SCENE := "res://world/test/player_fps_test.tscn"


func _ready() -> void:
	call_deferred("_boot")


func _boot() -> void:
	_enter_fps_test()


func _enter_fps_test() -> void:
	DfLog.info("MODULE_01", "Boot -> FPS test world")
	var err: Error = get_tree().change_scene_to_file(FPS_TEST_SCENE)
	if err != OK:
		DfLog.error("MODULE_01", "Failed to load FPS test scene: %s" % err)
