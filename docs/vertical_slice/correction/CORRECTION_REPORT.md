# DATE FACTORY — Vertical Slice Correction Pass

Date: 2026-08-04  
Evidence root: `docs/vertical_slice/correction/`

## Verdict

1. Full route apartment → street → restaurant → arrival → date → leave → FPS restore: **YES** (proven by Main-driven capture + quest `s1_date` completed).
2. Real seated pose on restaurant chair marker: **YES** (`alias=sit_idle`, `seated=true`, chair local `(0, 0.02, -1.15)`).
3. Main-gameplay screenshots: **19/19**.
4. Vertical-slice SCRIPT ERROR during final capture: **0** (GLES RID leak spam on CLI exit only).
5. Visual corrections applied: teleport hang, seating lock, pink Omni wash clamp, street spawn closer to route, transition sequencing.
6. Remaining: apartment empty mid-floor / open ceiling; street end still thin; restaurant still warm-pink; capsule city NPC placeholders; HUD density/polish incomplete.

## Fixes landed

| Area | Change |
|---|---|
| Transitions | Rewrote `TransitionOverlay.run_blackout`; removed static `await` teleports that could stall |
| Router | Teleport + date start use node-bound blackout callbacks; street spawn `(-32, 0.05, 2)` |
| Seating | DateStage uses restaurant `GirlSeat`/`GirlEntrance` markers; holds `sit_idle` while ready; freezes body velocity |
| Anim | `play_alias` sets `_is_seated` for sit aliases |
| Lighting | Lower evening sun energy; clamp/ remapped magenta Omni lights in mounted slice + date restaurant |

## Route proof

Capture tool: `tools/capture_correction_route.gd`  
Loads real `res://scenes/boot/main.tscn`, calls real `Interactable.on_interact`, drives DateUI buttons, saves viewport PNGs.

Raw log: `GODOT_STDOUT_STDERR.log` (stdout/stderr redirect, not hand-written).

## Remaining problems (honest)

- Apartment still reads sparse: large open floor, perimeter furniture, heavy beams, pink wall panels.
- Street still shows map end / block facades and capsule NPCs with labels.
- Restaurant/date lighting still warm-red; not fully neutralized.
- Trait-confirmed shot is taken at end of phase 3 when date closes; confirmation UI is brief.
- CLI GLES resource-leak lines on exit are renderer shutdown noise, not gameplay SCRIPT ERROR.
