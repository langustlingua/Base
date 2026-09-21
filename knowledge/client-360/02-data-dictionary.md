# 02. Словарь данных

Пометка обязательности:

- **MUST** — без поля сущность не работает;
- **SHOULD** — желательно, но можно заполнить позже;
- **OPTIONAL** — только при понятной цели;
- **SENSITIVE** — ограничить доступ и срок хранения.

## Family — семья

| Поле | Тип | Уровень | Назначение |
|---|---|---:|---|
| `family_id` | UUID | MUST | стабильный внутренний ID |
| `display_name` | text | SHOULD | понятное название карточки |
| `lifecycle_stage` | enum | MUST | lead / trial / customer / paused / churned / archived |
| `city` | text | SHOULD | локальные кампании и расписание |
| `region` | text | OPTIONAL | география и юридические условия |
| `country` | ISO code | SHOULD | правила коммуникаций и валюта |
| `timezone` | IANA | SHOULD | не писать ночью |
| `preferred_language` | code | SHOULD | язык сообщений |
| `acquisition_source` | text | SHOULD | канал первого привлечения |
| `first_touch_at` | datetime | MUST | первое касание |
| `owner_user_id` | UUID | SHOULD | ответственный сотрудник |
| `next_best_action` | text | SHOULD | что делать дальше |
| `next_action_at` | datetime | SHOULD | когда делать |
| `risk_level` | enum | SHOULD | low / medium / high |
| `tags` | array | OPTIONAL | вспомогательные метки, не бизнес-логика |
| `created_at`, `updated_at` | datetime | MUST | аудит |

## Guardian — родитель / законный представитель

| Поле | Тип | Уровень | Назначение |
|---|---|---:|---|
| `guardian_id` | UUID | MUST | внутренний ID |
| `family_id` | UUID | MUST | семья |
| `first_name`, `last_name` | text | SHOULD | персональное обращение |
| `relationship_to_student` | enum | SHOULD | мама / папа / представитель / другое |
| `email_normalized` | text | SHOULD | контакт и дедупликация |
| `phone_e164` | text | SHOULD | звонки / WhatsApp |
| `preferred_channel` | enum | SHOULD | email / WhatsApp / phone / none |
| `preferred_contact_window` | text | OPTIONAL | удобное время |
| `marketing_email_status` | enum | MUST | unknown / opted_in / opted_out / blocked |
| `marketing_messenger_status` | enum | MUST | unknown / opted_in / opted_out / blocked |
| `service_messages_allowed` | boolean | MUST | договорные и сервисные уведомления |
| `email_deliverability` | enum | SHOULD | valid / bounced / complaint / unknown |
| `do_not_call` | boolean | MUST | запрет звонков |
| `birthday_month_day` | MM-DD | OPTIONAL | поздравление только при разрешённом сценарии |
| `notes_restricted` | text | SENSITIVE | только факты, необходимые для обслуживания |

## Student — ребёнок

| Поле | Тип | Уровень | Назначение |
|---|---|---:|---|
| `student_id` | UUID | MUST | внутренний ID |
| `family_id` | UUID | MUST | семья |
| `first_name` | text | SHOULD | обращение внутри сервиса |
| `birth_year` | integer | OPTIONAL | возрастная пригодность курса |
| `birthday_month_day` | MM-DD | OPTIONAL | только при отдельной цели |
| `grade` | integer | MUST | класс |
| `school_book` | enum/text | SHOULD | Spotlight 2 и другие программы |
| `current_module` | text | SHOULD | текущая школьная тема |
| `learning_goal` | text | SHOULD | что семья хочет изменить |
| `support_need` | enum | OPTIONAL | чтение / слова / грамматика / аудирование / домашка |
| `accessibility_notes` | text | SENSITIVE | только необходимое и с ограниченным доступом |
| `progressme_user_id` | text | SHOULD | связь с платформой |
| `last_learning_at` | datetime | SHOULD | активность |

Не собирать без необходимости: полную дату рождения, школу, номер класса/букву, домашний адрес, медицинские диагнозы, фото документов.

## Lead — заявка

| Поле | Тип | Уровень |
|---|---|---:|
| `lead_id`, `family_id`, `guardian_id`, `student_id` | UUID | MUST |
| `submitted_at` | datetime | MUST |
| `form_id`, `landing_url` | text | SHOULD |
| `utm_source`, `utm_medium`, `utm_campaign`, `utm_content`, `utm_term` | text | SHOULD |
| `referrer_url`, `first_landing_url` | text | SHOULD |
| `promo_code` | text | OPTIONAL |
| `campaign_key` | text | SHOULD |
| `comment_original` | text | SENSITIVE |
| `lead_status` | enum | MUST |
| `qualification_reason` | enum | SHOULD |
| `assigned_to` | UUID | SHOULD |

`lead_status`: `new`, `contacted`, `trial_created`, `activated`, `qualified`, `checkout`, `won`, `lost`, `invalid`, `duplicate`.

## Consent — согласие и запрет

| Поле | Тип | Назначение |
|---|---|---|
| `consent_id` | UUID | запись истории |
| `subject_type`, `subject_id` | enum + UUID | кто дал согласие |
| `purpose` | enum | processing / email_marketing / messenger_marketing / analytics / testimonial / birthday |
| `status` | enum | granted / withdrawn / denied |
| `captured_at` | datetime | когда |
| `source` | text | форма / кабинет / письмо / оператор |
| `notice_version` | text | версия текста согласия |
| `proof_reference` | text | ссылка на доказательство, не публичная |
| `ip_hash` | text | при необходимости, не сырой IP |
| `withdrawn_at` | datetime | отзыв |

Согласие не обновляется «на месте»: каждое изменение добавляет новую запись в журнал.

## Enrollment — доступ к курсу

Поля: `enrollment_id`, `student_id`, `course_id`, `product_version`, `status`, `access_started_at`, `access_ends_at`, `trial_started_at`, `trial_ends_at`, `source_lead_id`, `tariff_id`, `progressme_enrollment_id`, `paused_at`, `ended_reason`.

## Interaction — контакт

Поля: `interaction_id`, `family_id`, `guardian_id`, `student_id?`, `channel`, `direction`, `type`, `subject`, `summary`, `outcome`, `sent_at`, `delivered_at`, `replied_at`, `template_id`, `campaign_id`, `employee_id`, `external_message_id`, `next_action`, `next_action_at`, `contains_sensitive_data`.

## Payment — платёж

Поля: `payment_id`, `family_id`, `guardian_id`, `enrollment_id`, `provider`, `external_invoice_id`, `amount`, `currency`, `status`, `created_at`, `paid_at`, `refunded_at`, `refund_amount`, `promo_code`, `campaign_key`, `receipt_reference`, `failure_code`, `failure_message`, `is_recurring`, `period_start`, `period_end`.

Никогда не хранить полный номер карты, CVV или банковские реквизиты, которые платежный провайдер не требует вернуть системе.

## Task — задача

Поля: `task_id`, `family_id`, `assigned_to`, `type`, `priority`, `title`, `description`, `due_at`, `status`, `source_event_id`, `completed_at`, `completion_note`.

## Case — обращение / проблема

Поля: `case_id`, `family_id`, `student_id?`, `category`, `severity`, `status`, `opened_at`, `first_response_at`, `resolved_at`, `owner`, `root_cause`, `resolution`, `satisfaction_score`.

Категории: `login`, `access`, `payment`, `lesson`, `content`, `technical`, `billing`, `refund`, `privacy`, `complaint`, `other`.

