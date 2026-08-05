# DATE FACTORY — Art Direction (Production Polish)

Критерии готовности UI/SFX/постановок и матрица приёмки: [09_PRESENTATION_QA.md](09_PRESENTATION_QA.md). Этот файл — токены и язык оформления.

## Fantasy
**"Romance Industry Luxury"** — сатира на романтическую индустрию как личную корпорацию героя: деньги, популярность, KPI любви, гиперроскошь и абсурдный масштаб (не «агентство для клиенток»).

## Palette
| Token | Hex | Use |
|-------|-----|-----|
| `bg_deep` | `#140C18` | Menus, dim overlays |
| `panel` | `#241828` | Panels / phone chrome |
| `panel_hi` | `#322036` | Raised cards |
| `stroke` | `#E8B86D` | Gold luxury outline |
| `accent` | `#FF4D8D` | CTA / love pulse |
| `accent_2` | `#6EE7FF` | Tech / automation |
| `ok` | `#5DDEA4` | Success |
| `warn` | `#FFB454` | Bottleneck / caution |
| `bad` | `#FF6B6B` | Error / scandal |
| `text` | `#F7F0E8` | Primary text |
| `text_dim` | `#B5A8B8` | Secondary |
| `money` | `#F0D078` | Currency |

Avoid flat purple-on-white. Dark plum panels + gold stroke + hot coral CTAs.

## Typography
- **Display:** Outfit Bold / SemiBold (titles, stage reveals, brand)
- **UI body:** DM Sans Regular / Medium / Bold
- Sizes: title 28–36, section 18–20, body 14–16, micro 12

## Panel language
- Rounded 12–16px panels, 2px gold hairline, soft inner glow (modulate)
- Buttons: filled accent (primary), stroke ghost (secondary), disabled desaturated
- Toasts: color-coded left bar (ok/warn/bad/money/story)
- Phone: “device” frame, not a naked TabContainer

## Motion
- UI open: 0.18–0.28s fade + scale 0.94→1
- Toasts: slide 0.2s
- Reveals (stage/girl/unlock): 1.5–3s skippable
- Date intro: spatial walk-in 4–6s skippable with click

## Audio identity
- Soft UI ticks (high short)
- Money: bright ascending
- Date: warm mid chord
- Scandal/warn: dissonant low
- Music: optional light bed under menus / dates (procedural or loop stubs)

## License notes
- Outfit, DM Sans: SIL Open Font License 1.1 (Google Fonts)
- SFX: project-generated procedural WAV stubs (replaceable)

## Temporary 3D
Capsule mannequins remain until final character art; presentation/polish must not wait for them. Defects for clone QA must stay readable on stubs (contrast hair, large clocks, clear gestures) — see [07_CLONES_AND_LEGEND.md](07_CLONES_AND_LEGEND.md).
