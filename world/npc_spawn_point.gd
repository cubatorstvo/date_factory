class_name NpcSpawnPoint
extends Marker3D
## Named NPC placement marker. Does not auto-spawn actors (MODULE 12).

enum NpcKind {
	GENERIC = 0,
	GIRL = 1,
	RIVAL = 2,
}

@export var spawn_id: StringName = &""
@export var npc_kind: NpcKind = NpcKind.GENERIC


func _enter_tree() -> void:
	if String(spawn_id) == "":
		spawn_id = content_id_from_npc_name(name)


func bound_content_id() -> StringName:
	if String(spawn_id) != "":
		return spawn_id
	return content_id_from_npc_name(name)


static func content_id_from_npc_name(node_name: String) -> StringName:
	if node_name.begins_with("npc_"):
		return StringName(node_name.substr(4))
	return &""
