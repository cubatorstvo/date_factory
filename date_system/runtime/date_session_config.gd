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
var venue_source_limit: int = 1
var vika_reroll_available: bool = false
var dasha_soften_available: bool = false
var nika_swap_available: bool = false
var backup_outfit_id: StringName = &""
var express_styling_bonus: int = 0
var forced_situation_id: StringName = &""
