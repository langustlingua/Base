# 42. Словарь метрик

У каждой метрики должны быть владелец, формула, источник, окно, часовой пояс и версия. Нельзя использовать одно название для разных формул.

| Метрика | Формула | Источник |
|---|---|---|
| lead_to_trial | trial_created / qualified_lead | Client 360 |
| trial_activation | first_login / trial_created | кабинет |
| first_value_rate | first_value / first_login | учебные события |
| second_session_rate | second_session / first_login | учебные события |
| trial_to_paid | first_payment / eligible_trial | платежи + trial |
| payment_success | successful_attempt / payment_attempt | Robokassa |
| access_mismatch | paid_without_access / paid | сверка |
| day_7_active | active_day_7 / paid_cohort | learning facts |
| renewal_rate | renewed / eligible_to_renew | enrollment + payments |
| gross_revenue | сумма успешных оплат | платежи |
| refunds | сумма подтверждённых возвратов | платежи |
| net_revenue | gross_revenue - refunds | финансовый слой |
| contribution_margin | net_revenue - variable_costs | финансовый слой |
| first_response_time | first_human_reply_at - case_created_at | support |
| promise_breach_rate | overdue_promises / due_promises | tasks |
| hard_bounce_rate | hard_bounced / accepted | email provider |
| complaint_rate | complained / delivered | email provider |

## Правила расчёта

- деноминатор и исключения фиксируются явно;
- cohort определяется датой первого квалифицирующего события;
- денежные суммы хранятся в минимальных единицах и с валютой;
- время хранится в UTC, показывается в локальном часовом поясе;
- бот-трафик и внутренние тесты помечаются, а не удаляются задним числом;
- перерасчёт прошлого периода оставляет версию формулы;
- missing, zero и not applicable — разные состояния.

## Запреты

- не оптимизировать кампанию только по open rate;
- не смешивать заявки и семьи;
- не считать повторную оплату новым клиентом;
- не делить на всех посетителей, если метрика относится к consented сегменту;
- не менять формулу без записи в changelog.
