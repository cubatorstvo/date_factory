class_name DatingEventDefinition
extends Resource
## Static central dating event definition (MODULE 03).

@export var id: StringName = &""
@export var category: GameTypes.DatingEventCategory = GameTypes.DatingEventCategory.CONVERSATION
@export var title: String = ""
@export var setup_text: String = ""
@export var actions: Array[DatingActionDefinition] = []
@export var allowed_location_ids: Array[StringName] = []
