class_name AnimationProfileDefinition
extends Resource
## Static animation profile — AnimationLibrary resource for character playback (MODULE 04).
## Assign copied .res/.tres libraries via library (and optional seated_library).

@export var id: StringName = &""
@export var library: AnimationLibrary = null
@export var seated_library: AnimationLibrary = null
