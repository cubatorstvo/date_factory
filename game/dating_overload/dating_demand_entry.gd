class_name DatingDemandEntry
extends RefCounted
## One media-originated dating demand request (MODULE 16).

var request_id: int = 0
var girl_id: StringName = &""
var created_day: int = 0
var appointment_day: int = 0
var slot: DatingOverloadTypes.DatingDemandSlot = DatingOverloadTypes.DatingDemandSlot.EARLY_EVENING
var status: DatingOverloadTypes.DatingDemandStatus = DatingOverloadTypes.DatingDemandStatus.WAITING
var fulfilled_day: int = -1


func duplicate_entry() -> DatingDemandEntry:
	var copy: DatingDemandEntry = DatingDemandEntry.new()
	copy.request_id = request_id
	copy.girl_id = girl_id
	copy.created_day = created_day
	copy.appointment_day = appointment_day
	copy.slot = slot
	copy.status = status
	copy.fulfilled_day = fulfilled_day
	return copy


func is_backlog() -> bool:
	return (
		status == DatingOverloadTypes.DatingDemandStatus.WAITING
		or status == DatingOverloadTypes.DatingDemandStatus.OVERDUE
	)
