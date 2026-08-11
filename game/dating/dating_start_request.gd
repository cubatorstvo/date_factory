class_name DatingStartRequest
extends RefCounted
## Explicit start payload for one date (MODULE 09).

var girl_id: StringName = &""
var location_id: StringName = &""
var greeting_ids: Array[StringName] = []
var farewell_id: StringName = &""
var excluded_event_ids: Array[StringName] = []
var forced_event_ids: Array[StringName] = []
var tutorial_mode: bool = false
var rng_seed: int = -1
