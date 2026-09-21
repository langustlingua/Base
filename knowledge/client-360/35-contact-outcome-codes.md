# 35. Итоги контакта

Свободной заметки недостаточно: для аналитики нужен справочник результата, а комментарий дополняет его.

## Входящий контакт

- `question_answered`;
- `access_problem`;
- `payment_problem`;
- `lesson_help`;
- `complaint`;
- `refund_request`;
- `privacy_request`;
- `positive_feedback`;
- `feature_request`;
- `wrong_recipient`;
- `spam`;
- `needs_followup`.

## Исходящий контакт

- `reached_resolved`;
- `reached_followup_needed`;
- `reached_not_interested`;
- `reached_call_later`;
- `no_answer`;
- `invalid_contact`;
- `message_delivered_no_reply`;
- `blocked_by_consent`;
- `duplicate_lead`;
- `technical_handoff`.

## Причины отложить

- нет времени сегодня;
- каникулы;
- болезнь — не хранить диагноз;
- ждут школьную тему;
- ждут зарплату / решение семьи — хранить только если сообщил родитель и это нужно;
- техническая проблема;
- попросили конкретную дату.

## Следующий шаг

После `needs_followup` обязательны:

- действие;
- ответственный;
- срок;
- разрешённый канал;
- условие отмены.

`no_answer` не запускает бесконечную серию. После заданного числа попыток запись переводится в спокойный статус без давления.

