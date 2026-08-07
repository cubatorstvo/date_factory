class_name PrimaryTraitDefinition
extends Resource
## Static primary girl trait definition (MODULE 03).
## Field `primary_trait` is the canonical trait identity (spec: trait).

@export var primary_trait: GameTypes.PrimaryGirlTrait = GameTypes.PrimaryGirlTrait.KIND
@export var display_name: String = ""
@export var liked_tags: Array[GameTypes.ActionTag] = []
@export var disliked_tags: Array[GameTypes.ActionTag] = []
@export var description: String = ""
