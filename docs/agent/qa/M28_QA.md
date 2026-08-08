# M28 Independent QA — MODULE 28 Release Integration

**Date:** 2026-08-08  
**Repo:** `C:\Users\User\Documents\GodotProjects\date_factory`  
**Spec:** `docs/modules/MODULE_28_RELEASE_INTEGRATION.md`  
**Godot:** `C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe` (4.7.1.stable)  
**QA role:** independent (`df-qa-worker`); writable only `tmp/m28_qa/**` + this report  
**Overall status:** **TECHNICAL READY**

---

## Verdict summary

Prior independent QA was **NOT READY** solely because title `v1.0.0` was off-screen (`global.y≈855` on viewport height 720).  
**Recheck after layout fix:** headless inspect reports `onscreen=true` at `y=688`; independent windowed PNGs visually show readable **`v1.0.0`** at the bottom of the title menu. Fresh release ZIP rebuilt at 22:19:12, package scan clean (no GodotIQ), standalone export boot/exit=0.

All prior green gates (RC 34/34, Steam fail-open, schema v1, RELEASE_STATUS honesty) remain accepted; the previous blocking acceptance gap is closed.

---

## Recheck (title version layout fix) — 2026-08-08 evening

### R1. Title version on-screen (layout)

| Status | **PASS** |
|---|---|
| Evidence (headless) | `tmp/m28_qa/inspect_title_version_fix_out.txt`: `QA_VERSION_LABEL=v1.0.0 global=(0.0, 688.0) size=(1280.0, 22.0) onscreen=true` with `QA_VIEWPORT=(1280.0, 720.0)`. |
| Evidence (visual) | Opened `tmp/m28_qa/title_version_recheck_full.png`: DATE FACTORY title menu (Russian buttons); **`v1.0.0` clearly visible** centered near bottom edge, below Выход, fully inside frame. Opened `tmp/m28_qa/title_version_recheck_strip.png`: bottom band crop with Выход + **`v1.0.0`**. |
| Commands | ```powershell
$env:GODOT = 'C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe'
& $env:GODOT --path . --headless -s res://tmp/m28_qa/inspect_title_version_fix.gd
& $env:GODOT --path . --quit-after 8 -s res://tmp/m28_qa/capture_title_version.gd
``` |
| Note | Capture script exit code 4 is a lambda outer-scope quirk in the QA harness (label printed correctly; PNGs written); visual inspection of PNGs is authoritative. |

### R2. Fresh Windows release package

| Status | **PASS** |
|---|---|
| Evidence | Rebuild was already running (`tools/release/build_windows.py --release --allow-dirty`); completed without QA re-invocation. `dist/DateFactory_1.0.0_win64.zip` mtime **2026-08-08 22:19:12**, size 64443843. SHA256 match `fc524ba6eae7c97aa859dce55e7ab542a1ea8ac9d9a0e412b6514ce311cdbe7a` (`tmp/m28_qa/package_scan_recheck.txt`). Manifest: version 1.0.0, qa 34/34, save_schema 1, `steam_app_id_configured: false`, UNSIGNED, `build_time_utc=2026-08-08T19:19:12Z`. |

### R3. Package ZIP scan (no GodotIQ)

| Status | **PASS** |
|---|---|
| Evidence | `tmp/m28_qa/package_scan_recheck.txt` — 5 entries: `DateFactory.exe`, `DateFactory.pck`, `THIRD_PARTY_NOTICES.txt`, `steam_api64.dll`, `libgodotsteam.windows.template_release.x86_64.dll`. `FORBIDDEN_HITS=0` (no godotiq / steam_appid.txt / docs / qa / tools / .cursor / tmp). |

### R4. Standalone smoke (new ZIP)

| Status | **PASS** |
|---|---|
| Evidence | Extract to `%TEMP%\df_m28_qa_recheck\DateFactory` (no AppID). Alive after 8s; `CloseMainWindow` → **exit=0** (`tmp/m28_qa/standalone_recheck.txt`). Boot log copy `tmp/m28_qa/date_factory_boot_recheck.log`: Steam fail-open, `version=1.0.0`, `save_schema=1`, `Steam=unavailable`. |

---

## Criteria

### 1. Input gate M27 facts + schema v1

| Status | **PASS** |
|---|---|
| Evidence | Prior QA: ACCEPTANCE / KNOWN_ISSUES honesty; schema **1**; post-M28 RC **34/34**. Unchanged by title layout fix. |
| Reproduction | Read ACCEPTANCE / KNOWN_ISSUES; confirm `SAVE_SCHEMA_VERSION`. |

### 2. `project.godot` release metadata / autoloads / logging

| Status | **PASS** |
|---|---|
| Evidence | Prior QA + GodotIQ `project_summary(detail=brief)` recheck: autoloads include `SteamBridge`, no `GodotIQRuntime`. `config/version="1.0.0"`. |
| Reproduction | `project_summary`; inspect `project.godot`. |

### 3. Title menu version from ProjectSettings

| Status | **PASS** (code + player-visible) |
|---|---|
| Evidence (code) | `ui/frontend/title_menu.gd` builds label from `ProjectSettings` (`v%s`); version is CanvasLayer sibling with BOTTOM_WIDE anchors (orchestrator fix). |
| Evidence (runtime) | Headless: `v1.0.0`, `onscreen=true`, `global.y=688` on viewport 720 (`inspect_title_version_fix_out.txt`). |
| Evidence (visual) | `title_version_recheck_full.png` / `title_version_recheck_strip.png` — **`v1.0.0` readable on title screen**. |
| Prior FAIL disposition | Previous inspect `y=855` / screenshots without version superseded by this recheck. |
| GodotIQ screenshot | Unavailable (`runtime_attached=false` after GodotIQRuntime removal) — used CLI windowed capture. |
| Reproduction | Headless inspect script; windowed capture script; open PNGs. |

### 4. `export_presets.cfg` “Windows Release”

| Status | **PASS** |
|---|---|
| Evidence | Prior QA inspection of preset unchanged by this recheck. |

### 5. RC suites `--only-rc`

| Status | **PASS** (34/34) |
|---|---|
| Evidence | Prior independent run: TOTAL 34 / PASS 34 / FAIL 0 (`tmp/m28_qa/rc_summary.txt`). Manifest of fresh ZIP still reports `qa_passed=34` / `qa_required=34`. Full RC not re-run on this recheck (scope = title visibility + package). |

### 6. Windows release package build

| Status | **PASS** |
|---|---|
| Evidence | Fresh artifact after layout fix: `dist/DateFactory_1.0.0_win64.zip` @ 22:19:12; SHA match; see R2. |

### 7. Package ZIP scan

| Status | **PASS** |
|---|---|
| Evidence | Recheck scan clean — see R3 / `package_scan_recheck.txt`. |

### 8. Standalone export smoke (outside repo, no Steam)

| Status | **PASS** |
|---|---|
| Evidence | Prior smoke + recheck on new ZIP — see R4. |

### 9. SteamBridge fail-open

| Status | **PASS** |
|---|---|
| Evidence | Prior `release_integration` ALL PASS; recheck boot log still fail-open without AppID. |

### 10. RELEASE_STATUS TECHNICAL vs STORE

| Status | **PASS** |
|---|---|
| Evidence | Prior QA: TECHNICAL READY goal vs STORE PENDING without production AppID — honest. This recheck clears the remaining TECHNICAL blocker (title version visibility). |

### 11. No gameplay/content/balance drift

| Status | **PASS** (spot-check from prior QA) |
|---|---|
| Evidence | Prior empty content/balance diff scope; this recheck did not modify game code (QA writable only `tmp/m28_qa/**` + this report). |

### Edge cases

| Case | Status | Evidence |
|---|---|---|
| Headless Steam unavailable | PASS | prior + boot recheck |
| Standalone no Steam / no appid | PASS | `standalone_recheck.txt` exit=0 |
| Repeat standalone launch | PASS | prior `standalone_repeat.txt` |
| Title version off-screen | **PASS** (was FAIL) | y=688 onscreen + visual PNGs |

### Control return / repeated use / save-load

| Item | Status | Notes |
|---|---|---|
| Control return after export close | PASS | recheck exit=0 |
| Repeated export use | PASS | prior repeat OK |
| Save/load in export UI | **WARNING** | Full New Game→save→continue in exported UI not driven here; RC `save_system` PASS; STORE/manual checklist still PENDING |

### Runtime / package hygiene

| Item | Status |
|---|---|
| Missing resources in ZIP | PASS |
| GodotIQ in package | PASS (absent) |
| Debug UI in title capture | PASS (none observed) |
| Stale player-facing `v2` | PASS |
| Notices encoding | WARNING — possible UTF-8 console mojibake on punctuation (prior) |

---

## Blocking issues

None for TECHNICAL READY.

~~Title version not player-visible~~ — **resolved** on recheck (onscreen + visual proof).

## Non-blocking issues

1. GodotIQ runtime tools unavailable after GodotIQRuntime removal — expected; used CLI/standalone evidence.  
2. KI-M27-01 still occurs on some headless suites after ALL PASS — accepted MINOR; exported exit clean.  
3. `release_integration` exit leaks ObjectDB/resources warnings — harness noise.  
4. THIRD_PARTY_NOTICES possible UTF-8 console mojibake on punctuation.  
5. Full manual exported route New Game→save→continue still environment-limited / PENDING.  
6. STORE READY / Steam overlay / production AppID remain PENDING (honest).  
7. Capture harness exit code 4 due to GDScript lambda scope — does not affect PNG evidence.

## Evidence index

| Path | What |
|---|---|
| `tmp/m28_qa/inspect_title_version_fix_out.txt` | Recheck: onscreen=true @ y=688 |
| `tmp/m28_qa/title_version_recheck_full.png` | Recheck visual: title + **v1.0.0** |
| `tmp/m28_qa/title_version_recheck_strip.png` | Recheck visual: bottom strip with **v1.0.0** |
| `tmp/m28_qa/capture_title_version_out.txt` | Capture log |
| `tmp/m28_qa/package_scan_recheck.txt` | Fresh ZIP list + SHA + forbid scan |
| `tmp/m28_qa/standalone_recheck.txt` | New ZIP outside-repo smoke exit=0 |
| `tmp/m28_qa/date_factory_boot_recheck.log` | New ZIP boot fields |
| `tmp/m28_qa/rc_suite.log` / `rc_summary.txt` | Prior RC 34/34 |
| `tmp/m28_qa/release_integration.log` | Prior Steam fail-open + ALL PASS |
| `dist/DateFactory_1.0.0_win64.zip` | Fresh release artifact (22:19:12) |
| `dist/release_manifest.json` | Manifest |
| `docs/release/RELEASE_STATUS.md` | TECHNICAL vs STORE |

## Reproduction steps (minimal)

1. Set `$env:GODOT` to Godot 4.7.1 console exe.  
2. `& $env:GODOT --path . --headless -s res://tmp/m28_qa/inspect_title_version_fix.gd` → expect `onscreen=true`, `y` &lt; 720.  
3. `& $env:GODOT --path . --quit-after 8 -s res://tmp/m28_qa/capture_title_version.gd` → open `title_version_recheck_full.png` / strip; require visible `v1.0.0`.  
4. Confirm `dist/DateFactory_1.0.0_win64.zip` fresh; list entries (required present, forbidden absent); SHA matches `.sha256`.  
5. Extract ZIP under `%TEMP%`, run `DateFactory.exe` without Steam/AppID, close → exit 0.

---

## Overall status

**TECHNICAL READY** for MODULE 28 technical acceptance.

Player-visible title version `v1.0.0` is proven (headless geometry + opened screenshots). Fresh Windows ZIP is clean (no GodotIQ), SHA-verified, and standalone boots with Steam fail-open. STORE READY remains out of scope / PENDING without production AppID.
