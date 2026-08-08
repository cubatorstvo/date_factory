# Steam Release Checklist (external)

This checklist is for **STORE READY** work. It does not block TECHNICAL READY.

## Partner / identity

- [ ] Production Steam AppID issued (do not invent; do not use 480 as DF AppID)
- [ ] Steamworks partner app configured
- [ ] Depot IDs assigned

## Build / package

- [ ] `py -3 tools/release/build_windows.py --release --steam-app-id <APPID>`
- [ ] ZIP SHA256 recorded
- [ ] Package scan: no `steam_appid.txt`, no GodotIQ, notices present, Steam DLLs present
- [ ] Code signing applied externally if required (`UNSIGNED` until then)

## Local Steam smoke

- [ ] Launch via Steam test/app
- [ ] SteamBridge.available == true
- [ ] Overlay open/close
- [ ] Mouse capture recovers
- [ ] WASD / E work after overlay
- [ ] Modal/UI state not corrupted

## Store

- [ ] Store page copy / capsules / age rating
- [ ] Build uploaded (manual Steam Pipe / partner tools — **no auto-upload from this repo**)
- [ ] Branches / depots verified
- [ ] Launch options verified

## Secrets

- Never commit Steam credentials, upload keys, or signing passwords.
- Never commit production `steam_appid.txt`.

## Optional VDF placeholders

See `docs/release/steam_vdf/` — placeholders only (`YOUR_APP_ID`, `YOUR_DEPOT_ID`).
