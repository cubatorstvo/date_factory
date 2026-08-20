class_name CompetitionDefinition
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var rival_id: StringName = &""
@export var time_cost_minutes: int = 60
@export var base_win_chance: float = 0.5
@export var primary_characteristic_id: StringName = CharacteristicIds.MUSCLE
@export var entry_fee: int = 100
