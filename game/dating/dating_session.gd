class_name DatingSession
extends RefCounted
## Transient one-date session state — not saved (MODULE 09).

var date_id: int = 0
var girl_id: StringName = &""
var location_id: StringName = &""
var tutorial_mode: bool = false
var phase: DatingTypes.Phase = DatingTypes.Phase.ARRIVAL

var greeting_ids: Array[StringName] = []
var selected_greeting_id: StringName = &""
var greeting_reaction: int = 0

var central_event_ids: Array[StringName] = []
var central_categories: Array = []
var current_event_index: int = 0

var farewell_id: StringName = &""

var decision_records: Array[DatingDecisionRecord] = []

var secondary_reaction: int = 0
var primary_total: int = 0
var date_delta: int = 0
var money_spent_total: int = 0

var used_right_to_say_nothing: bool = false
var used_second_outfit: bool = false
var apartment_was_prepared: bool = false
var used_public_significance: bool = false
var used_representation_expenses: bool = false
var used_encore: bool = false
var first_evaluated_started: bool = false
var finished: bool = false
var date_finished_emitted: bool = false

## Pending action commit state (RESOLVING / ENCORE).
var pending_action: DatingActionDefinition = null
var pending_event_id: StringName = &""
var pending_execution: DatingActionExecutionResult = null
var pending_tags: Array[GameTypes.ActionTag] = []
var pending_was_public: bool = false
var pending_primary: int = 0
var pending_money_cost: int = 0
var pending_money_spent: int = 0
var pending_used_public_significance: bool = false
var pending_money_refunded: bool = false
var pending_result_text: String = ""
var pending_execution_request: DatingActionExecutionRequest = null

var last_result_text: String = ""
var last_primary_reaction: int = 0
var result: DatingResult = null
