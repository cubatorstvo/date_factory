# Release autotest runbook

Task: `RC-C001` / `RC-REGRESSION-FOUNDATION-001`  
Modes: `smoke` (fast contracts) and `full` (deterministic New Game → finale).  
Coverage: headless logical/API contracts only — **no visual coverage**.

Legacy `tools/smoke_test.gd` may still call `mark_met` and force stages — **not** evidence of the normal player route. Use `tests/release/**` only.

## Prerequisites

- Godot: `C:\godot\Godot_v4.7.1-stable_win64.exe`
- Project: `C:\Users\User\Documents\GodotProjects\date_factory`
- Writable artifacts: `tests/release/artifacts/`
- Do not edit production gameplay / UI / `project.godot` to make tests green

## Exact launch commands

```powershell
cd C:\Users\User\Documents\GodotProjects\date_factory

# SMOKE
powershell -ExecutionPolicy Bypass -File .\tests\release\run_release_tests.ps1 -Mode smoke

# FULL PROGRESSION
powershell -ExecutionPolicy Bypass -File .\tests\release\run_release_tests.ps1 -Mode full
```

Both:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\release\run_release_tests.ps1 -Mode both
```

Exit code: `0` only if selected mode(s) PASS; otherwise non-zero. Launcher prints `duration_sec` and kills leftover `tests/release` Godot processes for this project.

## Artifact paths

| Mode | Raw Godot log | Concise report |
|---|---|---|
| smoke | `tests/release/artifacts/smoke_godot.log` | `tests/release/artifacts/smoke_report.txt` |
| full | `tests/release/artifacts/full_godot.log` | `tests/release/artifacts/full_report.txt` |

Report fields include `result`, `duration_sec`, step list, and `failed_step` on FAIL.

## Direct Godot (optional)

```powershell
$Godot = "C:\godot\Godot_v4.7.1-stable_win64.exe"
$Proj  = "C:\Users\User\Documents\GodotProjects\date_factory"
$Art   = "$Proj\tests\release\artifacts"

& $Godot --headless --path $Proj --script "res://tests/release/run_smoke.gd" `
  --log-file "$Art\smoke_godot.log" --quit-after 120

& $Godot --headless --path $Proj --script "res://tests/release/run_full.gd" `
  --log-file "$Art\full_godot.log" --quit-after 300
```

## SMOKE contracts

- Project / autoloads / modules load
- ContentDB counts + critical scenes/scripts loadable
- New Game → `stage_1`, no QA profile marker
- No-save Continue disabled; with-save Continue enabled
- Normal `save_slot_1` save/load restores markers; QA slot untouched
- Unique discover/talk contracts (no auto-contact / no early algorithm)
- Arcade capacity ≠ cafe (`venue_id=arcade`)
- Soft check failures still fail the mode

## FULL contracts

- Deterministic accelerated route via production APIs only
- **Never** calls `GirlsAPI.mark_met` from the runner
- Does **not** write QA full-access into the normal save
- Test-only economy/time/date seeds live under `tests/release/harness/release_test_seed.gd` only
- Covers: apartment/city, shops/inventory, home+cafe+park+arcade booking, POI actions, unique talk→date→met, staff/clone when available, stage expand → Algorithm date → postgame save/load
- First failed step recorded as `failed_step=...`; process auto-quits non-zero

## Process hygiene

```powershell
Get-CimInstance Win32_Process |
  Where-Object { $_.Name -match "Godot" -and $_.CommandLine -match "date_factory" } |
  Select-Object ProcessId, CommandLine
```

## After production fixes

1. Re-run smoke (must stay green).
2. Re-run full; on FAIL read `failed_step` in `full_report.txt` + matching lines in `full_godot.log`.
3. Do not weaken assertions or reintroduce `mark_met` to force PASS.

## Explicitly not covered

- Visuals, input feel, audio mix
- District/room art presentation
- Windows export packaging (`RC-C002`)
