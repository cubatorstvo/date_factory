# File ownership — Visual Bootstrap (Donor / Asset Packs)

**Status:** in progress  
**Spec:** user TZ «VISUAL BOOTSTRAP ИЗ DONOR / ASSET PACKS» (executive, no redesign)

| Task id | Agent | Writable paths | Read-only dependencies | Forbidden | Status |
|---|---|---|---|---|---|
| VB-DOCS | Orchestrator | `docs/agent/OWNERSHIP.md`, `docs/agent/ACCEPTANCE.md`, `docs/agent/DECISIONS.md`, `docs/ASSET_LICENSES.md`, `docs/THIRD_PARTY_ASSETS.md` | donor RO | gameplay / location scenes | active |
| VB-A-legacy-shots | df-qa-worker | `tmp/visual_bootstrap_review/**`, `tmp/vb_legacy_capture_proj/**`, `tmp/vb_*.py`, `tmp/vb_*.gd` | `../date_factory_legacy` RO | `world/locations/**`, `project.godot`, gameplay | complete |
| VB-COPY-assets | df-asset-worker | `assets/environment/**`, `assets/props/**`, `assets/characters/**` (expand), `assets/animation/**` (expand), `world/art/**` (donor scene copies), license txt under assets | donor RO | gameplay scripts, balance, story | complete |
| VB-B-city | df-scene-worker | `world/locations/city_hub/city_hub.tscn`, `world/art/donor_import/city/**` (fixes only) | copied assets, World APIs RO | apartment/cafe/mine/lab/production `.tscn`, autoloads | complete |
| VB-C-room | df-scene-worker | `world/locations/apartment/apartment.tscn`, `world/art/donor_import/apartment/**` (fixes only) | copied assets | other location `.tscn` | complete |
| VB-D-cafe | df-scene-worker | `world/locations/cafe/cafe.tscn`, `world/art/donor_import/cafe/**` (fixes only) | copied assets | other location `.tscn`; must stay **cafe** not restaurant location | complete |
| VB-E1-mine | df-scene-worker | `world/locations/salary_mine/salary_mine.tscn` | `assets/environment/factory/kenney_factory/**` | other location `.tscn` | complete |
| VB-E2-lab | df-scene-worker | `world/locations/laboratory/laboratory.tscn` | `assets/environment/lab/**` | other location `.tscn` | complete |
| VB-E3-late | df-scene-worker | `world/locations/production_area/production_area.tscn` | factory + lab assets | other location `.tscn` | complete |
| VB-F-chars | df-scene-worker | `characters/female/**`, `characters/male/**` (new wrappers only), `data/content/appearances/*.tres` (visual_scene remap only), `tmp/visual_bootstrap_review/current/current_chars_*.png`, `tmp/vb_stage_f_*` | CharacterActor/Factory RO, pack meshes RO | girl_actor/rival_actor scripts, player.tscn, dating/story | complete |
| VB-G-verify | df-qa-worker | `tmp/visual_bootstrap_review/**`, `tmp/vb_stage_g_*`, `docs/agent/qa/VISUAL_BOOTSTRAP_STAGE_G_QA.md` | full game RO for play | product redesign, location art rewrites unless critical FAIL | complete |
| VB-REVIEW-BRANCH | Orchestrator | git branch `visual-review/bootstrap-20260809` for PNGs only | — | do not dump PNGs on main | complete |

## Serialization rules

1. **VB-COPY-assets** before B/C/D/E (shared `assets/`).
2. **One writer per `.tscn`** — never parallelize B/C/D/E on the same file.
3. B → C → D may run sequentially after copy; E1/E2/E3 sequential after D (or after copy if no shared scene files — still serialize to avoid asset import races).
4. Donor `../date_factory_legacy` is **READ-ONLY** forever.

One writer per file at a time.
