class_name GirlDefinition
extends Resource
## Static girl content definition (MODULE 03).

@export var id: StringName = &""
@export var display_name: String = ""
@export var romance_available: bool = true
@export var is_story: bool = false
@export var has_story_stage: bool = false
@export var story_stage: GameTypes.GameStage = GameTypes.GameStage.PROLOGUE
@export var primary_trait: GameTypes.PrimaryGirlTrait = GameTypes.PrimaryGirlTrait.KIND
@export var secondary_trait: GameTypes.SecondaryGirlTrait = GameTypes.SecondaryGirlTrait.CONSISTENT
@export var required_experience: int = 0
@export var discovery_situation_id: StringName = &""
@export var appearance_profile_id: StringName = &""
@export var dating_pool_ids: Array[StringName] = []
@export var default_date_location_id: StringName = &""
@export var dating_greeting_ids: Array[StringName] = []
@export var dating_farewell_id: StringName = &""
@export var speech_style_note: String = ""
@export var clue_notes: Array[String] = []
