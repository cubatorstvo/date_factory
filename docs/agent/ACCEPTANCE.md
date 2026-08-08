# ACCEPTANCE — MODULE 28 Release Integration

## Question
Can we produce a reproducible Windows 1.0.0 release package with fail-open Steam, no GodotIQ runtime, local logs, notices, and an honest technical vs store readiness gate?

## Input gate (MODULE 27)
- RC baseline: 33/33 → post-M28 **34/34** (added `release_integration`)
- BLOCKER=0, MAJOR=0
- Manual A–F: NOT EXECUTABLE IN ENVIRONMENT
- KI-M27-01: headless teardown MINOR; exported normal exit **exit=0** (not escalated)

## Evidence
- version `1.0.0`; description `Date Factory` (no player-facing `v2`)
- Title shows `v1.0.0` from ProjectSettings (onscreen; `tmp/m28_qa/title_version_recheck_full.png`)
- `export_presets.cfg` “Windows Release”
- GodotIQRuntime removed from production autoload; package scan FORBIDDEN_HITS=0
- SteamBridge fail-open; GodotSteam GDExtension 4.20.1 + Steamworks 1.64; AppID not invented
- `tools/release/build_windows.py` + portable `tools/common/godot_cli.py`
- ZIP + SHA256 + `dist/release_manifest.json` (gitignored artifacts; rebuildable)
- RC: **34/34 PASS**
- `docs/release/RELEASE_STATUS.md`: TECHNICAL READY vs STORE PENDING
- Independent QA: `docs/agent/qa/M28_QA.md` → TECHNICAL READY
- Schema **v1**; no gameplay/content/balance drift

## Verdict
**READY** (TECHNICAL READY)

STORE READY / Steam overlay / production AppID remain **PENDING** (do not block MODULE 28).

STOP — MODULE00–28 complete. Do not invent MODULE 29.
