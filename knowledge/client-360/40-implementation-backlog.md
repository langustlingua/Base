# 40. Backlog реализации

## P0 — до любых массовых отправок

- закрытая база, не GitHub;
- RBAC;
- отдельное marketing consent;
- suppression;
- dry-run default;
- owner approval с expiry;
- unsubscribe;
- audit log;
- offer registry;
- production/staging separation;
- backup и restore test;
- HTTPS;
- webhook signatures;
- импорт через staging;
- запрет PII/secrets в логах.

## P1 — операционная польза

- карточка семьи;
- дети и enrollments;
- журнал контактов;
- задачи и обещания;
- trial states;
- Robokassa reconciliation;
- today queue;
- support cases;
- ProgressMe activity;
- weekly parent report;
- daily digest Татьяне / Гузель.

## P2 — рост и удержание

- campaign registry;
- template registry;
- attribution;
- engaged web time;
- churn risk;
- win-back;
- referrals;
- reviews/UGC permissions;
- experiments;
- cohort dashboards;
- expenses and profit.

## P3 — масштабирование

- data warehouse;
- anomaly detection;
- self-service preference center;
- self-service support;
- next best action engine;
- автоматический учебный календарь;
- разные учебники / классы / регионы;
- партнёрский кабинет;
- интеграционные health dashboards.

## Не делать раньше времени

- AI, который автоматически отвечает родителям без контроля;
- сложный predictive churn на 182 семьях;
- тотальную запись сессий;
- десятки кастомных scores;
- мобильное приложение до проверки web-кабинета;
- перенос всех данных без dedupe;
- массовую рассылку для «проверки, работает ли».

## Следующий конкретный спринт

1. Утвердить домены кабинета и ProgressMe.
2. Развернуть staging по HTTPS.
3. Создать таблицы families / guardians / students / consents / leads / enrollments / interactions / tasks / payments.
4. Загрузить синтетический пример.
5. Импортировать копию clients.json только в staging.
6. Получить отчёт дублей и качества.
7. Собрать экран «Сегодня».
8. Подключить read-only Robokassa reconciliation.
9. Подключить trial events.
10. Запустить только внутренний dry run.

