class_name SalaryClaimResult
extends RefCounted
## Typed outcome of a salary claim (MODULE 13).


var ok: bool = false
var error: SalaryTypes.ClaimError = SalaryTypes.ClaimError.OK
var method: SalaryTypes.ClaimMethod = SalaryTypes.ClaimMethod.MANUAL_MINE
var amount: int = 0
var pending_after: int = 0
var money_after: int = 0
var period_index: int = 0
var manual_cycle_first_time: bool = false
