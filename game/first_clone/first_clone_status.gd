class_name FirstCloneStatus
extends RefCounted
## Phone/UI snapshot of FirstClone state (MODULE 17).

var eligible: bool = false
var sequence_active: bool = false
var clone_created: bool = false
var assignment: FirstCloneTypes.Assignment = FirstCloneTypes.Assignment.NONE
var availability: FirstCloneTypes.MachineAvailability = FirstCloneTypes.MachineAvailability.NOT_IN_LAB
