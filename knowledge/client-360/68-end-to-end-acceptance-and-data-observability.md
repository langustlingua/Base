# 68. Сквозная приёмка и наблюдаемость данных

## Цель

Client 360 считается готовой не тогда, когда созданы таблицы, а когда доказано, что сквозные сценарии работают безопасно: от заявки и события до сообщения, оплаты, доступа, журнала, отчёта и удаления.

## 1. Уровни тестирования

1. Schema validation.
2. Unit tests бизнес-правил.
3. Contract tests внешних адаптеров.
4. Integration tests в staging.
5. End-to-end synthetic journeys.
6. Migration rehearsal.
7. Security/privacy tests.
8. Operational game days.
9. Production canary и reconciliation.

## 2. Test data

Только синтетические семьи:

- одна мама + один ребёнок;
- два взрослых + два ребёнка;
- один плательщик, другой основной контакт;
- два email одного взрослого;
- общий телефон у двух исторических записей;
- bounced email + разрешённый бот;
- неизвестное согласие;
- отписка;
- возврат;
- ошибка merge и последующий split;
- ребёнок с UGC permission и без него;
- креаторская атрибуция;
- неизвестный timezone;
- high-risk privacy case.

Синтетические адреса используют зарезервированные домены/allowlist. Staging физически не может отправить реальному получателю.

## 3. Сквозные сценарии

### E2E-01. Новая заявка

1. Форма отправлена один раз.
2. Созданы family/guardian/student/lead без дубля.
3. Сохранены first touch и UTM.
4. Зафиксированы версии уведомления/согласий.
5. Создан пробник или операционная задача.
6. Кандидат на сервисное письмо прошёл policy.
7. Timeline отображает события в правильном порядке.

Повтор webhook не создаёт вторую семью или письмо.

### E2E-02. Дубликат заявки

- совпал verified email;
- новая заявка добавлена к существующей семье;
- исходные UTM новой заявки сохранены;
- lifecycle не откатился;
- consent не был повышен автоматически;
- оператор видит новую потребность.

### E2E-03. Три пробных дня

- доступ доставлен;
- no-login шаг остановлен после входа;
- first-value шаг остановлен после результата;
- checkout остановлен после payment success;
- ответ клиента включает conversation lock;
- окончание пробника не блокирует поддержку.

### E2E-04. Все каналы

- email и бот получают одну тему без дубля;
- предпочтение канала соблюдается;
- fallback запускается только после допустимого failure;
- общий family cap работает;
- opt-out в одном purpose не блокирует необходимый сервис и не открывает другой маркетинговый канал.

### E2E-05. День рождения

- MM-DD обрабатывается без фиктивного года;
- требуется birthday preference;
- детское сообщение идёт взрослому;
- open complaint отменяет сообщение;
- повторный запуск job не создаёт дубль.

### E2E-06. Оплата

- client redirect не создаёт success;
- provider webhook с валидной подписью создаёт payment;
- duplicate webhook идемпотентен;
- invoice/order/entitlement согласованы;
- отправлено сервисное уведомление;
- creator commission provisional, если есть атрибуция.

### E2E-07. Частичный возврат

- создаётся refund operation;
- original payment неизменен;
- net cash пересчитан;
- entitlement обработан по policy;
- комиссия скорректирована;
- клиент получает status update;
- маркетинг поставлен на паузу в конфликтном окне.

### E2E-08. Hard bounce и complaint

- hard bounce блокирует contact point;
- complaint создаёт suppression;
- queued marketing отменяется;
- owner получает alert;
- сервис выбирает только допустимый резервный путь;
- повторный импорт не снимает suppression.

### E2E-09. Merge/split

- кандидат объясним;
- ручное merge сохраняет aliases и provenance;
- строгие запреты объединяются;
- split восстанавливает связи;
- в процессе marketing paused;
- audit полный.

### E2E-10. Privacy request

- личность проверена;
- найдены все системы;
- marketing paused;
- export/correction/delete выполняются по scope;
- processors получают задания;
- ограниченно сохраняемые данные отделены;
- финальный audit не раскрывает удалённые данные.

### E2E-11. UGC

- asset нельзя опубликовать без набора permissions;
- withdrawal снимает публикацию;
- creator portal не показывает PII;
- малые question clusters скрыты;
- refund меняет payout ledger;
- публичная карточка не содержит точную дату/школу/локацию.

## 4. Contract tests

Для каждого connector:

- подпись/аутентификация;
- schema version;
- required fields;
- idempotency;
- retry/backoff;
- out-of-order events;
- late events;
- unknown event type;
- rate limit;
- timeout;
- dead-letter queue;
- replay;
- PII redaction in logs;
- sandbox/production separation.

## 5. Data observability

### Freshness

- когда последний успешный sync;
- lag p50/p95/max;
- stale tables/views;
- missed partitions/jobs.

### Volume

- события по источнику и имени;
- резкие нули/скачки;
- лиды, платежи, сообщения, занятия;
- production vs expected seasonality.

### Validity

- schema errors;
- invalid enums;
- impossible dates;
- negative sums/time;
- events from future;
- invalid UUID/reference.

### Uniqueness

- duplicate event IDs;
- duplicate provider operations;
- duplicate message idempotency keys;
- external identity collisions;
- multiple primary contacts.

### Referential integrity

- payments without invoice/order;
- enrollment without student;
- message without recipient;
- consent without subject;
- UGC asset without subject/permission;
- question without conversation/source.

### Consistency

- paid but no access;
- refund > payment;
- active program after stop event;
- marketing allowed after opt-out;
- birthday message without date/purpose;
- creator payable after full refund;
- family lifecycle contradicts active enrollment.

## 6. SLO и alerts

| Сигнал | Цель | Severity |
|---|---:|---:|
| consent/payment lag | <1 мин p95 | P1 |
| trial creation lag | <5 мин p95 | P1/P2 |
| site event lag | <15 мин p95 | P2 |
| duplicate payment | 0 | P0/P1 |
| marketing after opt-out | 0 | P0 |
| paid without access >5 мин | 0 | P1 |
| critical case without owner | 0 | P1 |
| failed daily reconciliation | 0 | P1 |
| schema rejection | <0.5%, investigated | P2 |
| real recipient in staging | 0 | P0 |

## 7. Reconciliation jobs

Ежедневно:

- Tilda/website leads ↔ Client 360;
- ProgressMe users/enrollments/events ↔ students/enrollments;
- Robokassa operations ↔ invoices/payments/refunds;
- provider deliveries ↔ message records;
- consents ↔ current preference snapshot;
- UGC permissions ↔ active publications;
- creator ledger ↔ net attributed receipts;
- tasks/promises ↔ open/overdue queue.

Каждый job сохраняет start/end, counts, checksums, discrepancies и resolution.

## 8. Migration rehearsal

До production:

1. Заморозить копию исходной выгрузки в закрытом контуре.
2. Посчитать строки и уникальные контакты.
3. Прогнать staging normalization.
4. Получить duplicate/conflict report.
5. Проверить consent evidence.
6. Выполнить dry run загрузки.
7. Сверить counts, sums и выборку карточек.
8. Проверить rollback.
9. Повторить на новой копии.
10. Только затем назначить production cutover.

## 9. Release gates

Запуск блокируется, если:

- нет suppression/отписки;
- staging может отправлять наружу;
- payment webhook не идемпотентен;
- consent нельзя доказать;
- нет backup/restore test;
- нет owner/kill switch;
- real PII есть в GitHub или fixtures;
- paid-without-access не отслеживается;
- журнал аудита изменяем;
- роли не проверены;
- deletion/withdrawal не протестированы;
- UGC можно опубликовать без permissions.

## 10. Production canary

Порядок:

1. Только внутренние синтетические записи.
2. Одна разрешённая тестовая семья.
3. Один сервисный сценарий.
4. Небольшая когорта пробника.
5. Один marketing program после review.
6. Наблюдение полного окна результата.
7. Расширение только при выполнении guardrails.

## 11. Еженедельный data review

- нарушения SLO;
- новые discrepancies;
- PII/security alerts;
- top suppressions;
- неклассифицированные события;
- duplicates/merge errors;
- изменения схем;
- просроченные processor/retention reviews;
- ложные alerts;
- один конкретный corrective action с владельцем и сроком.

## 12. Definition of Done

Функция готова, если:

- schema и business rules версионированы;
- unit/contract/E2E tests проходят;
- audit и observability есть;
- privacy/access/retention учтены;
- rollback проверен;
- owner и runbook назначены;
- dashboard показывает outcome и guardrails;
- документация и machine contract синхронизированы;
- в GitHub нет реальных данных и секретов.
