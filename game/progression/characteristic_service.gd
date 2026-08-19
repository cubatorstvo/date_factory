extends Node

signal characteristic_changed(
	characteristic_id: StringName,
	previous_value: int,
	current_value: int,
	delta: int
)

var _catalog: CharacteristicCatalog


func _ready() -> void:
	_catalog = CharacteristicCatalog.create_seed()


func get_catalog() -> CharacteristicCatalog:
	if _catalog == null:
		_catalog = CharacteristicCatalog.create_seed()
	return _catalog


func get_value(characteristic_id: StringName) -> int:
	var player: PlayerState = _player()
	if player == null:
		return 0
	match characteristic_id:
		CharacteristicIds.MUSCLE:
			return player.muscle
		CharacteristicIds.APPEARANCE:
			return player.appearance
		CharacteristicIds.CAPITAL:
			return player.capital
		CharacteristicIds.AURA:
			return player.aura
		_:
			return 0


func add_value(characteristic_id: StringName, amount: int) -> int:
	var player: PlayerState = _player()
	if player == null:
		return 0
	if not CharacteristicIds.is_known(characteristic_id):
		return 0
	var previous_value: int = get_value(characteristic_id)
	var current_value: int = previous_value + amount
	match characteristic_id:
		CharacteristicIds.MUSCLE:
			player.muscle = current_value
		CharacteristicIds.APPEARANCE:
			player.appearance = current_value
		CharacteristicIds.CAPITAL:
			player.capital = current_value
		CharacteristicIds.AURA:
			player.aura = current_value
	characteristic_changed.emit(characteristic_id, previous_value, current_value, amount)
	return current_value


func create_upgrade_action(upgrade_id: StringName) -> GameAction:
	var purchases: Variant = _purchase_service()
	var upgrade: CharacteristicUpgradeDefinition = get_catalog().get_upgrade(upgrade_id)
	if purchases == null or upgrade == null:
		return GameAction.new()
	return purchases.create_purchase_action(upgrade)


func _player() -> PlayerState:
	var gs: Variant = _game_state()
	if gs == null:
		return null
	return gs.player as PlayerState


func _game_state() -> Variant:
	var node: Node = get_node_or_null("/root/GameState")
	if not is_instance_valid(node):
		push_error("GameState autoload missing")
		return null
	return node


func _purchase_service() -> Variant:
	var node: Node = get_node_or_null("/root/PurchaseService")
	if not is_instance_valid(node):
		push_error("PurchaseService autoload missing")
		return null
	return node
