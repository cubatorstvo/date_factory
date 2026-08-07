class_name PerkIds
extends RefCounted
## Canonical StringName constants for all 32 production perk IDs (MODULE 05).
## Values must match ContentDB / PerkDefinition.id exactly.


const MUSCLE_NO_WARMUP: StringName = &"perk_muscle_no_warmup"
const MUSCLE_TOUGH_CHEEK: StringName = &"perk_muscle_tough_cheek"
const MUSCLE_DOUBLE_SLAP: StringName = &"perk_muscle_double_slap"
const MUSCLE_COUNTER_ARGUMENT: StringName = &"perk_muscle_counter_argument"
const MUSCLE_HOLD_DOORWAY: StringName = &"perk_muscle_hold_doorway"
const MUSCLE_HEROIC_DEFEAT: StringName = &"perk_muscle_heroic_defeat"
const MUSCLE_MASS_RESERVE: StringName = &"perk_muscle_mass_reserve"
const MUSCLE_TWO_HANDED_ARGUMENT: StringName = &"perk_muscle_two_handed_argument"

const APPEARANCE_GOOD_PROFILE: StringName = &"perk_appearance_good_profile"
const APPEARANCE_STAGED_WALK: StringName = &"perk_appearance_staged_walk"
const APPEARANCE_POCKET_MIRROR: StringName = &"perk_appearance_pocket_mirror"
const APPEARANCE_CONTROL_PROFILE: StringName = &"perk_appearance_control_profile"
const APPEARANCE_SECOND_OUTFIT: StringName = &"perk_appearance_second_outfit"
const APPEARANCE_ENCORE: StringName = &"perk_appearance_encore"
const APPEARANCE_RHYTHM_IN_BODY: StringName = &"perk_appearance_rhythm_in_body"
const APPEARANCE_PUBLIC_SIGNIFICANCE: StringName = &"perk_appearance_public_significance"

const CAPITAL_PAYABLE_INTENT: StringName = &"perk_capital_payable_intent"
const CAPITAL_REPRESENTATION_EXPENSES: StringName = &"perk_capital_representation_expenses"
const CAPITAL_BUY_PROBLEM: StringName = &"perk_capital_buy_problem"
const CAPITAL_HOSTILE_ACQUISITION: StringName = &"perk_capital_hostile_acquisition"
const CAPITAL_SALARY_ADVANCE: StringName = &"perk_capital_salary_advance"
const CAPITAL_DIGNITY_REFUND: StringName = &"perk_capital_dignity_refund"
const CAPITAL_FINANCIAL_INERTIA: StringName = &"perk_capital_financial_inertia"
const CAPITAL_NO_LIMIT: StringName = &"perk_capital_no_limit"

const AURA_PRESENCE_REGISTERED: StringName = &"perk_aura_presence_registered"
const AURA_DONT_BLINK_FIRST: StringName = &"perk_aura_dont_blink_first"
const AURA_SILENCE_LONGER: StringName = &"perk_aura_silence_longer"
const AURA_REVERSE_PRESSURE: StringName = &"perk_aura_reverse_pressure"
const AURA_RIGHT_TO_SAY_NOTHING: StringName = &"perk_aura_right_to_say_nothing"
const AURA_SHE_ALREADY_STARTED: StringName = &"perk_aura_she_already_started"
const AURA_ATMOSPHERIC_INFLUENCE: StringName = &"perk_aura_atmospheric_influence"
const AURA_LOCAL_SIGNIFICANCE: StringName = &"perk_aura_local_significance"


## All 32 constants for validators / self-tests.
static func all_ids() -> Array[StringName]:
	var out: Array[StringName] = [
		MUSCLE_NO_WARMUP,
		MUSCLE_TOUGH_CHEEK,
		MUSCLE_DOUBLE_SLAP,
		MUSCLE_COUNTER_ARGUMENT,
		MUSCLE_HOLD_DOORWAY,
		MUSCLE_HEROIC_DEFEAT,
		MUSCLE_MASS_RESERVE,
		MUSCLE_TWO_HANDED_ARGUMENT,
		APPEARANCE_GOOD_PROFILE,
		APPEARANCE_STAGED_WALK,
		APPEARANCE_POCKET_MIRROR,
		APPEARANCE_CONTROL_PROFILE,
		APPEARANCE_SECOND_OUTFIT,
		APPEARANCE_ENCORE,
		APPEARANCE_RHYTHM_IN_BODY,
		APPEARANCE_PUBLIC_SIGNIFICANCE,
		CAPITAL_PAYABLE_INTENT,
		CAPITAL_REPRESENTATION_EXPENSES,
		CAPITAL_BUY_PROBLEM,
		CAPITAL_HOSTILE_ACQUISITION,
		CAPITAL_SALARY_ADVANCE,
		CAPITAL_DIGNITY_REFUND,
		CAPITAL_FINANCIAL_INERTIA,
		CAPITAL_NO_LIMIT,
		AURA_PRESENCE_REGISTERED,
		AURA_DONT_BLINK_FIRST,
		AURA_SILENCE_LONGER,
		AURA_REVERSE_PRESSURE,
		AURA_RIGHT_TO_SAY_NOTHING,
		AURA_SHE_ALREADY_STARTED,
		AURA_ATMOSPHERIC_INFLUENCE,
		AURA_LOCAL_SIGNIFICANCE,
	]
	return out
