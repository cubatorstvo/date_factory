# -*- coding: utf-8 -*-
"""Generate city_poi_refactor docs + contact sheets from analysis JSON. No city edits."""
from __future__ import annotations
import json
import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(r"C:\Users\User\Documents\GodotProjects\date_factory")
OUT = ROOT / "docs" / "city_poi_refactor"
SHOT = OUT / "hollow_shots"
CONTACT = OUT / "contact_sheets"
RAW = json.loads((OUT / "_analysis_raw.json").read_text(encoding="utf-8"))

B_SMALL = "res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf"
B_MED = "res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf"
B_LARGE = "res://assets/environment/city/downtown_megakit/meshes/Building_Large_2.gltf"
DOOR1 = "res://assets/environment/city/downtown_megakit/meshes/Door_1.gltf"

# Functional classification + progression (district unlock stage)
POIS = [
    # VenueEntrancePOI
    dict(poi_id="cafe_two_hearts", node="Buildings/CafeTwoHearts", marker="Markers/CafeEntrance",
         action_id="sit_cafe", district="main_street", stage="1 / start", func="VenueEntrancePOI",
         prefab="CafeTwoHearts.tscn", loadable="DateStage cafe", interior_need="no (entrance+seat)", mesh="Building_Medium"),
    dict(poi_id="park_restaurant", node="POIs/ParkRestaurant", marker="Markers/ParkRestaurantEntrance",
         action_id="sit_restaurant", district="park_leisure", stage="2 / park unlock", func="VenueEntrancePOI",
         prefab="ParkRestaurant.tscn", loadable="DateStage restaurant", interior_need="no", mesh="Building_Medium"),
    dict(poi_id="cinema", node="POIs/CinemaFacade", marker="Markers/CinemaEntrance",
         action_id="sit_cinema", district="park_leisure", stage="2 / park unlock", func="VenueEntrancePOI",
         prefab="CinemaFacade.tscn", loadable="DateStage cinema", interior_need="no", mesh="Building_Medium"),
    dict(poi_id="arcade", node="POIs/ArcadeFacade", marker="Markers/ArcadeEntrance",
         action_id="open_arcade+sit_arcade", district="park_leisure", stage="2 / park unlock", func="VenueEntrancePOI",
         prefab="ArcadeFacade.tscn", loadable="DateStage arcade / UI play", interior_need="optional walk-in later", mesh="Building_Small+screens"),
    dict(poi_id="player_home", node="Buildings/HomeFacade", marker="Markers/HomeEntrance",
         action_id="go_home", district="main_street", stage="1 / start", func="VenueEntrancePOI",
         prefab="PlayerHomeFacade.tscn", loadable="apartment scene", interior_need="no (travel)", mesh="Building_Small"),
    # StorefrontPOI
    dict(poi_id="flower_shop", node="POIs/FlowerShop", marker="Markers/FlowerEntrance",
         action_id="open_flower_shop", district="main_street", stage="1", func="StorefrontPOI",
         prefab="FlowerShop.tscn", loadable="UI shop only", interior_need="optional", mesh="Building_Small"),
    dict(poi_id="gift_shop", node="POIs/GiftShop", marker="Markers/GiftEntrance",
         action_id="open_gift_shop", district="main_street", stage="1", func="StorefrontPOI",
         prefab="GiftShop.tscn", loadable="UI shop only", interior_need="optional", mesh="Building_Small"),
    dict(poi_id="jewelry_shop", node="POIs/JewelryShop", marker="Markers/JewelryEntrance",
         action_id="open_jewelry_shop", district="main_street", stage="1", func="StorefrontPOI",
         prefab="JewelryShop.tscn", loadable="UI shop only", interior_need="optional", mesh="Building_Small"),
    dict(poi_id="clothing_shop", node="POIs/ClothingShop", marker="Markers/ClothingEntrance",
         action_id="open_clothing_shop", district="main_street", stage="1", func="StorefrontPOI",
         prefab="ClothingShop.tscn", loadable="UI shop only", interior_need="optional", mesh="Building_Small"),
    dict(poi_id="homeware_shop", node="POIs/HomewareShop", marker="Markers/HomewareEntrance",
         action_id="open_homeware_shop", district="main_street", stage="1", func="StorefrontPOI",
         prefab="HomewareShop.tscn", loadable="UI shop only", interior_need="optional", mesh="Building_Small"),
    dict(poi_id="bookstore", node="Buildings/BookstoreLeisure", marker="Markers/BookstoreEntrance",
         action_id="open_bookstore", district="park_leisure", stage="2", func="StorefrontPOI",
         prefab="BookstoreFacade.tscn", loadable="UI shop only", interior_need="optional", mesh="Building_Small"),
    dict(poi_id="gym", node="POIs/GymFacade", marker="Markers/GymEntrance",
         action_id="city_workout+city_gym_pass", district="park_leisure", stage="2", func="StorefrontPOI",
         prefab="GymFacade.tscn", loadable="UI only", interior_need="optional", mesh="Building_Medium"),
    dict(poi_id="internet_cafe", node="POIs/InternetCafe", marker="Markers/InternetCafeEntrance",
         action_id="city_cafe_job+city_cafe_scroll+city_coffee", district="main_street", stage="1", func="StorefrontPOI",
         prefab="InternetCafe.tscn", loadable="world interacts / UI", interior_need="preferred walk-in later", mesh="Building_Small"),
    dict(poi_id="bar", node="POIs/BarFacade", marker="Markers/BarEntrance",
         action_id="city_bar_drink", district="park_leisure", stage="2", func="StorefrontPOI",
         prefab="BarFacade.tscn", loadable="world interact", interior_need="optional", mesh="Building_Small"),
    dict(poi_id="photo_studio", node="POIs/PhotoStudio", marker="Markers/PhotoStudioEntrance",
         action_id="open_photo_studio", district="agency_row", stage="3 / agency unlock", func="StorefrontPOI",
         prefab="PhotoStudio.tscn", loadable="UI / venue photo", interior_need="optional", mesh="Building_Small"),
    dict(poi_id="barber", node="POIs/BarberShop", marker="Markers/BarberEntrance",
         action_id="open_barber", district="agency_row", stage="3", func="StorefrontPOI",
         prefab="BarberShop.tscn", loadable="UI", interior_need="optional", mesh="Building_Small"),
    dict(poi_id="agency_office", node="POIs/AgencyOffice", marker="Markers/AgencyOfficeEntrance",
         action_id="open_agency_board", district="agency_row", stage="3", func="StorefrontPOI",
         prefab="AgencyOffice.tscn", loadable="schedule board UI", interior_need="optional", mesh="Building_Medium"),
    # WorldActivityPOI
    dict(poi_id="main_bench", node="POIs/MainBench", marker="(node root)",
         action_id="city_rest", district="main_street", stage="1", func="WorldActivityPOI",
         prefab="MainBench.tscn", loadable="none", interior_need="n/a", mesh="Environment_Bench"),
    dict(poi_id="park_bench", node="POIs/ParkBench", marker="(node root)",
         action_id="city_rest", district="park_leisure", stage="2", func="WorldActivityPOI",
         prefab="ParkBench.tscn", loadable="none", interior_need="n/a", mesh="Environment_Bench"),
    dict(poi_id="duck_feeding", node="POIs/DuckFeeding", marker="(node root)",
         action_id="city_park_fun", district="park_leisure", stage="2", func="WorldActivityPOI",
         prefab="DuckFeeding.tscn", loadable="none", interior_need="n/a", mesh="props/planters"),
    dict(poi_id="karaoke", node="POIs/KaraokeStand", marker="(node root)",
         action_id="city_karaoke", district="park_leisure", stage="2", func="WorldActivityPOI",
         prefab="KaraokeStand.tscn", loadable="none", interior_need="n/a", mesh="desk+screen"),
    dict(poi_id="bus_stop_candy", node="POIs/BusStopCandy", marker="Markers/BusStop",
         action_id="city_bus_info+city_buy_gift", district="agency_row", stage="3", func="WorldActivityPOI",
         prefab="BusStopCandy.tscn", loadable="none", interior_need="n/a", mesh="props+machine"),
    dict(poi_id="park_picnic", node="Markers/ParkPicnicSpot", marker="Markers/ParkPicnicSpot",
         action_id="sit_park", district="park_leisure", stage="2", func="VenueEntrancePOI",
         prefab="(marker + bench cluster)", loadable="DateStage park", interior_need="n/a outdoor", mesh="WorldActivity seating"),
]

prefab_by_name = {p["name"]: p for p in RAW.get("prefabs", [])}
building_by_name = {b["name"]: b for b in RAW.get("buildings", [])}


def font(size=18):
    for fp in [
        r"C:\Windows\Fonts\arial.ttf",
        r"C:\Windows\Fonts\calibri.ttf",
        r"C:\Windows\Fonts\segoeui.ttf",
    ]:
        if os.path.exists(fp):
            return ImageFont.truetype(fp, size)
    return ImageFont.load_default()


def label_image(src: Path, dest: Path, lines: list[str], width=1100):
    if not src.exists():
        img = Image.new("RGB", (width, 420), (40, 44, 52))
    else:
        base = Image.open(src).convert("RGB")
        ratio = width / base.width
        base = base.resize((width, int(base.height * ratio)), Image.Resampling.LANCZOS)
        img = Image.new("RGB", (width, base.height + 110), (24, 26, 30))
        img.paste(base, (0, 0))
    draw = ImageDraw.Draw(img)
    band_y = img.height - 110
    draw.rectangle([0, band_y, img.width, img.height], fill=(18, 20, 24))
    f = font(16)
    y = band_y + 8
    for line in lines:
        draw.text((12, y), line, fill=(235, 238, 245), font=f)
        y += 22
    dest.parent.mkdir(parents=True, exist_ok=True)
    img.save(dest)


def contact_sheet(paths_labels: list[tuple[Path, list[str]]], out: Path, cols=2, cell_w=900):
    tiles = []
    for src, lines in paths_labels:
        tmp = OUT / "_tmp_tile.png"
        label_image(src, tmp, lines, width=cell_w)
        tiles.append(Image.open(tmp).convert("RGB"))
    if not tiles:
        return
    rows = (len(tiles) + cols - 1) // cols
    th = max(t.height for t in tiles)
    tw = cell_w
    sheet = Image.new("RGB", (cols * tw + 20, rows * th + 20), (12, 14, 18))
    for i, t in enumerate(tiles):
        r, c = divmod(i, cols)
        sheet.paste(t, (10 + c * tw, 10 + r * th))
    sheet.save(out)
    print("SHEET", out)


def write(name: str, text: str):
    p = OUT / name
    p.write_text(text, encoding="utf-8")
    print("WRITE", p, "bytes", p.stat().st_size)


# --- docs ---

def doc_inventory():
    lines = ["# POI Inventory\n", "Источник: Stage5 layout + `complex_world.gd` + prefab tree scan. `city.tscn` не изменялся.\n"]
    for p in POIS:
        pref = prefab_by_name.get(Path(p["prefab"]).stem if p["prefab"].endswith(".tscn") else "", {})
        ext = pref.get("external_instances", [])
        meshes = [e.get("scene", "") for e in ext]
        lights = pref.get("lights", [])
        labels = pref.get("labels", [])
        collision = pref.get("collision", [])
        areas = pref.get("areas", [])
        anchors = pref.get("anchors", [])
        lines += [
            f"## `{p['poi_id']}`\n",
            f"- **NodePath (в City visual):** `{p['node']}`\n",
            f"- **Entrance / marker:** `{p['marker']}`\n",
            f"- **action_id:** `{p['action_id']}`\n",
            f"- **district_id:** `{p['district']}`\n",
            f"- **стадия прогрессии:** {p['stage']}\n",
            f"- **функциональный тип:** `{p['func']}`\n",
            f"- **текущий prefab:** `res://scenes/art/city/prefabs/{p['prefab']}`\n",
            f"- **building/mesh сейчас:** {p['mesh']}; instances: {meshes[:6]}\n",
            f"- **коллизии:** внутри prefab — {collision[:6] or 'нет CollisionShape3D в prefab (часто только visual + runtime interact на маркере)'}\n",
            f"- **взаимодействие:** Area/Interact создаётся runtime у маркера в `complex_world._bind_city_art_interactions` (не внутри packed interactable)\n",
            f"- **anchors:** {anchors[:8] or 'Anchors/* если есть в prefab; иначе только city Markers'}\n",
            f"- **вывески:** Label3D/CSG — {labels[:4] or 'CSG SignBoard / SignText в Visuals'}\n",
            f"- **локальный свет:** {lights[:4] or 'OmniLight3D в Visuals (если есть) / отсутствует'}\n",
            f"- **вне корня POI:** city Markers, runtime Interact nodes на City root, district gates, streets/nav\n",
            f"- **перенести внутрь будущей сцены:** visual building + DoorAnchor + collision capsule/box у двери + InteractionArea + signage + local lights + props; marker sync optional\n",
            f"- **отдельная загружаемая сцена:** {p['loadable']}\n",
            f"- **нужен физический интерьер:** {p['interior_need']}\n",
        ]
    write("POI_INVENTORY.md", "".join(lines))


def doc_catalog():
    lines = [
        "# Building Asset Catalog\n",
        "Фактический осмотр downtown megakit `Building_*` (Godot AABB + interior cameras + ray probes).\n",
        "В проекте сейчас только **3 целых здания**. Остальной megakit — модульный кирпич/двери/пропы.\n\n",
    ]
    for b in RAW["buildings"]:
        sz = b.get("aabb_size", [0, 0, 0])
        lines += [
            f"## `{b['name']}`\n",
            f"- **path:** `{b['path']}`\n",
            f"- **AABB size (unit scale):** {sz[0]:.3f} × {sz[1]:.3f} × {sz[2]:.3f} m\n",
            f"- **visual floors estimate (÷3.2m):** {b.get('visual_floors_estimate')}\n",
            f"- **отдельные входы (named door nodes):** {b.get('door_guess', {}).get('named_doors') or 'нет — дверь в baked facade'}\n",
            f"- **положение двери/арки:** front_face_center_guess={b.get('door_guess', {}).get('front_face_center_guess')}; использовать `Door_*` prop или DoorAnchor перед визуальным проёмом\n",
            f"- **фронт:** условно +Z AABB (уточнять при посадке по силуэту окон)\n",
            f"- **полое?** ray interior_probe_hits={b.get('interior_probe_hits')} / open_sky={b.get('open_sky_probes')} — **не полое как walk-in объём**\n",
            f"- **внутреннее пространство пригодно?** нет (камера “interior” упирается в фасад/пустоту без пола/потолков как gameplay volume)\n",
            f"- **пол/стены/потолок внутри:** mesh shell без collision; probes ceiling/floor = false\n",
            f"- **открыта задняя сторона:** визуально фасадный объём; не использовать как комнату без доработки\n",
            f"- **войти игроком?** только после добавления кастомных collision + interior occluders / или отказаться\n",
            f"- **прилавок внутри?** не рекомендуется на текущей модели\n",
            f"- **лестница/переход?** нет готового; MultiTenant потребует внешние StairTransitionPOI или отдельные DoorAnchors на фасаде\n",
            f"- **DedicatedBuilding:** да\n",
            f"- **MultiTenantBuilding:** {b.get('multi_tenant_ok')} по габариту, но только как несколько фасадных DoorAnchors, не этажи-интерьеры\n",
            f"- **HollowWalkInBuilding:** **нет** на текущих данных\n",
            f"- **проблемы импорта:** has_collision_shapes={b.get('has_collision_shapes')}; mesh_instance_count={b.get('mesh_instance_count')}\n",
            f"- **shots:** {', '.join(b.get('shots', []))}\n\n",
        ]
    lines += [
        "## Двери / рамы\n",
    ]
    for d in RAW.get("doors", []):
        if not d.get("exists"):
            continue
        sz = d.get("aabb_size", [0, 0, 0])
        lines.append(f"- `{d['path']}` AABB≈{sz}\n")
    lines += [
        "\n## Модульный megakit (не целые здания)\n",
        "- `Brick_*`, `Sidewalk_*`, `Prop_*` — можно собрать кастомный hollow storefront (высокая сложность).\n",
        "- Не считать готовым HollowWalkInBuilding без отдельного build pipeline.\n",
        "\n## Прочие наборы\n",
        "- `sushi_restaurant` Environment_* — прилавки/столы/стулья для storefront props.\n",
        "- `kenney_factory` screens/machine — аркада/агентство/караоке (не здания).\n",
        "- `scifi_essentials` desk/shelves/chair — барбер/офис props.\n",
    ]
    write("BUILDING_ASSET_CATALOG.md", "".join(lines))


def doc_assignment():
    lines = ["# POI Asset Assignment (варианты для утверждения)\n",
             "Повтор ассетов неизбежен: в репо только 3 Building_*. Повтор допустим только с разным scale/yaw/sign/light/prop kit.\n\n"]

    def variants(poi, opts):
        lines.append(f"## `{poi}`\n")
        for i, o in enumerate(opts, 1):
            lines.append(
                f"### Вариант {i}{' ★ recommend' if o.get('rec') else ''}\n"
                f"- asset: `{o['asset']}`\n"
                f"- режим: `{o['mode']}`\n"
                f"- дверь/арка: {o['door']}\n"
                f"- этажность: {o['floors']}\n"
                f"- multi-tenant: {o['mt']}\n"
                f"- партнёры: {o['partners']}\n"
                f"- совместимость: {o['why']}\n"
                f"- стадии: {o['stages']}\n"
                f"- lock closed tenant: {o['lock']}\n"
                f"- отличие от соседей: {o['diff']}\n"
                f"- сложность: **{o['diffc']}**\n"
                f"- повтор ассета: {o.get('reuse', 'n/a')}\n\n"
            )

    variants("cafe_two_hearts", [
        dict(asset=B_MED, mode="DedicatedBuilding / FacadeOnlyBuilding", door="Door_1 перед baked opening", floors="visual 2–3 @scale0.45",
             mt="нет", partners="—", why="якорь main_street", stages="1", lock="n/a",
             diff="розовая вывеска TWO HEARTS + warm omni + outdoor table", diffc="низкая", rec=True,
             reuse="Medium часто; cafe получает уникальный sign/awning/props"),
        dict(asset=B_LARGE, mode="DedicatedBuilding", door="Door_1", floors="крупный landmark", mt="нет", partners="—",
             why="максимальная узнаваемость", stages="1", lock="n/a", diff="самый крупный силуэт на улице", diffc="средняя",
             reuse="Large редкий — лучше сохранить для cinema/agency"),
        dict(asset=B_SMALL, mode="FacadeOnlyBuilding", door="Door_1", floors="1–2", mt="нет", partners="—",
             why="компактнее", stages="1", lock="n/a", diff="слабее как landmark", diffc="низкая"),
    ])
    variants("park_restaurant", [
        dict(asset=B_MED, mode="DedicatedBuilding / FacadeOnly", door="Door_2", floors="2", mt="нет", partners="—",
             why="venue stage2", stages="2", lock="district gate", diff="PARK BISTRO sign + warm light", diffc="низкая", rec=True,
             reuse="тот же Medium что cafe — другой yaw/district/sign/props"),
        dict(asset=B_LARGE, mode="DedicatedBuilding", door="Door_2", floors="3", mt="возможно + bar", partners="bar (тот же district)",
             why="крупный night/food hub", stages="2", lock="если bar отдельно — отдельный DoorAnchor", diff="крупнее cinema", diffc="средняя"),
        dict(asset=B_SMALL, mode="FacadeOnly", door="Door_1", floors="1", mt="нет", partners="—", why="бюджетный", stages="2", lock="n/a", diff="слабый", diffc="низкая"),
    ])
    variants("cinema", [
        dict(asset=B_LARGE, mode="DedicatedBuilding / FacadeOnly", door="Door_3 wide", floors="3 visual", mt="нет", partners="—",
             why="нужен уникальный силуэт", stages="2", lock="district", diff="wide door + neon posters + marquee CSG", diffc="средняя", rec=True,
             reuse="Large #1 priority for cinema"),
        dict(asset=B_MED, mode="FacadeOnly", door="Door_2", floors="2", mt="с gift? нет — разные районы", partners="—",
             why="если Large занят agency", stages="2", lock="district", diff="постеры/неон", diffc="низкая"),
        dict(asset=B_LARGE, mode="MultiTenantBuilding (фасадные DoorAnchors)", door="ground Door_3 + side Door_1", floors="ground cinema / upper unused locked",
             mt="да: cinema + optional gift kiosk только если gift переносится в park — не рекомендуется",
             partners="не рекомендовать gift", why="риск путаницы", stages="2", lock="верхний DoorAnchor закрыт prop door",
             diff="сложнее без выигрыша", diffc="высокая"),
    ])
    variants("arcade", [
        dict(asset=B_SMALL, mode="FacadeOnly + awning props", door="Door_1", floors="1", mt="нет", partners="—",
             why="screen props уже есть", stages="2", lock="district", diff="kenney screens + neon", diffc="низкая", rec=True,
             reuse="Small часто; screens делают уникальность"),
        dict(asset=B_MED, mode="Dedicated", door="Door_1", floors="2", mt="нет", partners="—", why="крупнее", stages="2", lock="district", diff="сильнее", diffc="средняя"),
        dict(asset="WorldActivity awning + machines (без building)", mode="WorldActivityPOI cluster", door="n/a", floors="0",
             mt="n/a", partners="—", why="если не хватает зданий", stages="2", lock="district", diff="не здание", diffc="средняя"),
    ])
    variants("flower_shop", [
        dict(asset=B_SMALL, mode="FacadeOnlyBuilding", door="Door_1", floors="1", mt="нет", partners="—",
             why="storefront", stages="1", lock="n/a", diff="plants + pink awning", diffc="низкая", rec=True,
             reuse="Small shared; identity via plants/sign"),
        dict(asset=B_SMALL, mode="MultiTenantBuilding с gift_shop", door="две Door_* side-by-side", floors="1 shared facade",
             mt="да flower+gift", partners="gift_shop", why="оба stage1 main_street retail", stages="1+1",
             lock="не нужен", diff="две вывески на одном Small — тесно", diffc="средняя"),
        dict(asset="modular Brick storefront (custom)", mode="HollowWalkInBuilding", door="arch Brick", floors="1",
             mt="нет", partners="—", why="реальный walk-in", stages="1", lock="n/a", diff="уникальный", diffc="высокая"),
    ])
    variants("gift_shop", [
        dict(asset=B_SMALL, mode="FacadeOnly", door="Door_1", floors="1", mt="нет", partners="—", why="retail", stages="1", lock="n/a",
             diff="gift props/sign", diffc="низкая", rec=True, reuse="Small; другой accent color"),
        dict(asset=B_SMALL, mode="MultiTenant с flower", door="shared", floors="1", mt="да", partners="flower_shop",
             why="совместимо", stages="1", lock="n/a", diff="сдвоенная витрина", diffc="средняя"),
        dict(asset=B_MED, mode="Dedicated", door="Door_1", floors="2", mt="нет", partners="—", why="если нужен крупный gift hub", stages="1", lock="n/a", diff="крупнее", diffc="средняя"),
    ])
    variants("jewelry_shop", [
        dict(asset=B_SMALL, mode="FacadeOnly", door="Door_2", floors="1", mt="нет", partners="—", why="retail", stages="1", lock="n/a",
             diff="gold accent band + glass props", diffc="низкая", rec=True, reuse="Small"),
        dict(asset=B_SMALL, mode="MultiTenant с clothing", door="две двери", floors="1", mt="да", partners="clothing_shop",
             why="fashion cluster", stages="1", lock="n/a", diff="fashion strip", diffc="средняя"),
        dict(asset=B_MED, mode="Dedicated", door="Door_2", floors="2", mt="нет", partners="—", why="premium silhouette", stages="1", lock="n/a", diff="крупнее", diffc="средняя"),
    ])
    variants("clothing_shop", [
        dict(asset=B_SMALL, mode="FacadeOnly", door="Door_1", floors="1", mt="нет", partners="—", why="retail", stages="1", lock="n/a",
             diff="wardrobe prop + color", diffc="низкая", rec=True, reuse="Small"),
        dict(asset=B_SMALL, mode="MultiTenant jewelry", door="dual", floors="1", mt="да", partners="jewelry_shop", why="fashion", stages="1", lock="n/a", diff="paired", diffc="средняя"),
        dict(asset=B_MED, mode="Dedicated", door="Door_1", floors="2", mt="нет", partners="—", why="flagship", stages="1", lock="n/a", diff="крупнее", diffc="средняя"),
    ])
    variants("homeware_shop", [
        dict(asset=B_SMALL, mode="FacadeOnly", door="Door_1", floors="1", mt="нет", partners="—", why="retail", stages="1", lock="n/a",
             diff="shelf props", diffc="низкая", rec=True, reuse="Small"),
        dict(asset=B_SMALL, mode="MultiTenant с homeware+internet? нет", door="—", floors="1", mt="не рек.", partners="internet_cafe",
             why="разный UX (shop UI vs terminals)", stages="1", lock="—", diff="путаница", diffc="высокая"),
        dict(asset=B_MED, mode="Dedicated", door="Door_1", floors="2", mt="нет", partners="—", why="крупный", stages="1", lock="n/a", diff="силуэт", diffc="средняя"),
    ])
    variants("bookstore", [
        dict(asset=B_SMALL, mode="FacadeOnly", door="Door_1", floors="1", mt="нет", partners="—", why="leisure retail", stages="2", lock="district",
             diff="bookshelf + blue awning", diffc="низкая", rec=True, reuse="Small"),
        dict(asset=B_MED, mode="MultiTenant bookstore ground + cinema upper? ", door="ground Door_1 / upper locked",
             floors="2", mt="книжный+кино — разные здания лучше", partners="cinema", why="тематика слабо; cinema теряет uniqueness",
             stages="2+2", lock="верхний вход prop-door", diff="плохо для cinema landmark", diffc="высокая"),
        dict(asset=B_SMALL, mode="MultiTenant bookstore+gym? нет", door="—", floors="1", mt="не рек.", partners="gym",
             why="несовместимо тематически", stages="2", lock="—", diff="—", diffc="высокая"),
    ])
    variants("gym", [
        dict(asset=B_MED, mode="FacadeOnly", door="Door_1", floors="2", mt="нет", partners="—", why="machine prop identity", stages="2", lock="district",
             diff="kenney machine + posters", diffc="низкая", rec=True, reuse="Medium"),
        dict(asset=B_LARGE, mode="Dedicated", door="Door_2", floors="3", mt="нет", partners="—", why="спорт landmark", stages="2", lock="district", diff="крупный", diffc="средняя"),
        dict(asset=B_SMALL, mode="FacadeOnly", door="Door_1", floors="1", mt="нет", partners="—", why="компакт", stages="2", lock="district", diff="слабее", diffc="низкая"),
    ])
    variants("internet_cafe", [
        dict(asset=B_SMALL, mode="FacadeOnly (+ later Hollow custom)", door="Door_1", floors="1", mt="нет", partners="—",
             why="multiple terminal interacts", stages="1", lock="n/a", diff="PC desks outside/under awning", diffc="низкая", rec=True, reuse="Small"),
        dict(asset="modular hollow", mode="HollowWalkInBuilding", door="arch", floors="1", mt="нет", partners="—",
             why="лучшие терминалы внутри", stages="1", lock="n/a", diff="уникальный walk-in", diffc="высокая"),
        dict(asset=B_MED, mode="Dedicated", door="Door_1", floors="2", mt="нет", partners="—", why="крупнее", stages="1", lock="n/a", diff="силуэт", diffc="средняя"),
    ])
    variants("bar", [
        dict(asset=B_SMALL, mode="FacadeOnly", door="Door_1", floors="1", mt="нет", partners="—", why="night leisure", stages="2", lock="district",
             diff="warm/red light + counter", diffc="низкая", rec=True, reuse="Small"),
        dict(asset=B_MED, mode="MultiTenant bar ground + karaoke annex", door="Door_1", floors="1–2", mt="bar + karaoke world activity рядом лучше отдельно",
             partners="karaoke (рядом, не внутри)", why="karaoke WorldActivity", stages="2", lock="n/a", diff="кластер", diffc="средняя"),
        dict(asset=B_LARGE, mode="Dedicated", door="Door_2", floors="2", mt="нет", partners="—", why="club silhouette", stages="2", lock="district", diff="крупный", diffc="средняя"),
    ])
    variants("photo_studio", [
        dict(asset=B_SMALL, mode="FacadeOnly", door="Door_1", floors="1", mt="нет", partners="—", why="agency row", stages="3", lock="agency gate",
             diff="screen-panel + posters", diffc="низкая", rec=True, reuse="Small"),
        dict(asset=B_MED, mode="MultiTenant photo + barber", door="две двери на фасаде", floors="1", mt="да", partners="barber",
             why="оба stage3 agency services", stages="3+3", lock="не нужен", diff="services strip", diffc="средняя"),
        dict(asset=B_MED, mode="Dedicated", door="Door_1", floors="2", mt="нет", partners="—", why="studio landmark", stages="3", lock="gate", diff="крупнее", diffc="средняя"),
    ])
    variants("barber", [
        dict(asset=B_SMALL, mode="FacadeOnly", door="Door_1", floors="1", mt="нет", partners="—", why="service", stages="3", lock="gate",
             diff="chair/desk props + stripe pole CSG", diffc="низкая", rec=True, reuse="Small"),
        dict(asset=B_SMALL, mode="MultiTenant с photo", door="dual", floors="1", mt="да", partners="photo_studio", why="agency services", stages="3", lock="n/a", diff="paired", diffc="средняя"),
        dict(asset=B_MED, mode="Dedicated", door="Door_1", floors="2", mt="нет", partners="—", why="крупный", stages="3", lock="gate", diff="силуэт", diffc="средняя"),
    ])
    variants("agency_office", [
        dict(asset=B_MED, mode="DedicatedBuilding / FacadeOnly", door="Door_2", floors="2–3", mt="нет", partners="—",
             why="quest hub / schedule board — нужен читаемый офис", stages="3", lock="gate",
             diff="wide screen + office desks", diffc="низкая", rec=True, reuse="Medium; agency lighting cooler"),
        dict(asset=B_LARGE, mode="Dedicated", door="Door_3", floors="3", mt="нет", partners="—", why="HQ silhouette", stages="3", lock="gate", diff="самый крупный в agency", diffc="средняя"),
        dict(asset=B_LARGE, mode="MultiTenant agency + photo + barber", door="lobby Door_3 + side doors", floors="3 visual",
             mt="да", partners="photo, barber", why="один HQ", stages="все 3", lock="side doors ok same stage",
             diff="сильный hub но сложная навигация", diffc="высокая"),
    ])
    variants("player_home", [
        dict(asset=B_SMALL, mode="Dedicated / FacadeOnly", door="Door_1", floors="2", mt="нет", partners="—", why="spawn landmark", stages="1", lock="n/a",
             diff="HOME sign purple", diffc="низкая", rec=True, reuse="Small"),
        dict(asset=B_MED, mode="Dedicated", door="Door_1", floors="3", mt="нет", partners="—", why="более жилой", stages="1", lock="n/a", diff="крупнее cafe?", diffc="средняя"),
        dict(asset=B_SMALL, mode="FacadeOnly", door="Door_1", floors="1", mt="нет", partners="—", why="как сейчас", stages="1", lock="n/a", diff="стандарт", diffc="низкая"),
    ])
    for wa in ["main_bench", "park_bench", "duck_feeding", "karaoke", "bus_stop_candy", "park_picnic"]:
        lines.append(
            f"## `{wa}`\n"
            f"- Режим: **WorldActivityPOI** — без Building_* обязательно.\n"
            f"- Вариант A ★: текущий prop prefab, перенос interact внутрь корня prefab.\n"
            f"- Вариант B: усиленный prop cluster (ещё props) без здания.\n"
            f"- Вариант C: привязка к навесу/стене ближайшего FacadeOnly только как backdrop, не multi-tenant.\n"
            f"- сложность: низкая.\n\n"
        )
    write("POI_ASSET_ASSIGNMENT.md", "".join(lines))


def doc_multitenant():
    groups = [
        ("flower+gift", "высокая", "высокая (оба 1)", "main_street", "желательно 2 двери", "1 этаж ок", "нет", "средняя", "средняя", "допустимо"),
        ("jewelry+clothing", "высокая", "высокая", "main_street", "2 двери", "1", "нет", "средняя", "средняя", "допустимо"),
        ("photo+barber", "высокая", "высокая (оба 3)", "agency_row", "2 двери", "1", "нет", "низкая", "средняя", "рекомендуется"),
        ("agency+photo+barber", "средняя", "высокая", "agency_row", "lobby+side", "visual floors", "нет", "средняя", "высокая", "допустимо осторожно"),
        ("cinema+bookstore", "низкая", "оба 2", "park_leisure", "отдельные", "2", "cinema loadable", "высокая", "высокая", "не рекомендуется"),
        ("cinema+arcade", "средняя", "оба 2", "park_leisure", "отдельные", "лучше отдельно", "оба venue", "высокая", "высокая", "не рекомендуется"),
        ("restaurant+bar", "средняя", "оба 2", "park_leisure", "2 двери", "1–2", "restaurant loadable", "средняя", "средняя", "допустимо"),
        ("gym+bookstore", "низкая", "оба 2", "park_leisure", "2", "1", "нет", "высокая", "средняя", "не рекомендуется"),
        ("cafe+flower", "низкая", "оба 1", "main_street", "2", "1", "cafe loadable", "высокая (cafe uniqueness)", "средняя", "не рекомендуется"),
        ("internet+homeware", "низкая", "оба 1", "main_street", "2", "1", "нет", "высокая", "средняя", "не рекомендуется"),
        ("arcade+karaoke", "средняя", "оба 2", "park_leisure", "arcade facade + karaoke world", "karaoke не здание", "arcade venue", "средняя", "низкая", "допустимо как соседство, не один building"),
    ]
    lines = ["# Multi-Tenant Compatibility Matrix\n",
             "| Группа | Тема | Стадии | Район | Отд. вход | Отд. этаж | Loadable transition | Путаница | Сложность | Итог |\n|---|---|---|---|---|---|---|---|---|---|\n"]
    for g in groups:
        lines.append("| " + " | ".join(g) + " |\n")
    lines += [
        "\n## Правила из проверки\n",
        "1. Cafe / Cinema / Agency — **не** отдавать в multi-tenant без крайней нужды (узнаваемость).\n",
        "2. Лучший multi-tenant: **photo+barber** (один stage, один district, оба Storefront).\n",
        "3. Retail pairs на main_street допустимы, если две читаемые двери и две вывески.\n",
        "4. Не смешивать stage1 storefront с stage2/3 venue в одном shell.\n",
        "5. Hollow multi-floor на текущих Building_* **отклонён** (нет пригодного интерьера).\n",
    ]
    write("MULTI_TENANT_COMPATIBILITY.md", "".join(lines))


def doc_hollow():
    lines = ["# Hollow Building Feasibility\n",
             "Вердикт по факту осмотра `Building_Small_1`, `Building_Medium_2_001`, `Building_Large_2`.\n\n"]
    for b in RAW["buildings"]:
        name = b["name"]
        lines += [
            f"## {name}\n",
            f"- exterior: `hollow_shots/{name}_exterior.png`\n",
            f"- interior attempt: `hollow_shots/{name}_interior.png`\n",
            f"- topdown: `hollow_shots/{name}_topdown.png`\n",
            f"- вход: baked facade opening + recommended Door_* prop; named door nodes: {b.get('door_guess',{}).get('named_doors')}\n",
            f"- AABB: {b.get('aabb_size')}\n",
            f"- доступный внутренний объём (gameplay): **≈0** (collision отсутствует, probes interior={b.get('interior_probe_hits')})\n",
            f"- прилавок: только снаружи / под навесом, не внутри mesh\n",
            f"- NPC внутри: нет\n",
            f"- лестница: нет геометрии\n",
            f"- нужны occluders/стены: да, полный кастомный interior, если настаивать на walk-in\n",
            f"- сложность collision: **высокая** (сейчас has_collision={b.get('has_collision_shapes')})\n",
            f"- лучший POI для этой модели: **FacadeOnly / Dedicated facade**, не HollowWalkIn\n",
            f"- **практический вердикт: НЕ использовать как HollowWalkInBuilding без нового ассета или модульной сборки**\n\n",
        ]
    lines += [
        "## Альтернатива hollow\n",
        "1. Собрать storefront из `Brick_*` + пол/потолок CSG/модули — отдельный pipeline.\n",
        "2. Купить/добавить полые shop kits — вне текущего scope.\n",
        "3. Оставить FacadeOnly + props у двери (текущий практичный путь).\n",
    ]
    write("HOLLOW_BUILDING_FEASIBILITY.md", "".join(lines))


def doc_report():
    text = f"""# ANALYSIS_REPORT — City POI Modular Architecture

Статус: **ANALYSIS ONLY** — `city.tscn` не менялся, новые prefab не создавались, здания не переставлялись.

## Резюме

В проекте для целых фасадов доступны только три mesh:

| Asset | AABB (m) | Hollow walk-in | Рекомендуемая роль |
|---|---|---|---|
| Building_Small_1 | {building_by_name.get('Building_Small_1',{}).get('aabb_size')} | нет | массовые Storefront / Home / Arcade |
| Building_Medium_2_001 | {building_by_name.get('Building_Medium_2_001',{}).get('aabb_size')} | нет | Cafe / Restaurant / Gym / Agency |
| Building_Large_2 | {building_by_name.get('Building_Large_2',{}).get('aabb_size')} | нет | Cinema (приоритет) / optional Agency HQ |

Текущие POI prefab почти все — **FacadeOnlyBuilding**: Building_* + отдельный Door_* + awning/sign/props. Interact живёт на city Markers через `complex_world.gd`, то есть **ещё не инкапсулирован** в корень POI-сцены.

## 5 лучших зданий для уникальных POI

1. **Building_Large_2 → Cinema** (нужен самый читаемый leisure landmark)
2. **Building_Medium_2_001 → Cafe Two Hearts** (стартовый якорь)
3. **Building_Medium_2_001 → Agency Office** (stage3 hub; другой light/sign)
4. **Building_Medium_2_001 → Park Restaurant** (venue stage2)
5. **Building_Small_1 → Player Home** (spawn identity via HOME sign)

*(«Лучших зданий» физически три — ранжирование по назначению, не по количеству файлов.)*

## 3 лучших кандидата MultiTenantBuilding

1. **Photo Studio + Barber** в одном Small/Medium на agency_row (одинаковая стадия, две двери) — **рекомендуется**
2. **Flower + Gift** dual-door Small на main_street — **допустимо**
3. **Jewelry + Clothing** dual-door Small — **допустимо**

## 3 лучших полых здания

**Нет пригодных.** Все три Building_* дали interior_probe_hits=0 и has_collision=false.  
HollowWalkIn откладывается до модульной сборки Brick_* или новых ассетов.

## POI, которым обязателен уникальный силуэт

- Cafe Two Hearts
- Cinema
- Player Home
- Agency Office
- Park Restaurant

## POI, которые безопасно объединить

- photo_studio + barber
- flower_shop + gift_shop (если две вывески/двери)
- jewelry_shop + clothing_shop

## Отклонённые идеи (слишком сложно / непрактично)

1. HollowWalkIn на текущих Building_* без кастомного интерьера
2. Cinema+Bookstore multi-floor в одном Large
3. Cafe внутри multi-tenant с магазинами (ломает uniqueness)
4. Смешение stage1 storefront с stage2/3 venue в одном shell
5. Массовая сборка 20 уникальных зданий из Brick_* в этом этапе (отдельный pipeline, не analysis-approve)

## Целевая архитектура (не реализована)

`POIBuilding` с TenantSlots / EntranceAnchors — принять после утверждения таблицы назначений.  
WorldActivityPOI остаются отдельными сценами.

## Артефакты

- `POI_INVENTORY.md`
- `BUILDING_ASSET_CATALOG.md`
- `POI_ASSET_ASSIGNMENT.md`
- `MULTI_TENANT_COMPATIBILITY.md`
- `HOLLOW_BUILDING_FEASIBILITY.md`
- `contact_sheets/*`
- `hollow_shots/*`
- `_analysis_raw.json` (машинные замеры)
"""
    write("ANALYSIS_REPORT.md", text)


def make_sheets():
    # Venue candidates
    contact_sheet([
        (CONTACT / "prefab_CafeTwoHearts.png", ["CafeTwoHearts", "VenueEntrancePOI", "rec: Medium Dedicated/FacadeOnly", "door: Door_1 front", "stage1 main_street"]),
        (CONTACT / "prefab_ParkRestaurant.png", ["ParkRestaurant", "VenueEntrancePOI", "rec: Medium FacadeOnly", "door: Door_2", "stage2 park"]),
        (CONTACT / "prefab_CinemaFacade.png", ["CinemaFacade", "VenueEntrancePOI", "rec: Large Dedicated", "door: Door_3 wide", "stage2 park"]),
        (CONTACT / "prefab_ArcadeFacade.png", ["ArcadeFacade", "VenueEntrancePOI", "rec: Small + screens", "door: Door_1", "stage2 park"]),
        (CONTACT / "prefab_PlayerHomeFacade.png", ["PlayerHome", "VenueEntrancePOI", "rec: Small Dedicated", "door: Door_1", "stage1"]),
        (CONTACT / "prefab_ParkBench.png", ["Park picnic uses benches/markers", "VenueEntrancePOI outdoor", "no building required", "action sit_park", "stage2"]),
    ], CONTACT / "sheet_venue_entrance_candidates.png")

    contact_sheet([
        (CONTACT / "prefab_FlowerShop.png", ["FlowerShop", "StorefrontPOI", "FacadeOnly Small", "door Door_1", "stage1"]),
        (CONTACT / "prefab_GiftShop.png", ["GiftShop", "StorefrontPOI", "FacadeOnly Small", "door Door_1", "stage1"]),
        (CONTACT / "prefab_JewelryShop.png", ["JewelryShop", "StorefrontPOI", "FacadeOnly Small", "door Door_2", "stage1"]),
        (CONTACT / "prefab_ClothingShop.png", ["ClothingShop", "StorefrontPOI", "FacadeOnly Small", "door Door_1", "stage1"]),
        (CONTACT / "prefab_HomewareShop.png", ["HomewareShop", "StorefrontPOI", "FacadeOnly Small", "door Door_1", "stage1"]),
        (CONTACT / "prefab_BookstoreFacade.png", ["Bookstore", "StorefrontPOI", "FacadeOnly Small", "door Door_1", "stage2"]),
        (CONTACT / "prefab_GymFacade.png", ["Gym", "StorefrontPOI", "FacadeOnly Medium", "door Door_1", "stage2"]),
        (CONTACT / "prefab_InternetCafe.png", ["InternetCafe", "StorefrontPOI", "FacadeOnly Small", "multi terminal", "stage1"]),
        (CONTACT / "prefab_BarFacade.png", ["Bar", "StorefrontPOI", "FacadeOnly Small", "door Door_1", "stage2"]),
        (CONTACT / "prefab_PhotoStudio.png", ["PhotoStudio", "StorefrontPOI", "FacadeOnly Small", "door Door_1", "stage3"]),
        (CONTACT / "prefab_BarberShop.png", ["Barber", "StorefrontPOI", "FacadeOnly Small", "door Door_1", "stage3"]),
        (CONTACT / "prefab_AgencyOffice.png", ["AgencyOffice", "StorefrontPOI/hub", "Medium Dedicated", "door Door_2", "stage3"]),
    ], CONTACT / "sheet_storefront_candidates.png", cols=3)

    contact_sheet([
        (SHOT / "Building_Small_1_exterior.png", ["Building_Small_1.gltf", "AABB ~12.5x17x14.5", "mode: FacadeOnly/Dedicated", "door: baked+Door_*", "POI: shops/home/arcade"]),
        (SHOT / "Building_Medium_2_001_exterior.png", ["Building_Medium_2_001.gltf", "AABB ~15x25x13", "mode: Dedicated/FacadeOnly", "door: baked+Door_*", "POI: cafe/restaurant/gym/agency"]),
        (SHOT / "Building_Large_2_exterior.png", ["Building_Large_2.gltf", "AABB ~20.6x28x16.6", "mode: Dedicated landmark", "door: baked+Door_*", "POI: cinema / HQ"]),
    ], CONTACT / "sheet_building_assets.png", cols=3)

    contact_sheet([
        (SHOT / "Building_Small_1_exterior.png", ["Small exterior", "Hollow? NO", "collision: none", "walk-in: reject", "use FacadeOnly"]),
        (SHOT / "Building_Small_1_interior.png", ["Small interior cam", "no usable room", "sky/facade only", "occluders needed for walk-in", "verdict: fail"]),
        (SHOT / "Building_Small_1_topdown.png", ["Small topdown", "solid roof shell", "no floor plan cavity", "—", "—"]),
        (SHOT / "Building_Medium_2_001_exterior.png", ["Medium exterior", "Hollow? NO", "collision: none", "walk-in: reject", "FacadeOnly"]),
        (SHOT / "Building_Medium_2_001_interior.png", ["Medium interior cam", "no usable room", "—", "—", "verdict: fail"]),
        (SHOT / "Building_Medium_2_001_topdown.png", ["Medium topdown", "—", "—", "—", "—"]),
        (SHOT / "Building_Large_2_exterior.png", ["Large exterior", "Hollow? NO", "collision: none", "walk-in: reject", "landmark facade"]),
        (SHOT / "Building_Large_2_interior.png", ["Large interior cam", "no usable room", "—", "—", "verdict: fail"]),
        (SHOT / "Building_Large_2_topdown.png", ["Large topdown", "—", "—", "—", "—"]),
    ], CONTACT / "sheet_hollow_buildings.png", cols=3)

    contact_sheet([
        (CONTACT / "prefab_PhotoStudio.png", ["MultiTenant cand.", "Photo + Barber", "same stage3", "dual DoorAnchors", "recommended"]),
        (CONTACT / "prefab_BarberShop.png", ["MultiTenant cand.", "Barber + Photo", "agency_row", "dual doors", "recommended"]),
        (CONTACT / "prefab_FlowerShop.png", ["MultiTenant cand.", "Flower + Gift", "stage1", "dual doors", "acceptable"]),
        (CONTACT / "prefab_GiftShop.png", ["MultiTenant cand.", "Gift + Flower", "stage1", "dual signs", "acceptable"]),
        (CONTACT / "prefab_JewelryShop.png", ["MultiTenant cand.", "Jewelry + Clothing", "stage1", "fashion strip", "acceptable"]),
        (CONTACT / "prefab_ClothingShop.png", ["MultiTenant cand.", "Clothing + Jewelry", "stage1", "fashion strip", "acceptable"]),
        (CONTACT / "prefab_AgencyOffice.png", ["MultiTenant cand.", "Agency HQ + services", "stage3", "high complexity", "cautious"]),
        (CONTACT / "prefab_CinemaFacade.png", ["Anti-pattern", "Cinema+Bookstore", "loses uniqueness", "not recommended", "—"]),
    ], CONTACT / "sheet_multi_tenant_candidates.png", cols=2)

    contact_sheet([
        (CONTACT / "prefab_DuckFeeding.png", ["DuckFeeding", "WorldActivityPOI", "no building", "props only", "stage2"]),
        (CONTACT / "prefab_MainBench.png", ["MainBench", "WorldActivityPOI", "city_rest", "bench mesh", "stage1"]),
        (CONTACT / "prefab_ParkBench.png", ["ParkBench", "WorldActivityPOI", "city_rest", "bench mesh", "stage2"]),
        (CONTACT / "prefab_KaraokeStand.png", ["KaraokeStand", "WorldActivityPOI", "desk+screen", "no building", "stage2"]),
        (CONTACT / "prefab_BusStopCandy.png", ["BusStopCandy", "WorldActivityPOI", "bus info + candy", "agency edge", "stage3"]),
    ], CONTACT / "sheet_world_activity_pois.png", cols=3)

    # Per important POI 2-4 candidates sheets
    for poi, tiles in {
        "cafe": [
            (SHOT / "Building_Medium_2_001_exterior.png", ["Cafe cand A ★", B_MED, "Dedicated/FacadeOnly", "Door_1", "recommend"]),
            (SHOT / "Building_Large_2_exterior.png", ["Cafe cand B", B_LARGE, "Dedicated", "Door_1", "overkill"]),
            (SHOT / "Building_Small_1_exterior.png", ["Cafe cand C", B_SMALL, "FacadeOnly", "Door_1", "weak landmark"]),
            (CONTACT / "prefab_CafeTwoHearts.png", ["Current prefab", "Medium+door+awning", "FacadeOnly today", "keep identity props", "baseline"]),
        ],
        "cinema": [
            (SHOT / "Building_Large_2_exterior.png", ["Cinema cand A ★", B_LARGE, "Dedicated", "Door_3", "recommend"]),
            (SHOT / "Building_Medium_2_001_exterior.png", ["Cinema cand B", B_MED, "FacadeOnly", "Door_2", "fallback"]),
            (CONTACT / "prefab_CinemaFacade.png", ["Current prefab", "needs Large upgrade", "FacadeOnly", "marquee/neon", "baseline"]),
            (SHOT / "Building_Small_1_exterior.png", ["Cinema cand C", B_SMALL, "reject for landmark", "Door_1", "too small"]),
        ],
        "agency": [
            (SHOT / "Building_Medium_2_001_exterior.png", ["Agency cand A ★", B_MED, "Dedicated", "Door_2", "recommend"]),
            (SHOT / "Building_Large_2_exterior.png", ["Agency cand B", B_LARGE, "HQ Dedicated", "Door_3", "if cinema uses Medium"]),
            (CONTACT / "prefab_AgencyOffice.png", ["Current prefab", "Medium+screen", "FacadeOnly", "schedule board", "baseline"]),
            (CONTACT / "prefab_PhotoStudio.png", ["MT option", "Agency lobby + photo/barber", "MultiTenant", "high complexity", "optional"]),
        ],
        "restaurant": [
            (SHOT / "Building_Medium_2_001_exterior.png", ["Restaurant cand A ★", B_MED, "FacadeOnly", "Door_2", "recommend"]),
            (SHOT / "Building_Large_2_exterior.png", ["Restaurant cand B", B_LARGE, "Dedicated", "Door_2", "alt"]),
            (SHOT / "Building_Small_1_exterior.png", ["Restaurant cand C", B_SMALL, "FacadeOnly", "Door_1", "weak"]),
            (CONTACT / "prefab_ParkRestaurant.png", ["Current prefab", "Medium+bistro sign", "FacadeOnly", "park district", "baseline"]),
        ],
    }.items():
        contact_sheet(tiles, CONTACT / f"sheet_poi_{poi}_candidates.png", cols=2)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    CONTACT.mkdir(parents=True, exist_ok=True)
    doc_inventory()
    doc_catalog()
    doc_assignment()
    doc_multitenant()
    doc_hollow()
    doc_report()
    make_sheets()
    # cleanup tmp
    tmp = OUT / "_tmp_tile.png"
    if tmp.exists():
        tmp.unlink()
    print("DONE_DOCS")


if __name__ == "__main__":
    main()
