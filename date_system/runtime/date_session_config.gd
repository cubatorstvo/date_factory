class_name DateSessionConfig
extends RefCounted

var seed: int = 0
var girl_id: StringName = &""
var venue_id: StringName = &""
var outfit_id: StringName = &""
var local_object_ids: Array[StringName] = []
var catalog: DateContentCatalog
var girl_progress: GirlProgress
var player_snapshot: DatePlayerSnapshot
var relationship_max: int = 0
