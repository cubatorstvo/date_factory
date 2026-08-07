class_name DiscoverySituationDefinition
extends Resource
## Fixed discovery situation content (MODULE 08). No NPC schedule/AI.

@export var id: StringName = &""
@export var location_id: StringName = &""
@export var setup_text: String = ""
@export var approaches: Array[DiscoveryApproachDefinition] = []
