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
