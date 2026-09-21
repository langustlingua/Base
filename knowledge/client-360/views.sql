-- Reference analytical views for PostgreSQL.
-- Review field-level permissions before exposing these views to staff.

create or replace view family_360_summary as
select
  f.family_id,
  f.display_name,
  f.lifecycle_stage,
  f.city,
  f.timezone,
  f.owner_user_id,
  f.next_best_action,
  f.next_action_at,
  f.risk_level,
  count(distinct s.student_id) as students_count,
  max(s.last_learning_at) as last_learning_at,
  count(distinct e.enrollment_id) filter (where e.status in ('trial','active')) as active_enrollments,
  max(e.access_ends_at) filter (where e.status in ('trial','active')) as nearest_known_access_end,
  coalesce(sum(p.amount - p.refund_amount) filter (where p.status in ('succeeded','partially_refunded')), 0) as net_revenue,
  count(distinct c.case_id) filter (where c.status not in ('resolved','closed')) as open_cases,
  count(distinct t.task_id) filter (where t.status in ('open','in_progress') and t.due_at < now()) as overdue_tasks,
  count(distinct pr.promise_id) filter (where pr.status in ('open','overdue') and pr.due_at < now()) as overdue_promises
from families f
left join students s on s.family_id = f.family_id
left join enrollments e on e.student_id = s.student_id
left join payments p on p.family_id = f.family_id
left join support_cases c on c.family_id = f.family_id
left join tasks t on t.family_id = f.family_id
left join promises pr on pr.family_id = f.family_id
group by f.family_id;

create or replace view trial_funnel_by_day as
with normalized as (
  select
    coalesce(properties->>'enrollment_id', family_id::text) as trial_key,
    family_id,
    event_name,
    occurred_at
  from events
  where event_name in (
    'trial_created','first_login','activity_completed',
    'second_session_started','checkout_started','payment_succeeded'
  )
), cohorts as (
  select trial_key, family_id, min(occurred_at) as trial_started_at
  from normalized
  where event_name = 'trial_created' and trial_key is not null
  group by trial_key, family_id
), outcomes as (
  select
    c.trial_key,
    c.family_id,
    date_trunc('day', c.trial_started_at) as cohort_day,
    bool_or(n.event_name = 'first_login') as first_login,
    bool_or(n.event_name = 'activity_completed') as first_value,
    bool_or(n.event_name = 'second_session_started') as repeat_use,
    bool_or(n.event_name = 'checkout_started') as checkout_started,
    bool_or(n.event_name = 'payment_succeeded') as payment_succeeded
  from cohorts c
  left join normalized n
    on n.trial_key = c.trial_key
   and n.occurred_at >= c.trial_started_at
  group by c.trial_key, c.family_id, date_trunc('day', c.trial_started_at)
)
select
  cohort_day as day,
  count(*) as trials,
  count(*) filter (where first_login) as activated,
  count(*) filter (where first_value) as first_value,
  count(*) filter (where repeat_use) as repeated,
  count(*) filter (where checkout_started) as checkouts,
  count(*) filter (where payment_succeeded) as purchases
from outcomes
group by cohort_day
order by cohort_day desc;

create or replace view today_action_queue as
select
  f.family_id,
  f.display_name,
  'privacy_or_support'::text as queue_type,
  1 as priority,
  c.opened_at as due_reference,
  concat('Открыто обращение: ', c.category) as action_reason
from families f
join support_cases c on c.family_id = f.family_id
where c.status not in ('resolved','closed')

union all

select
  f.family_id,
  f.display_name,
  'overdue_promise',
  2,
  pr.due_at,
  concat('Просрочено обещание: ', pr.description)
from families f
join promises pr on pr.family_id = f.family_id
where pr.status in ('open','overdue') and pr.due_at < now()

union all

select
  f.family_id,
  f.display_name,
  'task',
  case t.priority when 'urgent' then 3 when 'high' then 4 else 5 end,
  t.due_at,
  t.title
from families f
join tasks t on t.family_id = f.family_id
where t.status in ('open','in_progress') and t.due_at <= now() + interval '1 day';
