# DATE FACTORY — Release Status

**Version:** 1.0.0  
**Engine:** Godot 4.7.1.stable  
**Platform target:** Windows 10+ x86_64 / Forward Plus / Steam-capable  
**Module:** MODULE 28 — Release Integration

## Two ready states

| State | Meaning | Current |
|---|---|---|
| **TECHNICAL READY** | Reproducible Windows package, fail-open Steam, logs, notices, RC QA green, schema v1 | **ACHIEVED** (MODULE 28) |
| **STORE READY** | Steamworks partner AppID, store page, depots, upload, signing, overlay/manual store checks | **PENDING** without production AppID / external Steam tasks |

Absence of a production Steam AppID does **not** block TECHNICAL READY / MODULE 28 completion.

## Gates

- Save schema: **1** (unchanged)
- Open BLOCKER: **0** (`release/release_gate.json`)
- Open MAJOR: **0**
- Accepted MINOR: `KI-M27-01` (headless teardown after ALL PASS)

## Steam

- Integration: GodotSteam GDExtension **4.20.1** + Steamworks redistributable **1.64**
- Fail-open without client/AppID
- No achievements / Cloud / Workshop / leaderboards / rich presence / telemetry / DRM
- Production AppID: **not invented** (not even Spacewar `480` as DF AppID)

## Manual / external PENDING

Mark honestly when not performed in environment:

- STEAM OVERLAY: MANUAL VERIFICATION REQUIRED (needs real AppID + Steam client)
- STORE page / depots / upload / Steam Pipe: PENDING EXTERNAL TASKS
- Code signing certificate: UNSIGNED unless external
- Full manual exported UI checklist (New Game → save → continue): PENDING if Cursor cannot drive exported UI

## KI-M27-01 disposition

Recheck on exported normal exit during MODULE 28 smoke.  
If exported exit is clean → keep as headless-only MINOR.  
If exported exit crashes → escalate to release BLOCKER.

## Implementation smoke (2026-08-08)

- RC: 34/34 PASS
- ZIP: dist/DateFactory_1.0.0_win64.zip
- Package scan: no GodotIQ / no steam_appid.txt; notices + steam_api64.dll + GodotSteam DLL present
- Standalone export: process starts; user://logs/date_factory.log boot fields OK; CloseMainWindow **exit=0**
- Outside-repo extract smoke: process starts; exit=0
- STEAM OVERLAY: MANUAL VERIFICATION REQUIRED (no production AppID)
- STORE READY: PENDING EXTERNAL TASKS
