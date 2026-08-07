class_name RivalDefinition
extends Resource
## Static rival (male competitor) content definition (MODULE 03).

@export var id: StringName = &""
@export var display_name: String = ""
@export var is_story: bool = false
@export var has_story_stage: bool = false
@export var story_stage: GameTypes.GameStage = GameTypes.GameStage.PROLOGUE
@export var required_authority: int = 0
@export var authority_reward: int = 0
@export var muscle: int = 0
@export var appearance: int = 0
@export var capital: int = 0
@export var aura: int = 0
@export var preferred_competition: GameTypes.CompetitionType = GameTypes.CompetitionType.SLAP
@export var allowed_competitions: Array[GameTypes.CompetitionType] = []
@export var appearance_profile_id: StringName = &""
@export var competition_modifier_id: StringName = &""
