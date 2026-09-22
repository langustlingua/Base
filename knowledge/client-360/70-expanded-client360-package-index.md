# 70. Расширенный пакет Client 360

## Назначение

Этот индекс объединяет новый implementation-ready слой базы знаний. Он дополняет ранее опубликованное мастер-ТЗ и не содержит production-данных, персональных сведений, секретов или коммерческих выгрузок.

## Контакты и память

| Документ | Назначение |
|---|---|
| [58-contact-and-identity-master.md](58-contact-and-identity-master.md) | Многоканальные контакты, внешние ID, provenance, дедупликация и merge/split |
| [60-dates-birthdays-and-occasion-engine.md](60-dates-birthdays-and-occasion-engine.md) | Дни рождения, годовщины, точность дат и scheduled occasions |
| [61-journals-diaries-and-customer-memory.md](61-journals-diaries-and-customer-memory.md) | Контакты, обучение, продажи, поддержка, деньги, обещания и решения |
| [66-questions-objections-and-voice-of-customer.md](66-questions-objections-and-voice-of-customer.md) | Вопросы, возражения, ответы, кластеры тем и продуктовые улучшения |

## Email и все каналы

| Документ | Назначение |
|---|---|
| [59-email-marketing-operating-system.md](59-email-marketing-operating-system.md) | Lifecycle-программы, шаблоны, stop events, измерение и deliverability |
| [64-communication-orchestration-and-contact-policy.md](64-communication-orchestration-and-contact-policy.md) | Общая политика email, Telegram, MAX, WhatsApp, звонков и ручных контактов |
| [65-next-best-action-and-alerts.md](65-next-best-action-and-alerts.md) | Объяснимые рекомендации, приоритеты и alerts |
| [email-programs.json](email-programs.json) | 21 программа и 33 шага в машиночитаемом виде |
| [contact-policy.json](contact-policy.json) | Caps, quiet hours, suppression, channel rules и conversation lock |

## Сайт, обучение и деньги

| Документ | Назначение |
|---|---|
| [62-web-product-and-learning-telemetry.md](62-web-product-and-learning-telemetry.md) | Визиты, engaged time, web/product/learning events и identity stitching |
| [63-financial-ledger-access-and-reconciliation.md](63-financial-ledger-access-and-reconciliation.md) | Orders, invoices, payments, refunds, subscriptions, entitlements и сверка |
| [event-schema-v2.json](event-schema-v2.json) | Расширенный и безопасный контракт событий |

## Privacy, реализация и качество

| Документ | Назначение |
|---|---|
| [67-data-purpose-retention-and-privacy-register.md](67-data-purpose-retention-and-privacy-register.md) | Цели, минимизация, детские данные, обработчики, сроки и удаление |
| [68-end-to-end-acceptance-and-data-observability.md](68-end-to-end-acceptance-and-data-observability.md) | E2E-сценарии, SLO, сверки, release gates и production canary |
| [69-client360-build-runbook.md](69-client360-build-runbook.md) | Модули, API, jobs, экраны, миграции и порядок запуска |
| [client360-extensions.sql](client360-extensions.sql) | 37 новых таблиц, 21 индекс и 3 представления |
| [data-purpose-register.json](data-purpose-register.json) | 14 целей, 8 retention classes и 22 группы полей |

## Рекомендуемый порядок чтения

1. [69-client360-build-runbook.md](69-client360-build-runbook.md) — увидеть целевой контур и порядок работ.
2. [58-contact-and-identity-master.md](58-contact-and-identity-master.md) — утвердить модель семьи и контактов.
3. [67-data-purpose-retention-and-privacy-register.md](67-data-purpose-retention-and-privacy-register.md) — удалить всё, для чего нет цели.
4. [62-web-product-and-learning-telemetry.md](62-web-product-and-learning-telemetry.md) и [63-financial-ledger-access-and-reconciliation.md](63-financial-ledger-access-and-reconciliation.md) — определить факты.
5. [64-communication-orchestration-and-contact-policy.md](64-communication-orchestration-and-contact-policy.md) — определить, когда контакт допустим.
6. [59-email-marketing-operating-system.md](59-email-marketing-operating-system.md) — включать программы только поверх готовой политики.
7. [68-end-to-end-acceptance-and-data-observability.md](68-end-to-end-acceptance-and-data-observability.md) — проверить систему до импорта и отправок.

## Безопасная граница

Публичный репозиторий хранит только документацию, DDL, справочники и синтетические примеры. Реальные контакты, даты рождения, платежи, переписка, идентификаторы аналитики, выгрузки, токены и резервные копии должны находиться только в закрытом рабочем контуре.
