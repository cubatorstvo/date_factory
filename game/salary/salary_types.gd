class_name SalaryTypes
extends RefCounted
## Shared salary enums for SalaryMine (MODULE 13).


enum ClaimMethod {
	MANUAL_MINE = 0,
	SALARY_ADVANCE = 1,
}


enum ClaimError {
	OK = 0,
	LOCKED = 1,
	NO_PENDING = 2,
	PERK_REQUIRED = 3,
	ADVANCE_ALREADY_USED = 4,
	BUSY = 5,
}
