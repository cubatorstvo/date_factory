class_name CloneUpgradePurchaseResult
extends RefCounted
## Typed outcome of CloneIncremental.buy_upgrade (MODULE 18).


var ok: bool = false
var error: CloneIncrementalTypes.UpgradePurchaseError = CloneIncrementalTypes.UpgradePurchaseError.OK
var upgrade_type: CloneIncrementalTypes.UpgradeType = CloneIncrementalTypes.UpgradeType.PRODUCTION_SPEED
var new_level: int = 0
var money_spent: int = 0
var money_after: int = 0
