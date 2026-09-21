-- LANGUST Client 360 — reference schema (PostgreSQL 15+)
-- Structure only. Never commit real customer data to this repository.

create extension if not exists pgcrypto;

create table families (
  family_id uuid primary key default gen_random_uuid(),
  display_name text,
  lifecycle_stage text not null default 'lead'
    check (lifecycle_stage in ('lead','trial','customer','paused','churned','archived')),
  city text,
  region text,
  country_code char(2),
  timezone text not null default 'Europe/Moscow',
  preferred_language text not null default 'ru',
  acquisition_source text,
  first_touch_at timestamptz not null default now(),
  owner_user_id uuid,
  next_best_action text,
  next_action_at timestamptz,
  risk_level text check (risk_level in ('low','medium','high')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);

create table guardians (
  guardian_id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(family_id),
  first_name text,
  last_name text,
  relationship_to_student text,
  email_normalized text,
  phone_e164 text,
  preferred_channel text check (preferred_channel in ('email','whatsapp','phone','none')),
  preferred_contact_window text,
  marketing_email_status text not null default 'unknown'
    check (marketing_email_status in ('unknown','opted_in','opted_out','blocked')),
  marketing_messenger_status text not null default 'unknown'
    check (marketing_messenger_status in ('unknown','opted_in','opted_out','blocked')),
  service_messages_allowed boolean not null default true,
  email_deliverability text not null default 'unknown'
    check (email_deliverability in ('unknown','valid','soft_bounce','hard_bounce','complaint')),
  do_not_call boolean not null default false,
  birthday_month_day char(5),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (email_normalized is not null or phone_e164 is not null)
);

create unique index guardians_email_unique
  on guardians(email_normalized)
  where email_normalized is not null;
create unique index guardians_phone_unique
  on guardians(phone_e164)
  where phone_e164 is not null;

create table students (
  student_id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(family_id),
  first_name text,
  birth_year smallint,
  birthday_month_day char(5),
  grade smallint check (grade between 1 and 11),
  school_book text,
  current_module text,
  learning_goal text,
  support_need text,
  progressme_user_id text,
  last_learning_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index students_progressme_unique
  on students(progressme_user_id)
  where progressme_user_id is not null;

create table leads (
  lead_id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(family_id),
  guardian_id uuid references guardians(guardian_id),
  student_id uuid references students(student_id),
  submitted_at timestamptz not null,
  form_id text,
  landing_url text,
  utm_source text,
  utm_medium text,
  utm_campaign text,
  utm_content text,
  utm_term text,
  referrer_url text,
  first_landing_url text,
  promo_code text,
  campaign_key text,
  comment_original text,
  lead_status text not null default 'new'
    check (lead_status in ('new','contacted','trial_created','activated','qualified','checkout','won','lost','invalid','duplicate')),
  qualification_reason text,
  assigned_to uuid,
  external_source text,
  external_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (external_source, external_id)
);

create table consents (
  consent_id uuid primary key default gen_random_uuid(),
  subject_type text not null check (subject_type in ('guardian','student','family')),
  subject_id uuid not null,
  purpose text not null check (purpose in (
    'processing','email_marketing','messenger_marketing','analytics',
    'testimonial','photo_publication','birthday'
  )),
  status text not null check (status in ('granted','withdrawn','denied')),
  captured_at timestamptz not null,
  source text not null,
  notice_version text not null,
  proof_reference text,
  ip_hash text,
  withdrawn_at timestamptz,
  created_at timestamptz not null default now()
);
create index consents_subject_purpose_idx on consents(subject_type, subject_id, purpose, captured_at desc);

create table courses (
  course_id uuid primary key default gen_random_uuid(),
  course_key text not null unique,
  title text not null,
  grade smallint,
  school_book text,
  product_version text,
  active boolean not null default true
);

create table enrollments (
  enrollment_id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(student_id),
  course_id uuid not null references courses(course_id),
  source_lead_id uuid references leads(lead_id),
  tariff_id text,
  status text not null check (status in ('trial','active','paused','expired','cancelled')),
  access_started_at timestamptz not null,
  access_ends_at timestamptz,
  trial_started_at timestamptz,
  trial_ends_at timestamptz,
  progressme_enrollment_id text,
  paused_at timestamptz,
  ended_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table interactions (
  interaction_id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(family_id),
  guardian_id uuid references guardians(guardian_id),
  student_id uuid references students(student_id),
  channel text not null check (channel in ('email','whatsapp','phone','site','form','progressme','in_person','other')),
  direction text not null check (direction in ('inbound','outbound','system')),
  interaction_type text not null,
  subject text,
  summary text,
  outcome text,
  sent_at timestamptz,
  delivered_at timestamptz,
  replied_at timestamptz,
  template_id text,
  campaign_id text,
  employee_id uuid,
  external_message_id text,
  next_action text,
  next_action_at timestamptz,
  contains_sensitive_data boolean not null default false,
  created_at timestamptz not null default now()
);

create table payments (
  payment_id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(family_id),
  guardian_id uuid references guardians(guardian_id),
  enrollment_id uuid references enrollments(enrollment_id),
  provider text not null,
  external_invoice_id text not null,
  amount numeric(12,2) not null check (amount >= 0),
  currency char(3) not null default 'RUB',
  status text not null check (status in ('created','pending','succeeded','failed','cancelled','partially_refunded','refunded','chargeback')),
  created_at timestamptz not null,
  paid_at timestamptz,
  refunded_at timestamptz,
  refund_amount numeric(12,2) not null default 0 check (refund_amount >= 0),
  promo_code text,
  campaign_key text,
  receipt_reference text,
  failure_code text,
  failure_message text,
  is_recurring boolean not null default false,
  period_start date,
  period_end date,
  unique (provider, external_invoice_id)
);

create table tasks (
  task_id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(family_id),
  assigned_to uuid not null,
  task_type text not null,
  priority text not null default 'normal' check (priority in ('low','normal','high','urgent')),
  title text not null,
  description text,
  due_at timestamptz not null,
  status text not null default 'open' check (status in ('open','in_progress','done','cancelled')),
  source_event_id uuid,
  completed_at timestamptz,
  completion_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table support_cases (
  case_id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(family_id),
  student_id uuid references students(student_id),
  category text not null,
  severity text not null check (severity in ('low','medium','high','critical')),
  status text not null default 'open' check (status in ('open','waiting_customer','waiting_internal','resolved','closed')),
  opened_at timestamptz not null,
  first_response_at timestamptz,
  resolved_at timestamptz,
  owner_user_id uuid,
  root_cause text,
  resolution text,
  satisfaction_score smallint check (satisfaction_score between 1 and 5)
);

create table promises (
  promise_id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(family_id),
  interaction_id uuid references interactions(interaction_id),
  promised_by uuid not null,
  description text not null,
  due_at timestamptz not null,
  status text not null default 'open' check (status in ('open','done','overdue','cancelled')),
  completed_at timestamptz,
  evidence_reference text,
  created_at timestamptz not null default now()
);

create table events (
  event_id uuid primary key,
  event_name text not null,
  occurred_at timestamptz not null,
  received_at timestamptz not null default now(),
  source text not null,
  anonymous_id text,
  family_id uuid references families(family_id),
  guardian_id uuid references guardians(guardian_id),
  student_id uuid references students(student_id),
  session_id uuid,
  properties jsonb not null default '{}'::jsonb,
  schema_version integer not null default 1
);
create index events_name_time_idx on events(event_name, occurred_at desc);
create index events_family_time_idx on events(family_id, occurred_at desc);
create index events_student_time_idx on events(student_id, occurred_at desc);
create index events_properties_gin_idx on events using gin(properties);

create table suppression_list (
  suppression_id uuid primary key default gen_random_uuid(),
  channel text not null check (channel in ('email','whatsapp','phone','all_marketing')),
  normalized_destination_hash text not null,
  reason text not null,
  created_at timestamptz not null default now(),
  source text not null,
  unique (channel, normalized_destination_hash)
);

create table audit_log (
  audit_id uuid primary key default gen_random_uuid(),
  actor_type text not null,
  actor_id text not null,
  action text not null,
  entity_type text not null,
  entity_id text not null,
  occurred_at timestamptz not null default now(),
  request_id text,
  safe_metadata jsonb not null default '{}'::jsonb
);

-- Useful operational indexes
create index tasks_open_due_idx on tasks(due_at) where status in ('open','in_progress');
create index cases_open_idx on support_cases(severity, opened_at) where status not in ('resolved','closed');
create index promises_open_due_idx on promises(due_at) where status = 'open';
create index enrollments_active_end_idx on enrollments(access_ends_at) where status in ('trial','active');
create index payments_family_paid_idx on payments(family_id, paid_at desc) where status = 'succeeded';

