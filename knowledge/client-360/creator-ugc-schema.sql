-- LANGUST creator/UGC extension for PostgreSQL.
-- Public repository: schema only, never real creators, children, payments or tokens.

create extension if not exists pgcrypto;

create table creators (
  creator_id uuid primary key default gen_random_uuid(),
  public_name text not null,
  public_slug text not null unique,
  legal_status text not null check (legal_status in ('unknown','individual','self_employed','individual_entrepreneur','legal_entity')),
  legal_profile_reference text,
  owner_user_id uuid,
  manager_user_id uuid,
  status text not null check (status in ('prospect','onboarding','pilot','active','paused','ended','blocked')),
  default_share_rate numeric(7,6) not null default 0.5 check (default_share_rate >= 0 and default_share_rate <= 1),
  timezone text,
  preferred_language text not null default 'ru',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table creator_channels (
  creator_channel_id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references creators(creator_id),
  platform text not null,
  public_handle text,
  public_url text,
  channel_type text not null check (channel_type in ('social_profile','channel','blog','website','messenger','other')),
  ownership_status text not null check (ownership_status in ('unverified','verified','revoked')),
  verified_at timestamptz,
  status text not null check (status in ('active','paused','closed')),
  created_at timestamptz not null default now(),
  unique(creator_id, platform, public_handle)
);

create table creator_agreements (
  creator_agreement_id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references creators(creator_id),
  agreement_reference text not null,
  agreement_version text not null,
  valid_from date not null,
  valid_until date,
  compensation_model text not null check (compensation_model in ('net_receipts_share','gross_after_refunds_share','fixed','hybrid')),
  share_rate numeric(7,6) check (share_rate >= 0 and share_rate <= 1),
  hold_days integer not null default 14 check (hold_days >= 0),
  attribution_window_days integer not null default 30 check (attribution_window_days > 0),
  renewal_policy text not null,
  permitted_deductions jsonb not null default '[]'::jsonb,
  payout_schedule text not null default 'monthly',
  tax_document_rules jsonb not null default '{}'::jsonb,
  status text not null check (status in ('draft','pending_signature','active','expired','terminated')),
  signed_at timestamptz,
  created_at timestamptz not null default now()
);

create table creator_campaigns (
  creator_campaign_id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references creators(creator_id),
  creator_agreement_id uuid not null references creator_agreements(creator_agreement_id),
  campaign_key text not null,
  title text not null,
  offer_id uuid references offers(offer_id),
  starts_at timestamptz not null,
  ends_at timestamptz,
  attribution_rule_version text not null,
  status text not null check (status in ('draft','review','active','paused','completed','cancelled')),
  created_at timestamptz not null default now(),
  unique(creator_id, campaign_key)
);

create table creator_promo_codes (
  creator_promo_code_id uuid primary key default gen_random_uuid(),
  creator_campaign_id uuid not null references creator_campaigns(creator_campaign_id),
  code text not null unique,
  valid_from timestamptz not null,
  valid_until timestamptz,
  discount_definition jsonb not null,
  allowed_products jsonb not null default '[]'::jsonb,
  usage_limit integer,
  new_customer_only boolean not null default false,
  attribution_priority integer not null default 100,
  status text not null check (status in ('draft','active','paused','expired','revoked')),
  terms_version text not null,
  created_at timestamptz not null default now()
);

create table creator_tracked_links (
  creator_link_id uuid primary key default gen_random_uuid(),
  creator_campaign_id uuid not null references creator_campaigns(creator_campaign_id),
  creator_channel_id uuid references creator_channels(creator_channel_id),
  content_key text not null,
  opaque_code text not null unique,
  target_url text not null,
  utm_source text not null,
  utm_medium text not null default 'creator_ugc',
  utm_campaign text not null,
  utm_content text not null,
  utm_term text,
  signature_version text not null,
  valid_from timestamptz not null,
  valid_until timestamptz,
  status text not null check (status in ('draft','active','expired','revoked')),
  created_at timestamptz not null default now()
);

create table creator_touchpoints (
  creator_touch_id uuid primary key default gen_random_uuid(),
  creator_campaign_id uuid not null references creator_campaigns(creator_campaign_id),
  creator_link_id uuid references creator_tracked_links(creator_link_id),
  anonymous_id text,
  analytics_client_id text,
  lead_id uuid references leads(lead_id),
  family_id uuid references families(family_id),
  session_id text,
  content_key text,
  platform text,
  touch_type text not null check (touch_type in ('view','click','landing','self_reported','promo_code','assisted')),
  occurred_at timestamptz not null,
  received_at timestamptz not null default now(),
  properties jsonb not null default '{}'::jsonb,
  consent_state text,
  is_bot_traffic boolean not null default false
);

comment on column creator_touchpoints.analytics_client_id is 'Restricted technical identifier; never exposed to creator portal';

create table creator_attribution_decisions (
  attribution_id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references payments(payment_id),
  creator_id uuid references creators(creator_id),
  creator_campaign_id uuid references creator_campaigns(creator_campaign_id),
  creator_promo_code_id uuid references creator_promo_codes(creator_promo_code_id),
  winning_touch_id uuid references creator_touchpoints(creator_touch_id),
  model text not null check (model in ('promo_override','signed_link','last_eligible_creator_touch','manual_verified','unattributed')),
  rule_version text not null,
  confidence text not null check (confidence in ('low','medium','high','deterministic')),
  evidence jsonb not null default '[]'::jsonb,
  assisted_creator_ids jsonb not null default '[]'::jsonb,
  conflict_status text not null default 'none' check (conflict_status in ('none','open','resolved','rejected')),
  decided_at timestamptz not null default now(),
  decided_by text not null,
  override_reason text,
  unique(payment_id)
);

create table creator_commission_ledger (
  commission_entry_id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references creators(creator_id),
  creator_agreement_id uuid not null references creator_agreements(creator_agreement_id),
  creator_campaign_id uuid not null references creator_campaigns(creator_campaign_id),
  attribution_id uuid not null references creator_attribution_decisions(attribution_id),
  payment_id uuid not null references payments(payment_id),
  entry_type text not null check (entry_type in ('sale','refund','chargeback','fee_adjustment','tax_adjustment','manual_adjustment')),
  gross_amount_minor bigint not null,
  refund_amount_minor bigint not null default 0,
  allowed_deductions_minor bigint not null default 0,
  commissionable_amount_minor bigint not null,
  share_rate numeric(7,6) not null check (share_rate >= 0 and share_rate <= 1),
  creator_amount_minor bigint not null,
  currency char(3) not null,
  status text not null check (status in ('provisional','held','confirmed','statement','payable','paid','reversed','adjusted','disputed')),
  hold_until timestamptz,
  rule_version text not null,
  calculation jsonb not null,
  adjustment_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table creator_statements (
  creator_statement_id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references creators(creator_id),
  creator_agreement_id uuid not null references creator_agreements(creator_agreement_id),
  period_start date not null,
  period_end date not null,
  opening_balance_minor bigint not null default 0,
  confirmed_amount_minor bigint not null,
  adjustments_minor bigint not null default 0,
  payable_amount_minor bigint not null,
  currency char(3) not null,
  statement_reference text not null,
  status text not null check (status in ('draft','review','accepted','disputed','payable','paid','cancelled')),
  dispute_until timestamptz,
  accepted_at timestamptz,
  created_at timestamptz not null default now(),
  unique(creator_id, period_start, period_end)
);

create table creator_payouts (
  creator_payout_id uuid primary key default gen_random_uuid(),
  creator_statement_id uuid not null references creator_statements(creator_statement_id),
  amount_minor bigint not null,
  currency char(3) not null,
  payout_method_reference text not null,
  tax_document_reference text,
  status text not null check (status in ('pending_documents','approved','processing','paid','failed','cancelled')),
  provider_reference text,
  approved_by uuid,
  paid_at timestamptz,
  failure_code text,
  created_at timestamptz not null default now()
);

create table ugc_subject_profiles (
  ugc_subject_id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(student_id),
  creator_id uuid not null references creators(creator_id),
  public_slug text not null unique,
  display_name text not null,
  avatar_asset_reference text,
  grade_display text,
  school_book_display text,
  public_goal text,
  search_indexing text not null default 'noindex' check (search_indexing in ('noindex','index_anonymized')),
  publication_delay_hours integer not null default 48 check (publication_delay_hours >= 0),
  status text not null check (status in ('draft','review','active','paused','withdrawn','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table ugc_permissions (
  ugc_permission_id uuid primary key default gen_random_uuid(),
  ugc_subject_id uuid not null references ugc_subject_profiles(ugc_subject_id),
  guardian_id uuid not null references guardians(guardian_id),
  permission_scope jsonb not null,
  allowed_platforms jsonb not null,
  paid_advertising_allowed boolean not null default false,
  derivative_edits_allowed jsonb not null default '[]'::jsonb,
  allowed_public_metrics jsonb not null default '[]'::jsonb,
  assent_status text not null check (assent_status in ('not_applicable','pending','agreed','declined','withdrawn')),
  notice_version text not null,
  evidence_reference text not null,
  valid_from timestamptz not null,
  valid_until timestamptz,
  status text not null check (status in ('pending','active','expired','withdrawn','revoked')),
  withdrawn_at timestamptz,
  takedown_due_at timestamptz,
  created_at timestamptz not null default now()
);

create table ugc_assets (
  ugc_asset_id uuid primary key default gen_random_uuid(),
  ugc_subject_id uuid references ugc_subject_profiles(ugc_subject_id),
  creator_id uuid not null references creators(creator_id),
  asset_type text not null check (asset_type in ('avatar','photo','video','audio','story','reel','text','subtitle','thumbnail')),
  original_storage_reference text not null,
  public_derivative_reference text,
  content_hash text not null,
  captured_at timestamptz,
  contains_child_face boolean not null default false,
  contains_child_voice boolean not null default false,
  contains_third_party boolean not null default false,
  redaction_status text not null check (redaction_status in ('not_reviewed','required','completed','not_needed')),
  moderation_status text not null check (moderation_status in ('captured','uploaded','parent_review','brand_review','legal_marking','approved','scheduled','published','expired','withdrawn','rejected')),
  permission_id uuid references ugc_permissions(ugc_permission_id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table ugc_episodes (
  ugc_episode_id uuid primary key default gen_random_uuid(),
  ugc_subject_id uuid not null references ugc_subject_profiles(ugc_subject_id),
  creator_campaign_id uuid references creator_campaigns(creator_campaign_id),
  season_key text not null,
  episode_number integer not null,
  episode_key text not null,
  title text not null,
  highlight_circle text,
  period_start date,
  period_end date,
  observation_summary text not null,
  parent_observation text,
  child_quote text,
  verified_event_references jsonb not null default '[]'::jsonb,
  allowed_public_metrics jsonb not null default '{}'::jsonb,
  next_step text,
  status text not null check (status in ('draft','review','approved','scheduled','published','withdrawn','archived')),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  unique(ugc_subject_id, season_key, episode_number)
);

create table ugc_episode_assets (
  ugc_episode_id uuid not null references ugc_episodes(ugc_episode_id),
  ugc_asset_id uuid not null references ugc_assets(ugc_asset_id),
  display_order integer not null,
  role text not null check (role in ('cover','story','main_video','supporting','thumbnail')),
  primary key(ugc_episode_id, ugc_asset_id)
);

create table ugc_publications (
  ugc_publication_id uuid primary key default gen_random_uuid(),
  ugc_episode_id uuid references ugc_episodes(ugc_episode_id),
  ugc_asset_id uuid references ugc_assets(ugc_asset_id),
  creator_channel_id uuid references creator_channels(creator_channel_id),
  platform text not null,
  placement_type text not null,
  public_url text,
  creator_link_id uuid references creator_tracked_links(creator_link_id),
  erid text,
  advertising_label text,
  ord_status text check (ord_status in ('not_required','draft','registered','reported','corrected','failed')),
  published_at timestamptz,
  expires_at timestamptz,
  takedown_requested_at timestamptz,
  removed_at timestamptz,
  status text not null check (status in ('draft','scheduled','published','paused','removed','expired')),
  created_at timestamptz not null default now(),
  check (ugc_episode_id is not null or ugc_asset_id is not null)
);

create table creator_content_metrics_daily (
  metric_date date not null,
  creator_id uuid not null references creators(creator_id),
  creator_campaign_id uuid references creator_campaigns(creator_campaign_id),
  ugc_publication_id uuid references ugc_publications(ugc_publication_id),
  impressions bigint,
  video_starts bigint,
  video_completions bigint,
  engagements bigint,
  tracked_clicks bigint,
  landing_sessions bigint,
  leads bigint,
  trials bigint,
  first_logins bigint,
  first_values bigint,
  checkouts bigint,
  payments bigint,
  refunds bigint,
  source_updated_at timestamptz not null,
  primary key(metric_date, creator_id, ugc_publication_id)
);

create table audience_question_clusters (
  question_cluster_id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references creators(creator_id),
  creator_campaign_id uuid references creator_campaigns(creator_campaign_id),
  ugc_publication_id uuid references ugc_publications(ugc_publication_id),
  period_start date not null,
  period_end date not null,
  category text not null,
  unique_people_count integer not null,
  question_count integer not null,
  privacy_threshold integer not null default 5,
  redacted_examples jsonb not null default '[]'::jsonb,
  conversion_summary jsonb not null default '{}'::jsonb,
  status text not null check (status in ('below_threshold','review','visible','suppressed')),
  reviewed_by uuid,
  created_at timestamptz not null default now()
);

create table creator_recommendations (
  creator_recommendation_id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references creators(creator_id),
  creator_campaign_id uuid references creator_campaigns(creator_campaign_id),
  funnel_stage text not null,
  observation text not null,
  sample_size integer,
  confidence text not null check (confidence in ('exploratory','directional','strong','blocked')),
  likely_cause text,
  alternative_causes jsonb not null default '[]'::jsonb,
  action_owner text not null check (action_owner in ('creator_action','langust_content','langust_product','langust_sales','joint_test')),
  proposed_action text not null,
  success_metric text,
  guardrails jsonb not null default '[]'::jsonb,
  evidence_references jsonb not null default '[]'::jsonb,
  review_at timestamptz,
  status text not null check (status in ('draft','visible','accepted','rejected','testing','completed','expired')),
  rejected_reason text,
  created_at timestamptz not null default now()
);

create table creator_notifications (
  creator_notification_id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references creators(creator_id),
  type text not null,
  title text not null,
  body_redacted text not null,
  object_type text,
  object_id uuid,
  channel text not null check (channel in ('in_app','email','telegram','max')),
  status text not null check (status in ('queued','sent','read','failed','cancelled')),
  deduplication_key text not null unique,
  created_at timestamptz not null default now(),
  sent_at timestamptz,
  read_at timestamptz
);

create index creator_touchpoints_campaign_time_idx on creator_touchpoints(creator_campaign_id, occurred_at desc);
create index creator_touchpoints_lead_idx on creator_touchpoints(lead_id) where lead_id is not null;
create index creator_commission_status_idx on creator_commission_ledger(creator_id, status, hold_until);
create index ugc_permissions_active_idx on ugc_permissions(ugc_subject_id, valid_until) where status = 'active';
create index ugc_assets_review_idx on ugc_assets(moderation_status, updated_at);
create index ugc_publications_active_idx on ugc_publications(status, expires_at) where status in ('scheduled','published');
create index creator_recommendations_visible_idx on creator_recommendations(creator_id, created_at desc) where status in ('visible','accepted','testing');
