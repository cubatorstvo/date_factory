class_name DatingOverloadStatus
extends RefCounted
## Phone/UI snapshot of DatingOverload state (MODULE 16).

var active: bool = false
var problem_recognized: bool = false

var current_day: int = 1
var capacity_per_day: int = DatingOverloadTypes.PERSONAL_DATE_CAPACITY_PER_DAY
var capacity_used_today: int = 0

var total_generated: int = 0
var fulfilled_count: int = 0
var backlog_count: int = 0
var overdue_count: int = 0

var feed_boost_available: bool = false
var boost_pending: bool = false
