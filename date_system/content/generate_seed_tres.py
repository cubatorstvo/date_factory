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
    ("muscle", "Мышца", "Физическая сила. Открывает силовые ходы и повышает шанс победы в силовых соревнованиях."),
    ("appearance", "Внешность", "Внешняя привлекательность. Открывает специальные ходы и повышает шанс победы в соревнованиях на внешность."),
    ("capital", "Капитал", "Деньги и ресурсы героя. Открывает дорогие ходы и повышает шанс победы в соревнованиях на капитал."),
    ("aura", "Аура", "Способность давить присутствием и управлять вниманием. Открывает соответствующие ходы и повышает шанс победы в соревнованиях на ауру."),
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

# id, name, price, stat_id or "", min_story_stage, outfit_move_id or ""
OUTFITS = [
    ("casual", "Повседневная", 0, "", 1, ""),
    ("sport", "Спортивный комплект", 250, "muscle", 1, ""),
    ("stylish", "Стильный комплект", 250, "appearance", 1, ""),
    ("business", "Деловой костюм", 250, "capital", 1, ""),
    ("minimal_black", "Минималистичный чёрный образ", 250, "aura", 1, ""),
    ("wrestling", "Борцовка", 700, "muscle", 2, "outfit_flex_bicep"),
    ("magician", "Костюм фокусника", 700, "appearance", 2, "outfit_card_trick"),
    ("luxury", "Роскошный костюм", 700, "capital", 2, "outfit_premium_card"),
    ("leather_jacket", "Кожаная куртка", 700, "aura", 2, "outfit_dramatic_entrance"),
    ("stunt", "Костюм каскадёра", 1200, "muscle", 4, "outfit_dangerous_idea"),
    ("model", "Модельный образ", 1200, "appearance", 4, "outfit_beautiful_couple"),
    ("philanthropist", "Образ филантропа", 1200, "capital", 4, "outfit_pay_extra"),
    ("black_turtleneck", "Чёрная водолазка", 1200, "aura", 4, "outfit_silent_hold"),
]

DIFFICULTIES = [
    ("starter", "Стартовая", "Высокая совместимость с базовым арсеналом героя. Подходит для первых девушек игры.", 6, 0),
    ("early", "Ранняя", "Небольшая вероятность получить полностью неподходящий набор базовых ходов.", 5, 1),
    ("mid", "Средняя", "Прокачка героя и подготовка к свиданию начинают заметно влиять на стабильность результата.", 4, 2),
    ("late", "Поздняя", "Базовый набор регулярно оставляет игрока без положительного тега. Развитый арсенал становится важной частью свидания.", 3, 3),
    ("elite", "Элитная", "Очень узкий набор положительных реакций. Рассчитана на сильно развитого героя и полноценную подготовку.", 2, 4),
]

TAG_IDS = [tag_id for tag_id, *_ in TAGS]

TRAITS = [
    ("loves_strong", "Любит сильных", "Первый за свидание положительный ход с требованием Мышца даёт +1.", 0, "muscle", ""),
    ("values_appearance", "Ценит внешность", "Первый за свидание положительный ход с требованием Внешность даёт +1.", 0, "appearance", ""),
    ("loves_wealthy", "Любит обеспеченных", "Первый за свидание положительный ход с требованием Капитал даёт +1.", 0, "capital", ""),
    ("senses_aura", "Чувствует ауру", "Первый за свидание положительный ход с требованием Аура даёт +1.", 0, "aura", ""),
    ("homebody", "Домоседка", "Свидание в Квартире даёт +1 к итогу.", 1, "", "apartment"),
    ("loves_cafe", "Любит кафе", "Свидание в Кафе даёт +1 к итогу.", 1, "", "cafe"),
    ("loves_restaurants", "Любит рестораны", "Свидание в Ресторане даёт +1 к итогу.", 1, "", "restaurant"),
]

# id, name, description, difficulty, positives, trait_id, initial_known
GIRLS = [
    ("alina", "Алина", "Алина", "starter", ["politeness", "directness", "care", "generosity", "composure", "humor"], "homebody", ["politeness", "audacity"]),
    ("marina", "Марина", "держит спокойный тон и предпочитает ясную заботу без суеты", "mid", ["care", "composure", "directness", "humor"], "senses_aura", ["care", "risk"]),
    ("girl_actress", "Актриса", "любит внимание, эффектность, уверенность и человека, который умеет поддерживать ощущение шоу", "early", ["flattery", "audacity", "generosity", "status", "humor"], "values_appearance", []),
    ("vika", "Вика", "Вика", "early", ["audacity", "dominance", "risk", "humor", "cunning"], "values_appearance", ["humor", "politeness"]),
    ("dasha", "Даша", "любит дерзкие ставки и человека, который не боится задать тон", "mid", ["audacity", "risk", "humor", "dominance"], "loves_strong", ["risk", "care"]),
    ("girl_mine_boss", "Начальница шахты", "ценит конкретику, контроль ситуации и людей, которые не начинают суетиться под давлением", "mid", ["directness", "dominance", "generosity", "composure"], "loves_restaurants", []),
    ("katya", "Катя", "любит спонтанность, игры, подколы и быстрые нестандартные решения", "mid", ["directness", "risk", "humor", "cunning"], "loves_cafe", ["humor", "status"]),
    ("girl_magazine_editor", "Редактор журнала", "профессионально оценивает людей и любит, когда собеседник умеет держать позицию и выбирать слова", "mid", ["directness", "status", "composure", "cunning"], "senses_aura", []),
    ("lera", "Лера", "любит красивую спокойную подачу, хороший вкус и социальную уверенность", "mid", ["politeness", "flattery", "status", "composure"], "loves_restaurants", ["status", "audacity"]),
    ("kira", "Кира", "режет лишнее напрямую, проверяет наглостью и держит самообладание дольше, чем удобно", "mid", ["directness", "audacity", "cunning", "composure"], "loves_strong", ["audacity", "flattery"]),
    ("olya", "Оля", "ценит щедрый жест, статус и вежливый уход за атмосферой", "mid", ["generosity", "status", "care", "politeness"], "loves_wealthy", ["generosity", "dominance"]),
    ("girl_scientist", "Учёная", "ценит ясность, спокойствие, наблюдательность и необычные решения", "mid", ["directness", "composure", "cunning", "care"], "loves_cafe", []),
    ("sonya", "Соня", "поздняя необязательная девушка, которая любит хаос, риск и человека, способного превратить свидание в историю", "late", ["audacity", "risk", "humor"], "homebody", ["risk", "composure"]),
    ("nika", "Ника", "проверяет собеседника прямым ходом и обходным правилом", "mid", ["cunning", "directness", "audacity", "composure"], "senses_aura", ["cunning", "flattery"]),
    ("rita", "Рита", "любит дорогой жест, контроль сцены и риск напоказ", "mid", ["status", "dominance", "generosity", "risk"], "loves_wealthy", ["status", "care"]),
    ("eva", "Ева", "занимает зал статусом, щедрым жестом и ставкой, которую нельзя тихо отменить", "mid", ["status", "dominance", "risk", "generosity"], "loves_restaurants", ["dominance", "humor"]),
    ("girl_president", "Президент", "максимально статусная ручная сюжетная цель; ценит контроль, положение и абсолютное самообладание", "late", ["dominance", "status", "composure"], "loves_wealthy", []),
]


def girl_resource_fields(girl: tuple) -> str:
    girl_id, name, description, difficulty, positives, trait_id, initial_known = girl
    return (
        f'id = &"{girl_id}"\n'
        f'display_name = "{esc(name)}"\n'
        f'description = "{esc(description)}"\n'
        "enabled = true\n"
        f'difficulty_preset_id = &"{difficulty}"\n'
        f'trait_id = &"{trait_id}"\n'
        f"positive_tag_ids = {string_name_array(positives)}\n"
        f"initial_known_tag_ids = {string_name_array(initial_known)}\n"
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

# id, name, tag, option, positive, negative, stat, level
CHARACTERISTIC_MOVES = [
    ("char_say_plain", "Сказать по-простому", "directness", "Сказать всё прямо, без лишних конструкций.", "Прямолинейность без обёртки ей зашла.", "Сказал слишком прямо — ей это режет.", "muscle", 1),
    ("char_stress_test", "Проверить на прочность", "risk", "Предложить немедленно проверить идею на практике, даже если это выглядит сомнительно.", "Готовность сразу проверить идею ей зашла.", "Предложил проверить идею на практике — ей это слишком рискованно.", "muscle", 3),
    ("char_force_argument", "Силовой аргумент", "dominance", "Продемонстрировать физическое превосходство как окончательный аргумент.", "Силовой аргумент закрыл тему — ей это зашло.", "Показал физическое превосходство — ей это слишком грубо.", "muscle", 5),
    ("char_gallantry", "Включить галантность", "politeness", "Принять максимально учтивый вид и повести себя безупречно воспитанно.", "Галантность к месту — ей приятно.", "Включил галантность слишком театрально — ей это фальшиво.", "appearance", 1),
    ("char_polished_compliment", "Красиво подать комплимент", "flattery", "Сделать комплимент так, будто это профессионально подготовленная презентация.", "Комплимент подан как витрина — ей это зашло.", "Комплимент прозвучал как презентация — ей это слишком подобострастно.", "appearance", 3),
    ("char_play_with_looks", "Сыграть внешностью", "audacity", "Демонстративно использовать собственную внешность как аргумент.", "Сыграл внешностью как аргументом — ей это зашло.", "Выставил внешность аргументом — ей это слишком нагло.", "appearance", 5),
    ("char_cover_expenses", "Взять расходы на себя", "generosity", "Немедленно предложить оплатить вопрос за свой счёт.", "Взял расходы на себя — ей это приятно.", "Сразу предложил всё оплатить — ей это покупка настроения.", "capital", 1),
    ("char_propose_scheme", "Предложить схему", "cunning", "Предложить подозрительно эффективную схему, в которой формально все остаются в выигрыше.", "Схема звучит ловко — ей это зашло.", "Предложил схему, в которой все «в выигрыше» — ей это слишком скользко.", "capital", 3),
    ("char_status_solve", "Решить вопрос статусом", "status", "Небрежно задействовать деньги, связи или статус как решение ситуации.", "Статус закрыл вопрос — ей это зашло.", "Решил вопрос статусом — ей это слишком демонстративно.", "capital", 5),
    ("char_support_mode", "Включить поддержку", "care", "Переключиться в режим уверенной и спокойной поддержки.", "Спокойная поддержка к месту — ей спокойнее.", "Включил режим поддержки — ей это кажется лишней опекой.", "aura", 1),
    ("char_joke_relief", "Разрядить шуткой", "humor", "Снять напряжение уместной или неуместной шуткой.", "Шутка сняла напряжение — ей смешно.", "Шутка не попала — ей это ломает тон.", "aura", 3),
    ("char_hold_pause", "Выдержать паузу", "composure", "Молча выдерживать ситуацию до тех пор, пока первой не сдастся она.", "Выдержал паузу — ей это спокойствие по делу.", "Молча ждал, пока она сдастся — ей это давление.", "aura", 5),
]

# id, name, tag, option, positive, negative
OUTFIT_MOVES = [
    ("outfit_flex_bicep", "Напрячь бицепс без причины", "dominance", "Внезапно перевести внимание на собственную физическую форму.", "Внезапный акцент на форме зашёл как контроль сцены.", "Напряг бицепс без причины — ей это слишком театрально."),
    ("outfit_card_trick", "Показать фокус с исчезновением", "humor", "Достать реквизит и немедленно устроить карточный фокус.", "Карточный фокус сработал как шутка — ей смешно.", "Достал реквизит посреди разговора — ей это не к месту."),
    ("outfit_premium_card", "Показать премиальную карту", "status", "Небрежно продемонстрировать максимально статусный способ оплаты.", "Премиальная карта закрыла вопрос статусом — ей это зашло.", "Показал премиальную карту — ей это слишком демонстративно."),
    ("outfit_dramatic_entrance", "Сделать демонстративный выход", "audacity", "На несколько секунд превратить обычную ситуацию в собственную сцену.", "Демонстративный выход зашёл как наглость к месту.", "Превратил ситуацию в собственную сцену — ей это слишком нагло."),
    ("outfit_dangerous_idea", "Предложить опасную идею", "risk", "Немедленно предложить сделать что-нибудь неоправданно рискованное.", "Опасная идея зашла как ставка.", "Предложил неоправданный риск — ей это слишком лихо."),
    ("outfit_beautiful_couple", "Объявить вас красивой парой", "flattery", "Вслух констатировать, насколько эффектно вы смотритесь вместе.", "Комплимент паре зашёл.", "Объявил вас красивой парой слишком презентационно — ей это льстит не к месту."),
    ("outfit_pay_extra", "Оплатить что-нибудь лишнее", "generosity", "Демонстративно потратить деньги на вещь, которую никто не просил покупать.", "Лишняя покупка сработала как щедрый жест.", "Оплатил то, что никто не просил — ей это покупка настроения."),
    ("outfit_silent_hold", "Молча выдержать ситуацию", "composure", "Сохранять абсолютное спокойствие до тех пор, пока неловко не станет всем остальным.", "Молчаливое спокойствие закрыло паузу — ей это по делу.", "Держал молчание, пока неловко не стало всем — ей это давление."),
]


def date_rules_fields() -> str:
    return (
        "opening_episode_count = 1\n"
        "core_episode_count = 3\n"
        "closing_episode_count = 1\n"
        "base_moves_per_episode = 3\n"
        "allow_situation_repeats = false\n"
        "positive_move_score = 1\n"
        "negative_move_score = -1\n"
        "reveal_tag_after_use = true\n"
        "combo_required_distinct_success_tags = 3\n"
        "combo_bonus_score = 1\n"
        "combo_max_rewards_per_date = 1\n"
        "apartment_unprepared_penalty = -1\n"
        "min_distinct_base_tags_per_situation = 6\n"
    )


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


def write_fixed_move(move_id: str, name: str, kind: int, tag: str, option: str, pos: str, neg: str, req=None) -> None:
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
    parts.append(f"kind = {kind}\n")
    parts.append("enabled = true\n")
    parts.append("max_uses_per_date = 1\n")
    if req:
        parts.append('unlock_requirement = SubResource("req_1")\n')
    parts.append("situation_mappings = []\n")
    parts.append(f'fixed_tag_id = &"{tag}"\n')
    parts.append(f'fixed_option_text = "{esc(option)}"\n')
    parts.append(f'fixed_positive_result_text = "{esc(pos)}"\n')
    parts.append(f'fixed_negative_result_text = "{esc(neg)}"\n')
    write(CONTENT / "moves" / f"{move_id}.tres", "".join(parts))


def write_local_move(move_id: str, name: str, tag: str, option: str, pos: str, neg: str, req=None) -> None:
    write_fixed_move(move_id, name, 2, tag, option, pos, neg, req)


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
            CONTENT / "characteristics" / f"{stat_id}.tres",
            simple_resource(
                "CharacteristicDefinition",
                "res://date_system/content/characteristic_definition.gd",
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
            CONTENT / "venues" / f"{loc_id}.tres",
            simple_resource("DateVenue", "res://date_system/content/date_venue.gd", fields),
        )
    for outfit_id, name, price, stat_id, stage, move_id in OUTFITS:
        bonus = 1 if stat_id else 0
        fields = (
            f'id = &"{outfit_id}"\n'
            f'display_name = "{esc(name)}"\n'
            f'description = "{esc(name)}"\n'
            "enabled = true\n"
            f"price = {price}\n"
            f'stat_id = &"{stat_id}"\n'
            f"stat_bonus = {bonus}\n"
            f"min_story_stage = {stage}\n"
            f'outfit_move_id = &"{move_id}"\n'
        )
        write(
            CONTENT / "outfits" / f"{outfit_id}.tres",
            simple_resource("Outfit", "res://date_system/content/outfit.gd", fields),
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
    for move_id, name, tag, option, pos, neg, stat, level in CHARACTERISTIC_MOVES:
        write_fixed_move(move_id, name, 1, tag, option, pos, neg, req=(stat, level))
    for move_id, name, tag, option, pos, neg in OUTFIT_MOVES:
        write_fixed_move(move_id, name, 3, tag, option, pos, neg)
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
    for trait_id, name, desc, kind, characteristic_id, location_id in TRAITS:
        write(
            CONTENT / "traits" / f"{trait_id}.tres",
            simple_resource(
                "GirlTrait",
                "res://date_system/content/girl_trait.gd",
                f'id = &"{trait_id}"\n'
                f'display_name = "{esc(name)}"\n'
                f'description = "{esc(desc)}"\n'
                "enabled = true\n"
                f"kind = {kind}\n"
                f'characteristic_id = &"{characteristic_id}"\n'
                f'date_venue_id = &"{location_id}"\n',
            ),
        )

    write(
        CONTENT / "rules" / "date_rules.tres",
        simple_resource(
            "DateRules",
            "res://date_system/content/date_rules.gd",
            date_rules_fields(),
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
    move_ids += [add_res(f"res://date_system/content/moves/{i}.tres", "moves") for i, *_ in CHARACTERISTIC_MOVES]
    move_ids += [add_res(f"res://date_system/content/moves/{i}.tres", "moves") for i, *_ in OUTFIT_MOVES]
    move_ids += [add_res(f"res://date_system/content/moves/{i}.tres", "moves") for i, *_ in LOCAL_MOVES]
    sit_ids = [add_res(f"res://date_system/content/situations/{i}.tres", "situations") for i, *_ in SITUATIONS]
    girl_ids = [add_res(f"res://date_system/content/girls/{girl[0]}.tres", "girls") for girl in GIRLS]
    difficulty_ids = [add_res(f"res://date_system/content/girl_difficulty/{i}.tres", "diff") for i, *_ in DIFFICULTIES]
    object_ids = [add_res(f"res://date_system/content/local_objects/{i}.tres", "obj") for i, *_ in LOCAL_OBJECTS]
    loc_ids = [add_res(f"res://date_system/content/venues/{i}.tres", "loc") for i, *_ in LOCATIONS]
    outfit_ids = [add_res(f"res://date_system/content/outfits/{i}.tres", "outfit") for i, *_ in OUTFITS]
    trait_ids = [add_res(f"res://date_system/content/traits/{i}.tres", "trait") for i, *_ in TRAITS]
    stat_ids = [add_res(f"res://date_system/content/characteristics/{i}.tres", "stat") for i, *_ in STATS]
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
        + f"local_objects = {arr(object_ids)}\n"
        + f"date_venues = {arr(loc_ids)}\n"
        + f"outfits = {arr(outfit_ids)}\n"
        + f"traits = {arr(trait_ids)}\n"
        + f"characteristics = {arr(stat_ids)}\n"
        + f'date_rules = ExtResource("{rules_id}")\n'
    )
    write(CONTENT / "catalog" / "date_content_catalog.tres", body)
    print("seed tres written")


if __name__ == "__main__":
    main()
