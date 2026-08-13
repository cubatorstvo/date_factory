class_name DatingResult
extends RefCounted
## Immutable-ish finish payload for one date (MODULE 09).
## Does not mutate GameState relationship.
## date_id assigned by DatingCore for MODULE 10 exactly-once apply.

var date_id: int = 0
var girl_id: StringName = &""
var location_id: StringName = &""
var tutorial_mode: bool = false
var greeting_id: StringName = &""
var greeting_reaction: int = 0
var central_event_ids: Array[StringName] = []
var decision_records: Array[DatingDecisionRecord] = []
var primary_total: int = 0
var secondary_reaction: int = 0
var trait_delta: int = 0
var venue_quality_bonus: int = 0
var leisure_preference_bonus: int = 0
var apartment_prep_penalty: int = 0
var outfit_bonus: int = 0
var date_delta: int = 0
var money_spent_total: int = 0
var used_right_to_say_nothing: bool = false
var used_second_outfit: bool = false
