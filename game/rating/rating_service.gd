extends Node

signal rating_changed(previous_rating: int, current_rating: int, delta: int)


func get_rating() -> int:
	var player: PlayerState = _player()
	if player == null:
		return 0
	return player.rating


func add_rating(amount: int = 1) -> int:
	var player: PlayerState = _player()
	if player == null:
		return 0
	if amount <= 0:
		return player.rating
	var previous_rating: int = player.rating
	player.rating = previous_rating + amount
	rating_changed.emit(previous_rating, player.rating, amount)
	return player.rating


func _player() -> PlayerState:
	var node: Node = get_node_or_null("/root/GameState")
	if not is_instance_valid(node):
		push_error("GameState autoload missing")
		return null
	var gs: Variant = node
	return gs.player as PlayerState
