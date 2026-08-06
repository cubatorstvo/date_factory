# Multi-Tenant Compatibility Matrix
| Группа | Тема | Стадии | Район | Отд. вход | Отд. этаж | Loadable transition | Путаница | Сложность | Итог |
|---|---|---|---|---|---|---|---|---|---|
| flower+gift | высокая | высокая (оба 1) | main_street | желательно 2 двери | 1 этаж ок | нет | средняя | средняя | допустимо |
| jewelry+clothing | высокая | высокая | main_street | 2 двери | 1 | нет | средняя | средняя | допустимо |
| photo+barber | высокая | высокая (оба 3) | agency_row | 2 двери | 1 | нет | низкая | средняя | рекомендуется |
| agency+photo+barber | средняя | высокая | agency_row | lobby+side | visual floors | нет | средняя | высокая | допустимо осторожно |
| cinema+bookstore | низкая | оба 2 | park_leisure | отдельные | 2 | cinema loadable | высокая | высокая | не рекомендуется |
| cinema+arcade | средняя | оба 2 | park_leisure | отдельные | лучше отдельно | оба venue | высокая | высокая | не рекомендуется |
| restaurant+bar | средняя | оба 2 | park_leisure | 2 двери | 1–2 | restaurant loadable | средняя | средняя | допустимо |
| gym+bookstore | низкая | оба 2 | park_leisure | 2 | 1 | нет | высокая | средняя | не рекомендуется |
| cafe+flower | низкая | оба 1 | main_street | 2 | 1 | cafe loadable | высокая (cafe uniqueness) | средняя | не рекомендуется |
| internet+homeware | низкая | оба 1 | main_street | 2 | 1 | нет | высокая | средняя | не рекомендуется |
| arcade+karaoke | средняя | оба 2 | park_leisure | arcade facade + karaoke world | karaoke не здание | arcade venue | средняя | низкая | допустимо как соседство, не один building |

## Правила из проверки
1. Cafe / Cinema / Agency — **не** отдавать в multi-tenant без крайней нужды (узнаваемость).
2. Лучший multi-tenant: **photo+barber** (один stage, один district, оба Storefront).
3. Retail pairs на main_street допустимы, если две читаемые двери и две вывески.
4. Не смешивать stage1 storefront с stage2/3 venue в одном shell.
5. Hollow multi-floor на текущих Building_* **отклонён** (нет пригодного интерьера).
