class_name SalaryStatus
extends RefCounted
## Read-only salary snapshot for Phone / UI (MODULE 13).


var unlocked: bool = false
var authority: int = 0
var salary_level: int = 1
var gross_per_period: int = 10
var period_index: int = 0
var pending_salary: int = 0
var manual_cycle_seen: bool = false
var passive_enabled: bool = false
var passive_per_period: int = 0
var salary_advance_owned: bool = false
var salary_advance_available: bool = false
var salary_advance_used_this_period: bool = false
