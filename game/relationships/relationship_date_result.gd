class_name RelationshipDateResult
extends RefCounted
## Typed outcome of applying one DatingResult (MODULE 10).

var ok: bool = false
var error: StringName = &""

var girl_id: StringName = &""
var date_delta: int = 0
var relationship_before: int = 0
var relationship_after: int = 0
var applied_delta: int = 0

var newly_conquered: bool = false
var experience_gained: int = 0
var upgrade_points_gained: int = 0

var repeat_cooldown_days: int = 0
var played_event_ids: Array[StringName] = []
