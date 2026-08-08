# DATE FACTORY — Production Dependencies

Exact pins for Windows 1.0.0 release. Do not write “latest”.

| Dependency | Version | License | Location |
|---|---|---|---|
| Godot Engine | **4.7.1.stable** | MIT | Engine / export templates |
| GodotSteam GDExtension | **4.20.1** | MIT | `addons/godotsteam/` |
| Steamworks SDK (redistributable) | **1.64** | Valve / Steamworks SDK terms (**not MIT**) | `addons/godotsteam/win64/steam_api64.dll` (+ other platform redistributables) |
| Quaternius character/world packs | project-vendored snapshot | CC0 | see `docs/THIRD_PARTY_ASSETS.md`, `docs/ASSET_LICENSES.md` |
| Abstraction Music Loop Bundle | project-vendored snapshot | CC0 | `assets/audio/` + licenses |
| Kenney Interface / Impact / Jingles / Sci-Fi / world SFX | project-vendored snapshot | CC0 | `assets/audio/` + licenses |

Notes:

- Runtime never downloads dependencies.
- Steamworks redistributable DLLs are required for Steam-enabled exports; they remain under Valve terms.
- Full notice text: `release/THIRD_PARTY_NOTICES.txt`.
- Pin source note: `third_party/godotsteam/README.md`.
