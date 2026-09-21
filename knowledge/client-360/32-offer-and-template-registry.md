# 32. Реестр офферов и шаблонов

## Offer registry

Цена не должна жить в десятках писем и файлов.

Поля оффера:

- `offer_id`;
- продукт и тариф;
- аудитория;
- регион;
- класс;
- цена;
- обычная сравнительная стоимость и её основание;
- скидка и способ расчёта;
- промокод;
- valid_from / valid_until;
- timezone дедлайна;
- landing URL;
- checkout URL;
- разрешённые каналы;
- несовместимые офферы;
- owner;
- status;
- version.

Пример логики Смоленска:

```text
offer_id: smolensk_grade2_2026
grade: 2
region: Smolensk
price: 7900 RUB
discount_message: 60% скидка
valid_until: 2026-10-05 23:59:59 Europe/Moscow
promo_code: Смоленск
```

Перед запуском перепроверяется фактическая опубликованная страница. Конфликтующие старые креативы 7 495 ₽ / 50% и другие тарифы не являются источником истины.

## Template registry

Для каждого шаблона:

- `template_id` и версия;
- канал;
- язык;
- service / marketing;
- program_key;
- funnel role;
- subject / preview;
- body;
- variables;
- fallback каждой переменной;
- CTA;
- required consent;
- allowed offer IDs;
- owner;
- status;
- approved_at;
- test evidence;
- last reviewed_at.

## Переменные

Хорошие:

- `parent_first_name`;
- `child_first_name` с fallback «ребёнок»;
- `trial_link`;
- `current_module`;
- `trial_end_at_local`;
- `offer_price_formatted`;
- `support_reply_address`.

Плохие:

- произвольный HTML из формы;
- полный комментарий клиента;
- секретный токен в analytics URL;
- значение без fallback;
- цена, рассчитанная прямо в тексте письма.

## Статусы шаблона

`draft → reviewed → approved → active → deprecated → archived`

Изменение смысла, цены или обязательных переменных создаёт новую версию. Старые отправки всегда указывают точную версию.

## Tone check LANGUST

- спокойно и конкретно;
- не стыдить маму;
- не обещать гарантированные оценки;
- не называть ребёнка ленивым или неспособным;
- один CTA;
- объяснять следующий шаг;
- после заявки — помощь и продуктовый опыт, не повторное ковыряние боли;
- дедлайн настоящий и не продлевается скрыто.

