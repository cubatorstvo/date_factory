class_name DatingDecisionRecord
extends RefCounted
## One evaluated central/farewell decision (MODULE 09).

var source_id: StringName = &""
var event_id: StringName = &""
var characteristic: GameTypes.PlayerCharacteristic = GameTypes.PlayerCharacteristic.MUSCLE
var final_tags: Array[GameTypes.ActionTag] = []
var primary_reaction: int = 0
var execution_outcome: DatingTypes.ExecutionOutcome = DatingTypes.ExecutionOutcome.SUCCESS
var was_public: bool = false
var money_cost: int = 0
var money_spent: int = 0
var used_public_significance: bool = false
var used_encore: bool = false
var money_paid_then_refunded: bool = false
