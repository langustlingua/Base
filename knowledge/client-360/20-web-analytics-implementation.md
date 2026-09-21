# 20. Web-аналитика без ложной точности

## Домены и среды

Разделить:

- production;
- staging;
- локальную разработку;
- тестовые аккаунты;
- домены лендингов;
- домен кабинета;
- домен ProgressMe White Label.

Тестовые события не попадают в production-отчёты. Конфликт `lk.langust.online` с зарезервированным ProgressMe-поддоменом должен быть разрешён до настройки cross-domain измерений.

## Путь

```text
landing_view
→ cta_clicked
→ form_started
→ form_submitted
→ trial_created
→ access_email_delivered
→ first_login
→ lesson_started
→ activity_completed
→ second_session_started
→ pricing_viewed
→ checkout_started
→ payment_succeeded
```

## Обязательные свойства страницы

- `page_type`;
- `page_version`;
- `campaign_key`;
- `offer_id`;
- `course_key`;
- `grade`;
- `referrer_domain`;
- UTM;
- `device_class`;
- `consent_state`;
- `environment`.

Не отправлять в аналитику имя, email, телефон, текст комментария или фото учебника.

## Engaged time

Таймер работает только при `document.visibilityState = visible` и недавней активности. Каждые 15 секунд отправляется heartbeat с накопленным временем; после 30 секунд бездействия накопление ставится на паузу.

Сервер агрегирует heartbeat в сессию и удаляет дубли. Верхний предел одной сессии ограничивается, чтобы зависшая вкладка не создала часы «вовлечённости».

## Цели

- `trial_form_submit`;
- `trial_created`;
- `words_to_lk` — переход из тренажёра слов в кабинет;
- `first_login`;
- `first_value`;
- `checkout_started`;
- `purchase`;
- `week_1_active`.

`click` не следует называть конверсией, если бизнес-цель — заявка или первый результат.

## Cross-device

До входа используется `anonymous_id`; после входа события можно связать с внутренним ID при допустимом основании. Не пытаться скрыто идентифицировать ребёнка fingerprinting-методами.

## Формы

Отслеживать:

- начал форму;
- ошибка поля по имени поля и коду, но не введённое значение;
- успешная отправка;
- backend подтвердил заявку;
- доступ действительно создан.

Локальная надпись «успешно» без backend-confirmation не является `form_submitted`.

## Мониторинг

Алерты:

- падение заявок до нуля при обычном трафике;
- submit есть, trial_created нет;
- оплаты есть, purchase event нет;
- рост login_failed;
- рост белого экрана / JS errors;
- резкий рост времени страницы без CTA — возможно, ошибка измерения;
- события из staging в production.

