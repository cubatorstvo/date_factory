# VISUAL ART PASS 01 — Independent QA

**Task ID:** AP1-QA / AP1-QA-FINAL-RECHECK  
**Date:** 2026-08-09  
**QA agent:** df-qa-worker (independent capture + open-PNG review)  
**Source (main):** `7ee5fdef23ffcf2676b95fe2a9bf796785a3db6e` (`7ee5fde`, fix3 after `328ce66` — chest tops + flat foot shoes)  
**Prior source reviewed:** `328ce66` (NOT READY — walk hollow/back-plate clothing + ankle IK shoe cubes)  
**Review branch:** `visual-review/art-pass-01-20260809`  
**Screenshot path:** `_review/art_pass_01/`

## Overall status

**READY**

Independent recapture of the four critical character shots on main `@7ee5fde` meets TZ temporary clothing rules: hair seated on scalp, tops read as solid chest shells (not back plates / giant hollow frames), shoes are flat soles under both feet (not ankle IK cubes), and walk poses remain readable. City/cafe/regression frames retained from prior accepted set (not re-captured this pass).

---

## Criteria

| Criterion | Status | Evidence |
|---|---|---|
| Branch from latest main @ `7ee5fde` | **PASS** | Review branch reset onto `origin/main` (`7ee5fde`) |
| TZ screenshot set 1920×1080 | **PASS** | Critical chars `03`/`05`/`08`/`09` re-captured; remaining set retained |
| Publish under `_review/art_pass_01/` + push review branch | **PASS** | Four PNGs overwritten + QA md; review branch push |
| Hair on scalp (not face / not floating) | **PASS** | Idle fronts scalp-correct; female walk hair seated; male walk uses short/near-bald style 1 (not floating) |
| Top on chest (not back plate / not giant hollow frame) | **PASS** | Teal solid chest boxes on idle + walk for male and female |
| Shoes flat under BOTH feet (not ankle IK cubes) | **PASS** | Thin black sole slabs under both feet in all four opened shots |
| Walk still readable | **PASS** | `08`/`09` mid-stride clear (legs/arms counterpose) |
| City / cafe / regression | **PASS** (prior) | Not re-captured; prior acceptance retained |
| Temporary clothing remains placeholder boxes | **WARNING** | Expected for TZ temp clothing — opaque teal chest cubes / black sole slabs, not final garments |

---

## Opened PNG verdicts (critical final recheck)

### `03_male_variants_front.png`

| Check | Result | Seen |
|---|---|---|
| Hair on scalp | **PASS** | Bald / short / blond / long red / purple buns — all on scalp, face clear |
| Top on chest | **PASS** | Solid teal chest boxes on all five; not backpack/back-plate hollow frames |
| Shoes flat under both feet | **PASS** | Thin black sole slabs under both feet on all five |
| Walk readable | n/a | Idle lineup |

**Shot verdict:** PASS vs TZ temporary clothing rules.

### `05_female_variants_front.png`

| Check | Result | Seen |
|---|---|---|
| Hair on scalp | **PASS** | Flat-top / swept / blond bun / red twin buns / bald — seated on scalp |
| Top on chest | **PASS** | Solid teal chest cubes centered on torso for all five |
| Shoes flat under both feet | **PASS** | Flat black soles under both feet; not ankle cubes |
| Walk readable | n/a | Idle lineup |

**Shot verdict:** PASS vs TZ temporary clothing rules.

### `08_male_walk_pose.png`

| Check | Result | Seen |
|---|---|---|
| Hair on scalp | **PASS** | Short/near-bald style 1; no floating hair mass |
| Top on chest | **PASS** | Solid teal chest box stays on front of torso during walk (not collapsed back plate) |
| Shoes flat under both feet | **PASS** | Flat black soles under leading and trailing feet |
| Walk readable | **PASS** | Clear mid-stride; arms/legs counterpose |

**Shot verdict:** PASS — prior walk clothing/shoes FAIL cleared.

### `09_female_walk_pose.png`

| Check | Result | Seen |
|---|---|---|
| Hair on scalp | **PASS** | Dark brown hair seated on scalp (no rear detach) |
| Top on chest | **PASS** | Solid teal chest box on torso during walk |
| Shoes flat under both feet | **PASS** | Flat black soles under both feet through stride |
| Walk readable | **PASS** | Clear mid-stride walk pose |

**Shot verdict:** PASS — prior walk FAIL cleared.

### Not re-opened this pass

City/cafe/regression (`20`–`43`) and supporting char shots (`01`/`02`/`04`/`06`/`07`) retained from prior review assets on the branch; prior acceptance kept.

---

## Automated verification (final recheck)

Commands:

```text
GODOT=C:\godot\Godot_v4.7.1-stable_win64.exe
git fetch origin main
git checkout visual-review/art-pass-01-20260809
git reset --hard origin/main   # -> 7ee5fde
# restore prior _review set, then overwrite 4 critical PNGs
godot --path . --windowed --resolution 1920x1080 --script res://tmp/ap1_qa/capture_art_pass_01.gd
Copy-Item tmp/art_pass_01/{03,05,08,09}_*.png _review/art_pass_01/ -Force
```

Results:

- Capture: `AP1_CAPTURE_DONE`, shots `01`–`09` `save=0 1920x1080`, `AP1_CHARS_ONLY skip locations`, exit 0
- Engine: Godot 4.7.1-stable / Vulkan Forward+ / RTX 4060 Laptop
- Stdout: `tmp/ap1_qa/capture_final_recheck_stdout.txt`
- Log: `tmp/ap1_qa/capture_art_pass_01.log`
- Independent hashes differ from implementer `docs/agent/qa/evidence/ap1_chars_fix3/` (fresh capture; same visual conclusions)

---

## Blocking issues

None for TZ temporary clothing acceptance on the four critical shots.

## Non-blocking issues

1. Temporary tops remain obvious opaque teal cubes (allowed by TZ temporary clothing; not final garments).
2. Temporary shoes remain flat black sole slabs (correct placement; not final footwear art).
3. Male walk uses hair style `1` which reads nearly bald in this framing — not a detach/placement fail.
4. City prior warnings unchanged (blue Area volumes in `22`, pink prism in `25`) — out of this recheck scope.

## Evidence

- `_review/art_pass_01/03_male_variants_front.png`
- `_review/art_pass_01/05_female_variants_front.png`
- `_review/art_pass_01/08_male_walk_pose.png`
- `_review/art_pass_01/09_female_walk_pose.png`
- `tmp/ap1_qa/capture_final_recheck_stdout.txt`
- `tmp/ap1_qa/capture_art_pass_01.log`

## Reproduction steps

1. Checkout `main` @ `7ee5fde` (or review branch after this push).
2. Run windowed capture script `res://tmp/ap1_qa/capture_art_pass_01.gd` at 1920×1080.
3. Open `_review/art_pass_01/03`, `05`, `08`, `09`.
4. Confirm chest tops + flat sole shoes + scalp hair + readable walk per TZ temporary clothing rules.
