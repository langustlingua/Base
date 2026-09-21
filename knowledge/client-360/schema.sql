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

create table offers (
  offer_id text primary key,
  product_key text not null,
  tariff_id text not null,
  audience_rule text not null,
  region text,
  grade smallint,
  price numeric(12,2) not null,
  currency char(3) not null default 'RUB',
  comparison_price numeric(12,2),
  discount_message text,
  promo_code text,
  valid_from timestamptz not null,
  valid_until timestamptz not null,
  deadline_timezone text not null,
  landing_url text not null,
  checkout_url text,
  status text not null check (status in ('draft','active','expired','cancelled')),
  version integer not null default 1,
  owner_user_id uuid,
  created_at timestamptz not null default now(),
  check (valid_until > valid_from)
);

create table message_templates (
  template_id text not null,
  version integer not null,
  channel text not null check (channel in ('email','whatsapp','sms','in_app')),
  message_class text not null check (message_class in ('service','marketing')),
  program_key text not null,
  funnel_role text,
  subject text,
  preview_text text,
  body text not null,
  primary_cta text,
  required_consent text,
  allowed_offer_ids text[] not null default '{}',
  variables jsonb not null default '[]'::jsonb,
  status text not null check (status in ('draft','reviewed','approved','active','deprecated','archived')),
  owner_user_id uuid,
  approved_at timestamptz,
  last_reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  primary key (template_id, version)
);

create table campaigns (
  campaign_id uuid primary key default gen_random_uuid(),
  campaign_key text not null unique,
  purpose text not null,
  status text not null check (status in ('draft','qa','dry_run','awaiting_approval','approved','scheduled','running','paused','completed','cancelled')),
  audience_rule text not null,
  exclusion_rules jsonb not null default '[]'::jsonb,
  channel text not null,
  template_id text not null,
  template_version integer not null,
  offer_id text references offers(offer_id),
  required_consent text,
  frequency_cap text not null,
  stop_events text[] not null,
  success_event text not null,
  owner_user_id uuid not null,
  scheduled_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  foreign key (template_id, template_version) references message_templates(template_id, version)
);

create table campaign_approvals (
  approval_id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references campaigns(campaign_id),
  approved_by uuid not null,
  approved_at timestamptz not null,
  expires_at timestamptz not null,
  template_hash text not null,
  audience_hash text not null,
  recipient_count integer not null check (recipient_count >= 0),
  revoked_at timestamptz,
  revoke_reason text
);

create table message_deliveries (
  delivery_id uuid primary key default gen_random_uuid(),
  campaign_id uuid references campaigns(campaign_id),
  family_id uuid not null references families(family_id),
  guardian_id uuid references guardians(guardian_id),
  channel text not null,
  normalized_destination_hash text not null,
  template_id text not null,
  template_version integer not null,
  status text not null check (status in ('queued','sent','delivered','soft_bounce','hard_bounce','complaint','cancelled')),
  idempotency_key text not null unique,
  provider_message_id text,
  queued_at timestamptz not null,
  sent_at timestamptz,
  delivered_at timestamptz,
  replied_at timestamptz,
  error_code text,
  foreign key (template_id, template_version) references message_templates(template_id, version)
);

create table web_sessions (
  session_id uuid primary key,
  anonymous_id text,
  family_id uuid references families(family_id),
  started_at timestamptz not null,
  ended_at timestamptz,
  engaged_seconds integer not null default 0 check (engaged_seconds >= 0),
  pages_viewed integer not null default 0 check (pages_viewed >= 0),
  landing_url text,
  referrer_domain text,
  utm_source text,
  utm_medium text,
  utm_campaign text,
  utm_content text,
  device_class text,
  browser_family text,
  consent_state text,
  environment text not null check (environment in ('production','staging','development','test'))
);

create table referrals (
  referral_id uuid primary key default gen_random_uuid(),
  referrer_family_id uuid not null references families(family_id),
  invited_lead_id uuid references leads(lead_id),
  referral_code text not null,
  shared_at timestamptz,
  converted_at timestamptz,
  reward_type text,
  reward_value numeric(12,2),
  reward_status text check (reward_status in ('pending','approved','issued','cancelled')),
  fraud_check_status text,
  terms_version text
);

create table content_permissions (
  permission_id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(family_id),
  asset_id text not null,
  asset_type text not null,
  internal_use boolean not null default false,
  public_use boolean not null default false,
  allowed_name text,
  allowed_platforms text[] not null default '{}',
  editing_allowed boolean not null default false,
  granted_at timestamptz not null,
  expires_at timestamptz,
  withdrawn_at timestamptz,
  proof_reference text
);

create table expenses (
  expense_id uuid primary key default gen_random_uuid(),
  category text not null,
  vendor text,
  amount numeric(12,2) not null check (amount >= 0),
  currency char(3) not null,
  incurred_at date not null,
  campaign_key text,
  course_id uuid references courses(course_id),
  is_recurring boolean not null default false,
  period_start date,
  period_end date,
  receipt_reference text,
  note text
);

create table oauth_connections (
  connection_id uuid primary key default gen_random_uuid(),
  service text not null,
  account_alias text not null,
  scopes text[] not null,
  data_categories text[] not null,
  connected_at timestamptz not null,
  approved_by uuid,
  last_used_at timestamptz,
  review_due_at timestamptz,
  revoke_instructions text,
  revoked_at timestamptz,
  deletion_verified_at timestamptz
);

create table data_subject_requests (
  request_id uuid primary key default gen_random_uuid(),
  family_id uuid references families(family_id),
  guardian_id uuid references guardians(guardian_id),
  request_type text not null check (request_type in ('access','correction','export','withdraw_consent','delete','restrict','object')),
  received_at timestamptz not null,
  identity_verified_at timestamptz,
  due_at timestamptz not null,
  owner_user_id uuid not null,
  status text not null check (status in ('new','verifying','in_progress','partially_fulfilled','fulfilled','denied','cancelled')),
  resolution text,
  completed_at timestamptz
);

create table integration_failures (
  failure_id uuid primary key default gen_random_uuid(),
  connector text not null,
  external_event_id text,
  safe_payload_hash text,
  first_seen_at timestamptz not null,
  last_seen_at timestamptz not null,
  retry_count integer not null default 0,
  error_category text not null,
  impact text,
  owner_user_id uuid,
  status text not null check (status in ('open','retrying','dead_letter','resolved','ignored')),
  resolution text
);

create table experiments (
  experiment_id uuid primary key default gen_random_uuid(),
  experiment_key text not null unique,
  hypothesis text not null,
  segment_rule text not null,
  exclusion_rules jsonb not null default '[]'::jsonb,
  primary_metric text not null,
  guardrail_metrics text[] not null,
  variants jsonb not null,
  randomization_unit text not null default 'family_id',
  started_at timestamptz,
  ended_at timestamptz,
  owner_user_id uuid not null,
  status text not null check (status in ('draft','running','paused','completed','cancelled')),
  result_summary text,
  decision text
);

create table daily_family_snapshots (
  snapshot_date date not null,
  family_id uuid not null references families(family_id),
  lifecycle_stage text not null,
  active_enrollments integer not null,
  days_since_learning integer,
  health_score smallint check (health_score between 0 and 100),
  open_cases integer not null,
  net_revenue numeric(12,2) not null,
  marketing_eligible boolean not null,
  next_best_action text,
  cohort_date date,
  primary key (snapshot_date, family_id)
);

create index message_deliveries_family_time_idx on message_deliveries(family_id, queued_at desc);
create index web_sessions_family_time_idx on web_sessions(family_id, started_at desc);
create index offers_active_idx on offers(valid_until) where status = 'active';
create index data_subject_requests_due_idx on data_subject_requests(due_at) where status not in ('fulfilled','denied','cancelled');
