class_name RecordWorkDayEffect
extends ActionEffect


func apply() -> void:
	var player: PlayerState = _player_state()
	if player == null:
		return
	player.last_work_day_index = _current_day_index()


func get_description() -> String:
	return "Работа засчитана на сегодня"


func _current_day_index() -> int:
	var minutes: int = 0
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		var clock: Node = tree.root.get_node_or_null("TimeService")
		if is_instance_valid(clock):
			minutes = int(clock.get_game_time_minutes())
		else:
			var gs: Variant = _game_state()
			if gs != null and gs.flow != null:
				minutes = int(gs.flow.game_time_minutes)
	return int(minutes / 1440)


func _player_state() -> PlayerState:
	var gs: Variant = _game_state()
	if gs == null:
		return null
	return gs.player as PlayerState


func _game_state() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("GameState")
	if not is_instance_valid(node):
		return null
	return node
