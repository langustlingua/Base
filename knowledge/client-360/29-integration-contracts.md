# 29. Контракты интеграций

## Общие правила webhook

- HTTPS only;
- подпись / shared secret;
- timestamp и защита от replay;
- уникальный external event ID;
- idempotent processing;
- быстрый `2xx` после помещения в очередь;
- retry с exponential backoff;
- dead-letter queue;
- безопасные логи без секретов;
- schema version;
- мониторинг задержки и ошибок.

## Tilda / формы

Принимать:

- submission ID;
- form ID;
- submitted_at;
- контакт;
- класс;
- учебник;
- комментарий;
- согласия и версия текста;
- landing page;
- UTM;
- campaign key.

Ответ формы «успех» показывать только после принятия backend или честно сообщать о постановке в очередь.

## ProgressMe

Синхронизировать, если API/экспорт позволяет:

- пользователь / enrollment;
- курс;
- статус доступа;
- начало и конец;
- последний вход;
- lesson/activity events;
- прогресс;
- ошибки синхронизации.

Не перезаписывать CRM-согласия данными ProgressMe.

## Robokassa

Принимать:

- invoice ID;
- amount и currency;
- status;
- signature verification result;
- product/tariff reference;
- promo code;
- paid_at;
- refund / chargeback.

Доступ выдаётся после серверного подтверждения, не после возврата пользователя на success page.

## Email provider

Исходящие:

- recipient ID, не логировать лишний PII;
- template version;
- program/campaign;
- merge variables;
- idempotency key;
- unsubscribe state.

Входящие события:

- accepted;
- delivered;
- soft/hard bounce;
- complaint;
- unsubscribe;
- click;
- reply, если доступно.

Hard bounce и complaint немедленно обновляют deliverability/suppression.

## Gmail

Gmail остаётся источником оригинальной переписки, но в Client 360 попадают метаданные и резюме. Связь по verified email/external message ID; неоднозначные адреса не прикрепляются автоматически.

## WhatsApp

- opt-in отдельно;
- approved template, если это требует провайдер;
- session window;
- delivery/read/reply status;
- stop words;
- человеческая передача;
- частотные лимиты;
- стоимость сообщения.

## Ошибки интеграции

Для каждой:

- connector;
- external event ID;
- safe payload hash;
- first_seen / last_seen;
- retry count;
- error category;
- impact;
- owner;
- resolution.

Нельзя бесконечно повторять невалидное событие.

