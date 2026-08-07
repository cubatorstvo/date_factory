class_name DatingActionDefinition
extends Resource
## Static dating action variant inside an event (MODULE 03).

@export var id: StringName = &""
@export var label: String = ""
@export var characteristic: GameTypes.PlayerCharacteristic = GameTypes.PlayerCharacteristic.MUSCLE
@export var required_characteristic_level: int = 0
@export var money_cost: int = 0
@export var resolver_id: StringName = &"direct"
@export var direct_tags: Array[GameTypes.ActionTag] = []
