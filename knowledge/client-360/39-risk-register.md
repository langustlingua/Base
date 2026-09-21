# 39. Реестр рисков

| Риск | Вероятность / ущерб | Контроль |
|---|---|---|
| Реальные данные попали в публичный GitHub | высокий ущерб | .gitignore, secret/PII scan, review |
| Рассылка старой базе без согласия | высокий | consent unknown, dry run, approval |
| Смешаны цены Смоленска и стандартные | высокий | offer registry и audience guard |
| Оплата есть, доступа нет | высокий | webhook + reconciliation + urgent task |
| Доступ есть после возврата | средний/высокий | refund reconciliation |
| Один родитель получает дубли по двум детям | средний | family-level frequency cap |
| Неверное объединение семей | высокий | staging и ручной review medium matches |
| Open rate принят за интерес | средний | product success events |
| Время вкладки принято за обучение | средний | active heartbeat |
| Токен/API key утёк | высокий | secrets manager, rotation, scan |
| lk-поддомен конфликтует с ProgressMe | высокий | решить доменную схему до релиза |
| Нет email verification | высокий | отдельный release gate |
| Публичная ссылка прогресса перебирается | высокий | random token, expiry, rate limit |
| Гузель видит/экспортирует лишнее | средний | RBAC и audit |
| Маркетинг идёт при открытой жалобе | высокий | suppression by case priority |
| Невыполненные обещания теряются | средний | promise ledger и overdue queue |
| Backup не восстанавливается | высокий | restore drills |
| Профилирование унижает ребёнка | высокий | только наблюдаемые факты, human review |
| Система слишком сложна и не заполняется | высокий | этапность и экран «Сегодня» |
| SaaS-расходы съедают прибыль | средний | subscription registry и monthly review |

## Поля риска

- owner;
- trigger;
- preventive controls;
- detective controls;
- response;
- residual risk;
- review date;
- evidence.

Риск со словами «когда-нибудь проверим» без owner и даты считается открытым.

