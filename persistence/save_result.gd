class_name SaveResult
extends RefCounted
## Typed result for SaveSystem slot I/O (MODULE 24).


var ok: bool = false
var error: SaveTypes.ErrorCode = SaveTypes.ErrorCode.OK
var slot: SaveTypes.Slot = SaveTypes.Slot.AUTOSAVE
var message: String = ""
var recovered_from_backup: bool = false


static func success(slot: SaveTypes.Slot, message: String = "", recovered: bool = false) -> SaveResult:
	var r := SaveResult.new()
	r.ok = true
	r.error = SaveTypes.ErrorCode.OK
	r.slot = slot
	r.message = message
	r.recovered_from_backup = recovered
	return r


static func fail(
	slot: SaveTypes.Slot,
	error: SaveTypes.ErrorCode,
	message: String = "",
	recovered: bool = false,
) -> SaveResult:
	var r := SaveResult.new()
	r.ok = false
	r.error = error
	r.slot = slot
	r.message = message
	r.recovered_from_backup = recovered
	return r
