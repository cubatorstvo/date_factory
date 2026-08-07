class_name ContentCatalog
extends Resource
## Explicit production (or test) content catalog — no filesystem scan (MODULE 03).

@export var primary_traits: Array[PrimaryTraitDefinition] = []
@export var secondary_traits: Array[SecondaryTraitDefinition] = []
@export var girls: Array[GirlDefinition] = []
@export var rivals: Array[RivalDefinition] = []
@export var competitions: Array[CompetitionDefinition] = []
@export var dating_events: Array[DatingEventDefinition] = []
@export var dating_pools: Array[DatingEventPoolDefinition] = []
@export var perks: Array[PerkDefinition] = []
@export var locations: Array[LocationDefinition] = []
@export var stages: Array[StoryStageDefinition] = []
