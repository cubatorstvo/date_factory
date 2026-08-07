class_name CompetitionDefinition
extends Resource
## Static male competition type definition (MODULE 03).
## Field `competition_type` is the canonical identity (spec: type).

@export var competition_type: GameTypes.CompetitionType = GameTypes.CompetitionType.SLAP
@export var display_name: String = ""
@export var characteristic: GameTypes.PlayerCharacteristic = GameTypes.PlayerCharacteristic.MUSCLE
@export var expected_duration_min_seconds: int = 20
@export var expected_duration_max_seconds: int = 60
