from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

CARE, VULN, SIMP, PREST, CTRL, DOM, RISK, CONF, SPON, ABS, ORIG, OBS = range(12)
KIND, STATUS, THRILL, STRANGE = range(4)
SCAND, CONS, VARI, DEM = range(4)
SLAP, DANCE, MONEY, SIGMA = range(4)
MUSCLE, APPEARANCE, CAPITAL, AURA = range(4)
EARLY, BRANCH_A, BRANCH_B, LATE = range(4)
CONV, SPACE, PROP = range(3)


def write(rel: str, text: str) -> None:
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text, encoding="utf-8", newline="\n")
    print("wrote", rel)


def main() -> None:
    primary = [
        (
            "primary_kind.tres",
            KIND,
            "Добрая",
            [CARE, VULN, SIMP],
            [DOM, CONF, OBS],
            "Основная черта: положительно реагирует на заботу, уязвимость и простоту; отвергает доминирование, конфликт и одержимость.",
        ),
        (
            "primary_status.tres",
            STATUS,
            "Статусная",
            [PREST, CTRL, DOM],
            [VULN, SPON, ABS],
            "Основная черта: ценит престиж, контроль и доминирование; отвергает уязвимость, спонтанность и абсурд.",
        ),
        (
            "primary_thrill_seeking.tres",
            THRILL,
            "Азартная",
            [RISK, CONF, SPON],
            [CTRL, SIMP, PREST],
            "Основная черта: любит риск, конфликт и спонтанность; отвергает контроль, простоту и престиж.",
        ),
        (
            "primary_strange.tres",
            STRANGE,
            "Странная",
            [ABS, ORIG, OBS],
            [PREST, CTRL, SIMP],
            "Основная черта: ценит абсурд, оригинальность и одержимость; отвергает престиж, контроль и простоту.",
        ),
    ]
    prim_paths: list[str] = []
    for fname, t, name, likes, dislikes, desc in primary:
        rel = f"data/content/traits/{fname}"
        prim_paths.append(rel)
        write(
            rel,
            f"""[gd_resource type="Resource" script_class="PrimaryTraitDefinition" load_steps=2 format=3]

[ext_resource type="Script" path="res://data/definitions/primary_trait_definition.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
primary_trait = {t}
display_name = "{name}"
liked_tags = Array[int]({likes})
disliked_tags = Array[int]({dislikes})
description = "{desc}"
""",
        )

    secondary = [
        (
            "secondary_scandalous.tres",
            SCAND,
            "Скандальная",
            "+1: минимум одно оцениваемое событие содержало публичный CONFLICT. -1: свидание прошло полностью тихо и незаметно. 0: иначе.",
        ),
        (
            "secondary_consistent.tres",
            CONS,
            "Последовательная",
            "+1: минимум 3 из 4 оцениваемых решений используют одну характеристику. -1: все 4 решения используют разные характеристики. 0: иначе.",
        ),
        (
            "secondary_variety_seeking.tres",
            VARI,
            "Переменчивая",
            "+1: использованы минимум 3 разные характеристики. -1: одна характеристика использована минимум 3 раза. 0: иначе.",
        ),
        (
            "secondary_demanding.tres",
            DEM,
            "Требовательная",
            "+1: нет отрицательных реакций основной черты и есть минимум 2 положительные. -1: минимум 2 отрицательные реакции. 0: иначе.",
        ),
    ]
    sec_paths: list[str] = []
    for fname, t, name, desc in secondary:
        rel = f"data/content/traits/{fname}"
        sec_paths.append(rel)
        write(
            rel,
            f"""[gd_resource type="Resource" script_class="SecondaryTraitDefinition" load_steps=2 format=3]

[ext_resource type="Script" path="res://data/definitions/secondary_trait_definition.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
secondary_trait = {t}
display_name = "{name}"
description = "{desc}"
""",
        )

    comps = [
        ("competition_slap.tres", SLAP, "Пощёчинный бой", MUSCLE, 25, 45),
        ("competition_dance.tres", DANCE, "Танцевальное противостояние", APPEARANCE, 30, 50),
        ("competition_money.tres", MONEY, "Денежное противостояние", CAPITAL, 20, 40),
        ("competition_sigma.tres", SIGMA, "Сигма-давление", AURA, 30, 60),
    ]
    comp_paths: list[str] = []
    for fname, ct, name, char, dmin, dmax in comps:
        rel = f"data/content/competitions/{fname}"
        comp_paths.append(rel)
        write(
            rel,
            f"""[gd_resource type="Resource" script_class="CompetitionDefinition" load_steps=2 format=3]

[ext_resource type="Script" path="res://data/definitions/competition_definition.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
competition_type = {ct}
display_name = "{name}"
characteristic = {char}
expected_duration_min_seconds = {dmin}
expected_duration_max_seconds = {dmax}
""",
        )

    locs = [
        ("apartment", "Квартира", "Домашняя база героя."),
        ("city_hub", "Улица и городской хаб", "Городской хаб и улицы."),
        ("cafe", "Ресторан / кафе", "Место для свиданий и встреч."),
        ("gym", "Качалка", "Локация прокачки Мышцы."),
        ("appearance_space", "Пространство Внешности", "Нейтральное пространство визуальной прокачки."),
        ("salary_mine", "Зарплатная шахта", "Источник денег героя."),
        ("laboratory", "Лаборатория", "Производственная/научная зона."),
        ("production_area", "Поздняя производственная зона", "Поздняя фабрика/производство."),
        ("final_location", "Финальная локация", "Финальная сюжетная локация."),
    ]
    loc_paths: list[str] = []
    for lid, name, desc in locs:
        rel = f"data/content/locations/{lid}.tres"
        loc_paths.append(rel)
        write(
            rel,
            f"""[gd_resource type="Resource" script_class="LocationDefinition" load_steps=2 format=3]

[ext_resource type="Script" path="res://data/definitions/location_definition.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
id = &"{lid}"
display_name = "{name}"
description = "{desc}"
scene_path = ""
""",
        )

    stages = [
        (0, "Пролог — Соседка", "girl_neighbor", "", "Reserved story IDs only."),
        (1, "Стадия 1 — Актриса", "girl_actress", "rival_actress", "Reserved story IDs only."),
        (2, "Стадия 2 — Начальница шахты", "girl_mine_boss", "rival_mine_boss", "Reserved story IDs only."),
        (3, "Стадия 3 — Редактор журнала", "girl_magazine_editor", "rival_magazine_editor", "Reserved story IDs only."),
        (4, "Стадия 4 — Учёная", "girl_scientist", "rival_scientist", "Reserved story IDs only."),
        (5, "Стадия 5 — Президент", "girl_president", "rival_president", "Reserved story IDs only."),
        (6, "Стадия 6 — Мировое расширение", "", "", "No required earthly story girl/rival."),
        (7, "Финал", "girl_final_target", "", "Finale rivals are a separate sequence."),
    ]
    stage_paths: list[str] = []
    for st, name, gid, rid, notes in stages:
        rel = f"data/content/stages/stage_{st}.tres"
        stage_paths.append(rel)
        write(
            rel,
            f"""[gd_resource type="Resource" script_class="StoryStageDefinition" load_steps=2 format=3]

[ext_resource type="Script" path="res://data/definitions/story_stage_definition.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
stage = {st}
display_name = "{name}"
story_girl_id = &"{gid}"
story_rival_id = &"{rid}"
notes = "{notes}"
""",
        )

    perks = [
        ("perk_muscle_no_warmup", "Без разминки", MUSCLE, EARLY, 1, "", "Открывает основные специальные варианты Мышцы. В первой силовой активности новой сцены стартовое окно тайминга немного шире."),
        ("perk_muscle_tough_cheek", "Крепкая щека", MUSCLE, EARLY, 2, "", "Один раз за пощёчинный бой пропущенный удар не сбрасывает текущую серию полностью."),
        ("perk_muscle_double_slap", "Двойная пощёчина", MUSCLE, BRANCH_A, 1, "Удар", "Один раз за бой идеальное попадание позволяет ударить двумя руками и получить сразу 2 очка вместо 1."),
        ("perk_muscle_counter_argument", "Ответный аргумент", MUSCLE, BRANCH_A, 2, "Удар", "После идеального блока следующий идеальный удар получает дополнительное очко в ближайшем окне атаки."),
        ("perk_muscle_hold_doorway", "Удержание проёма", MUSCLE, BRANCH_B, 1, "Масса", "Открывает специальные силовые сцены, где герой удерживает проход, позицию или объект через Мышцу."),
        ("perk_muscle_heroic_defeat", "Героическое поражение", MUSCLE, BRANCH_B, 2, "Масса", "При поражении заметно более сильному сопернику герой не теряет весь возможный Авторитет; в свидании получает теги Уязвимость и Риск."),
        ("perk_muscle_mass_reserve", "Запас массы", MUSCLE, LATE, 1, "", "В силовой мини-игре один раз разрешается дополнительная ошибка или дополнительный раунд."),
        ("perk_muscle_two_handed_argument", "Двуручный довод", MUSCLE, LATE, 2, "", "Один раз за крупное силовое состязание можно объявить решающий приём с крупным риском/наградой."),
        ("perk_appearance_good_profile", "Выгодный профиль", APPEARANCE, EARLY, 1, "", "Открывает специальные варианты Внешности. При визуальном вступлении девушки одна деталь её образа показывается более явно."),
        ("perk_appearance_staged_walk", "Поставленная походка", APPEARANCE, EARLY, 2, "", "Первая ошибка в танцевальной или модельной активности не разрушает серию полностью."),
        ("perk_appearance_pocket_mirror", "Карманное зеркало", APPEARANCE, BRANCH_A, 1, "Отражение", "Один раз за сигма-противостояние зона удержания лица становится стабильнее и легче читается."),
        ("perk_appearance_control_profile", "Контрольный профиль", APPEARANCE, BRANCH_A, 2, "Отражение", "Если во время действия зеркала герой идеально удерживает сигма-лицо, получает дополнительное очко."),
        ("perk_appearance_second_outfit", "Второй комплект", APPEARANCE, BRANCH_B, 1, "Образ", "После прихода девушки, но до первого оцениваемого события, можно один раз сменить заранее подготовленный аксессуарный комплект."),
        ("perk_appearance_encore", "Выход на бис", APPEARANCE, BRANCH_B, 2, "Образ", "Один раз за свидание после нейтральной реакции на действие Внешности открывается короткий дополнительный визуальный жест."),
        ("perk_appearance_rhythm_in_body", "Ритм в теле", APPEARANCE, LATE, 1, "", "Окна правильного ритма в танцевальных состязаниях немного шире; первая сложная связка содержит подсказку."),
        ("perk_appearance_public_significance", "Внешность общественного значения", APPEARANCE, LATE, 2, "", "Один раз за свидание можно выбрать специальный вариант Внешности на один уровень выше текущего требования."),
        ("perk_capital_payable_intent", "Платёжеспособное намерение", CAPITAL, EARLY, 1, "", "Открывает специальные варианты Капитала и денежные противостояния."),
        ("perk_capital_representation_expenses", "Представительские расходы", CAPITAL, EARLY, 2, "", "Первое обычное платное действие на свидании не расходует Деньги."),
        ("perk_capital_buy_problem", "Купить проблему", CAPITAL, BRANCH_A, 1, "Собственность", "Один раз за свидание можно купить объект или право-препятствие, если событие допускает понятную покупку."),
        ("perk_capital_hostile_acquisition", "Враждебное приобретение", CAPITAL, BRANCH_A, 2, "Собственность", "После крупной победы деньгами можно оставить в собственности небольшой объект мира."),
        ("perk_capital_salary_advance", "Зарплата вперёд", CAPITAL, BRANCH_B, 1, "Поток", "Один раз за игровой период можно получить ближайшую доступную выплату без личного похода."),
        ("perk_capital_dignity_refund", "Возврат достоинства", CAPITAL, BRANCH_B, 2, "Поток", "Если платное действие заканчивается провалом, его стоимость возвращается; комедийный провал сохраняется."),
        ("perk_capital_financial_inertia", "Финансовая инерция", CAPITAL, LATE, 1, "", "Повышение зарплатного уровня начинает давать небольшой автоматический денежный поток после показанной шахтной шутки."),
        ("perk_capital_no_limit", "Лимит отсутствует", CAPITAL, LATE, 2, "", "Один раз за крупную стадию можно выполнить допустимый вариант Капитала независимо от цены."),
        ("perk_aura_presence_registered", "Присутствие зарегистрировано", AURA, EARLY, 1, "", "Открывает специальные варианты Ауры и сигма-противостояния."),
        ("perk_aura_dont_blink_first", "Не моргать первым", AURA, EARLY, 2, "", "Первая ошибка удержания в сигма-противостоянии не уменьшает уже набранный прогресс."),
        ("perk_aura_silence_longer", "Молчание длиннее нормы", AURA, BRANCH_A, 1, "Давление", "Один раз за сигма-противостояние соперник временно прекращает создавать помехи."),
        ("perk_aura_reverse_pressure", "Обратное давление", AURA, BRANCH_A, 2, "Давление", "После успешного пережидания помехи следующая идеальная секция даёт дополнительное очко."),
        ("perk_aura_right_to_say_nothing", "Право первым ничего не говорить", AURA, BRANCH_B, 1, "Инициатива", "Один раз за свидание можно не выбирать приветствие и молчать; в конфликте позволяет заменить тип состязания."),
        ("perk_aura_she_already_started", "Она уже начала", AURA, BRANCH_B, 2, "Инициатива", "После права молчать первая реакция девушки содержит более явную подсказку о основной черте."),
        ("perk_aura_atmospheric_influence", "Атмосферное влияние", AURA, LATE, 1, "", "Толпа и наблюдатели больше не усложняют удержание Ауры; усиливают визуальную реакцию."),
        ("perk_aura_local_significance", "Аура местного значения", AURA, LATE, 2, "", "Один раз за обычное столкновение заметно более слабый соперник может признать поражение до мини-игры."),
    ]
    perk_paths: list[str] = []
    for pid, name, char, sec, order, branch, desc in perks:
        rel = f"data/content/perks/{pid}.tres"
        perk_paths.append(rel)
        write(
            rel,
            f"""[gd_resource type="Resource" script_class="PerkDefinition" load_steps=2 format=3]

[ext_resource type="Script" path="res://data/definitions/perk_definition.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
id = &"{pid}"
display_name = "{name}"
description = "{desc}"
characteristic = {char}
section = {sec}
order_in_section = {order}
branch_label = "{branch}"
""",
        )

    idx = 2
    ext_lines = [
        '[ext_resource type="Script" path="res://data/definitions/content_catalog.gd" id="1_script"]'
    ]

    def add_ext(relpath: str) -> str:
        nonlocal idx
        rid = f"r{idx}"
        ext_lines.append(
            f'[ext_resource type="Resource" path="res://{relpath}" id="{rid}"]'
        )
        idx += 1
        return rid

    prim_ids = [add_ext(p) for p in prim_paths]
    sec_ids = [add_ext(p) for p in sec_paths]
    comp_ids = [add_ext(p) for p in comp_paths]
    loc_ids = [add_ext(p) for p in loc_paths]
    stage_ids = [add_ext(p) for p in stage_paths]
    perk_ids = [add_ext(p) for p in perk_paths]
    load_steps = len(ext_lines) + 1

    def arr(ids: list[str]) -> str:
        return ", ".join(f'ExtResource("{i}")' for i in ids)

    catalog = f"""[gd_resource type="Resource" script_class="ContentCatalog" load_steps={load_steps} format=3]

{chr(10).join(ext_lines)}

[resource]
script = ExtResource("1_script")
primary_traits = [{arr(prim_ids)}]
secondary_traits = [{arr(sec_ids)}]
girls = []
rivals = []
competitions = [{arr(comp_ids)}]
dating_events = []
dating_pools = []
perks = [{arr(perk_ids)}]
locations = [{arr(loc_ids)}]
stages = [{arr(stage_ids)}]
"""
    write("data/catalog/content_catalog.tres", catalog)

    write(
        "data/test/girl_test_kind.tres",
        f"""[gd_resource type="Resource" script_class="GirlDefinition" load_steps=2 format=3]

[ext_resource type="Script" path="res://data/definitions/girl_definition.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
id = &"girl_test_kind"
display_name = "Test Girl"
is_story = false
has_story_stage = false
story_stage = 0
primary_trait = {KIND}
secondary_trait = {CONS}
required_experience = 0
discovery_situation_id = &""
appearance_profile_id = &""
dating_pool_ids = Array[StringName]([&"date_pool_test"])
speech_style_note = "test fixture"
clue_notes = Array[String]([])
""",
    )

    write(
        "data/test/rival_test.tres",
        f"""[gd_resource type="Resource" script_class="RivalDefinition" load_steps=2 format=3]

[ext_resource type="Script" path="res://data/definitions/rival_definition.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
id = &"rival_test"
display_name = "Test Rival"
is_story = false
has_story_stage = false
story_stage = 0
required_authority = 0
authority_reward = 1
muscle = 3
appearance = 3
capital = 3
aura = 3
preferred_competition = {SLAP}
allowed_competitions = Array[int]([{SLAP}, {DANCE}])
appearance_profile_id = &""
competition_modifier_id = &""
""",
    )

    def make_event(fname: str, eid: str, cat: int, title: str, actions: list) -> None:
        lines = [
            f'[gd_resource type="Resource" script_class="DatingEventDefinition" load_steps={3 + len(actions)} format=3]',
            "",
            '[ext_resource type="Script" path="res://data/definitions/dating_event_definition.gd" id="1_script"]',
            '[ext_resource type="Script" path="res://data/definitions/dating_action_definition.gd" id="2_action"]',
            "",
        ]
        action_refs: list[str] = []
        for i, (aid, label, char, tags) in enumerate(actions):
            sid = f"Action_{i}"
            action_refs.append(sid)
            lines.extend(
                [
                    f'[sub_resource type="Resource" id="{sid}"]',
                    'script = ExtResource("2_action")',
                    f'id = &"{aid}"',
                    f'label = "{label}"',
                    f"characteristic = {char}",
                    "required_characteristic_level = 0",
                    "money_cost = 0",
                    'resolver_id = &"direct"',
                    f"direct_tags = Array[int]({tags})",
                    "",
                ]
            )
        arr_a = ", ".join(f'SubResource("{s}")' for s in action_refs)
        lines.extend(
            [
                "[resource]",
                'script = ExtResource("1_script")',
                f'id = &"{eid}"',
                f"category = {cat}",
                f'title = "{title}"',
                f'setup_text = "{title} setup"',
                f"actions = [{arr_a}]",
                "allowed_location_ids = Array[StringName]([])",
                "",
            ]
        )
        write(f"data/test/{fname}", "\n".join(lines))

    make_event(
        "date_event_test_conversation.tres",
        "date_event_test_conversation",
        CONV,
        "Test Conversation",
        [
            ("action_a", "Action A", MUSCLE, [CARE]),
            ("action_b", "Action B", APPEARANCE, [PREST, CTRL]),
        ],
    )
    make_event(
        "date_event_test_space.tres",
        "date_event_test_space",
        SPACE,
        "Test Space",
        [
            ("action_space_a", "Action A", CAPITAL, [RISK]),
            ("action_space_b", "Action B", AURA, [ABS, ORIG]),
        ],
    )
    make_event(
        "date_event_test_proposal.tres",
        "date_event_test_proposal",
        PROP,
        "Test Proposal",
        [
            ("action_prop_a", "Action A", MUSCLE, [CONF]),
            ("action_prop_b", "Action B", CAPITAL, [OBS, SPON]),
        ],
    )
    make_event(
        "date_event_invalid_three_tags.tres",
        "date_event_invalid_three_tags",
        CONV,
        "Invalid Three Tags",
        [("action_bad", "Bad Action", MUSCLE, [CARE, VULN, SIMP])],
    )

    write(
        "data/test/date_pool_test.tres",
        """[gd_resource type="Resource" script_class="DatingEventPoolDefinition" load_steps=2 format=3]

[ext_resource type="Script" path="res://data/definitions/dating_event_pool_definition.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
id = &"date_pool_test"
event_ids = Array[StringName]([&"date_event_test_conversation", &"date_event_test_space", &"date_event_test_proposal"])
""",
    )

    write(
        "data/test/girl_test_dup_a.tres",
        f"""[gd_resource type="Resource" script_class="GirlDefinition" load_steps=2 format=3]

[ext_resource type="Script" path="res://data/definitions/girl_definition.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
id = &"girl_test_dup"
display_name = "Dup A"
primary_trait = {KIND}
secondary_trait = {CONS}
required_experience = 0
""",
    )
    write(
        "data/test/girl_test_dup_b.tres",
        f"""[gd_resource type="Resource" script_class="GirlDefinition" load_steps=2 format=3]

[ext_resource type="Script" path="res://data/definitions/girl_definition.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
id = &"girl_test_dup"
display_name = "Dup B"
primary_trait = {STATUS}
secondary_trait = {DEM}
required_experience = 0
""",
    )

    print("DONE", len(perk_paths), "perks")


if __name__ == "__main__":
    main()
