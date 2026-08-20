# -*- coding: utf-8 -*-
"""Generate seed .tres files for Date System Lab."""
from __future__ import annotations

import os
from pathlib import Path
from textwrap import indent

ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / "date_system" / "content"

TAGS = [
    ("politeness", "УЧТИВОСТЬ", "Вежливость, уважение, мягкая поддержка."),
    ("directness", "ПРЯМОЛИНЕЙНОСТЬ", "Прямая речь без украшений."),
    ("flattery", "ПОДХАЛИМАЖ", "Угодливая похвала и сглаживание."),
    ("audacity", "НАГЛОСТЬ", "Колкость, дерзость, провокация."),
    ("dominance", "ДОМИНИРОВАНИЕ", "Контроль ситуации и давления."),
    ("risk", "АЗАРТ", "Готовность к риску и пари."),
    ("generosity", "ЩЕДРОСТЬ", "Деньги и материальная помощь."),
    ("status", "СТАТУС", "Демонстрация положения и ресурсов."),
    ("care", "ЗАБОТА", "Внимание к комфорту, состоянию и интересам другого человека."),
    ("humor", "ЮМОР", "Реакция через шутку, иронию или превращение ситуации в комедию."),
    ("composure", "САМООБЛАДАНИЕ", "Спокойствие, выдержка и отсутствие суеты под давлением ситуации."),
    ("cunning", "ХИТРОСТЬ", "Решение ситуации через обходной ход, проверку условий или использование правил в свою пользу."),
]

STATS = [
    ("muscle", "Мышца", "Физическая сила."),
    ("appearance", "Внешность", "Внешняя привлекательность."),
    ("capital", "Капитал", "Деньги и ресурсы."),
    ("aura", "Аура", "Присутствие и давление молчанием."),
]

# id, name, description, move_ids
LOCAL_OBJECTS = [
    ("window", "Окно", "Окно, которое можно приоткрыть или распахнуть.", ["local_window_audacity", "local_window_care"]),
    ("sofa", "Диван", "Диван, на котором можно задать позу и темп разговора.", ["local_sofa_composure", "local_sofa_dominance"]),
    ("tv", "Телевизор", "Телевизор с передачами и роликами под руку.", ["local_tv_humor", "local_tv_cunning"]),
    ("jukebox", "Музыкальный автомат", "Музыкальный автомат с чужими и своими композициями.", ["local_jukebox_humor", "local_jukebox_audacity"]),
    ("barista", "Бариста", "Бариста, который может принести десерт или подыграть истории.", ["local_barista_generosity", "local_barista_cunning"]),
    ("waiter", "Официант", "Официант, через которого заказывают десерт и «то самое».", ["local_waiter_generosity", "local_waiter_status"]),
    ("piano", "Рояль", "Рояль в зале — сыграть самому или занять место музыканта.", ["local_piano_humor", "local_piano_dominance"]),
]

# id, name, tag, option, positive, negative, req or None
LOCAL_MOVES = [
    ("local_window_audacity", "Распахнуть окно", "audacity", "Распахнуть окно настежь и продолжить разговор с улицей.", "Окно настежь, улица в разговоре — ей это зашло.", "Распахнул окно настежь — ей слишком шумно и демонстративно.", None),
    ("local_window_care", "Приоткрыть окно", "care", "Слегка приоткрыть окно для свежего воздуха.", "Свежий воздух к месту — ей спокойнее.", "Приоткрыл окно «для воздуха» — ей это кажется лишней заботой не к месту.", None),
    ("local_sofa_composure", "Откинуться на диван", "composure", "Откинуться на диван и невозмутимо продолжить разговор.", "Откинулся и держишь тон — ей это спокойствие по делу.", "Откинулся на диван слишком расслабленно — ей это выглядит как равнодушие.", None),
    ("local_sofa_dominance", "Занять центр дивана", "dominance", "Пересесть в центр дивана и самому задать темп разговору.", "Занял центр дивана и темп разговора — ей это зашло.", "Пересел в центр и задал темп — ей это слишком навязано.", ("aura", 2)),
    ("local_tv_humor", "Неуместная передача", "humor", "Включить максимально неуместную передачу и сделать вид, что так и было задумано.", "Неуместная передача сработала как шутка — ей смешно.", "Включил неуместную передачу — ей это выглядит как сбой, а не юмор.", None),
    ("local_tv_cunning", "Подтверждающий ролик", "cunning", "Найти ролик, который неожиданно подтверждает твою версию.", "Ролик неожиданно подтвердил твою версию — ей это ловко.", "Подобрал ролик «в подтверждение» — ей это выглядит как подтасовка.", None),
    ("local_jukebox_humor", "Неуместная песня", "humor", "Поставить максимально неуместную песню.", "Неуместная песня попала в тон — ей смешно.", "Поставил максимально неуместную песню — ей это ломает вечер.", None),
    ("local_jukebox_audacity", "Переключить музыку", "audacity", "Переключить музыку на свой выбор посреди чужой композиции.", "Переключил чужую композицию на свою — ей это зашло как наглость к месту.", "Перебил чужую песню своим выбором — ей это грубо.", None),
    ("local_barista_generosity", "Фирменный десерт", "generosity", "Заказать девушке фирменный десерт.", "Фирменный десерт к месту — ей приятно.", "Заказал фирменный десерт — ей это кажется покупкой настроения.", None),
    ("local_barista_cunning", "Подыграть истории", "cunning", "Попросить бариста подыграть твоей истории.", "Бариста подыграл истории — ей это ловко.", "Попросил бариста подыграть — ей это выглядит как постановка.", ("aura", 2)),
    ("local_waiter_generosity", "Дорогой десерт", "generosity", "Заказать для неё самый дорогой десерт.", "Самый дорогой десерт к месту — ей приятно.", "Заказал самый дорогой десерт — ей это слишком демонстративно.", None),
    ("local_waiter_status", "То самое", "status", "Попросить принести «то самое», будто ты здесь постоянный гость.", "«То самое» принесли как постоянному гостю — ей это зашло.", "Попросил «то самое» как завсегдатай — ей это выглядит как игра в статус.", ("capital", 2)),
    ("local_piano_humor", "Пафосный марш", "humor", "Сыграть одним пальцем максимально пафосный марш.", "Пафосный марш одним пальцем сработал — ей смешно.", "Сыграл пафосный марш одним пальцем — ей это не смешно, а жалко.", None),
    ("local_piano_dominance", "Занять рояль", "dominance", "Попросить музыканта уступить тебе рояль и занять его место.", "Занял рояль вместо музыканта — ей это зашло как контроль сцены.", "Попросил уступить рояль — ей это слишком театрально и навязчиво.", ("aura", 3)),
]

# id, name, enabled, apt_prep, local_object_ids
LOCATIONS = [
    ("apartment", "Квартира", True, True, ["window", "sofa"]),
    ("cafe", "Кафе", True, False, ["window", "jukebox", "barista"]),
    ("restaurant", "Ресторан", True, False, ["window", "waiter", "piano"]),
    ("park", "Парк", False, False, []),
    ("cinema", "Кинотеатр", False, False, []),
    ("arcade", "Аркада", False, False, []),
    ("museum", "Музей", False, False, []),
    ("planetarium", "Планетарий", False, False, []),
]

OUTFITS = [
    ("casual", "Повседневный", 0, 0),
    ("business", "Деловой", 1, 500),
    ("luxury", "Роскошный", 2, 800),
]

DIFFICULTIES = [
    ("starter", "Стартовая", "Высокая совместимость с базовым арсеналом героя. Подходит для первых девушек игры.", 6, 0),
    ("early", "Ранняя", "Небольшая вероятность получить полностью неподходящий набор базовых ходов.", 5, 1),
    ("mid", "Средняя", "Прокачка героя и подготовка к свиданию начинают заметно влиять на стабильность результата.", 4, 2),
    ("late", "Поздняя", "Базовый набор регулярно оставляет игрока без положительного тега. Развитый арсенал становится важной частью свидания.", 3, 3),
    ("elite", "Элитная", "Очень узкий набор положительных реакций. Рассчитана на сильно развитого героя и полноценную подготовку.", 2, 4),
]

TAG_IDS = [tag_id for tag_id, *_ in TAGS]

# id, name, description, difficulty, positives, secondary
GIRLS = [
    ("alina", "Алина", "Алина", "starter", ["politeness", "directness", "care", "generosity", "composure", "humor"], "variety"),
    ("marina", "Марина", "держит спокойный тон и предпочитает ясную заботу без суеты", "mid", ["care", "composure", "directness", "humor"], "variety"),
    ("girl_actress", "Актриса", "любит внимание, эффектность, уверенность и человека, который умеет поддерживать ощущение шоу", "early", ["flattery", "audacity", "generosity", "status", "humor"], "variety"),
    ("vika", "Вика", "Вика", "early", ["audacity", "dominance", "risk", "humor", "cunning"], "demanding"),
    ("dasha", "Даша", "любит дерзкие ставки и человека, который не боится задать тон", "mid", ["audacity", "risk", "humor", "dominance"], "variety"),
    ("girl_mine_boss", "Начальница шахты", "ценит конкретику, контроль ситуации и людей, которые не начинают суетиться под давлением", "mid", ["directness", "dominance", "generosity", "composure"], "demanding"),
    ("katya", "Катя", "любит спонтанность, игры, подколы и быстрые нестандартные решения", "mid", ["directness", "risk", "humor", "cunning"], "variety"),
    ("girl_magazine_editor", "Редактор журнала", "профессионально оценивает людей и любит, когда собеседник умеет держать позицию и выбирать слова", "mid", ["directness", "status", "composure", "cunning"], "demanding"),
    ("lera", "Лера", "любит красивую спокойную подачу, хороший вкус и социальную уверенность", "mid", ["politeness", "flattery", "status", "composure"], "variety"),
    ("olya", "Оля", "ценит щедрый жест, статус и вежливый уход за атмосферой", "mid", ["generosity", "status", "care", "politeness"], "variety"),
    ("girl_scientist", "Учёная", "ценит ясность, спокойствие, наблюдательность и необычные решения", "mid", ["directness", "composure", "cunning", "care"], "demanding"),
    ("sonya", "Соня", "поздняя необязательная девушка, которая любит хаос, риск и человека, способного превратить свидание в историю", "late", ["audacity", "risk", "humor"], "variety"),
    ("nika", "Ника", "проверяет собеседника прямым ходом и обходным правилом", "mid", ["cunning", "directness", "audacity", "composure"], "variety"),
    ("rita", "Рита", "любит дорогой жест, контроль сцены и риск напоказ", "mid", ["status", "dominance", "generosity", "risk"], "variety"),
    ("girl_president", "Президент", "максимально статусная ручная сюжетная цель; ценит контроль, положение и абсолютное самообладание", "late", ["dominance", "status", "composure"], "demanding"),
]


def negative_tags(positives: list[str]) -> list[str]:
    pos = set(positives)
    return [tag_id for tag_id in TAG_IDS if tag_id not in pos]


def girl_resource_fields(girl: tuple) -> str:
    girl_id, name, description, difficulty, positives, secondary = girl
    return (
        f'id = &"{girl_id}"\n'
        f'display_name = "{esc(name)}"\n'
        f'description = "{esc(description)}"\n'
        "enabled = true\n"
        "relationship_min = -5\n"
        "relationship_start = 0\n"
        "relationship_max = 5\n"
        f'difficulty_preset_id = &"{difficulty}"\n'
        f"positive_tag_ids = {string_name_array(positives)}\n"
        f"negative_tag_ids = {string_name_array(negative_tags(positives))}\n"
        f'secondary_rule_id = &"{secondary}"\n'
    )


def write_girls() -> None:
    for girl in GIRLS:
        write(
            CONTENT / "girls" / f"{girl[0]}.tres",
            simple_resource("GirlProfile", "res://date_system/content/girl_profile.gd", girl_resource_fields(girl)),
        )

SITUATIONS = [
    ("appearance_question", "Оценка внешности", "В начале встречи девушка спрашивает:\n«Ну что, как я выгляжу?»", 0),
    ("money_request", "Просьба о деньгах", "К вам подходит незнакомец и просит денег на срочную проблему.", 1),
    ("rival_provocation", "Провокация самца", "К вам подходит другой самец, заявляет, что рейтинг героя выглядит подозрительно, и начинает провоцировать.", 1),
    ("spontaneous_bet", "Пари", "Девушка предлагает пари: проигравший выполняет условие победителя.", 1),
    ("date_verdict", "Оценка свидания", "Перед расставанием девушка спрашивает:\n«Ну и как тебе сегодняшний вечер?»", 2),
]

BASE_MOVES = [
    ("say_directly", "Сказать прямо", [
        ("appearance_question", "directness", "Сказать, что именно в её образе нравится и что вызывает вопросы."),
        ("money_request", "directness", "Спросить, на что конкретно нужны деньги."),
        ("rival_provocation", "directness", "Сказать самцу, что он мешает свиданию и должен уйти."),
        ("spontaneous_bet", "directness", "Сразу сказать своё мнение об идее пари."),
        ("date_verdict", "directness", "Сказать, что именно в вечере понравилось и что хотелось бы изменить."),
    ]),
    ("compliment", "Сделать комплимент", [
        ("appearance_question", "politeness", "Сказать, что она отлично выглядит."),
        ("spontaneous_bet", "flattery", "Сказать, что она наверняка победит."),
        ("date_verdict", "flattery", "Сказать, что это было идеальное свидание."),
    ]),
    ("support", "Поддержать", [
        ("appearance_question", "care", "Спросить, нравится ли образ ей самой, и поддержать её выбор."),
        ("money_request", "generosity", "Дать незнакомцу небольшую сумму."),
        ("spontaneous_bet", "politeness", "Согласиться на предложенные девушкой правила."),
        ("date_verdict", "care", "Сказать, что главное — понравился ли вечер ей самой."),
    ]),
    ("smooth", "Сгладить ситуацию", [
        ("appearance_question", "flattery", "Сказать, что к её образу невозможно придраться."),
        ("money_request", "politeness", "Вежливо отказать и пожелать удачи."),
        ("rival_provocation", "composure", "Спокойно предложить завершить конфликт и разойтись."),
    ]),
    ("tease", "Подколоть", [
        ("appearance_question", "humor", "Сказать, что ожидал увидеть что-то хуже."),
        ("money_request", "cunning", "Попросить сначала доказать историю, а потом вернуться к вопросу денег."),
        ("rival_provocation", "humor", "Высмеять его претензию."),
        ("spontaneous_bet", "audacity", "Добавить унизительное условие для проигравшего."),
        ("date_verdict", "humor", "Сказать, что бывало и хуже."),
    ]),
    ("take_initiative", "Взять инициативу", [
        ("money_request", "dominance", "Самому определить сумму и закончить разговор."),
        ("rival_provocation", "dominance", "Самому назначить способ выяснить, кто прав."),
        ("spontaneous_bet", "dominance", "Самому переписать условия пари."),
        ("date_verdict", "dominance", "Сразу назначить следующую встречу."),
    ]),
    ("refuse", "Отказаться", [
        ("money_request", "composure", "Спокойно отказать и закончить разговор."),
        ("rival_provocation", "cunning", "Отказаться участвовать в провокации и предложить проверить рейтинг через официальный сервис."),
        ("spontaneous_bet", "composure", "Спокойно отказаться от пари."),
    ]),
    ("accept_challenge", "Принять вызов", [
        ("rival_provocation", "risk", "Принять предложенное соревнование."),
        ("spontaneous_bet", "risk", "Согласиться на исходные условия пари."),
    ]),
    ("pay", "Заплатить", [
        ("money_request", "generosity", "Оплатить всю заявленную сумму."),
        ("rival_provocation", "status", "Предложить самцу деньги за завершение конфликта."),
        ("spontaneous_bet", "status", "Сделать денежную ставку существенно выше предложенной."),
    ]),
    ("show_off", "Показать себя", [
        ("appearance_question", "status", "Перевести разговор на собственный образ и сравнить его с её образом."),
        ("money_request", "status", "Дать крупную сумму так, чтобы это заметили окружающие."),
        ("rival_provocation", "status", "Назвать свой рейтинг и предложить сравнить показатели."),
        ("spontaneous_bet", "status", "Сказать, что предложенная ставка слишком мала."),
        ("date_verdict", "status", "Сказать, что для первого раза она справилась неплохо."),
    ]),
]

UNLOCK_MOVES = [
    ("punch", "Дать в жбан", "muscle", 4, [
        ("rival_provocation", "dominance", "Дать самцу в жбан."),
    ]),
    ("solve_with_money", "Решить деньгами", "capital", 3, [
        ("money_request", "generosity", "Полностью оплатить проблему незнакомца и его следующий день."),
        ("rival_provocation", "status", "Предложить самцу сумму, за которую он сам объявит поражение."),
        ("spontaneous_bet", "status", "Заменить условие пари на крупную денежную ставку."),
    ]),
    ("play_with_looks", "Сыграть внешностью", "appearance", 3, [
        ("appearance_question", "audacity", "Предложить сначала оценить твой образ."),
        ("rival_provocation", "status", "Продемонстрировать себя и предложить сравнить результат."),
        ("date_verdict", "flattery", "Сказать, что вечер выглядел хорошо, потому что вы хорошо смотрелись вместе."),
    ]),
    ("silent_pressure", "Молча продавить", "aura", 3, [
        ("money_request", "dominance", "Смотреть на незнакомца до завершения разговора с его стороны."),
        ("rival_provocation", "dominance", "Смотреть на самца до его отступления."),
        ("date_verdict", "composure", "Выдержать паузу до реакции девушки."),
    ]),
    ("raise_stakes", "Поднять ставки", "capital", 5, [
        ("money_request", "risk", "Предложить удвоить сумму после немедленного доказательства истории."),
        ("spontaneous_bet", "risk", "Удвоить ставку и усложнить условие проигравшему."),
    ]),
]


def esc(text: str) -> str:
    return text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.replace("\n", "\n"), encoding="utf-8")


def simple_resource(script_class: str, script_path: str, fields: str) -> str:
    return (
        f'[gd_resource type="Resource" script_class="{script_class}" load_steps=2 format=3]\n\n'
        f'[ext_resource type="Script" path="{script_path}" id="1_script"]\n\n'
        f"[resource]\n"
        f'script = ExtResource("1_script")\n'
        f"{fields}"
    )


def string_name_array(values: list[str]) -> str:
    inner = ", ".join(f'&"{v}"' for v in values)
    return f"Array[StringName]([{inner}])"


def mapping_block(index: int, situation: str, tag: str, option: str) -> str:
    pos = f"Ей это откликается. Тег «{tag}» работает в её пользу."
    neg = f"Ей это режет. Тег «{tag}» играет против вас."
    return (
        f'[sub_resource type="Resource" id="map_{index}"]\n'
        f'script = ExtResource("2_map")\n'
        f'situation_id = &"{situation}"\n'
        f'tag_id = &"{tag}"\n'
        f'option_text = "{esc(option)}"\n'
        f'positive_result_text = "{esc(pos)}"\n'
        f'negative_result_text = "{esc(neg)}"\n'
    )


def write_move(move_id: str, name: str, kind: int, mappings: list, req=None, max_uses: int = 0) -> None:
    parts = [
        f'[gd_resource type="Resource" script_class="DateMove" load_steps={3 if req else 3} format=3]\n',
        '[ext_resource type="Script" path="res://date_system/content/date_move.gd" id="1_move"]\n',
        '[ext_resource type="Script" path="res://date_system/content/date_move_situation_mapping.gd" id="2_map"]\n',
    ]
    if req:
        parts.append('[ext_resource type="Script" path="res://date_system/content/unlock_requirement.gd" id="3_req"]\n')
    parts.append("\n")
    for i, mapping in enumerate(mappings, start=1):
        parts.append(mapping_block(i, *mapping) + "\n")
    if req:
        parts.append(
            '[sub_resource type="Resource" id="req_1"]\n'
            'script = ExtResource("3_req")\n'
            f'stat_id = &"{req[0]}"\n'
            f"required_level = {req[1]}\n\n"
        )
    map_refs = ", ".join(f'SubResource("map_{i}")' for i in range(1, len(mappings) + 1))
    parts.append("[resource]\n")
    parts.append('script = ExtResource("1_move")\n')
    parts.append(f'id = &"{move_id}"\n')
    parts.append(f'display_name = "{esc(name)}"\n')
    parts.append(f'description = "{esc(name)}"\n')
    parts.append(f"kind = {kind}\n")
    parts.append("enabled = true\n")
    parts.append(f"max_uses_per_date = {max_uses}\n")
    if req:
        parts.append('unlock_requirement = SubResource("req_1")\n')
    parts.append(f"situation_mappings = [{map_refs}]\n")
    write(CONTENT / "moves" / f"{move_id}.tres", "".join(parts))


def write_local_move(move_id: str, name: str, tag: str, option: str, pos: str, neg: str, req=None) -> None:
    parts = [
        f'[gd_resource type="Resource" script_class="DateMove" load_steps={3 if req else 2} format=3]\n',
        '[ext_resource type="Script" path="res://date_system/content/date_move.gd" id="1_move"]\n',
    ]
    if req:
        parts.append('[ext_resource type="Script" path="res://date_system/content/unlock_requirement.gd" id="3_req"]\n')
    parts.append("\n")
    if req:
        parts.append(
            '[sub_resource type="Resource" id="req_1"]\n'
            'script = ExtResource("3_req")\n'
            f'stat_id = &"{req[0]}"\n'
            f"required_level = {req[1]}\n\n"
        )
    parts.append("[resource]\n")
    parts.append('script = ExtResource("1_move")\n')
    parts.append(f'id = &"{move_id}"\n')
    parts.append(f'display_name = "{esc(name)}"\n')
    parts.append(f'description = "{esc(name)}"\n')
    parts.append("kind = 2\n")
    parts.append("enabled = true\n")
    parts.append("max_uses_per_date = 0\n")
    if req:
        parts.append('unlock_requirement = SubResource("req_1")\n')
    parts.append("situation_mappings = []\n")
    parts.append(f'local_tag_id = &"{tag}"\n')
    parts.append(f'local_option_text = "{esc(option)}"\n')
    parts.append(f'local_positive_result_text = "{esc(pos)}"\n')
    parts.append(f'local_negative_result_text = "{esc(neg)}"\n')
    write(CONTENT / "moves" / f"{move_id}.tres", "".join(parts))


def main() -> None:
    for tag_id, name, desc in TAGS:
        write(
            CONTENT / "tags" / f"{tag_id}.tres",
            simple_resource(
                "DateTag",
                "res://date_system/content/date_tag.gd",
                f'id = &"{tag_id}"\ndisplay_name = "{esc(name)}"\ndescription = "{esc(desc)}"\nenabled = true\n',
            ),
        )
    for stat_id, name, desc in STATS:
        write(
            CONTENT / "progression" / f"{stat_id}.tres",
            simple_resource(
                "ProgressionStat",
                "res://date_system/content/progression_stat.gd",
                f'id = &"{stat_id}"\ndisplay_name = "{esc(name)}"\ndescription = "{esc(desc)}"\nmin_level = 0\nmax_level = 5\n',
            ),
        )
    for object_id, name, desc, move_ids in LOCAL_OBJECTS:
        write(
            CONTENT / "local_objects" / f"{object_id}.tres",
            simple_resource(
                "DateLocalObject",
                "res://date_system/content/date_local_object.gd",
                f'id = &"{object_id}"\n'
                f'display_name = "{esc(name)}"\n'
                f'description = "{esc(desc)}"\n'
                "enabled = true\n"
                f"move_ids = {string_name_array(move_ids)}\n",
            ),
        )
    for loc_id, name, enabled, apt_p, object_ids in LOCATIONS:
        fields = (
            f'id = &"{loc_id}"\n'
            f'display_name = "{esc(name)}"\n'
            f'description = "{esc(name)}"\n'
            f"enabled = {'true' if enabled else 'false'}\n"
            f"uses_apartment_preparation = {'true' if apt_p else 'false'}\n"
            f"local_object_ids = {string_name_array(object_ids)}\n"
        )
        write(
            CONTENT / "locations" / f"{loc_id}.tres",
            simple_resource("DateLocation", "res://date_system/content/date_location.gd", fields),
        )
    for outfit_id, name, bonus, price in OUTFITS:
        write(
            CONTENT / "outfits" / f"{outfit_id}.tres",
            simple_resource(
                "Outfit",
                "res://date_system/content/outfit.gd",
                f'id = &"{outfit_id}"\ndisplay_name = "{esc(name)}"\ndescription = "{esc(name)}"\nenabled = true\nscore_bonus = {bonus}\nprice = {price}\n',
            ),
        )
    write(
        CONTENT / "secondary" / "variety.tres",
        simple_resource(
            "SecondaryRule",
            "res://date_system/content/secondary_rule.gd",
            'id = &"variety"\n'
            'display_name = "ЛЮБИТ РАЗНООБРАЗИЕ"\n'
            'description = "Получить +1 тремя различными Tags за свидание."\n'
            "enabled = true\n"
            "condition_type = 0\n"
            'condition_parameters = {\n"required_count": 3,\n"counted_phases": [0, 1, 2]\n}\n'
            "success_score = 2\n"
            "failure_score = 0\n",
        ),
    )
    write(
        CONTENT / "secondary" / "demanding.tres",
        simple_resource(
            "SecondaryRule",
            "res://date_system/content/secondary_rule.gd",
            'id = &"demanding"\n'
            'display_name = "ТРЕБОВАТЕЛЬНАЯ"\n'
            'description = "Завершить CORE с 0 ошибками."\n'
            "enabled = true\n"
            "condition_type = 1\n"
            'condition_parameters = {\n"counted_phases": [1]\n}\n'
            "success_score = 2\n"
            "failure_score = 0\n",
        ),
    )
    for sit_id, name, text, phase in SITUATIONS:
        write(
            CONTENT / "situations" / f"{sit_id}.tres",
            simple_resource(
                "DateSituation",
                "res://date_system/content/date_situation.gd",
                f'id = &"{sit_id}"\n'
                f'display_name = "{esc(name)}"\n'
                f'description = "{esc(name)}"\n'
                f'situation_text = "{esc(text)}"\n'
                "enabled = true\n"
                f"allowed_phases = Array[int]([{phase}])\n"
                "weight = 1.0\n",
            ),
        )
    for move_id, name, mappings in BASE_MOVES:
        write_move(move_id, name, 0, mappings, max_uses=0)
    for move_id, name, stat, level, mappings in UNLOCK_MOVES:
        write_move(move_id, name, 1, mappings, req=(stat, level), max_uses=1)
    for move_id, name, tag, option, pos, neg, req in LOCAL_MOVES:
        write_local_move(move_id, name, tag, option, pos, neg, req)

    for diff_id, name, desc, positive_count, order in DIFFICULTIES:
        write(
            CONTENT / "girl_difficulty" / f"{diff_id}.tres",
            simple_resource(
                "GirlDifficultyPreset",
                "res://date_system/content/girl_difficulty_preset.gd",
                f'id = &"{diff_id}"\n'
                f'display_name = "{esc(name)}"\n'
                f'description = "{esc(desc)}"\n'
                "enabled = true\n"
                f"positive_tag_count = {positive_count}\n"
                f"sort_order = {order}\n",
            ),
        )

    write_girls()

    write(
        CONTENT / "rules" / "date_rules.tres",
        simple_resource(
            "DateRules",
            "res://date_system/content/date_rules.gd",
            "opening_episode_count = 1\n"
            "core_episode_count = 3\n"
            "closing_episode_count = 1\n"
            "base_moves_per_episode = 3\n"
            "allow_situation_repeats = false\n"
            "show_locked_unlockable_moves = true\n"
            "opening_positive_score = 1\n"
            "opening_negative_score = -1\n"
            "core_positive_score = 1\n"
            "core_negative_score = -1\n"
            "closing_positive_score = 1\n"
            "closing_negative_score = -1\n"
            "reveal_tag_after_use = true\n"
            "reveal_secondary_after_first_completed_date = true\n"
            "secondary_counted_phases = Array[int]([1])\n"
            "apartment_unprepared_penalty = -1\n"
            "min_distinct_base_tags_per_situation = 6\n",
        ),
    )

    ext = ['[ext_resource type="Script" path="res://date_system/content/date_content_catalog.gd" id="1_script"]\n']
    refs = []
    n = 2

    def add_res(path: str, key: str) -> str:
        nonlocal n
        rid = f"res_{n}"
        n += 1
        ext.append(f'[ext_resource type="Resource" path="{path}" id="{rid}"]\n')
        refs.append((key, rid))
        return rid

    tag_ids = [add_res(f"res://date_system/content/tags/{i}.tres", "tags") for i, *_ in TAGS]
    move_ids = [add_res(f"res://date_system/content/moves/{i}.tres", "moves") for i, *_ in BASE_MOVES]
    move_ids += [add_res(f"res://date_system/content/moves/{i}.tres", "moves") for i, *_ in UNLOCK_MOVES]
    move_ids += [add_res(f"res://date_system/content/moves/{i}.tres", "moves") for i, *_ in LOCAL_MOVES]
    sit_ids = [add_res(f"res://date_system/content/situations/{i}.tres", "situations") for i, *_ in SITUATIONS]
    girl_ids = [add_res(f"res://date_system/content/girls/{girl[0]}.tres", "girls") for girl in GIRLS]
    difficulty_ids = [add_res(f"res://date_system/content/girl_difficulty/{i}.tres", "diff") for i, *_ in DIFFICULTIES]
    sec_ids = [add_res("res://date_system/content/secondary/variety.tres", "sec"), add_res("res://date_system/content/secondary/demanding.tres", "sec")]
    object_ids = [add_res(f"res://date_system/content/local_objects/{i}.tres", "obj") for i, *_ in LOCAL_OBJECTS]
    loc_ids = [add_res(f"res://date_system/content/locations/{i}.tres", "loc") for i, *_ in LOCATIONS]
    outfit_ids = [add_res(f"res://date_system/content/outfits/{i}.tres", "outfit") for i, *_ in OUTFITS]
    stat_ids = [add_res(f"res://date_system/content/progression/{i}.tres", "stat") for i, *_ in STATS]
    rules_id = add_res("res://date_system/content/rules/date_rules.tres", "rules")

    def arr(ids: list[str]) -> str:
        return "[" + ", ".join(f'ExtResource("{i}")' for i in ids) + "]"

    body = (
        '[gd_resource type="Resource" script_class="DateContentCatalog" load_steps='
        f"{len(ext)+1} format=3]\n\n"
        + "".join(ext)
        + "\n[resource]\n"
        + 'script = ExtResource("1_script")\n'
        + f"tags = {arr(tag_ids)}\n"
        + f"moves = {arr(move_ids)}\n"
        + f"situations = {arr(sit_ids)}\n"
        + f"girls = {arr(girl_ids)}\n"
        + f"girl_difficulty_presets = {arr(difficulty_ids)}\n"
        + f"secondary_rules = {arr(sec_ids)}\n"
        + f"local_objects = {arr(object_ids)}\n"
        + f"locations = {arr(loc_ids)}\n"
        + f"outfits = {arr(outfit_ids)}\n"
        + f"progression_stats = {arr(stat_ids)}\n"
        + f'date_rules = ExtResource("{rules_id}")\n'
    )
    write(CONTENT / "catalog" / "date_content_catalog.tres", body)
    print("seed tres written")


if __name__ == "__main__":
    main()
