class_name GlobalUpgradePurchaseResult
extends RefCounted
## Typed outcome of LateGameExpansion.buy_global_upgrade (MODULE 20).


var ok: bool = false
var error: LateGameTypes.GlobalUpgradePurchaseError = LateGameTypes.GlobalUpgradePurchaseError.OK
var upgrade_type: LateGameTypes.GlobalUpgradeType = LateGameTypes.GlobalUpgradeType.GLOBAL_PRODUCTION
var new_level: int = 0
var money_spent: int = 0
var money_after: int = 0
