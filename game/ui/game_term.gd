class_name GameTerm
extends Resource

enum Category {
	TAG,
	STAT,
	LOCAL_OBJECT,
	SYSTEM,
}

enum Visual {
	ACCENT,
	TAG,
}

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var aliases: PackedStringArray = PackedStringArray()
@export var category: Category = Category.SYSTEM
@export var visual: Visual = Visual.ACCENT
