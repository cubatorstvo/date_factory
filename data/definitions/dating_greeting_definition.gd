class_name DatingGreetingDefinition
extends Resource
## Static dating greeting option (MODULE 09).

@export var id: StringName = &""
@export var label: String = ""
@export var direct_tags: Array[GameTypes.ActionTag] = []
@export var has_requirement: bool = false
@export var required_characteristic: GameTypes.PlayerCharacteristic = GameTypes.PlayerCharacteristic.MUSCLE
@export var required_level: int = 0
@export var result_text: String = ""
