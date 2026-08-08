# Visual Playtest (development-only)

Development harness for scripted visual playthrough, state gallery, and UI layout audit after MODULE00–28.

This is **not** a gameplay module and is excluded from release export.

## Modes

```text
SCRIPTED PLAYTHROUGH   — production progression APIs; no stage/Reach/conquer cheats
VISUAL STATE GALLERY   — fixtures allowed for late visual states
HUMAN VERIFICATION REQUIRED
```

## Run

```powershell
$env:GODOT = "<godot-4.7.1-console>"
py -3 tools/visual_review/run_visual_playtest.py --all
```

Modes:

```text
--playthrough
--gallery
--layout
--all
```

Optional:

```text
--run-id <id>
--godot <path>
```

## Output

```text
_review/visual_playtest/<run_id>/
  report.md
  report.json
  1920x1080/
  1280x720/
  …
  contact_sheets/
  logs/
```

Generated PNGs must not live permanently on `main`. Publish on temporary branch `visual-review/<YYYYMMDD-HHMM>`.

## Layout RC regression

Headless centering invariants for Main Menu:

```powershell
py -3 tools/qa/run_all_tests.py --filter title_menu_layout
```

Full RC gate after visual fixes:

```powershell
py -3 tools/qa/run_all_tests.py --only-rc
```

## Harness files

- `game/visual_review/` — Godot runner, gallery, auditor, capture
- `tools/visual_review/run_visual_playtest.py` — multi-resolution wrapper
