# 03. Словарь событий

## Единый формат

Каждое событие передаёт:

| Поле | Требование |
|---|---|
| `event_id` | уникальный UUID для защиты от дублей |
| `event_name` | имя из утверждённого справочника |
| `occurred_at` | фактическое время события в UTC |
| `received_at` | когда событие получила Client 360 |
| `source` | tilda / website / progressme / robokassa / email / whatsapp / manual |
| `anonymous_id` | до идентификации пользователя |
| `family_id` | после безопасного связывания |
| `guardian_id` | когда действие совершил взрослый |
| `student_id` | когда действие относится к ребёнку |
| `session_id` | сессия сайта / кабинета |
| `properties` | параметры конкретного события |
| `schema_version` | версия контракта |

## Сайт и лендинги

| Событие | Когда | Полезные свойства |
|---|---|---|
| `page_viewed` | просмотр страницы | page_url, page_type, referrer, UTM |
| `session_started` | первый просмотр сессии | device_type, browser, landing_url |
| `session_ended` | закрытие / тайм-аут | engaged_seconds, pages_viewed |
| `scroll_depth_reached` | 25/50/75/90% | depth_percent |
| `cta_clicked` | клик по CTA | cta_id, cta_text, page_url |
| `form_started` | взаимодействие с формой | form_id |
| `form_field_error` | ошибка | field_name, error_code — без значения поля |
| `form_submitted` | успешная заявка | form_id, lead_id, campaign_key |
| `pricing_viewed` | просмотр цены | tariff_id, campaign_key |
| `checkout_opened` | переход к оплате | tariff_id, amount |

### Время на сайте

Не считать разницу между открытием и закрытием вкладки. Это завышает показатель.

`engaged_seconds` растёт только пока:

- вкладка видима;
- пользователь двигает мышью, прокручивает, нажимает или воспроизводит материал;
- нет более 30 секунд бездействия подряд.

Сохранять агрегат по сессии, а не поток координат мыши и каждое движение.

## Пробный доступ и кабинет

| Событие | Значение |
|---|---|
| `trial_requested` | заявка отправлена |
| `trial_created` | доступ реально создан |
| `access_email_sent` | письмо со входом отправлено |
| `access_email_delivered` | доставлено |
| `first_login` | первый успешный вход |
| `login_failed` | неуспешная попытка; без пароля в свойствах |
| `course_opened` | открыт курс |
| `lesson_started` | начат урок |
| `activity_started` | начато упражнение |
| `activity_completed` | упражнение завершено |
| `answer_submitted` | ответ отправлен; не хранить полный ответ без цели |
| `lesson_completed` | урок завершён |
| `second_session_started` | повторный вход в другой сессии |
| `trial_expiring` | служебное событие до окончания |
| `trial_expired` | пробник завершён |

## Обучение

| Событие | Свойства |
|---|---|
| `module_selected` | module_id, school_book |
| `audio_played` | asset_id, duration_seconds |
| `phrase_repeated` | activity_id, attempt_number |
| `vocabulary_item_practiced` | word_id, result |
| `activity_attempted` | activity_id, attempt_number, correct |
| `learning_session_completed` | active_seconds, activities_completed |
| `progress_milestone_reached` | milestone_key |
| `inactivity_threshold_reached` | inactive_days |
| `course_access_paused` | reason |
| `course_access_restored` | reason |

Не превращать образовательную аналитику в тотальное наблюдение. Собирать события, которые помогают улучшать курс, сопровождать ребёнка или объяснять результат родителю.

## Email и мессенджеры

| Событие | Комментарий |
|---|---|
| `message_queued` | поставлено в очередь |
| `message_sent` | провайдер принял |
| `message_delivered` | доставлено |
| `message_bounced` | hard / soft |
| `message_opened` | вспомогательно: может быть ложным |
| `message_link_clicked` | хранить link_id, не секретный URL |
| `message_replied` | есть ответ |
| `unsubscribe_requested` | немедленно остановить маркетинг |
| `spam_complaint_received` | блокировка маркетинга и расследование |
| `whatsapp_read` | если канал сообщает статус |
| `call_completed` | итог звонка, не запись по умолчанию |

## Оплаты

| Событие | Свойства |
|---|---|
| `checkout_started` | tariff_id, amount, campaign_key |
| `payment_pending` | invoice_id |
| `payment_succeeded` | amount, currency, provider |
| `payment_failed` | safe_failure_code |
| `payment_refunded` | amount, reason_category |
| `renewal_due` | due_at |
| `renewal_succeeded` | period_end |
| `renewal_failed` | safe_failure_code |
| `access_blocked_nonpayment` | enrollment_id |

## Поддержка и отношения

| Событие | Значение |
|---|---|
| `support_case_opened` | создано обращение |
| `support_first_response` | первый человеческий ответ |
| `support_case_resolved` | решено |
| `promise_made` | сотрудник пообещал действие |
| `promise_completed` | обещание выполнено |
| `feedback_received` | обратная связь |
| `nps_submitted` | оценка + причина |
| `testimonial_permission_granted` | отдельное разрешение |
| `referral_shared` | рекомендация отправлена |
| `referral_converted` | приглашённая семья купила |

## Правила качества

1. Событие — факт, а не вывод. `lesson_completed` — факт; `family_happy` — не событие.
2. Выводы хранятся как рассчитанные признаки: `health_score`, `churn_risk`.
3. Повторная доставка одного `event_id` не создаёт дубль.
4. Схема версионируется.
5. Нельзя записывать пароли, токены, полный текст платёжных ошибок с реквизитами.
6. PII не помещается в `properties`, если для неё есть отдельная защищённая сущность.

