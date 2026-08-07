# Perk Effect Contracts (MODULE 05)

Ownership and purchase live in Progression / GameState.  
**Effects are NOT implemented in MODULE 05.** Future modules check `GameState.has_perk(PerkIds.*)` and apply the contract below.

Source: `docs/modules/MODULE_05_PROGRESSION_PERKS.md` §§35–75.

---

## Muscle

| PerkId | ID | Contract (summary) | Future owners |
|---|---|---|---|
| `MUSCLE_NO_WARMUP` | `perk_muscle_no_warmup` | Unlocks muscle actions by level; first strength activity of a scene gets a wider start timing window | Dating/World availability; strength minigame |
| `MUSCLE_TOUGH_CHEEK` | `perk_muscle_tough_cheek` | Once per slap match, a missed opponent hit does not fully wipe the current streak | MODULE 07A Slap |
| `MUSCLE_DOUBLE_SLAP` | `perk_muscle_double_slap` | Once per slap match: special attack; perfect = 2 points; fail makes next defense harder | MODULE 07A |
| `MUSCLE_COUNTER_ARGUMENT` | `perk_muscle_counter_argument` | Perfect block arms bonus; next perfect attack gets +1 point (not carried forever) | MODULE 07A |
| `MUSCLE_HOLD_DOORWAY` | `perk_muscle_hold_doorway` | Unlocks authored hold-doorway / position actions only | Dating content; world scripted interactions |
| `MUSCLE_HEROIC_DEFEAT` | `perk_muscle_heroic_defeat` | Softens authority punishment vs clearly stronger rival; dating defeat may add VULNERABILITY + RISK | MODULE 06 Rival; MODULE 09 Dating |
| `MUSCLE_MASS_RESERVE` | `perk_muscle_mass_reserve` | Once per strength minigame: one extra mistake or round (form TBD) | Strength minigame owner |
| `MUSCLE_TWO_HANDED_ARGUMENT` | `perk_muscle_two_handed_argument` | Once per major strength contest: high-risk decisive move | MODULE 07A / major strength activities |

---

## Appearance

| PerkId | ID | Contract (summary) | Future owners |
|---|---|---|---|
| `APPEARANCE_GOOD_PROFILE` | `perk_appearance_good_profile` | Unlocks appearance actions by level; girl entrance clue detail more readable | MODULE 08 Discovery; MODULE 09 |
| `APPEARANCE_STAGED_WALK` | `perk_appearance_staged_walk` | First dance/model mistake does not fully wipe streak | MODULE 07B Dance |
| `APPEARANCE_POCKET_MIRROR` | `perk_appearance_pocket_mirror` | Once per sigma contest: short stable/clearer hold zone | MODULE 07C Sigma |
| `APPEARANCE_CONTROL_PROFILE` | `perk_appearance_control_profile` | Only during pocket mirror; perfect sigma section grants extra point | MODULE 07C |
| `APPEARANCE_SECOND_OUTFIT` | `perk_appearance_second_outfit` | Once per date, after girl arrives, before first scored event: swap prepared accessory set | MODULE 09; character presentation |
| `APPEARANCE_ENCORE` | `perk_appearance_encore` | Once per date after neutral (0) appearance action: extra visual action; success may replace one tag with ORIGINALITY | MODULE 09 |
| `APPEARANCE_RHYTHM_IN_BODY` | `perk_appearance_rhythm_in_body` | Dance rhythm windows slightly wider; first hard combo gets a visual clue | MODULE 07B |
| `APPEARANCE_PUBLIC_SIGNIFICANCE` | `perk_appearance_public_significance` | Once per date: choose appearance option requiring appearance+1; activity still must be played | MODULE 09 |

---

## Capital

| PerkId | ID | Contract (summary) | Future owners |
|---|---|---|---|
| `CAPITAL_PAYABLE_INTENT` | `perk_capital_payable_intent` | Unlocks capital actions by level; unlocks money contests | MODULE 06; 07D Money; 09 |
| `CAPITAL_REPRESENTATION_EXPENSES` | `perk_capital_representation_expenses` | First normal paid date action does not spend money (still counts as paid) | MODULE 09 |
| `CAPITAL_BUY_PROBLEM` | `perk_capital_buy_problem` | Once per date: authored purchase of an obstacle (event must allow it) | MODULE 09 + authored event |
| `CAPITAL_HOSTILE_ACQUISITION` | `perk_capital_hostile_acquisition` | After marked money victory, a small object may stay owned / open a shortcut (world fact elsewhere) | MODULE 07D; 11/12 Story/World |
| `CAPITAL_SALARY_ADVANCE` | `perk_capital_salary_advance` | Once per salary period: take nearest available payout without going to payout place | MODULE 13 Salary Mine |
| `CAPITAL_DIGNITY_REFUND` | `perk_capital_dignity_refund` | Failed paid action refunds money; failure/tags remain | MODULE 09 paid resolver |
| `CAPITAL_FINANCIAL_INERTIA` | `perk_capital_financial_inertia` | After salary joke/manual cycle seen, salary level-up may add small passive money | MODULE 13 |
| `CAPITAL_NO_LIMIT` | `perk_capital_no_limit` | Once per major story stage: allow authored capital solution regardless of price | MODULE 09; 11/12 |

---

## Aura

| PerkId | ID | Contract (summary) | Future owners |
|---|---|---|---|
| `AURA_PRESENCE_REGISTERED` | `perk_aura_presence_registered` | Unlocks aura actions by level; unlocks sigma contests | MODULE 06; 07C; 09 |
| `AURA_DONT_BLINK_FIRST` | `perk_aura_dont_blink_first` | First hold mistake in sigma does not reduce accumulated progress | MODULE 07C |
| `AURA_SILENCE_LONGER` | `perk_aura_silence_longer` | Once per sigma: opponent briefly stops disturbances | MODULE 07C |
| `AURA_REVERSE_PRESSURE` | `perk_aura_reverse_pressure` | After handling a disturbance, next perfect sigma section gets +1 point | MODULE 07C |
| `AURA_RIGHT_TO_SAY_NOTHING` | `perk_aura_right_to_say_nothing` | Dating: once/date skip greeting, girl starts (diagnostic, no relationship). Rival: once/encounter replace opponent-chosen competition if they initiated | MODULE 09; MODULE 06 |
| `AURA_SHE_ALREADY_STARTED` | `perk_aura_she_already_started` | Amplifies previous perk (clearer trait clue / no extra authority penalty on competition swap) | MODULE 06; 09 |
| `AURA_ATMOSPHERIC_INFLUENCE` | `perk_aura_atmospheric_influence` | Crowd no longer hardens aura hold; may only change presentation | MODULE 07C; presentation |
| `AURA_LOCAL_SIGNIFICANCE` | `perk_aura_local_significance` | Once per normal rival encounter: clearly weaker rival may concede before minigame (not story rivals) | MODULE 06 |

---

## Ownership matrix (by future module)

- **MODULE 06 Rival:** heroic defeat; right to say nothing; she already started; local significance; payable intent / presence registered as access
- **MODULE 07A Slap:** no warmup; tough cheek; double slap; counter argument; mass reserve; two-handed argument (as applicable)
- **MODULE 07B Dance:** staged walk; rhythm in body
- **MODULE 07C Sigma:** pocket mirror; control profile; don’t blink first; silence longer; reverse pressure; atmospheric influence
- **MODULE 07D Money:** payable intent; hostile acquisition
- **MODULE 08 Discovery:** good profile (visual clue)
- **MODULE 09 Dating:** hold doorway; heroic defeat; good profile; second outfit; encore; public significance; payable intent; representation expenses; buy problem; dignity refund; no limit; presence registered; right to say nothing; she already started
- **MODULE 11/12 Story/World:** hostile acquisition; no limit; hold doorway (authored persistent consequences)
- **MODULE 13 Salary Mine:** salary advance; financial inertia

Unimplemented effect contracts after MODULE 05 are expected, not bugs.
