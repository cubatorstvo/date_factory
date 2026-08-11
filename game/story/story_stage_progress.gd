class_name StoryStageProgress
extends RefCounted
## Typed read model for the current story stage objective (MODULE 11).


var stage: GameTypes.GameStage = GameTypes.GameStage.PROLOGUE
var display_name: String = ""
var objective_id: StringName = &""
var objective_text: String = ""
var story_girl_id: StringName = &""
var story_rival_id: StringName = &""
var rival_required: bool = false
var rival_defeated: bool = false
var girl_completed: bool = false
var completion_mode: StoryTypes.StageCompletionMode = StoryTypes.StageCompletionMode.GIRL_COMPLETED
var completion_flag_id: StringName = &""
var external_milestone_complete: bool = false
var is_complete: bool = false
