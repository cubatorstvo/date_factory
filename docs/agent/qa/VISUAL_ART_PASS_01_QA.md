# VISUAL ART PASS 01 — Independent QA

**Task ID:** AP1-QA / AP1-QA-RECHECK  
**Date:** 2026-08-09  
**QA agent:** df-qa-worker (independent capture + open-PNG review)  
**Source (main):** `328ce66dd56c4c93019644cef6e76a7919da3e0e` (`328ce66`, post-`ec64c55` silhouette fix2)  
**Prior source reviewed:** `ec64c55` (NOT READY — giant box clothing / broken hair / missing shoes)  
**Review branch:** `visual-review/art-pass-01-20260809`  
**Screenshot path:** `_review/art_pass_01/` (also mirrored under `tmp/art_pass_01/`)

## Overall status

**NOT READY**

Idle front lineups (`03`/`05`/`07`) show clear improvement after `328ce66` (hair on scalp, tops as thin close shells, both shoe-slot meshes). City/cafe remain accepted from prior review and were not re-captured. Blocking remains: **walk poses still show floating/hollow clothing + female hair detach**, and **shoes still read as black ankle cuboids / debug blocks** (DoD: clothing/shoes must not read as debug cubes).

---

## Criteria

| Criterion | Status | Evidence |
|---|---|---|
| Branch from latest main @ `328ce66` | **PASS** | Rebased `visual-review/art-pass-01-20260809` onto `328ce66` |
| TZ screenshot set 1920×1080 | **PASS** | Chars `01`–`09` re-captured; city/cafe/regression kept from prior set (already accepted) |
| Publish under `_review/art_pass_01/` + push review branch | **PASS** | Recheck chars force-added; review branch push |
| Characters: real hair (not primitive towers / not face) | **WARNING** | Idle fronts: scalp OK. Walk `09`: floating hair mass behind scalp. Some male styles still sparse cards |
| Characters: clothing silhouettes not giant boxes | **FAIL** | Idle fronts thin close shells (**improved**). Walk `08`/`09`: floating/hollow teal planes around torso still player-visible |
| Characters: both shoes | **FAIL** | Both feet have shoe-slot meshes, but they still read as black rectangular ankle cubes with bare feet visible — not readable footwear |
| Characters: bottoms covering legs | **PASS** (minimal) | Boxers / bikini bottoms cover pelvis + upper thigh; female hip blue plane in `05` is a thin bottom shell artifact (WARN) |
| City / cafe / regression | **PASS** (prior) | Not re-captured this recheck; prior acceptance retained |
| donor / women_modular prod refs | **PASS** (prior) | Unchanged since prior AP1-QA |
| Automated presentation ≠ visual readiness | **FAIL gate** | PNG open review remains hard gate; walk/shoes still fail DoD |

---

## Opened PNG verdicts (critical recheck)

### `03_male_variants_front.png`

| Check | Result | Seen |
|---|---|---|
| Hair on scalp (not face) | **PASS** | 5 males; styles on scalp (bald / short / blond / long red / purple buns); face clear |
| Tops thin close shells | **PASS** | Teal chest/back pieces sit as thin body-following shells — not giant hollow frames |
| Both shoes | **FAIL** (pair present, art fail) | Both feet have black rectangular ankle blocks; bare feet still readable |
| Bottoms covering legs | **PASS** | Dark boxer briefs cover pelvis/upper thighs; one variant has blue front flap |

**Shot verdict:** silhouette/hair improved vs prior FAIL; shoes still debug cubes → character DoD unmet.

### `05_female_variants_front.png`

| Check | Result | Seen |
|---|---|---|
| Hair on scalp (not face) | **PASS** | Flat-top / swept / blond bun / red twin buns / bald — on scalp, not face masks |
| Tops thin close shells | **PASS** | Dark bikini tops + teal back pieces read as thin close shells |
| Both shoes | **FAIL** (pair present, art fail) | Both feet black block shoes on all five |
| Bottoms covering legs | **PASS** + **WARN** | Bikini bottoms present; horizontal blue plane through hips (bottom shell) across lineup |

**Shot verdict:** major hair/top improvement; shoes + hip plane keep DoD short of READY.

### `07_mixed_variants.png`

| Check | Result | Seen |
|---|---|---|
| Hair on scalp (not face) | **PASS** | Mixed male/female styles on scalp; no face-cover hair |
| Tops thin close shells | **PASS** | Female bikini tops close to body; males mostly shirtless + backpack straps (not giant chest boxes) |
| Both shoes | **FAIL** (pair present, art fail) | All 10 have paired black foot blocks |
| Bottoms covering legs | **PASS** | Shorts / colored loincloth flaps cover pelvis/upper thighs |

**Shot verdict:** idle mixed lineup no longer dominated by giant teal boxes; shoes still blocky.

### Supporting recapture (opened)

| File | Verdict | What was seen |
|---|---|---|
| `01_male_base_clean.png` | **PASS** (clean base) | Bald male, underwear, barefoot — intentional clean base |
| `02_female_base_clean.png` | **PASS** (clean base) | Clean female base (not re-opened in detail; file refreshed) |
| `04_male_variants_side.png` | **WARNING** | Side: tops look close; shoe blocks at ankles |
| `06_female_variants_side.png` | **WARNING** | Side: thin teal shells; bald FG; shoe blocks |
| `08_male_walk_pose.png` | **FAIL** | Walk: floating cyan/teal torso planes + black ankle cubes; hair sparse card |
| `09_female_walk_pose.png` | **FAIL** | Walk: hollow teal/black torso frame; hair mass floating behind head; black ankle cubes |

### City / cafe / regression (not re-captured)

Prior AP1-QA acceptance retained for city megakit / cafe framing / apartment-mine-lab-late regression frames (`20`–`43`).

---

## Automated verification (recheck)

Commands:

```text
GODOT=C:\godot\Godot_v4.7.1-stable_win64.exe
# stash unrelated dirty UI, checkout main, pull, rebase review onto main
godot --path . --windowed --resolution 1920x1080 -s res://tmp/ap1_qa/capture_art_pass_01.gd
# capture patched to characters-only for AP1-QA-RECHECK
Copy-Item tmp/art_pass_01/0[1-9]_*.png _review/art_pass_01/ -Force
```

Results:

- Capture: `AP1_CAPTURE_DONE`, shots `01`–`09` `save=0 1920x1080`, `AP1_CHARS_ONLY skip locations`
- Log: `tmp/ap1_qa/capture_art_pass_01.log`
- Stdout: `tmp/ap1_qa/capture_recheck_stdout.txt`

---

## Blocking issues

1. **Walk poses still break clothing silhouette** (`08`/`09`) — floating/hollow teal planes around torso; DoD clothing resize incomplete under animation.
2. **Shoes still read as black debug cuboids** on variants/mixed/walk — both slots present, but not readable footwear (DoD: not debug cubes).
3. **Female walk hair detach** (`09`) — mass floating behind scalp under walk.

## Non-blocking issues

1. Female front `05`: blue hip plane through all five (thin bottom shell artifact).
2. City prior warnings unchanged (blue Area volumes in `22`, pink prism in `25`) — out of recheck scope.
3. Idle front progress is real vs `ec64c55` review — do not regress those transforms when fixing walk/shoes.

## Evidence

- Screenshots: `_review/art_pass_01/01`–`09` (recheck), `20`–`43` (prior)
- Capture log: `tmp/ap1_qa/capture_art_pass_01.log`
- Capture stdout: `tmp/ap1_qa/capture_recheck_stdout.txt`
- This report: `docs/agent/qa/VISUAL_ART_PASS_01_QA.md`

## Reproduction steps

1. `git checkout main && git pull` → expect `328ce66`.
2. Stash unrelated dirty UI if needed.
3. Update `visual-review/art-pass-01-20260809` onto main (rebase/merge).
4. Run characters-only capture at 1920×1080 via `tmp/ap1_qa/capture_art_pass_01.gd`.
5. Copy `tmp/art_pass_01/01`–`09` → `_review/art_pass_01/`.
6. Open `03`, `05`, `07` (and walk `08`/`09`); confirm remaining walk/shoes FAIL.

---

## Verdict

**NOT READY**

Idle front variants improved after silhouette fix2, but walk clothing/hair and shoe readability still fail Art Pass 01 DoD. City/cafe remain accepted; character route not READY.
