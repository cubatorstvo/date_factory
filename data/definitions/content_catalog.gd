class_name ContentCatalog
extends Resource
## Explicit production (or test) content catalog — no filesystem scan (MODULE 03 / 09).

@export var primary_traits: Array[PrimaryTraitDefinition] = []
@export var secondary_traits: Array[SecondaryTraitDefinition] = []
@export var girls: Array[GirlDefinition] = []
@export var rivals: Array[RivalDefinition] = []
@export var competitions: Array[CompetitionDefinition] = []
@export var dating_events: Array[DatingEventDefinition] = []
@export var dating_pools: Array[DatingEventPoolDefinition] = []
@export var dating_greetings: Array[DatingGreetingDefinition] = []
@export var dating_farewells: Array[DatingFarewellDefinition] = []
@export var perks: Array[PerkDefinition] = []
@export var locations: Array[LocationDefinition] = []
@export var stages: Array[StoryStageDefinition] = []
@export var appearance_profiles: Array[AppearanceProfileDefinition] = []
@export var animation_profiles: Array[AnimationProfileDefinition] = []
@export var discovery_situations: Array[DiscoverySituationDefinition] = []
