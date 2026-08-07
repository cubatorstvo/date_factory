class_name DiscoveryApproachDefinition
extends Resource
## Authored acquaintance approach inside a discovery situation (MODULE 08).

enum DiscoveryApproachOutcome {
	SUCCESS,
	FAILURE,
}

@export var id: StringName = &""
@export var label: String = ""
@export var has_requirement: bool = false
@export var required_characteristic: GameTypes.PlayerCharacteristic = GameTypes.PlayerCharacteristic.MUSCLE
@export var required_level: int = 0
@export var outcome: DiscoveryApproachOutcome = DiscoveryApproachOutcome.SUCCESS
@export var result_text: String = ""
