class_name CloneIncrementalStatus
extends RefCounted
## Read-only Clone Incremental snapshot (MODULE 18).


var active: bool = false
var total: int = 0
var working: int = 0
var dating: int = 0
var free: int = 0

var production_level: int = 0
var work_level: int = 0
var dating_level: int = 0

var production_interval: float = 0.0
var production_elapsed: float = 0.0
var seconds_to_next_clone: float = 0.0

var money_per_minute: float = 0.0
var dates_per_minute: float = 0.0

var backlog_count: int = 0
