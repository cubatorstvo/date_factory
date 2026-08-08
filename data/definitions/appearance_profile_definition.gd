class_name AppearanceProfileDefinition
extends Resource
## Static appearance profile for character visuals (MODULE 04).
## visual_scene may be null until scene worker provides PackedScenes.
## Modular variant fields are optional presentation overrides (safe defaults).

@export var id: StringName = &""
@export var body_type: GameTypes.CharacterBodyType = GameTypes.CharacterBodyType.FEMALE
@export var visual_scene: PackedScene = null
@export var visual_scale: float = 1.0
@export var vertical_offset: float = 0.0
@export var animation_profile_id: StringName = &""

@export_group("Modular Variants")
@export var hair_variant: StringName = &"01"
@export var hair_color: StringName = &"brown"
@export var top_variant: StringName = &"01"
@export var top_color: StringName = &"gray"
@export var bottom_variant: StringName = &"01"
@export var bottom_color: StringName = &"navy"
@export var shoes_variant: StringName = &"01"
@export var head_accessory: StringName = &"none"
@export var neck_accessory: StringName = &"none"
@export var hand_accessory: StringName = &"none"
