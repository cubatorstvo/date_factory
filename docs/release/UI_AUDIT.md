# Release UI audit

Status: functional framework exists; visual and resolution acceptance pending.

## Existing UI language

- Russian-primary player-facing copy.
- English DATE FACTORY brand is intentional.
- `UiStyle`, `ThemeFactory`, `DateFactoryTheme`, `UiLayers` and `UiEscape` form the canonical UI system.
- No second theme/framework will be introduced.

## Surface status

| Surface | Baseline | Required pass |
|---|---|---|
| Main menu | Themed RU | Restore normal Continue semantics; disabled without save |
| Pause/settings | Themed | Verify modal input, mouse and all resolutions |
| HUD/clock/toasts | Runtime-themed | Remove seed/debug leftovers; check obstruction |
| Phone/girls/schedule | Dense themed UI | Replace English seeds; verify 720p layout/focus |
| Shop overlays | Runtime-built theme | Consistent cards/buttons/disabled states |
| Inventory/gifts | Embedded in date flow | Replace placeholder icons; ensure clear ownership/counts |
| Date dialogue/result/end | Themed | Keep latest result visible; verify character framing |
| Events/reveal | Themed overlays | Verify Esc/modal ordering |
| District/elevator/gym/arcade/photo/barber/agency/clones | Runtime overlays | Align spacing, headings and close behavior |
| Finale/credits | Existing short overlay | Add clear completion summary, free play/menu and credits |

## Known defects

- `schedule`, `stats` and `offline` seed strings remain in English.
- Gift icons live under a placeholder path.
- No standalone world inventory screen was found; Orchestrator treats the existing gift/shop/date inventory surfaces as current scope unless player-route QA proves required items are inaccessible.
- Fixed minimum sizes and ItemList heights may fail at 720p.
- Stretch aspect is unset.
- Continue currently exposes QA state.
- Credits omit third-party packs.

## Visual standard

- Deep neutral panels with restrained warm/pink accent.
- One heading scale, one body scale and one compact metadata scale.
- Buttons must define normal, hover, pressed, disabled and focus states.
- Success, warning and error colors remain semantically consistent.
- Modal dim blocks world input.
- Text must remain readable without covering required character/date framing.
- No standard grey Godot button or debug label in the player route.

## Resolution acceptance

Required rendered/input checks:

1. 1280×720
2. 1920×1080
3. 2560×1440

For each: open/close every major overlay, keyboard/controller focus where supported, mouse capture restore, Esc stack, clipped text, scroll access and date-character visibility.

## Asset decision

Keep the current StyleBox theme. Import only selected CC0 Kenney game icons/input prompts/UI sounds where they replace placeholders or clarify controls. Do not wholesale reskin the game with an unrelated pack.

## Status

`NOT READY` until visual matrix and normal-route UI QA pass.
