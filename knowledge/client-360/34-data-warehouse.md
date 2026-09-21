# 34. Аналитический слой

Операционная CRM отвечает «что сделать сейчас». Аналитический слой отвечает «что системно работает». Их нельзя превращать в одну медленную таблицу.

## Факты

- `fact_events`;
- `fact_sessions`;
- `fact_learning_sessions`;
- `fact_messages`;
- `fact_payments`;
- `fact_support_cases`;
- `fact_daily_family_state`;
- `fact_campaign_costs`.

## Измерения

- `dim_date`;
- `dim_family` — surrogate key и исторические версии;
- `dim_student`;
- `dim_course`;
- `dim_offer`;
- `dim_campaign`;
- `dim_source`;
- `dim_template`;
- `dim_device`;
- `dim_region`.

## Историчность

Класс, город, учебник и lifecycle меняются. Для аналитики хранить состояние на момент события или Slowly Changing Dimension. Нельзя пересчитать прошлый сентябрь так, будто ребёнок всегда был в 3 классе.

## Daily family snapshot

На конец дня:

- lifecycle;
- active enrollment;
- days since learning;
- health score;
- open cases;
- outstanding balance;
- marketing eligibility;
- next best action;
- cumulative revenue;
- cohort.

Это позволяет видеть переходы и строить retention без тяжёлого пересчёта всей истории.

## PII

В аналитический слой по возможности не копируются email, телефон, точная дата рождения и тексты переписки. Используются внутренние ключи и агрегаты.

## Семантический словарь

Каждая метрика имеет:

- точное имя;
- формулу;
- grain;
- источник;
- owner;
- freshness;
- исключения;
- дату изменения.

Например `activated_trial` нельзя одновременно считать как «вошёл» в одном отчёте и «закончил упражнение» в другом.

