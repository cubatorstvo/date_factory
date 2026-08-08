class_name SaveSlotMetadata
extends RefCounted
## Lightweight slot summary without loading gameplay (MODULE 24).


var slot: SaveTypes.Slot = SaveTypes.Slot.AUTOSAVE
var exists: bool = false
var valid: bool = false
var schema_version: int = 0
var saved_at_unix: int = 0
var stage: int = 0
var game_day: int = 0
var location_id: String = ""
var money: int = 0
var authority: int = 0
var experience: int = 0
var total_clones: int = 0
var world_reach: int = 0
var final_completed: bool = false
var recovered_from_backup: bool = false
var error: SaveTypes.ErrorCode = SaveTypes.ErrorCode.OK
var message: String = ""


static func empty(slot: SaveTypes.Slot) -> SaveSlotMetadata:
	var m := SaveSlotMetadata.new()
	m.slot = slot
	return m
