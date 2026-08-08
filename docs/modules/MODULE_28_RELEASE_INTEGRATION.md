# MODULE 28 — RELEASE INTEGRATION

**Проект:** Date Factory  
**Модуль:** 28 — Release Integration  
**Статус:** финальный технический модуль  
**Предыдущий:** MODULE 27 — Full Game QA  
**Цель:** воспроизводимая Windows/Steam release-сборка, минимальная Steam-интеграция, локальные release-логи, упаковка, лицензии и финальный release gate.  
**Engine:** Godot 4.7.1 stable  
**Release version:** 1.0.0

---

# 0. ГРАНИЦА

MODULE 28 НЕ добавляет:

```text
gameplay
content
balance
stages
girls/rivals
perks
currencies
Steam achievements без утверждённого списка
Steam Cloud
Workshop
Leaderboards
Rich Presence
telemetry
remote crash uploader
DRM
```

Разрешено только:

```text
export/build
Steam bootstrap
release-safe platform handling
local logs
version metadata
third-party notices
package verification
release docs
```

---

# 1. INPUT GATE FROM MODULE 27

Подтвердить current facts:

```text
required RC suites: 33/33 PASS
BLOCKER: 0
MAJOR: 0
manual routes A–F: NOT EXECUTABLE IN ENVIRONMENT
```

Known accepted issue:

```text
KI-M27-01:
headless process can SIGSEGV during teardown AFTER explicit ALL PASS
severity MINOR
no known player-facing effect
```

Если этот crash воспроизводится при normal exported-game exit:

```text
это release BLOCKER
```

---

# 2. RELEASE TARGET

Exact first release:

```text
Windows 10+
x86_64
Godot 4.7.1.stable
Forward Plus
Steam
```

Не делать сейчас:

```text
Linux
macOS
Steam Deck-specific build
Win32
ARM64
```

---

# 3. VERSION / PLAYER-FACING METADATA

Set:

```text
application/config/version = "1.0.0"
config/name = "DATE FACTORY"
config/description = "Date Factory"
```

Убрать player-facing:

```text
Date Factory v2
```

Title menu bottom:

```text
v1.0.0
```

Version UI must read:

```text
ProjectSettings["application/config/version"]
```

No duplicated hardcoded version.

---

# 4. EXPORT PRESET

`export_presets.cfg` currently absent.

Create committed exact preset:

```text
Windows Release
```

Properties:

```text
platform = Windows Desktop
architecture = x86_64
release export
normal Godot 4.7.1 export templates
no debug console wrapper
Export all resources
default path = build/windows/DateFactory.exe
```

Preferred output:

```text
DateFactory.exe
DateFactory.pck
required native extension DLLs
```

Do not embed PCK solely to reduce file count.

---

# 5. WINDOWS ICON

Use existing:

```text
res://icon.svg
```

for Windows export/application icon.

Godot may generate ICO from SVG.

Acceptance:

```text
exported EXE/taskbar does not use default Godot icon
```

No redesign.

---

# 6. RELEASE EXCLUSIONS

Final runtime/package must not contain development-only content:

```text
.cursor/
.godotiq/
tmp/
docs/
qa/
tools/
game/**/test/
release test fixtures
steam_appid.txt
developer logs
```

Do not exclude anything production loads dynamically.

Verify actual package rather than trusting patterns blindly.

---

# 7. GODOTIQ — IMPORTANT CURRENT RELEASE ISSUE

Current project has:

```text
GodotIQRuntime
```

as runtime autoload.

GodotIQ is developer tooling and must not ship as game runtime.

Required final state:

```text
release runtime has no GodotIQ dependency
```

Preferred:

```text
remove GodotIQRuntime from production autoload
```

while editor addon can remain in repository if Cursor tooling still works.

If editor tooling needs it, use the smallest editor/debug-only solution.

Do NOT merely exclude addon files while leaving a broken autoload reference.

Release verifier must prove:

```text
GodotIQ runtime absent
```

---

# 8. FILE LOGGING

Enable desktop release logs:

```text
debug/file_logging/enable_file_logging.pc = true
debug/file_logging/log_path = "user://logs/date_factory.log"
debug/file_logging/max_log_files = 5
```

No remote upload.

Boot log once:

```text
DATE FACTORY
version=1.0.0
save_schema=1
Godot=<runtime>
OS=<name>
renderer=<renderer>
Steam=available/unavailable
```

Do not log:

```text
Steam identity
personal data
save contents
IP
```

---

# 9. STEAM — EXACT V1 SCOPE

Steam v1.0.0 supports only:

```text
initialization
availability status
safe standalone/no-Steam startup
safe Steam startup
overlay compatibility smoke
optional RestartAppIfNecessary if real AppID supplied
```

No other Steam feature.

---

# 10. ACHIEVEMENTS

There is no approved achievement list.

Therefore:

```text
Steam achievements = 0
```

Do not create placeholder AchievementManager/IDs/hooks.

---

# 11. STEAM DEPENDENCY AUDIT

Before adding dependency:

audit:

```text
current repo
../date_factory_legacy  # READ-ONLY
```

for compatible existing Steam integration.

Reuse only if:

```text
Godot4.7.1 compatible
license known
can be copied locally
does not pull legacy gameplay architecture
```

Otherwise use:

```text
GodotSteam GDExtension 4.20.1
Steamworks SDK 1.64
GodotSteam license MIT
```

Use **GDExtension + normal Godot export templates**.

Do not use custom GodotSteam engine/module templates.

Pin exact versions in docs.

---

# 12. THIRD-PARTY STEAM FILES

Vendor extension locally under a clear path, e.g.:

```text
third_party/godotsteam/
```

or upstream-required addon layout.

Runtime must never download dependencies.

Include upstream MIT license.

Document Steamworks redistributable separately; do not label Steamworks SDK as MIT.

---

# 13. STEAMBRIDGE

Create one compact autoload:

```text
SteamBridge
```

Responsibilities only:

```text
init Steam
report available
optional RestartAppIfNecessary
pump callbacks if selected GodotSteam API requires it
shutdown safely
```

No gameplay state.

Recommended autoload tail:

```text
SaveSystem
SteamBridge
AudioDirector
```

Exact order may follow actual API audit.

---

# 14. FAIL-OPEN STEAM RULE

If:

```text
Steam client absent
Steam init fails
AppID absent
overlay unavailable
```

then:

```text
SteamBridge.available = false
log warning/info
continue Main Menu/game normally
```

No blocking modal.

No gameplay/save dependency.

---

# 15. STEAM SUCCESS RULE

If init succeeds:

```text
SteamBridge.available = true
```

No gameplay reward.

Do not store Steam identity in save schema.

---

# 16. CALLBACKS

Use actual GodotSteam 4.20.1 API.

If explicit:

```text
Steam.run_callbacks()
```

is required, one lightweight SteamBridge process is allowed.

If current API handles callbacks internally:

do not poll unnecessarily.

No gameplay polling.

---

# 17. APPID — DO NOT INVENT

Current project does not contain real production AppID.

Do NOT hardcode:

```text
480
```

as Date Factory AppID.

AppID is external build/deployment input.

---

# 18. LOCAL `steam_appid.txt`

Local Steam smoke may temporarily create:

```text
steam_appid.txt
```

using:

```text
--steam-app-id <id>
or
DATE_FACTORY_STEAM_APP_ID
```

Developer may explicitly choose 480 for generic local Spacewar smoke.

But:

```text
steam_appid.txt MUST NOT be committed
steam_appid.txt MUST NOT be in final Steam depot/package
```

Add to `.gitignore`.

Package verifier fails if present.

---

# 19. REAL APPID CONFIG SEAM

Preferred simple build flow:

```text
tools/release/build_windows.py --steam-app-id <APPID>
```

build script temporarily creates:

```text
release/generated_steam_config.cfg
```

or equivalent generated ProjectSettings override.

Contains:

```text
app_id=<provided value>
```

Export includes config.

Generated source config is gitignored and removed after build.

No online config service.

---

# 20. RestartAppIfNecessary

Only when real AppID >0 is configured.

Flow:

```text
RestartAppIfNecessary(app_id)
if restart requested:
    quit current process
else:
    Steam init
```

Local `steam_appid.txt` behavior may suppress restart.

Standalone build with no AppID does not call restart.

---

# 21. STANDALONE MODE

Must support:

```text
Windows build with no Steam AppID
```

SteamBridge fails open.

This allows technical release QA without Steamworks credentials.

---

# 22. STEAM PACKAGE MODE

If AppID supplied:

record configured status in release manifest.

Final depot still excludes:

```text
steam_appid.txt
```

Steam client supplies context at launch.

---

# 23. STEAM OVERLAY SMOKE

If actual Steam environment/AppID available:

verify:

```text
Steam init
overlay opens
overlay closes
mouse capture recovers
WASD/E work
modal state not corrupted
```

If unavailable:

report exactly:

```text
STEAM OVERLAY: MANUAL VERIFICATION REQUIRED
```

Never fake PASS.

---

# 24. STEAM UNAVAILABLE SMOKE — MANDATORY

Exported build without usable Steam:

```text
Main Menu boots
New Game can start
SaveSystem works
no Steam symbol crash
no SCRIPT ERROR
```

This is a release gate.

---

# 25. NATIVE DEPENDENCY VERIFY

After export ensure actual selected GodotSteam dependencies exist.

Likely includes:

```text
GodotSteam native DLL
steam_api64.dll
```

Use actual upstream filenames.

Missing DLL = FAIL.

---

# 26. THIRD PARTY NOTICES

Create:

```text
release/THIRD_PARTY_NOTICES.txt
release/DEPENDENCIES.md
```

Include production dependencies:

```text
Godot Engine — MIT
GodotSteam — MIT
Steamworks redistributable — Valve/Steamworks terms
Quaternius — CC0
Abstraction Music Loop Bundle — CC0
Kenney assets — CC0
all other production external assets from docs/ASSET_LICENSES.md
```

Include full required MIT notices.

This does NOT make Date Factory source MIT.

Update:

```text
docs/ASSET_LICENSES.md
```

with exact GodotSteam version/license/source.

---

# 27. BUILD/DIST IGNORE

Add:

```text
build/
dist/
steam_appid.txt
release/generated_steam_config.cfg
```

Keep committed:

```text
export_presets.cfg
release/THIRD_PARTY_NOTICES.txt
release/DEPENDENCIES.md
release scripts/docs/examples
```

---

# 28. ONE-COMMAND BUILD

Create:

```text
tools/release/build_windows.py
```

Developer build:

```text
python tools/release/build_windows.py
```

Final gate:

```text
python tools/release/build_windows.py --release
```

Steam-configured:

```text
python tools/release/build_windows.py --release --steam-app-id <APPID>
```

---

# 29. GODOT CLI RESOLUTION

Remove committed developer-machine dependency from release tooling.

Resolution order:

```text
--godot <path>
GODOT env
PATH godot
PATH godot4
```

Do NOT require:

```text
C:\Users\User\Downloads\Godot...
```

Also update MODULE27 QA runner to the same portable resolver if practical.

Allowed tiny shared helper:

```text
tools/common/godot_cli.py
```

---

# 30. ENGINE VERSION GATE

Release builder runs:

```text
godot --version
```

Required:

```text
4.7.1
```

Wrong engine:

```text
FAIL release
```

Do not silently use 4.8/dev/nightly.

---

# 31. EXPORT TEMPLATE GATE

Verify Windows export templates available.

Missing:

```text
FAIL with actionable message
```

Do not auto-download/install templates.

---

# 32. PRE-BUILD QA

`--release` must run:

```text
python tools/qa/run_all_tests.py --only-rc
```

Build stops if required suite:

```text
FAIL
TIME
```

Known post-ALL-PASS headless teardown remains existing runner policy.

Do not `|| true`.

Do not hardcode test count 33; read manifest/summary.

---

# 33. RELEASE ISSUE GATE

Create machine-readable:

```text
release/release_gate.json
```

Example:

```json
{
  "blocker_open": 0,
  "major_open": 0,
  "accepted_minor_ids": ["KI-M27-01"]
}
```

Synchronize with QA docs.

`--release` fails if:

```text
blocker_open >0
major_open >0
```

---

# 34. CLEAN STAGING

Every build:

```text
delete/recreate build/staging/windows/
```

No stale DLL/PCK.

Export log:

```text
build/logs/export_windows.log
```

---

# 35. EXPORT COMMAND

Equivalent:

```text
godot --headless --path <repo> --export-release "Windows Release" <staging>/DateFactory.exe
```

Nonzero exit:

```text
FAIL
```

---

# 36. PACKAGE CONTENT

Copy notice into staging.

Required:

```text
DateFactory.exe
DateFactory.pck  # if separate
Steam/GodotSteam native DLLs
THIRD_PARTY_NOTICES.txt
```

Forbidden:

```text
steam_appid.txt
GodotIQ runtime
.cursor
.godotiq
test/QA loose files
editor executable
developer logs
```

Verifier owns exact actual required filenames after dependency audit.

---

# 37. ZIP + SHA

Generate:

```text
dist/DateFactory_1.0.0_win64.zip
dist/DateFactory_1.0.0_win64.zip.sha256
```

Preferred ZIP layout:

```text
DateFactory/
  DateFactory.exe
  DateFactory.pck
  DLLs
  THIRD_PARTY_NOTICES.txt
```

SHA file:

```text
<sha256>  DateFactory_1.0.0_win64.zip
```

---

# 38. RELEASE MANIFEST

Generate:

```text
dist/release_manifest.json
```

Fields:

```text
product
version
platform
arch
godot_version
git_commit
build_time_utc
save_schema
qa_required
qa_passed
steam_integration
steam_app_id_configured
code_signed
artifact
sha256
known_open_blocker
known_open_major
accepted_minor_ids
```

No secrets.

---

# 39. GIT TREE POLICY

Release build records:

```text
git commit SHA
```

`--release` preferred behavior:

```text
dirty tracked working tree → FAIL
```

Generated ignored files do not count.

Do not auto-commit/tag/push.

Recommended external tag later:

```text
v1.0.0
```

only if user explicitly chooses.

---

# 40. WINDOWS CODE SIGNING

No certificate is currently provided.

Do NOT invent one.

Signing:

```text
optional external release input
```

If Godot-supported environment credentials exist:

sign build.

Otherwise:

```text
code_signed=false
```

in manifest.

No credentials/passwords committed.

---

# 41. RELEASE FILE LOG SMOKE

Launch exported build standalone.

Verify latest:

```text
user://logs/date_factory.log
```

has release boot.

No:

```text
Parse Error
SCRIPT ERROR
missing production resource
Steam-extension crash
```

Steam unavailable info is allowed.

---

# 42. EXPORTED PROCESS SMOKE

Automated minimal:

```text
launch DateFactory.exe
process remains alive long enough to boot
release log created
Main Menu boot marker exists
no immediate crash
```

Do not add shipping debug commands just to automate clicking New Game.

---

# 43. MANUAL EXPORTED SMOKE

If Cursor cannot operate exported UI:

mark PENDING honestly.

Checklist:

```text
1. Extract ZIP outside repo.
2. Run DateFactory.exe without Steam.
3. Main Menu visible.
4. New Game → apartment.
5. Move / E / Phone.
6. Pause → Save slot1.
7. Exit.
8. Relaunch.
9. Continue restores.
10. Change FOV/UI/audio.
11. Exit normally.
12. Run in Steam test context if AppID exists.
13. Open/close overlay.
14. Verify mouse/input recovers.
```

No fake PASS.

---

# 44. CLEAN-FOLDER TEST

Copy/unzip build to a directory outside repository.

Expected:

```text
no res:// source dependency
no repo dependency
no donor dependency
boots normally
```

Mandatory automated/process smoke where feasible.

---

# 45. PATH WITH SPACES / NON-ASCII

Where practical run from:

```text
C:\Temp\Игры Date Factory\
```

Expected:

```text
boot
save/settings/log paths
```

work.

If environment cannot perform:

manual checklist.

---

# 46. MUTABLE FILE LOCATION

All mutable game state remains:

```text
user://saves/
user://settings.cfg
user://logs/
```

Game must not write into Steam/install folder.

---

# 47. SAVE COMPATIBILITY

Keep:

```text
SAVE_SCHEMA_VERSION = 1
```

No release-specific schema change.

Load existing MODULE24/27 schema-v1 save.

App version and save schema remain independent:

```text
app 1.0.0
schema 1
```

---

# 48. POST-ENDING SAVE

Release smoke fixture/check:

```text
FINALE completed save loads
no duplicate final reward
```

No Steam integration effect on save.

---

# 49. NORMAL EXIT VS KI-M27-01

Test exported normal exit:

```text
Title → Exit
Gameplay → Main Menu → Exit
post-ending → Main Menu → Exit
```

If normal release exits cleanly:

keep KI-M27-01 as headless-only accepted MINOR.

If exported build crashes on exit:

escalate/fix before release.

---

# 50. RELEASE-SPECIFIC TEST

Add small required test:

```text
release/test/release_integration_test.tscn
```

Validate:

```text
version ==1.0.0
save schema ==1
description no v2
GodotIQRuntime absent
THIRD_PARTY_NOTICES exists
SteamBridge fail-open without Steam
```

Add to QA manifest:

```text
module=M28
required_for_rc=true
```

Then required suite count becomes whatever manifest says, likely:

```text
34/34
```

Update QA docs with post-M28 recheck.

Do not preserve stale `33/33` as current final count.

---

# 51. HEADLESS STEAM SAFETY

SteamBridge must not make existing headless QA depend on Steam client.

If necessary skip Steam init under:

```text
headless
```

with clean unavailable state.

No Steam errors in QA logs.

---

# 52. PROJECT DEBUG TOOL SCAN

Final source/runtime gate:

```text
no production stage skip key
no grant XP/Money key
no spawn-clone cheat
no remote debug
```

Test-only fixtures may remain outside release package.

---

# 53. RELEASE PACKAGE SCAN

Final staging verifier checks:

```text
steam_appid.txt absent
GodotIQ absent
developer absolute paths absent in loose config
tmp/docs/tools absent
required DLLs present
notice present
```

Fail closed on forbidden files.

---

# 54. SYSTEM REQUIREMENTS — DO NOT INVENT

Create:

```text
docs/release/SYSTEM_REQUIREMENTS_DRAFT.md
```

Only verified baseline:

```text
Windows 10+
64-bit CPU
Vulkan-capable GPU required by Forward+
```

Do NOT invent exact GTX/CPU/RAM minimum without hardware QA.

Actual QA machine may be recorded as:

```text
tested configuration
```

not minimum.

---

# 55. STEAM RELEASE CHECKLIST

Create:

```text
docs/release/STEAM_RELEASE_CHECKLIST.md
```

Checklist:

```text
[ ] production AppID assigned
[ ] depot ID assigned
[ ] launch executable DateFactory.exe
[ ] Windows platform configured
[ ] build uploaded
[ ] Steam init smoke
[ ] overlay smoke
[ ] steam_appid.txt absent from depot
[ ] clean-machine smoke
[ ] save/restart smoke
[ ] store capsule/screenshots/trailer
[ ] description/tags/pricing
[ ] system requirements finalized
[ ] legal/privacy review
[ ] branch/package visibility
[ ] release controls
```

External unavailable items remain unchecked.

---

# 56. STEAM DEPOT TEMPLATES

Optional but recommended:

```text
release/steam/app_build.vdf.example
release/steam/depot_build_windows.vdf.example
```

Use placeholders:

```text
<APP_ID>
<DEPOT_ID>
```

No username/password.

No automatic Steam upload.

---

# 57. NO STORE CONTENT GENERATION

MODULE28 does not produce:

```text
capsule art
screenshots
trailer
Steam store copy
price
tags
tax/legal forms
```

Only checklist.

---

# 58. COMMON REDISTRIBUTABLES

Do not bundle random VC++/DirectX installers.

Steam Common Redistributables configuration remains external checklist unless clean-machine test proves one is required.

No custom installer.

---

# 59. RELEASE DEPOT LAYOUT

Preferred Steam depot root:

```text
DateFactory.exe
DateFactory.pck
GodotSteam dependency DLL(s)
steam_api64.dll
THIRD_PARTY_NOTICES.txt
```

No installer.

---

# 60. RELEASE STATUS DOCUMENT

Create:

```text
docs/release/RELEASE_STATUS.md
```

Statuses:

```text
PASS
PENDING
NOT CONFIGURED
N/A
FAIL
```

Fields:

```text
QA gate
Windows export
package verification
standalone process smoke
manual exported smoke
Steam dependency integrated
Steam AppID configured
Steam initialization
overlay
code signing
clean-machine smoke
Steam depot/store external tasks
```

---

# 61. TWO DIFFERENT READY STATES

## TECHNICAL RELEASE READY

Achieved when:

```text
all required QA pass
Blocker0/Major0
Windows export succeeds
package verification succeeds
standalone Steam-fail-open smoke succeeds
artifact/hash/manifest exist
```

## STORE RELEASE READY

Additionally requires external/manual:

```text
real Steam AppID
depot configuration/upload
Steam overlay smoke
clean-machine/manual smoke
store assets/legal
```

Do not conflate them.

---

# 62. NO APPID DOES NOT BLOCK MODULE COMPLETION

If production Steam AppID/credentials unavailable:

final report may correctly say:

```text
TECHNICAL RELEASE READY
STORE RELEASE PENDING EXTERNAL STEAM TASKS
```

This is successful MODULE28.

Do not invent credentials.

---

# 63. RELEASE BUILD DOC

Create:

```text
docs/release/RELEASE_BUILD.md
```

Sections:

```text
Prerequisites
Godot 4.7.1
export templates
Python3
Run RC QA
Build standalone Windows
Build with Steam AppID
Artifact structure
SHA verification
Steam local smoke
File logs
Code signing
KI-M27-01
```

No secrets.

---

# 64. DEPENDENCY DOC

`release/DEPENDENCIES.md` exact versions:

```text
Godot Engine 4.7.1
GodotSteam <actual chosen>
Steamworks SDK <actual chosen>
Quaternius
audio asset packs
```

Never write “latest”.

---

# 65. FINAL PROJECT DOCS

Update:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/ASSET_LICENSES.md
docs/qa/FULL_GAME_QA_REPORT.md
docs/qa/REGRESSION_MATRIX.md
docs/qa/KNOWN_ISSUES.md
```

Project status:

```text
After MODULE28 — Release Integration
MILESTONE G — Release Candidate
MODULE00–28 complete
```

External Steam deployment tasks listed separately.

---

# 66. BUILD SCRIPT OUTPUT

Final success summary:

```text
DATE FACTORY RELEASE BUILD

Version: 1.0.0
Commit: <sha>
Godot: 4.7.1
Platform: Windows x86_64

QA: <N>/<N> PASS
Blocker: 0
Major: 0

Steam: integrated
Steam AppID: configured / not configured
Signing: signed / unsigned

Artifact:
dist/DateFactory_1.0.0_win64.zip

SHA256:
<hash>

TECHNICAL RELEASE READY
STORE RELEASE: READY / PENDING EXTERNAL TASKS
```

---

# 67. DEFINITION OF DONE

- [ ] Module27 RC facts confirmed.
- [ ] Blocker0/Major0.
- [ ] Godot locked 4.7.1.
- [ ] Windows x86_64 only.
- [ ] application version1.0.0.
- [ ] player-facing `v2` removed.
- [ ] title reads version dynamically.
- [ ] committed `export_presets.cfg`.
- [ ] exact Windows Release preset.
- [ ] release templates, no debug console wrapper.
- [ ] icon correct.
- [ ] GodotIQ runtime absent from release.
- [ ] dev addon may remain repo-only.
- [ ] rotating file logs enabled at `user://logs/date_factory.log`.
- [ ] max logs5.
- [ ] boot version/platform/Steam status logged once.
- [ ] no remote telemetry.
- [ ] current/donor Steam audit done.
- [ ] compatible existing Steam reused OR pinned GodotSteam GDExtension vendored.
- [ ] exact dependency versions/licenses documented.
- [ ] SteamBridge exists.
- [ ] Steam fail-open works.
- [ ] no Steam gameplay/save state.
- [ ] no achievements.
- [ ] no Cloud/Workshop/Rich Presence.
- [ ] production AppID not invented.
- [ ] `steam_appid.txt` ignored and forbidden from release.
- [ ] optional AppID build seam exists.
- [ ] RestartAppIfNecessary only with configured AppID.
- [ ] Steam callbacks correct for actual version.
- [ ] no-Steam exported build boots.
- [ ] required Steam/GDExtension DLLs export correctly.
- [ ] GodotSteam MIT notice included.
- [ ] THIRD_PARTY_NOTICES complete.
- [ ] build/dist ignored.
- [ ] `build_windows.py` exists.
- [ ] no committed machine-specific Godot path required.
- [ ] Godot4.7.1 check.
- [ ] missing export templates fail clearly.
- [ ] `--release` runs all RC QA.
- [ ] build stops on QA failure.
- [ ] machine-readable Blocker/Major gate.
- [ ] clean staging.
- [ ] export log captured.
- [ ] package verifier.
- [ ] forbidden-file verifier.
- [ ] `DateFactory_1.0.0_win64.zip`.
- [ ] SHA256.
- [ ] release_manifest.json.
- [ ] git SHA recorded.
- [ ] dirty-tree release policy.
- [ ] no signing credentials committed.
- [ ] signing status recorded.
- [ ] standalone exported process smoke passes.
- [ ] build launches outside repo.
- [ ] mutable files stay under user://.
- [ ] save schema stays1.
- [ ] old schema-v1 save loads.
- [ ] required M28 release integration test exists.
- [ ] final full QA recheck passes.
- [ ] QA docs reflect new final suite count.
- [ ] STEAM_RELEASE_CHECKLIST exists.
- [ ] SYSTEM_REQUIREMENTS_DRAFT avoids invented hardware.
- [ ] optional VDF templates contain placeholders only.
- [ ] no Steam credentials committed.
- [ ] no automatic Steam upload.
- [ ] RELEASE_STATUS distinguishes technical/store ready.
- [ ] manual checks honestly PENDING if not performed.
- [ ] project docs mark MODULE00–28 complete.
- [ ] no gameplay/content/balance changes.

---

# 68. RECOMMENDED CURSOR ORDER

```text
1. Audit export/GodotIQ/current+legacy Steam integration.
2. Set version1.0.0; remove player-facing v2.
3. Remove/neutralize GodotIQ release runtime.
4. Enable rotating local logs.
5. Vendor pinned GodotSteam GDExtension only if needed.
6. Implement minimal fail-open SteamBridge.
7. Add AppID build seam + steam_appid ignore/forbid.
8. Add notices/dependency docs.
9. Create Windows Release export preset.
10. Make Godot CLI tooling portable, including QA runner.
11. Add M28 release integration test.
12. Run full QA after Steam/autoload changes.
13. Implement build_windows.py.
14. Clean export → verify → ZIP → SHA256 → manifest.
15. Run standalone exported smoke without Steam.
16. Test normal exit.
17. Run Steam init/overlay only if AppID/environment available; otherwise mark PENDING.
18. Verify extracted build outside repo.
19. Create RELEASE_BUILD / RELEASE_STATUS / Steam checklist / system requirements draft.
20. Update final QA/project docs.
21. STOP. MODULE00–28 complete.
```

---

# 69. CURSOR FINAL REPORT

## QA gate

Report final required suite count and result.

Confirm:

```text
Blocker0
Major0
KI-M27-01 disposition
```

## Platform/version

```text
Windows x86_64
Godot4.7.1
Date Factory1.0.0
save schema1
```

## Export

Show:
```text
Windows Release preset
staging layout
```

## GodotIQ

Explain final editor/release separation.

## Steam

State actual implementation/version.

Report exact:

```text
fail-open PASS/FAIL
AppID CONFIGURED / NOT CONFIGURED
Steam init PASS/PENDING
overlay PASS/PENDING
```

Confirm:

```text
achievements none
Cloud none
Workshop none
Rich Presence none
```

## Logging

```text
user://logs/date_factory.log
rotation5
no telemetry
```

## Package

Report:

```text
ZIP path
SHA256
release manifest
forbidden-file verification
third-party notices
Steam native dependency verification
```

## Build command

Show exact one-command final build.

## Exported smoke

Separate:

```text
automated process smoke
manual New Game/save/reload
normal exit
clean-folder
```

Use PASS/PENDING honestly.

## Steam deployment

Link `docs/release/STEAM_RELEASE_CHECKLIST.md`.

List only actually pending external tasks.

## Final state

Use:

```text
TECHNICAL RELEASE READY
```

if automated technical gates pass.

Separately:

```text
STORE RELEASE READY
```

or:

```text
STORE RELEASE PENDING EXTERNAL STEAM TASKS
```

## Commit

SHA.

Then STOP.

`MODULE 00–28` complete.
