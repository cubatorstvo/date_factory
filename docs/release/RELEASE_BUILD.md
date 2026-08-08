# DATE FACTORY — Release Build

Windows 1.0.0 technical release packaging (MODULE 28).

## Prerequisites

- Godot **4.7.1.stable** editor/CLI
- Windows x86_64 **export templates** for `4.7.1.stable` installed under  
  `%APPDATA%\Godot\export_templates\4.7.1.stable\`  
  (builder fails clearly if missing; **does not** auto-download)
- Python 3
- Git (for commit SHA / dirty policy)

### Godot CLI resolution

Committed tools never hardcode a machine path.

Order:

1. `--godot <path>`
2. `GODOT` environment variable
3. PATH: `godot` then `godot4`

Example (PowerShell):

```powershell
$env:GODOT = "C:\path\to\Godot_v4.7.1-stable_win64_console.exe"
```

Shared helper: `tools/common/godot_cli.py`.

## Run RC QA

```powershell
$env:GODOT = "<godot-4.7.1-console>"
py -3 tools/qa/run_all_tests.py --only-rc
```

## Build standalone Windows

Developer export (no QA gate):

```powershell
py -3 tools/release/build_windows.py --godot $env:GODOT
```

Release gate (RC QA + package + ZIP):

```powershell
py -3 tools/release/build_windows.py --release --godot $env:GODOT
```

Dirty tracked tree fails `--release` unless `--allow-dirty` (status recorded in manifest).

## Build with Steam AppID

Do **not** invent a production AppID. When you have a real AppID:

```powershell
py -3 tools/release/build_windows.py --release --steam-app-id <APPID> --godot $env:GODOT
```

Builder writes gitignored `release/generated_steam_config.cfg`, exports, then deletes it.  
Final package must **not** contain `steam_appid.txt`.

## Artifact structure

```text
dist/DateFactory_1.0.0_win64.zip
dist/DateFactory_1.0.0_win64.zip.sha256
dist/release_manifest.json

ZIP layout:
DateFactory/
  DateFactory.exe
  DateFactory.pck
  steam_api64.dll / GodotSteam native DLL(s)
  THIRD_PARTY_NOTICES.txt
```

Staging: `build/staging/windows/`  
Export log: `build/logs/export_windows.log`

## SHA verification

```powershell
Get-FileHash dist\DateFactory_1.0.0_win64.zip -Algorithm SHA256
Get-Content dist\DateFactory_1.0.0_win64.zip.sha256
```

## Steam local smoke

Optional local Spacewar (`480`) is an explicit developer choice via `--steam-app-id` / `DATE_FACTORY_STEAM_APP_ID` — never treated as Date Factory AppID in docs or defaults.

Without AppID: SteamBridge fails open; game must boot standalone.

## File logs

Enabled:

```text
user://logs/date_factory.log
max_log_files = 5
```

Boot once logs: product, version, save_schema=1, Godot, OS, renderer, Steam=available|unavailable.  
No Steam identity / save contents / personal data.

## Code signing

No certificate is committed. Manifest records `code_signed=false` / `UNSIGNED` unless an external signing step is applied outside this repo.

## GodotIQ (editor only)

Committed `project.godot` for release **must not** list `GodotIQRuntime`.

The `addons/godotiq` addon + `editor_plugins` entry may remain for Cursor.  
`build_windows.py` temporarily disables the GodotIQ editor plugin during export so the plugin cannot re-add `GodotIQRuntime` into the packaged project settings, then restores `project.godot`.  
Release export also excludes `addons/godotiq/`; package verifier fails if GodotIQ markers appear in staging/PCK.

To re-enable GodotIQRuntime for Cursor after a clean release checkout:

1. Open project in Godot with GodotIQ addon enabled (`editor_plugins`).
2. The addon registers autoload `GodotIQRuntime` on enable (do not commit that autoload for production release trees).
3. Keep using CLI/`GODOT` for release QA when the runtime autoload is absent.

## KI-M27-01

Known headless post-`ALL PASS` teardown SIGSEGV is accepted MINOR if exported normal exit does not crash.  
Disposition is recorded in `docs/qa/KNOWN_ISSUES.md` and `docs/release/RELEASE_STATUS.md`.
