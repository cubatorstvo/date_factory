class_name PerkDefinition
extends Resource
## Static perk identity in the characteristic tree (MODULE 03).
## Effects/prices/prerequisites belong to MODULE 05.

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var characteristic: GameTypes.PlayerCharacteristic = GameTypes.PlayerCharacteristic.MUSCLE
@export var section: GameTypes.PerkSection = GameTypes.PerkSection.EARLY_COMMON
@export var order_in_section: int = 1
@export var branch_label: String = ""
