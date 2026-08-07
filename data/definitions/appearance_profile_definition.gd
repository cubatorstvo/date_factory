class_name AppearanceProfileDefinition
extends Resource
## Static appearance profile for character visuals (MODULE 04).
## visual_scene may be null until scene worker provides PackedScenes.

@export var id: StringName = &""
@export var body_type: GameTypes.CharacterBodyType = GameTypes.CharacterBodyType.FEMALE
@export var visual_scene: PackedScene = null
@export var visual_scale: float = 1.0
@export var vertical_offset: float = 0.0
@export var animation_profile_id: StringName = &""
