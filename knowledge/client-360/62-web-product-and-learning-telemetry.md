# 62. Web-, продуктовая и учебная телеметрия

## Цель

Телеметрия должна отвечать на конкретные вопросы:

- откуда пришёл человек;
- увидел ли нужную информацию;
- где возник барьер;
- дошёл ли до заявки, входа, первого результата и оплаты;
- возвращается ли ребёнок к обучению;
- какая часть продукта помогает, а какая мешает.

Она не должна становиться скрытым наблюдением за семьёй.

## 1. Уровни данных

| Уровень | Пример | Срок/детализация |
|---|---|---|
| raw event | `cta_clicked` | ограниченный срок |
| session | визит, engaged time, страницы | средний срок |
| daily aggregate | 3 визита, 11 минут | дольше |
| family feature | days since last learning | пересчитываемый признак |
| analytical cohort | activation rate | обезличенный/агрегированный |

Raw-события не должны храниться бесконечно только потому, что «когда-нибудь пригодятся».

## 2. Идентификаторы

- `anonymous_id` — собственный first-party псевдоним до входа;
- `session_id` — отдельный визит;
- `user_id` — внутренний ID после аутентификации;
- `family_id`, `guardian_id`, `student_id` — серверные связи;
- `yandex_client_id` — браузерный идентификатор Метрики;
- `utm_*` — параметры касания;
- `request_id` — сквозная техническая диагностика.

Email, телефон, имя и дата рождения не передаются в URL, analytics properties или Яндекс Метрику.

## 3. Identity stitching

До входа события принадлежат `anonymous_id`. После безопасной идентификации сервер создаёт `identity_stitch`:

| Поле | Значение |
|---|---|
| `anonymous_id` | псевдоним браузера |
| `guardian_id` | подтверждённый взрослый |
| `family_id` | семья |
| `method` | login / verified_link / server_session |
| `stitched_at` | время |
| `confidence` | verified / strong / weak |
| `expires_at` | срок связи |

Нельзя связывать личность только по IP, fingerprint, похожему поведению или общему устройству. На общем устройстве возможны разные семьи.

## 4. Сессия и engaged time

### Начало

Новая сессия начинается при первом допустимом событии или после тайм-аута неактивности.

### Engaged time

Секунды считаются только если:

- вкладка видима;
- страница в фокусе или воспроизводится разрешённый материал;
- было допустимое взаимодействие за последние 30 секунд;
- событие не от бота/теста/сотрудника;
- heartbeat не дублируется.

`engaged_seconds = sum(min(heartbeat_delta, 30s))` для валидных активных интервалов.

Не считать просто `last_event - first_event`: открытая на ночь вкладка даст ложные часы.

### Завершение

- явный `session_end`;
- page hide/beacon;
- серверный timeout;
- максимум продолжительности;
- смена идентифицированного пользователя на общем устройстве.

## 5. Каталог сайта

### Навигация и контент

- `page_viewed`;
- `section_viewed` при реальной видимости;
- `scroll_depth_reached` 25/50/75/90;
- `navigation_clicked`;
- `cta_clicked`;
- `faq_expanded`;
- `comparison_viewed`;
- `pricing_viewed`;
- `case_viewed`;
- `video_started`, `video_progress`, `video_completed`;
- `file_downloaded`;
- `outbound_link_clicked`.

### Формы

- `form_viewed`;
- `form_started`;
- `form_step_completed`;
- `form_validation_failed` с именем поля и кодом, без введённого значения;
- `form_abandoned`;
- `form_submitted`;
- `lead_created` после серверного подтверждения.

### Поиск и помощь

- `site_search_performed` с нормализованной темой; сырой запрос хранить только если проверено отсутствие PII;
- `help_opened`;
- `contact_option_clicked`;
- `chat_started`;
- `support_request_submitted`;
- `error_shown` с безопасным кодом.

### Checkout

- `checkout_opened`;
- `offer_presented` с `offer_id/version`;
- `promo_applied` с внутренним promo ID;
- `checkout_validation_failed` без реквизитов;
- `payment_redirected`;
- `payment_result_viewed`;
- факт `payment_succeeded` приходит только с серверной стороны.

## 6. Кабинет и обучение

- `login_started`, `login_succeeded`, `login_failed`;
- `password_reset_requested/completed`;
- `course_opened`;
- `module_opened`;
- `lesson_started/completed`;
- `activity_started/completed`;
- `learning_session_started/completed`;
- `audio_started/completed`;
- `hint_requested`;
- `attempt_recorded` с результатом без полного детского ответа;
- `progress_milestone_reached`;
- `report_viewed`;
- `learning_resumed_after_inactivity`;
- `access_blocked` с безопасной категорией;
- `technical_error`.

Сырой голос, видео ребёнка, полный ввод с клавиатуры и запись экрана не входят в стандартную телеметрию.

## 7. Data layer

Пример безопасного события:

```json
{
  "event_id": "00000000-0000-4000-8000-000000000001",
  "event_name": "pricing_viewed",
  "occurred_at": "2026-09-21T12:00:00Z",
  "source": "website",
  "anonymous_id": "anon_demo_01",
  "session_id": "00000000-0000-4000-8000-000000000002",
  "properties": {
    "page_type": "pricing",
    "offer_id": "offer_demo_v1",
    "utm_campaign": "autumn_demo"
  },
  "schema_version": 2
}
```

Запрещён пример: `properties.email`, `properties.child_name`, полный URL с контактами или текстом формы.

## 8. Клиент и сервер

### Клиент фиксирует

- видимость;
- клики;
- скролл;
- проигрывание;
- ошибки интерфейса;
- heartbeat engaged time.

### Сервер подтверждает

- создание заявки;
- вход;
- выдачу доступа;
- оплату/возврат;
- изменение согласия;
- завершение упражнения, если оно проверяется сервером;
- отправку сообщения.

Серверный факт сильнее клиентского. `payment_result_viewed` не означает `payment_succeeded`.

## 9. Яндекс Метрика

Использование:

- acquisition и UTM;
- поведение по страницам;
- цели и агрегаты;
- сверка воронки;
- ClientID для допустимого связывания офлайн-конверсий;
- UserID после авторизации, если настройка и уведомление проверены.

Client 360 остаётся источником истины для контактов, согласий, оплат и доступа. Метрика не является финансовым ledger и не определяет, кому можно отправить письмо.

Рекомендуемые цели:

- `lead_created`;
- `trial_created`;
- `first_login`;
- `first_value`;
- `checkout_started`;
- `payment_succeeded`;
- `learning_resumed`.

Не передавать в параметры Метрики персональные данные и тексты обращений.

## 10. Consent mode и отключение

До допустимого состояния согласия/уведомления:

- не включать необязательные трекеры;
- сохранять только строго необходимые технические события;
- уважать отказ и обновлять состояние без перезагрузки, если возможно;
- версионировать текст уведомления;
- не считать отсутствие действия согласием;
- не связывать ранее анонимное поведение с человеком, если это не предусмотрено политикой.

## 11. Фильтрация шума

Исключать/маркировать:

- сотрудников и тестовые аккаунты;
- staging/development;
- известных ботов и health checks;
- дубли `event_id`;
- сверхбыстрые невозможные последовательности;
- preview link scanners;
- synthetic monitoring;
- события вне допустимого временного окна;
- некорректные версии схемы.

## 12. Воронки

### Acquisition

`landing → engaged session → form start → lead created`

### Trial

`trial created → access delivered → first login → first value → repeat use → checkout → payment`

### Learning

`access → first paid session → weekly active → milestone → retained month`

### Recovery

`inactivity detected → contact → return → completed activity`

Показывать абсолютные числа, конверсию, медианное время между этапами и причины выпадения.

## 13. Качество данных

SLO для production:

- события payment/consent: доступность в Client 360 до 1 минуты;
- site events: до 15 минут;
- учебные события: до 60 минут, если источник пакетный;
- ежедневные aggregates: до 08:00 локального операционного времени;
- duplicate event rate: <0,1%;
- события без environment: 0;
- payment success только client-side: 0;
- PII violations в analytics properties: 0.

## 14. Критерии приёмки

- фоновая вкладка не увеличивает engaged time;
- повторный heartbeat не удваивает время;
- оплата появляется только после подтверждения провайдера;
- согласие и отказ меняют поведение трекеров;
- анонимная сессия связывается только после проверенного события;
- UTM сохраняются как first touch и session touch отдельно;
- внутренний трафик исключается;
- события имеют schema version и валидируются;
- удаление/ограничение пользователя распространяется на связанные сырые данные;
- отчёт Метрики сверяется с first-party данными, но не перезаписывает их.
