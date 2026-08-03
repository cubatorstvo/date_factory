extends ColorRect
## Shared fill for dim/bg/glow. Change colors only in UiStyle.

@export var fill_role: StringName = &"dim"


func _ready() -> void:
	color = UiStyle.fill_color(fill_role)
