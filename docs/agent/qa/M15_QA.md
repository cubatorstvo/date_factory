# M15_QA — MODULE 15 Independent QA

**Task:** M15_D_QA / M15_QA  
**Module:** 15 — Media / Attention Escalation  
**Date:** 2026-08-08  
**Agent:** df-qa-worker  
**Product code changes by QA:** none  

## Verdict

**PASS**

---

## Criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | `MODULE_15_TEST` ALL PASS | **PASS** | Headless `res://game/media/test/media_test.tscn` → `MODULE_15_TEST: ALL PASS (145)` EXIT=0. Log: `tmp/m15_qa/media_self_test.log`. |
| 2 | F5 boots apartment | **PASS** | Main scene (`--quit-after 8`): `[DF][MODULE_12] Boot -> apartment via World`, Media autoload ready, Player ready. Indep QA: `reset_to_start` → `current_location_id=apartment`, Neighbor present. Screenshot `01_apartment_boot.png`. Log: `tmp/m15_qa/f5_main_boot.log`. |
| 3 | STAGE4: `PhotoSessionInteractable` at `appearance_space` | **PASS** *(stage via labeled `restore_stage(STAGE_4)`)* | After restore: `MEDIA_ATTENTION` unlocked; travel `appearance_space`; interactable present/visible; prompt `[E] Фотосессия у Редактора`. Shot `02_studio_photo_interactable.png`. |
| 4 | Complete session → Attention15 + feed article + offer; Phone MEDIA | **PASS** | `complete_photo_session` BASE → Attention=15, `feed_article_editor`, offer `girl_appearance_flash`. Phone: `Внимание: 15 / 100`, article headline, NEW incoming, 3 Publish buttons. Shot `03_phone_media.png`. |
| 5 | Publish respects daily limit; visuals at thresholds | **PASS** | Same-day second publish → `DAILY_LIMIT`, Attention unchanged. Next day publish OK. At Attention45: `Attention15Magazine` / `Attention30Posters` / `Attention45Crowd` Visual subtrees visible. Shot `04_city_fame_visual.png` (Att45 board). |
| 6 | `overload_ready` at Att≥45 + offers≥3; stage stays 4; no Scientist/calendar | **PASS** | After 3 base photo publishes: Attention=45, offers=3, `is_overload_ready()==true`, `get_stage()==STAGE_4`. `try_get_girl/rival` scientist null. `media.gd` has no `appointment_time` / `calendar_slot` / `deadline` / `overlap_time`. Phone story: «Спрос растёт быстрее обычного». |
| 7 | Screenshots opened and described | **PASS** | Four PNGs opened and described below. |
| 8 | Write `docs/agent/qa/M15_QA.md` | **PASS** | This file. |

---

## Player flow actually executed

1. Independent headless: `MODULE_15_TEST` ALL PASS (145).
2. Independent live harness `tmp/m15_qa/m15_indep_qa.tscn` (**54/54 PASS**):
   - World boot apartment + Neighbor
   - Labeled `restore_stage(STAGE_4)` + Experience 4
   - Phone MEDIA pre-session («Фотосессия…», Attention 0 path)
   - Travel `appearance_space` → PhotoSessionInteractable prompt
   - Complete BASE photo session → article +15 + offer1
   - Phone MEDIA post-session (Attention/photos/incoming/feed)
   - Publish profile; same-day chair → DAILY_LIMIT
   - Advance day → publish chair/cover → Attention45, 3 offers, overload_ready
   - City hub fame visuals visible at thresholds
   - No Scientist resources; no schedule fields in Media
3. Main-scene F5 smoke: boots apartment via World (quit-after).
4. Opened and described all four evidence screenshots.

Note: full three-shot modal click-through UI is covered by `MODULE_15_TEST` (104–107, phone tests); live indep path completes the same Media transaction API used by session RESULT and verifies world interactable + Phone UI.

---

## Edge cases

| Case | Status | Notes |
|------|--------|-------|
| Daily photo publish limit | **PASS** | Second publish same GameDay → `PublishError.DAILY_LIMIT`; no Attention/day mutation |
| Day advance without publish | **PASS** | Attention stays 25; next-day publish succeeds |
| Overload without Stage advance / Scientist / calendar | **PASS** | Stage remains 4; scientist try_get null; banned schedule tokens absent in `media.gd` |
| Session abort / double complete / thresholds | **PASS** | Covered by MODULE_15_TEST 106 / 78 / 116–119 (headless) |

---

## Screenshot descriptions (opened and inspected)

Evidence: `tmp/m15_qa/`

### 1) `01_apartment_boot.png`

- Grey/brown low-poly apartment; large label **«КВАРТИРА»**.
- Neighbor female CharacterActor (blonde, white tee, orange pants).
- Date table + «Самооценка» props; blue door block; crosshair; HUD `mode=GAMEPLAY`.
- Matches filename: apartment gameplay boot.

### 2) `02_studio_photo_interactable.png`

- Purple-floor `appearance_space` studio blockout.
- White backdrop, two softbox stands, camera-on-tripod placeholder, brown pedestal.
- Label3D **«РЕДАКЦИЯ / СЪЁМКА»**.
- Yellow **«ФОТОСЕССИЯ»** marker at PhotoSessionInteractable.
- Matches studio interactable requirement (STAGE_4 available).

### 3) `03_phone_media.png`

- Phone modal `mode=MODAL_UI`; title «Телефон — Журнал».
- Story: **СТАДИЯ 4 / Медийность** — «Публикуй фотографии. / Входящие предложения растут.»
- **МЕДИА:** `Внимание: 15 / 100`.
- Photos: Профиль / Стул / Обложка each with **Опубликовать**.
- Incoming: **NEW Девушка со вспышкой** + Открыть.
- Feed: inbound message + editorial article «Редакция подтверждает…».
- Matches Phone MEDIA post-session requirement.

### 4) `04_city_fame_visual.png`

- City hub outdoor greybox; HUD `mode=GAMEPLAY`.
- Fame board text **«ЛИЦО ПОДТВЕРЖДЕНО РЕДАКЦИЕЙ»** (Attention 45 visual).
- Floating **«ФАНАТЫ»**; travel prompt `[E] В квартиру`.
- Matches city fame visual at overload threshold (nodes for 15/30 also verified programmatically as visible).

---

## Commands + key log lines

### Headless MODULE 15

```text
Godot_v4.7.1-stable_win64_console.exe --path <repo> --headless --scene res://game/media/test/media_test.tscn
[DF][MODULE_15_TEST] ALL PASS (145)
MODULE_15_TEST: ALL PASS (145)
EXIT=0
```

Log: `tmp/m15_qa/media_self_test.log`

### Independent live QA + screenshots

```text
Godot_v4.7.1-stable_win64_console.exe --path <repo> --scene res://tmp/m15_qa/m15_indep_qa.tscn
M15_INDEP_QA: DONE passed=54 failed=0
Attention=45 offers=3 overload=true stage=4
EXIT=0
```

Log: `tmp/m15_qa/m15_indep_qa.log`  
Report: `tmp/m15_qa/m15_indep_qa_report.txt`

### F5 main boot smoke

```text
Godot_v4.7.1-stable_win64_console.exe --path <repo> --quit-after 8
[DF][MODULE_15] Media ready
[DF][MODULE_12] Boot -> apartment via World
[DF][MODULE_01] Player ready
EXIT=0
```

Log: `tmp/m15_qa/f5_main_boot.log`

---

## Overall status

**PASS** — MODULE 15 media escalation criteria verified independently. No MODULE 16 scheduling/Scientist/lab content observed.

## Blocking issues

None.

## Non-blocking issues

- GodotIQ MCP `godotiq_run` to editor port 6007 was rejected during this session; F5/world evidence gathered via console Godot launches instead.
- Quit-time RID/resource leak warnings from Godot (exit cleanup); no gameplay script errors during checks.
- City fame screenshot frames the Attention45 board; Attention15 magazine / Attention30 posters confirmed by node `Visual.visible` rather than separate close-ups.
- Disk save/load module not exercised (no dedicated save runner in scope); media fields exist on GameState + reset path verified by MODULE_15_TEST / indep reset boot.

## Evidence

| Path | Role |
|------|------|
| `tmp/m15_qa/media_self_test.log` | MODULE_15_TEST raw Godot log |
| `tmp/m15_qa/m15_indep_qa.log` | Indep flow raw Godot log |
| `tmp/m15_qa/m15_indep_qa_report.txt` | Capture journal (54 PASS) |
| `tmp/m15_qa/f5_main_boot.log` | Main-scene apartment boot |
| `tmp/m15_qa/01_apartment_boot.png` | Apartment boot |
| `tmp/m15_qa/02_studio_photo_interactable.png` | Studio PhotoSessionInteractable |
| `tmp/m15_qa/03_phone_media.png` | Phone MEDIA section |
| `tmp/m15_qa/04_city_fame_visual.png` | City fame visual @45 |

## Reproduction steps

1. Run headless: `--scene res://game/media/test/media_test.tscn` → expect `MODULE_15_TEST: ALL PASS (145)`.
2. Run main scene briefly → expect World boot apartment + Media ready.
3. Run `res://tmp/m15_qa/m15_indep_qa.tscn` (windowed) → expect 54/54 PASS and four PNGs under `tmp/m15_qa/`.
4. Confirm STAGE_4 path uses labeled `restore_stage` (documented); production F5 still reaches STAGE_4 via Editor +5 story (covered by MODULE_15_TEST / prior modules).
