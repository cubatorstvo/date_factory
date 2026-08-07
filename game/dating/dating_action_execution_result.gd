class_name DatingActionExecutionResult
extends RefCounted
## External / direct action execution outcome (MODULE 09).

var outcome: DatingTypes.ExecutionOutcome = DatingTypes.ExecutionOutcome.SUCCESS
var has_tag_override: bool = false
var tags: Array[GameTypes.ActionTag] = []
var was_public: bool = false
var result_text: String = ""
