class_name StoryStageDefinition
extends Resource
## Static story stage record with reserved girl/rival IDs and completion rules (MODULE 03/11).

@export var stage: GameTypes.GameStage = GameTypes.GameStage.PROLOGUE
@export var display_name: String = ""
@export var story_girl_id: StringName = &""
@export var story_rival_id: StringName = &""
@export var requires_story_rival: bool = false
@export var completion_mode: StoryTypes.StageCompletionMode = StoryTypes.StageCompletionMode.GIRL_COMPLETED
@export var next_stage: GameTypes.GameStage = GameTypes.GameStage.PROLOGUE
@export var notes: String = ""
