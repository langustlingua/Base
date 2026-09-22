# 69. Runbook сборки Client 360

## Результат

После выполнения runbook должна работать закрытая система, в которой:

- одна семья имеет единую карточку;
- все контакты, согласия и запреты согласованы;
- сайт, пробник, обучение и сообщения пишут нормализованные события;
- оплаты и доступ сверяются;
- email/боты используют единый contact policy;
- оператор работает из очереди действий;
- реальные данные не попадают в публичную Base.

## 1. Рекомендуемый контур

Минимум:

- PostgreSQL 15+;
- backend API;
- фоновые jobs/queue;
- закрытая admin-консоль;
- secret manager;
- object storage для разрешённых вложений;
- provider adapters;
- monitoring/logging;
- staging и production;
- CI с JSON/SQL/link/secret checks.

Конкретный стек выбирается после аудита уже создаваемого приложения. Схема не требует определённого frontend framework.

## 2. Порядок миграций

1. `schema.sql` — ядро.
2. `client360-extensions.sql` — контакты, журналы, оркестрация, финансы, NBA и retention.
3. `chatbot-schema.sql` — Telegram/MAX.
4. `creator-ugc-schema.sql` — UGC и креаторы.
5. `views.sql` — базовые представления.
6. Прикладные views/materialized views из production-кода.
7. Row-level/field-level access policies.
8. Seed только справочников; никаких production-клиентов.

Каждая миграция имеет номер, checksum, down/forward-fix стратегию и rehearsal в staging.

## 3. Модули backend

| Модуль | Ответственность |
|---|---|
| Identity | family/person/contact points, merge/split |
| Consent | append-only consent и preference snapshot |
| Leads | заявки, источники, trial creation |
| Events | schema validation, idempotency, routing |
| Learning | enrollments, progress aggregates, reports |
| Communications | templates, programs, candidates, policy, delivery |
| Conversations | inbound replies, questions, promises, cases |
| Finance | orders, invoices, payments, refunds, ledger, reconciliation |
| Entitlements | trial/paid access и status transitions |
| Occasions | даты, birthday, renewal и scheduled candidates |
| NBA | action candidates и alerting |
| UGC | permissions, assets, episodes, creator analytics |
| Privacy | retention, export, correction, deletion |
| Audit | immutable security/business trail |
| Reporting | snapshots, cohorts, dashboards |

## 4. API-контракты MVP

### Inbound

- `POST /webhooks/tilda/lead`
- `POST /webhooks/site/event`
- `POST /webhooks/progressme/event`
- `POST /webhooks/robokassa/payment`
- `POST /webhooks/email/event`
- `POST /webhooks/telegram/update`
- `POST /webhooks/max/update`

Каждый endpoint: authentication/signature, raw-body size limit, schema validation, idempotency, fast acknowledgement, queued processing.

### Admin

- `GET /families/{id}`
- `GET /families/{id}/timeline`
- `GET /families/{id}/contactability`
- `POST /families/{id}/tasks`
- `POST /families/{id}/promises`
- `POST /interactions`
- `POST /identity-cases/{id}/decision`
- `POST /support-cases/{id}/transition`
- `POST /refunds/{id}/decision`
- `POST /communication-candidates/{id}/override`
- `GET /queues/today`
- `GET /alerts`

### Self-service

- `GET /me/preferences`
- `PUT /me/preferences`
- `GET /me/consents`
- `POST /me/consents/{purpose}/withdraw`
- `GET /me/access`
- `GET /me/progress`
- `POST /me/privacy-requests`

## 5. Scheduled jobs

### Каждые 1–5 минут

- process webhook queue;
- evaluate urgent candidates;
- stop queued messages on stop events;
- payment/access mismatch check;
- P0/P1 alerts.

### Каждые 15–60 минут

- communication scheduling;
- provider delivery sync;
- learning event ingestion;
- SLA checks;
- stale pending payments.

### Ежедневно

- occasions;
- reconciliation;
- snapshots;
- data quality rules;
- retention actions;
- digest;
- failed job replay review;
- expiring UGC permissions and offers.

### Еженедельно

- Voice of Customer clusters;
- lifecycle/retention review;
- deliverability report;
- permission/access review deltas;
- creator recommendation generation;
- experiment guardrails.

## 6. Админ-экраны первой очереди

1. Авторизация и роли.
2. Очередь «Сегодня».
3. Карточка семьи.
4. Timeline.
5. Контакты/верификация/предпочтения.
6. Дети и доступы.
7. Контакты, вопросы, promises, cases.
8. Оплаты/возвраты/entitlements.
9. Consent/privacy.
10. Alerts/integration failures.

Вторая очередь: campaign builder, program monitor, reconciliation workspace, data quality, UGC/creator administration.

## 7. Карточка семьи — точная композиция

### Header

- display name и lifecycle;
- owner;
- timezone;
- главный alert;
- current NBA;
- кнопки безопасных действий.

### Contactability

- взрослые и роли;
- маскированные контакты;
- verification;
- allowed purposes/channels;
- quiet window;
- suppression причины.

### Children and learning

- каждый ребёнок отдельно;
- курс/учебник/класс;
- status доступа;
- last learning;
- milestone;
- только необходимая возрастная информация.

### Money

- order/invoice/payment/refund;
- net cash;
- entitlement period;
- next due;
- discrepancy.

### Memory

- последние контакты;
- открытые вопросы;
- promises;
- support cases;
- dates/occasions;
- timeline filters.

## 8. Очередь событий

Каждое входящее событие проходит:

`receive → authenticate → validate → dedupe → persist → route → project → automate → observe`

- raw payload хранится кратко и защищённо;
- normalized event — в event store;
- projection обновляет domain tables;
- automation создаёт candidates, но не отправляет в обход policy;
- ошибки уходят в dead-letter queue;
- replay идемпотентен.

## 9. Источники истины

| Домен | Канонический источник |
|---|---|
| семья/контакты/предпочтения | Client 360 |
| consent proof | append-only consent registry |
| заявки | Client 360 после приёма Tilda/site |
| обучение | ProgressMe/учебная система, агрегат в Client 360 |
| платёж/возврат | Robokassa + internal financial ledger |
| доступ | entitlement service, синхронизированный с платформой |
| доставка письма | provider events |
| переписка | канал; summary/outcome в Client 360 |
| web acquisition | first-party events + Метрика для сверки |
| UGC права | UGC permission registry |

## 10. Минимальные справочники

- lifecycle stages;
- contact types/statuses;
- consent purposes;
- channels/message classes;
- outcome codes;
- question topics;
- objection codes;
- support categories/severity;
- payment/refund statuses;
- entitlement basis/status;
- event names/schema versions;
- action types/reason codes;
- alert rules;
- retention classes;
- UGC permission scopes.

Справочники versioned; изменение значения не переписывает историю.

## 11. Безопасность до импорта

- 2FA/SSO для сотрудников;
- role and field-level access;
- encryption in transit/at rest;
- secret manager;
- audit;
- production allowlist/admin protection;
- backups и restore test;
- log redaction;
- staging recipient allowlist;
- dependency/secret scanning;
- incident runbook;
- export controls;
- session timeout и revoke.

Импорт реальных контактов запрещён до прохождения этих gates.

## 12. Импорт

1. Инвентаризация источников.
2. Защищённые выгрузки.
3. Mapping в staging tables.
4. Нормализация контактов.
5. Доказательства consent отдельно.
6. Duplicate candidates.
7. Conflict report.
8. Dry run counts/sums.
9. Ручное утверждение.
10. Production import.
11. Reconciliation.
12. Удаление временных файлов по policy.

## 13. Рекомендуемые волны

### Wave 0 — фундамент

Схема, auth, roles, audit, secrets, environments, CI, backups.

### Wave 1 — семья и заявка

Identity, contacts, consent, lead, trial, family card, Today queue.

### Wave 2 — события и обучение

Website/ProgressMe ingestion, sessions, trial funnel, parent progress.

### Wave 3 — деньги и доступ

Orders, payments, refunds, entitlements, reconciliation.

### Wave 4 — коммуникации

Templates, email programs, contact policy, replies, suppression, deliverability.

### Wave 5 — память и интеллект

Journals, questions, promises, NBA, alerts, data quality.

### Wave 6 — боты и UGC

Telegram/MAX, creator portal, permissions, attribution, payouts.

### Wave 7 — оптимизация

Experiments, warehouse, incremental measurement, advanced reporting.

## 14. Go-live checklist

- [ ] роли проверены тестами;
- [ ] secret scan чист;
- [ ] public GitHub чист от PII;
- [ ] consent proof работает;
- [ ] unsubscribe/suppression мгновенны;
- [ ] webhook idempotency доказана;
- [ ] staging не отправляет реальным людям;
- [ ] payment/access reconciliation работает;
- [ ] backup восстановлен на тесте;
- [ ] privacy request пройден E2E;
- [ ] delete/retention jobs работают;
- [ ] kill switches проверены;
- [ ] оператор обучен;
- [ ] первый запуск ограничен canary cohort;
- [ ] rollback owner на связи.

## 15. Что сверять с параллельной разработкой

Проверить, есть ли уже:

- отдельные person/family/contact point;
- multi-child family;
- append-only consent;
- event idempotency;
- source provenance;
- service vs marketing separation;
- cross-channel cap;
- conversation lock;
- payment/order/refund separation;
- entitlement как отдельная сущность;
- merge/split;
- data purpose/retention;
- restricted notes;
- raw vs aggregate analytics;
- server-side payment confirmation;
- stop events before send;
- audit/roles/secret manager;
- reconciliation и dead-letter queue.

Любой отсутствующий пункт — не обязательно блокер MVP, но его нужно явно поместить в backlog с владельцем и риском.
