-- LANGUST Client 360 — additive implementation schema (PostgreSQL 15+)
-- Apply after schema.sql. Structure only: never commit production data here.

-- ---------------------------------------------------------------------------
-- Sources, contact points, provenance and identity resolution
-- ---------------------------------------------------------------------------

create table data_sources (
  data_source_id uuid primary key default gen_random_uuid(),
  source_key text not null unique,
  source_type text not null check (source_type in (
    'website','tilda','progressme','robokassa','email_provider','telegram','max',
    'whatsapp','phone','manual','import','analytics','ugc','other'
  )),
  display_name text not null,
  source_of_truth_domains text[] not null default '{}',
  environment text not null check (environment in ('production','staging','development','test')),
  owner_user_id uuid,
  contains_personal_data boolean not null default false,
  review_due_at date,
  status text not null default 'active' check (status in ('planned','active','paused','retired')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table contact_points (
  contact_point_id uuid primary key default gen_random_uuid(),
  guardian_id uuid not null references guardians(guardian_id),
  contact_type text not null check (contact_type in (
    'email','phone','telegram','max','whatsapp','other'
  )),
  value_encrypted bytea not null,
  normalized_hash text not null,
  masked_value text not null,
  label text not null default 'unknown' check (label in (
    'personal','work','billing','emergency','unknown'
  )),
  is_primary boolean not null default false,
  status text not null default 'active' check (status in (
    'active','invalid','unreachable','disputed','archived'
  )),
  verification_status text not null default 'unverified' check (verification_status in (
    'unverified','pending','verified','failed'
  )),
  verified_at timestamptz,
  data_source_id uuid references data_sources(data_source_id),
  source_record_id text,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  valid_from timestamptz not null default now(),
  valid_to timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (valid_to is null or valid_to > valid_from)
);

create unique index contact_points_guardian_type_hash_unique
  on contact_points(guardian_id, contact_type, normalized_hash)
  where status <> 'archived';

create unique index contact_points_one_primary_per_type
  on contact_points(guardian_id, contact_type)
  where is_primary and status = 'active';

create index contact_points_normalized_hash_idx
  on contact_points(contact_type, normalized_hash);

create table contact_point_verifications (
  verification_id uuid primary key default gen_random_uuid(),
  contact_point_id uuid not null references contact_points(contact_point_id),
  method text not null check (method in (
    'email_link','one_time_code','authenticated_cabinet','inbound_contact',
    'trusted_import','operator_review'
  )),
  status text not null check (status in ('pending','succeeded','failed','expired','cancelled')),
  attempt_number integer not null default 1 check (attempt_number > 0),
  requested_at timestamptz not null,
  completed_at timestamptz,
  proof_reference text,
  safe_failure_code text,
  created_at timestamptz not null default now()
);

create index contact_verifications_contact_time_idx
  on contact_point_verifications(contact_point_id, requested_at desc);

create table external_identities (
  external_identity_id uuid primary key default gen_random_uuid(),
  data_source_id uuid not null references data_sources(data_source_id),
  external_subject_type text not null,
  external_subject_id_hash text not null,
  family_id uuid references families(family_id),
  guardian_id uuid references guardians(guardian_id),
  student_id uuid references students(student_id),
  status text not null default 'active' check (status in ('active','disputed','replaced','archived')),
  confidence text not null default 'verified' check (confidence in ('weak','strong','verified')),
  first_seen_at timestamptz not null,
  last_seen_at timestamptz not null,
  created_at timestamptz not null default now(),
  check (family_id is not null or guardian_id is not null or student_id is not null),
  unique (data_source_id, external_subject_type, external_subject_id_hash)
);

create table identity_stitches (
  identity_stitch_id uuid primary key default gen_random_uuid(),
  anonymous_id_hash text not null,
  session_id uuid references web_sessions(session_id),
  family_id uuid not null references families(family_id),
  guardian_id uuid references guardians(guardian_id),
  method text not null check (method in ('login','verified_link','server_session','operator_verified')),
  confidence text not null check (confidence in ('weak','strong','verified')),
  stitched_at timestamptz not null,
  expires_at timestamptz,
  revoked_at timestamptz,
  source_event_id uuid references events(event_id),
  created_at timestamptz not null default now(),
  check (expires_at is null or expires_at > stitched_at)
);

create index identity_stitches_anonymous_idx
  on identity_stitches(anonymous_id_hash, stitched_at desc);

create table field_facts (
  field_fact_id uuid primary key default gen_random_uuid(),
  entity_type text not null,
  entity_id uuid not null,
  field_name text not null,
  value_hash text,
  safe_display_value text,
  data_source_id uuid references data_sources(data_source_id),
  source_record_id text,
  captured_at timestamptz not null,
  captured_by_type text not null check (captured_by_type in ('user','operator','system','import')),
  captured_by_id text,
  confidence text not null check (confidence in ('weak','stated','strong','verified')),
  last_confirmed_at timestamptz,
  transformation_rule text,
  supersedes_fact_id uuid references field_facts(field_fact_id),
  status text not null default 'active' check (status in ('active','superseded','disputed','deleted')),
  created_at timestamptz not null default now()
);

create index field_facts_entity_field_idx
  on field_facts(entity_type, entity_id, field_name, captured_at desc);

create table identity_resolution_cases (
  identity_case_id uuid primary key default gen_random_uuid(),
  case_type text not null check (case_type in ('possible_duplicate','merge','split','ownership_dispute')),
  left_entity_type text not null,
  left_entity_id uuid not null,
  right_entity_type text not null,
  right_entity_id uuid not null,
  score integer,
  status text not null default 'open' check (status in (
    'open','reviewing','approved','rejected','executed','reversed','cancelled'
  )),
  marketing_paused boolean not null default true,
  opened_at timestamptz not null default now(),
  reviewed_by uuid,
  reviewed_at timestamptz,
  decision_reason text,
  executed_at timestamptz,
  reversed_at timestamptz
);

create table identity_resolution_evidence (
  identity_evidence_id uuid primary key default gen_random_uuid(),
  identity_case_id uuid not null references identity_resolution_cases(identity_case_id),
  signal_type text not null,
  signal_weight integer not null,
  safe_description text not null,
  source_reference text,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Preferences, dates and customer memory
-- ---------------------------------------------------------------------------

create table communication_preferences (
  preference_id uuid primary key default gen_random_uuid(),
  family_id uuid references families(family_id),
  guardian_id uuid references guardians(guardian_id),
  contact_point_id uuid references contact_points(contact_point_id),
  purpose text not null,
  channel text not null check (channel in ('email','telegram','max','whatsapp','phone','in_app','any')),
  topic text not null default 'all',
  status text not null check (status in ('allowed','blocked','unknown')),
  frequency text check (frequency in ('critical_only','as_needed','daily','weekly','monthly','none')),
  preferred_window_start time,
  preferred_window_end time,
  timezone text,
  source text not null,
  notice_version text,
  captured_at timestamptz not null,
  valid_until timestamptz,
  supersedes_preference_id uuid references communication_preferences(preference_id),
  created_at timestamptz not null default now(),
  check (family_id is not null or guardian_id is not null or contact_point_id is not null)
);

create index communication_preferences_lookup_idx
  on communication_preferences(family_id, guardian_id, contact_point_id, purpose, channel, captured_at desc);

create table customer_dates (
  customer_date_id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(family_id),
  guardian_id uuid references guardians(guardian_id),
  student_id uuid references students(student_id),
  date_type text not null,
  date_value date,
  month_day char(5),
  year_value smallint,
  precision text not null check (precision in ('exact','month_day','month','year','estimated')),
  recurrence_rule text,
  timezone text,
  data_source_id uuid references data_sources(data_source_id),
  source_record_id text,
  confidence text not null check (confidence in ('imported','inferred','stated','verified')),
  purpose text not null,
  consent_purpose text,
  valid_from timestamptz not null default now(),
  valid_until timestamptz,
  last_confirmed_at timestamptz,
  status text not null default 'active' check (status in ('active','disputed','withdrawn','archived')),
  created_at timestamptz not null default now(),
  check (date_value is not null or month_day is not null or year_value is not null),
  check (valid_until is null or valid_until > valid_from)
);

create index customer_dates_next_idx
  on customer_dates(date_type, month_day)
  where status = 'active';

create table journal_entries (
  journal_entry_id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(family_id),
  guardian_id uuid references guardians(guardian_id),
  student_id uuid references students(student_id),
  journal_type text not null check (journal_type in (
    'contact','learning','trial','sales','support','finance','consent',
    'promise','decision','risk','research','other'
  )),
  entry_type text not null,
  occurred_at timestamptz not null,
  recorded_at timestamptz not null default now(),
  author_type text not null check (author_type in ('user','operator','system','integration','ai_assisted')),
  author_id text,
  summary text not null,
  structured_data jsonb not null default '{}'::jsonb,
  source_reference text,
  sensitivity text not null default 'standard' check (sensitivity in (
    'standard','restricted','highly_restricted'
  )),
  visibility_scope text[] not null default '{operations}',
  correction_of uuid references journal_entries(journal_entry_id),
  retention_class text not null,
  created_from_event_id uuid references events(event_id),
  created_at timestamptz not null default now()
);

create index journal_entries_family_time_idx
  on journal_entries(family_id, occurred_at desc);

create unique index journal_entries_event_type_unique
  on journal_entries(created_from_event_id, entry_type)
  where created_from_event_id is not null;

create table customer_questions (
  question_id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(family_id),
  guardian_id uuid references guardians(guardian_id),
  interaction_id uuid references interactions(interaction_id),
  channel text not null,
  question_topic text not null,
  question_intent text,
  safe_summary text not null,
  status text not null default 'new' check (status in (
    'new','classified','assigned','answered','customer_confirmed','closed',
    'needs_product_fix','needs_content_fix','needs_finance','needs_privacy','duplicate','spam'
  )),
  owner_user_id uuid,
  due_at timestamptz,
  answer_reference text,
  resolved_at timestamptz,
  helpfulness_score smallint check (helpfulness_score between 1 and 5),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index customer_questions_open_idx
  on customer_questions(status, due_at)
  where status not in ('customer_confirmed','closed','duplicate','spam');

create table objection_records (
  objection_id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(family_id),
  interaction_id uuid references interactions(interaction_id),
  lead_id uuid references leads(lead_id),
  funnel_stage text not null,
  objection_code text not null,
  safe_customer_wording text,
  offer_id text references offers(offer_id),
  response_template_id text,
  outcome text,
  follow_up_allowed boolean,
  next_eligible_at timestamptz,
  created_at timestamptz not null default now()
);

create table voice_theme_clusters (
  theme_cluster_id uuid primary key default gen_random_uuid(),
  period_start date not null,
  period_end date not null,
  theme_key text not null,
  source_scope text not null,
  unique_families integer not null check (unique_families >= 0),
  total_mentions integer not null check (total_mentions >= 0),
  funnel_stages text[] not null default '{}',
  safe_paraphrases jsonb not null default '[]'::jsonb,
  confidence text not null check (confidence in ('insufficient','exploratory','directional','strong')),
  proposed_owner text,
  proposed_action text,
  privacy_threshold_met boolean not null default false,
  created_at timestamptz not null default now(),
  check (period_end >= period_start),
  unique (period_start, period_end, theme_key, source_scope)
);

-- ---------------------------------------------------------------------------
-- Email programs and cross-channel orchestration
-- ---------------------------------------------------------------------------

create table email_programs (
  program_key text primary key,
  display_name text not null,
  lifecycle_stage text not null,
  owner_role text not null,
  status text not null default 'draft' check (status in ('draft','qa','active','paused','retired')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table email_program_versions (
  program_key text not null references email_programs(program_key),
  version integer not null check (version > 0),
  message_class text not null,
  entry_event text not null,
  eligibility_rule jsonb not null,
  required_purpose text,
  exclusion_rules jsonb not null default '[]'::jsonb,
  stop_events text[] not null default '{}',
  frequency_group text not null,
  success_event text,
  attribution_window interval,
  approved_by uuid,
  approved_at timestamptz,
  active_from timestamptz,
  active_until timestamptz,
  config_hash text not null,
  created_at timestamptz not null default now(),
  primary key (program_key, version)
);

create table email_program_steps (
  program_key text not null,
  program_version integer not null,
  step_key text not null,
  step_order integer not null check (step_order > 0),
  delay_from_entry interval not null,
  template_id text not null,
  template_version integer not null,
  eligibility_rule jsonb not null default '{}'::jsonb,
  stop_events text[] not null default '{}',
  expires_after interval,
  created_at timestamptz not null default now(),
  primary key (program_key, program_version, step_key),
  foreign key (program_key, program_version)
    references email_program_versions(program_key, version),
  foreign key (template_id, template_version)
    references message_templates(template_id, version),
  unique (program_key, program_version, step_order)
);

create table communication_candidates (
  candidate_id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(family_id),
  guardian_id uuid references guardians(guardian_id),
  contact_point_id uuid references contact_points(contact_point_id),
  purpose text not null,
  message_class text not null,
  topic text not null,
  program_key text references email_programs(program_key),
  program_version integer,
  step_key text,
  preferred_channel text not null,
  priority text not null check (priority in ('P0','P1','P2','P3','P4','P5')),
  earliest_at timestamptz not null,
  latest_at timestamptz,
  required_consent_purpose text,
  stop_events text[] not null default '{}',
  dedupe_key text not null unique,
  contact_group_id uuid not null default gen_random_uuid(),
  related_entity_type text,
  related_entity_id uuid,
  expected_outcome_event text,
  status text not null default 'pending' check (status in (
    'pending','evaluating','allowed','scheduled','queued','sent','suppressed','cancelled','expired'
  )),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (latest_at is null or latest_at > earliest_at),
  foreign key (program_key, program_version)
    references email_program_versions(program_key, version)
);

create index communication_candidates_pending_idx
  on communication_candidates(priority, earliest_at)
  where status in ('pending','evaluating','allowed','scheduled');

create table send_decisions (
  send_decision_id uuid primary key default gen_random_uuid(),
  candidate_id uuid not null references communication_candidates(candidate_id),
  decision text not null check (decision in (
    'allow_now','schedule_for_window','switch_channel','merge_with_higher_priority',
    'pause_for_human_reply','suppress_missing_consent','suppress_opt_out',
    'suppress_invalid_destination','suppress_frequency_cap','suppress_open_case',
    'suppress_stop_event','suppress_duplicate','manual_review','cancel_expired'
  )),
  reason_code text not null,
  policy_version text not null,
  evaluated_at timestamptz not null,
  inputs_snapshot jsonb not null,
  next_evaluation_at timestamptz,
  actor_type text not null default 'system' check (actor_type in ('system','operator','owner')),
  actor_id text,
  override_reason text,
  created_at timestamptz not null default now()
);

create index send_decisions_candidate_time_idx
  on send_decisions(candidate_id, evaluated_at desc);

create table message_delivery_events (
  message_event_id uuid primary key,
  delivery_id uuid not null references message_deliveries(delivery_id),
  provider_event_id text,
  event_type text not null check (event_type in (
    'queued','provider_accepted','delivered','soft_bounced','hard_bounced',
    'complaint_received','unsubscribe_requested','opened','clicked','replied','cancelled'
  )),
  occurred_at timestamptz not null,
  received_at timestamptz not null default now(),
  safe_reason_code text,
  link_id text,
  raw_payload_hash text,
  created_at timestamptz not null default now(),
  unique (provider_event_id, event_type)
);

-- ---------------------------------------------------------------------------
-- Web detail, orders, invoices, refunds and access entitlements
-- ---------------------------------------------------------------------------

create table web_page_views (
  page_view_id uuid primary key,
  session_id uuid not null references web_sessions(session_id),
  family_id uuid references families(family_id),
  occurred_at timestamptz not null,
  page_type text not null,
  canonical_path text not null,
  title_safe text,
  referrer_domain text,
  engaged_seconds integer not null default 0 check (engaged_seconds >= 0),
  max_scroll_percent smallint check (max_scroll_percent between 0 and 100),
  offer_id text references offers(offer_id),
  environment text not null check (environment in ('production','staging','development','test')),
  created_at timestamptz not null default now()
);

create index web_page_views_session_time_idx
  on web_page_views(session_id, occurred_at);

create table customer_orders (
  order_id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(family_id),
  guardian_id uuid references guardians(guardian_id),
  student_id uuid references students(student_id),
  offer_id text references offers(offer_id),
  offer_version integer,
  product_key text not null,
  tariff_id text not null,
  list_price numeric(12,2) not null check (list_price >= 0),
  discount_amount numeric(12,2) not null default 0 check (discount_amount >= 0),
  gross_amount numeric(12,2) not null check (gross_amount >= 0),
  currency char(3) not null default 'RUB',
  promo_code text,
  campaign_key text,
  terms_version text not null,
  service_period_start date,
  service_period_end date,
  status text not null default 'draft' check (status in (
    'draft','offered','confirmed','payment_pending','paid','fulfilled','completed',
    'expired','cancelled','refunded','disputed'
  )),
  created_at timestamptz not null default now(),
  confirmed_at timestamptz,
  completed_at timestamptz,
  check (discount_amount <= list_price),
  check (service_period_end is null or service_period_start is null or service_period_end >= service_period_start)
);

create table invoices (
  invoice_id uuid primary key default gen_random_uuid(),
  order_id uuid not null references customer_orders(order_id),
  invoice_number text,
  amount_due numeric(12,2) not null check (amount_due >= 0),
  currency char(3) not null default 'RUB',
  due_at timestamptz,
  status text not null default 'created' check (status in (
    'created','issued','pending','partially_paid','paid','expired','cancelled','refunded'
  )),
  issued_at timestamptz,
  paid_at timestamptz,
  created_at timestamptz not null default now()
);

create index invoices_open_due_idx
  on invoices(due_at)
  where status in ('created','issued','pending','partially_paid');

create table payment_attempts (
  payment_attempt_id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references invoices(invoice_id),
  provider text not null,
  provider_attempt_id text,
  idempotency_key text not null unique,
  requested_amount numeric(12,2) not null check (requested_amount >= 0),
  currency char(3) not null,
  status text not null default 'created' check (status in (
    'created','redirected','provider_pending','succeeded','failed','cancelled','unknown'
  )),
  safe_failure_code text,
  created_at timestamptz not null default now(),
  provider_updated_at timestamptz,
  unique (provider, provider_attempt_id)
);

create table invoice_payment_allocations (
  invoice_id uuid not null references invoices(invoice_id),
  payment_id uuid not null references payments(payment_id),
  allocated_amount numeric(12,2) not null check (allocated_amount > 0),
  created_at timestamptz not null default now(),
  primary key (invoice_id, payment_id)
);

create table refunds (
  refund_id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references payments(payment_id),
  order_id uuid references customer_orders(order_id),
  amount numeric(12,2) not null check (amount > 0),
  currency char(3) not null,
  reason_category text not null,
  status text not null default 'requested' check (status in (
    'requested','reviewed','submitted','processing','succeeded','rejected','failed','cancelled'
  )),
  requested_at timestamptz not null,
  due_at timestamptz,
  reviewed_by uuid,
  provider_refund_id text,
  policy_version text,
  access_impact text,
  commission_adjustment_required boolean not null default false,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (provider_refund_id)
);

create index refunds_open_due_idx
  on refunds(due_at)
  where status not in ('succeeded','rejected','cancelled');

create table subscriptions (
  subscription_id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(family_id),
  guardian_id uuid references guardians(guardian_id),
  product_key text not null,
  tariff_id text not null,
  provider text not null,
  provider_mandate_reference text,
  billing_interval text not null,
  amount numeric(12,2) not null check (amount >= 0),
  currency char(3) not null,
  status text not null default 'pending' check (status in (
    'pending','active','past_due','paused','cancel_pending','cancelled','expired'
  )),
  next_billing_at timestamptz,
  grace_period interval,
  retry_policy_version text,
  cancel_requested_at timestamptz,
  cancel_effective_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table access_entitlements (
  entitlement_id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(family_id),
  student_id uuid not null references students(student_id),
  course_id uuid not null references courses(course_id),
  enrollment_id uuid references enrollments(enrollment_id),
  order_id uuid references customer_orders(order_id),
  basis_type text not null check (basis_type in (
    'trial','payment','manual_credit','scholarship','promo','service_recovery'
  )),
  basis_reference_id uuid,
  valid_from timestamptz not null,
  valid_until timestamptz,
  grace_until timestamptz,
  status text not null default 'scheduled' check (status in (
    'scheduled','active','grace','paused','expired','cancelled','revoked','restored'
  )),
  status_reason text,
  approved_by uuid,
  supersedes_entitlement_id uuid references access_entitlements(entitlement_id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (valid_until is null or valid_until > valid_from)
);

create index access_entitlements_active_idx
  on access_entitlements(student_id, valid_until)
  where status in ('scheduled','active','grace','restored');

create table account_ledger_entries (
  ledger_entry_id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(family_id),
  order_id uuid references customer_orders(order_id),
  payment_id uuid references payments(payment_id),
  refund_id uuid references refunds(refund_id),
  entry_type text not null check (entry_type in (
    'charge','payment','refund','chargeback','credit','credit_expiry','adjustment','reversal'
  )),
  direction text not null check (direction in ('debit','credit')),
  amount numeric(12,2) not null check (amount > 0),
  currency char(3) not null,
  reason_code text not null,
  reverses_entry_id uuid references account_ledger_entries(ledger_entry_id),
  approved_by uuid,
  occurred_at timestamptz not null,
  created_at timestamptz not null default now()
);

create index account_ledger_family_time_idx
  on account_ledger_entries(family_id, occurred_at desc);

create table reconciliation_runs (
  reconciliation_run_id uuid primary key default gen_random_uuid(),
  reconciliation_type text not null,
  period_start timestamptz not null,
  period_end timestamptz not null,
  started_at timestamptz not null,
  completed_at timestamptz,
  status text not null check (status in ('running','passed','passed_with_warnings','failed')),
  source_count bigint,
  target_count bigint,
  discrepancy_count bigint,
  source_checksum text,
  target_checksum text,
  owner_user_id uuid,
  check (period_end >= period_start)
);

create table reconciliation_items (
  reconciliation_item_id uuid primary key default gen_random_uuid(),
  reconciliation_run_id uuid not null references reconciliation_runs(reconciliation_run_id),
  discrepancy_type text not null,
  severity text not null check (severity in ('low','medium','high','critical')),
  entity_type text,
  entity_id text,
  safe_description text not null,
  status text not null default 'open' check (status in ('open','investigating','resolved','accepted')),
  owner_user_id uuid,
  due_at timestamptz,
  resolution text,
  resolved_at timestamptz,
  created_at timestamptz not null default now()
);

create index reconciliation_items_open_idx
  on reconciliation_items(severity, due_at)
  where status in ('open','investigating');

-- ---------------------------------------------------------------------------
-- Next best action, alerts, data registry and retention execution
-- ---------------------------------------------------------------------------

create table action_candidates (
  action_candidate_id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(family_id),
  action_type text not null,
  reason_code text not null,
  source_event_ids uuid[] not null default '{}',
  benefit_score smallint check (benefit_score between 0 and 100),
  urgency_score smallint check (urgency_score between 0 and 100),
  risk_score smallint check (risk_score between 0 and 100),
  confidence text not null check (confidence in ('insufficient','exploratory','directional','strong')),
  earliest_at timestamptz not null,
  due_at timestamptz,
  blocking_conditions jsonb not null default '[]'::jsonb,
  success_event text,
  expires_at timestamptz,
  owner_type text not null check (owner_type in ('system','operator','support','finance','owner')),
  owner_user_id uuid,
  status text not null default 'candidate' check (status in (
    'candidate','recommended','accepted','executed','declined','blocked','expired','cancelled'
  )),
  outcome text,
  override_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index action_candidates_queue_idx
  on action_candidates(owner_type, due_at)
  where status in ('candidate','recommended','accepted','blocked');

create table alert_instances (
  alert_id uuid primary key default gen_random_uuid(),
  alert_rule_key text not null,
  severity text not null check (severity in ('P0','P1','P2','P3')),
  family_id uuid references families(family_id),
  entity_type text,
  entity_id text,
  dedupe_key text not null,
  title text not null,
  safe_description text not null,
  first_seen_at timestamptz not null,
  last_seen_at timestamptz not null,
  occurrence_count integer not null default 1 check (occurrence_count > 0),
  owner_user_id uuid,
  due_at timestamptz,
  status text not null default 'open' check (status in ('open','acknowledged','resolved','suppressed','false_positive')),
  resolved_at timestamptz,
  resolution text,
  created_at timestamptz not null default now(),
  unique (alert_rule_key, dedupe_key, status)
);

create table data_field_registry (
  data_field_id uuid primary key default gen_random_uuid(),
  entity_name text not null,
  field_name text not null,
  data_class text not null,
  subject_type text not null,
  purpose_keys text[] not null,
  requirement_level text not null check (requirement_level in ('must','should','optional')),
  collection_source text not null,
  source_of_truth text not null,
  legal_basis_status text not null check (legal_basis_status in ('proposed','reviewed','approved','rejected')),
  retention_class text not null,
  access_roles text[] not null,
  exportable text not null check (exportable in ('yes','no','restricted')),
  deletion_action text not null check (deletion_action in ('delete','anonymize','retain_restricted')),
  processor_keys text[] not null default '{}',
  automated_decision_use text not null default 'none' check (automated_decision_use in ('none','assist','material')),
  owner_role text not null,
  review_due_at date,
  status text not null default 'active' check (status in ('draft','active','deprecated')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (entity_name, field_name)
);

create table retention_policies (
  retention_class text not null,
  version integer not null,
  description text not null,
  duration interval,
  trigger_event text not null,
  expiration_action text not null check (expiration_action in ('delete','anonymize','review','retain_restricted')),
  legal_review_status text not null check (legal_review_status in ('proposed','reviewed','approved')),
  approved_by uuid,
  effective_from date not null,
  effective_until date,
  created_at timestamptz not null default now(),
  primary key (retention_class, version)
);

create table retention_actions (
  retention_action_id uuid primary key default gen_random_uuid(),
  retention_class text not null,
  policy_version integer not null,
  entity_type text not null,
  entity_id text not null,
  due_at timestamptz not null,
  action text not null check (action in ('delete','anonymize','review','retain_restricted')),
  status text not null default 'pending' check (status in ('pending','running','completed','failed','held')),
  hold_reason text,
  started_at timestamptz,
  completed_at timestamptz,
  result_hash text,
  created_at timestamptz not null default now(),
  foreign key (retention_class, policy_version)
    references retention_policies(retention_class, version),
  unique (retention_class, policy_version, entity_type, entity_id, due_at)
);

create table data_quality_issues (
  data_quality_issue_id uuid primary key default gen_random_uuid(),
  rule_key text not null,
  severity text not null check (severity in ('low','medium','high','critical')),
  entity_type text not null,
  entity_id text,
  source_key text,
  safe_description text not null,
  detected_at timestamptz not null,
  owner_user_id uuid,
  due_at timestamptz,
  status text not null default 'open' check (status in ('open','investigating','resolved','accepted','false_positive')),
  resolution text,
  resolved_at timestamptz,
  created_at timestamptz not null default now()
);

create index data_quality_issues_open_idx
  on data_quality_issues(severity, due_at)
  where status in ('open','investigating');

-- ---------------------------------------------------------------------------
-- Reference operational views
-- ---------------------------------------------------------------------------

create or replace view current_primary_contact_points as
select distinct on (cp.guardian_id, cp.contact_type)
  cp.contact_point_id,
  cp.guardian_id,
  g.family_id,
  cp.contact_type,
  cp.masked_value,
  cp.status,
  cp.verification_status,
  cp.last_seen_at
from contact_points cp
join guardians g on g.guardian_id = cp.guardian_id
where cp.is_primary
  and cp.status = 'active'
  and cp.valid_to is null
order by cp.guardian_id, cp.contact_type, cp.verified_at desc nulls last, cp.updated_at desc;

create or replace view open_financial_discrepancies as
select
  ri.reconciliation_item_id,
  rr.reconciliation_type,
  ri.discrepancy_type,
  ri.severity,
  ri.entity_type,
  ri.entity_id,
  ri.safe_description,
  ri.owner_user_id,
  ri.due_at,
  ri.status,
  rr.period_start,
  rr.period_end
from reconciliation_items ri
join reconciliation_runs rr
  on rr.reconciliation_run_id = ri.reconciliation_run_id
where ri.status in ('open','investigating');

create or replace view family_open_action_summary as
select
  f.family_id,
  f.display_name,
  count(distinct ac.action_candidate_id) filter (
    where ac.status in ('candidate','recommended','accepted','blocked')
  ) as open_actions,
  min(ac.due_at) filter (
    where ac.status in ('candidate','recommended','accepted','blocked')
  ) as nearest_action_due_at,
  count(distinct ai.alert_id) filter (
    where ai.status in ('open','acknowledged')
  ) as open_alerts,
  min(ai.due_at) filter (
    where ai.status in ('open','acknowledged')
  ) as nearest_alert_due_at
from families f
left join action_candidates ac on ac.family_id = f.family_id
left join alert_instances ai on ai.family_id = f.family_id
group by f.family_id, f.display_name;
