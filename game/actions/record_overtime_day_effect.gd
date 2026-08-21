class_name RecordOvertimeDayEffect
extends ActionEffect


func apply() -> void:
	var player: PlayerState = _player_state()
	if player == null:
		return
	player.last_overtime_day_index = _current_day_index()


func get_description() -> String:
	return "Подработка засчитана на сегодня"


func _current_day_index() -> int:
	return WorkService.get_calendar_day_index()


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
