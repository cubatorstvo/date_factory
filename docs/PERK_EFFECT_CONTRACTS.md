# Perk Effect Contracts (MODULE 05)

Ownership and purchase live in Progression / GameState.  
**Effects are NOT implemented in MODULE 05.** Future modules check `GameState.has_perk(PerkIds.*)` and apply the contract below.

Source: `docs/modules/MODULE_05_PROGRESSION_PERKS.md` §§35–75.

---

## Muscle

| PerkId | ID | Contract (summary) | Future owners |
|---|---|---|---|
| `MUSCLE_NO_WARMUP` | `perk_muscle_no_warmup` | Unlocks muscle actions by level; **Slap:** first ATTACK zone width `×1.25` (cap `0.34`) | Dating/World availability; MODULE 07A Slap |
| `MUSCLE_TOUGH_CHEEK` | `perk_muscle_tough_cheek` | **Slap (implemented):** once/match on DEFENSE fail rival still +1; if prev streak>0 → `streak=max(1,ceil(prev/2))` and consume; streak0 does not consume | MODULE 07A Slap |
| `MUSCLE_DOUBLE_SLAP` | `perk_muscle_double_slap` | **Slap (implemented):** Q once/match; perfect +2; non-perfect +1 (or 0 on miss) and next DEFENSE width `×0.65` (min `0.08`) | MODULE 07A |
| `MUSCLE_COUNTER_ARGUMENT` | `perk_muscle_counter_argument` | **Slap (implemented):** perfect DEFENSE arms next ATTACK; that ATTACK perfect +1 extra then consume; stacks with Double (+3) | MODULE 07A |
| `MUSCLE_HOLD_DOORWAY` | `perk_muscle_hold_doorway` | **Dating (implemented):** `required_perk_id` gate on authored actions only | MODULE 09 Dating; world scripted interactions |
| `MUSCLE_HEROIC_DEFEAT` | `perk_muscle_heroic_defeat` | Softens authority punishment vs clearly stronger rival; dating defeat may add VULNERABILITY + RISK | MODULE 06 Rival; MODULE 09 Dating |
| `MUSCLE_MASS_RESERVE` | `perk_muscle_mass_reserve` | **Slap (implemented):** once/match first ordinary ATTACK miss → no score change, new ATTACK, streak0; not on Double/TwoHanded | MODULE 07A Slap |
| `MUSCLE_TWO_HANDED_ARGUMENT` | `perk_muscle_two_handed_argument` | **Slap (implemented):** story only; R once; exclusive with Double; perfect +2 (+counter); non-perfect → rival +2, skip DEFENSE | MODULE 07A |

---

## Appearance

| PerkId | ID | Contract (summary) | Future owners |
|---|---|---|---|
| `APPEARANCE_GOOD_PROFILE` | `perk_appearance_good_profile` | On **first discovery only**: clue 0 as usual + clue 1 if it exists (not retroactive; not on journal open/respawn/failure). Also unlocks appearance actions by level (MODULE 09). | MODULE 08 Discovery (clue); MODULE 09 |
| `APPEARANCE_STAGED_WALK` | `perk_appearance_staged_walk` | Dance: once/match, first ERROR at streak>0 → streak=`max(1,ceil(prev/2))` (error still counts); unused if first error at streak 0 | MODULE 07B Dance |
| `APPEARANCE_POCKET_MIRROR` | `perk_appearance_pocket_mirror` | Sigma: Q once/match, 2.5s; `zone_center=0`, `normal_half_width*=1.20` clamp≤0.46; pressure/disturbances continue; timer may carry across sections | MODULE 07C Sigma |
| `APPEARANCE_CONTROL_PROFILE` | `perk_appearance_control_profile` | Sigma: if PERFECT completes while Mirror still active → +1 extra (total +2 with base); stacks with Reverse Pressure (+3 max) | MODULE 07C |
| `APPEARANCE_SECOND_OUTFIT` | `perk_appearance_second_outfit` | **Dating (implemented):** once/date ARRIVAL/GREETING before first evaluated action; presentation flag + `second_outfit_requested` (no score/tags) | MODULE 09; character presentation |
| `APPEARANCE_ENCORE` | `perk_appearance_encore` | **Dating (implemented):** once/date after Appearance base primary 0 → ENCORE_DECISION; ORIGINALITY tag transform + re-eval; decline keeps charge | MODULE 09 |
| `APPEARANCE_RHYTHM_IN_BODY` | `perk_appearance_rhythm_in_body` | Dance: `base_window *= 1.20` before streak bonus (final ≤0.30); first complex (`length>=4`) PLAYER_REPEAT shows next-direction clue 0.25s before beats | MODULE 07B |
| `APPEARANCE_PUBLIC_SIGNIFICANCE` | `perk_appearance_public_significance` | **Dating (implemented):** once/date unlock Appearance action at current+1 only; consume on select; resolver still runs | MODULE 09 |

---

## Capital

| PerkId | ID | Contract (summary) | Future owners |
|---|---|---|---|
| `CAPITAL_PAYABLE_INTENT` | `perk_capital_payable_intent` | Unlocks capital actions by level; unlocks money contests (MODULE 06 access only — no extra Money match modifier) | MODULE 06; 07D Money; 09 |
| `CAPITAL_REPRESENTATION_EXPENSES` | `perk_capital_representation_expenses` | **Dating (implemented):** first normal paid (`!is_major_expense`) action free; consume on select | MODULE 09 |
| `CAPITAL_BUY_PROBLEM` | `perk_capital_buy_problem` | **Dating (implemented):** `required_perk_id` gate on authored actions only | MODULE 09 + authored event |
| `CAPITAL_HOSTILE_ACQUISITION` | `perk_capital_hostile_acquisition` | After MONEY match `PLAYER_WIN` vs rival with `competition_modifier_id=&"money_acquisition"`, Runner emits `hostile_acquisition_requested` once (no world mutation in 07D; ownership later) | MODULE 07D hook; 11/12 Story/World |
| `CAPITAL_SALARY_ADVANCE` | `perk_capital_salary_advance` | Salary Mine unlocked only. Once per salary period. Remote claim of ALL currently accumulated pending salary. Does not create future payout. Does not mark manual cycle seen. | MODULE 13 Salary Mine / PhoneJournal |
| `CAPITAL_DIGNITY_REFUND` | `perk_capital_dignity_refund` | **Dating (implemented):** on execution FAILURE with `money_spent>0`, `GameState.add_money` refund; tags/reaction unchanged. Does **not** refund Money Contest auction spends | MODULE 09 paid resolver |
| `CAPITAL_FINANCIAL_INERTIA` | `perk_capital_financial_inertia` | After at least one successful manual salary collection, 25% floor of each future gross salary period is deposited automatically; remaining gross stays pending for manual/advance collection. | MODULE 13 Salary Mine |
| `CAPITAL_NO_LIMIT` | `perk_capital_no_limit` | Once per major story stage: allow authored capital solution regardless of price. **MODULE 09 does NOT implement once/date freebie** | MODULE 11/12 Story; not MODULE 09 session |

---

## Aura

| PerkId | ID | Contract (summary) | Future owners |
|---|---|---|---|
| `AURA_PRESENCE_REGISTERED` | `perk_aura_presence_registered` | Unlocks aura actions by level; unlocks sigma contests | MODULE 06; 07C; 09 |
| `AURA_DONT_BLINK_FIRST` | `perk_aura_dont_blink_first` | Sigma: first hold error once/match skips −0.65; `total_error_count+=1`; perfect impossible; used even at progress 0 | MODULE 07C |
| `AURA_SILENCE_LONGER` | `perk_aura_silence_longer` | Sigma: R once/match, 2.0s; freezes disturbance schedule clock only; active disturbance finishes; baseline continues; may carry across sections | MODULE 07C |
| `AURA_REVERSE_PRESSURE` | `perk_aura_reverse_pressure` | Sigma: survive ACTIVE disturbance +0.75s with zero hold errors → arm; next PERFECT consumes for +1; arm persists across non-perfect sections | MODULE 07C |
| `AURA_RIGHT_TO_SAY_NOTHING` | `perk_aura_right_to_say_nothing` | **Dating (implemented):** silence greeting (reaction 0, no fake tags); reveal next unknown clue. Rival: once/encounter replace rival-chosen competition if they initiated; **no Authority penalty** for the swap | MODULE 09; MODULE 06 |
| `AURA_SHE_ALREADY_STARTED` | `perk_aura_she_already_started` | **Dating (implemented):** after silence, +1 more next unknown clue (max 2); does **not** call `reveal_primary_trait`. **No Rival Encounter effect** | MODULE 09 |
| `AURA_ATMOSPHERIC_INFLUENCE` | `perk_aura_atmospheric_influence` | Sigma: if observers present → `observer_wobble=0`; does not remove rival wobble/pressure/disturbances | MODULE 07C |
| `AURA_LOCAL_SIGNIFICANCE` | `perk_aura_local_significance` | Once per normal rival encounter: clearly weaker rival may concede before minigame (not story rivals) | MODULE 06 |

---

## Ownership matrix (by future module)

- **MODULE 06 Rival:** heroic defeat; right to say nothing (override, no auth penalty); local significance; payable intent / presence registered as access. Not: she already started
- **MODULE 07A Slap:** no warmup; tough cheek; double slap; counter argument; mass reserve; two-handed argument (as applicable)
- **MODULE 07B Dance:** staged walk; rhythm in body
- **MODULE 07C Sigma:** pocket mirror; control profile; don’t blink first; silence longer; reverse pressure; atmospheric influence
- **MODULE 07D Money:** payable intent; hostile acquisition
- **MODULE 08 Discovery:** good profile (visual clue)
- **MODULE 09 Dating (implemented):** hold doorway gate; buy problem gate; second outfit; encore; public significance; representation expenses; dignity refund; right to say nothing; she already started. **Not:** No Limit once/date; heroic defeat dating path (external resolver later); automatic trait reveal
- **MODULE 11/12 Story/World:** hostile acquisition; no limit stage usage; hold doorway (authored persistent consequences)
- **MODULE 13 Salary Mine:** salary advance; financial inertia

MODULE 07A implements Muscle slap rows above. Other unimplemented effect contracts remain expected, not bugs.
