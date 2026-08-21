class_name ObjectiveView
extends RefCounted

const TARGET_GIRL: StringName = &"girl"
const TARGET_RIVAL: StringName = &"rival"
const TARGET_LOCATION: StringName = &"location"
const TARGET_DATING: StringName = &"dating"
const TARGET_FACTORY: StringName = &"factory"
const MARKER_SUFFIX: String = "  ← ЦЕЛЬ"

var stage: int = 0
var title: String = ""
var description: String = ""
var progress_text: String = ""
var subgoals: Array[ObjectiveSubgoalView] = []
var next_step_text: String = ""
var target_type: StringName = &""
var target_id: StringName = &""
var target_location_id: StringName = &""
var completed: bool = false


func current_subgoal() -> ObjectiveSubgoalView:
	for subgoal in subgoals:
		if subgoal.is_current:
			return subgoal
	return null
