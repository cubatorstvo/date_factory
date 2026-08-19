extends Node

signal money_changed(previous_money: int, current_money: int, delta: int)


func get_money() -> int:
	var player: PlayerState = _player()
	if player == null:
		return 0
	return player.money


func can_afford(amount: int) -> bool:
	if amount <= 0:
		return true
	return get_money() >= amount


func add_money(amount: int) -> void:
	if amount == 0:
		return
	var player: PlayerState = _player()
	if player == null:
		return
	var previous_money: int = player.money
	player.money = previous_money + amount
	money_changed.emit(previous_money, player.money, amount)


func spend_money(amount: int) -> bool:
	if amount <= 0:
		return true
	if not can_afford(amount):
		return false
	var player: PlayerState = _player()
	if player == null:
		return false
	var previous_money: int = player.money
	player.money = previous_money - amount
	money_changed.emit(previous_money, player.money, -amount)
	return true


func _player() -> PlayerState:
	var node: Node = get_node_or_null("/root/GameState")
	if not is_instance_valid(node):
		push_error("GameState autoload missing")
		return null
	var gs: Variant = node
	return gs.player as PlayerState
