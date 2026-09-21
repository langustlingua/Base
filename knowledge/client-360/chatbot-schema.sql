-- LANGUST chatbot extension for PostgreSQL
-- No real tokens, messages or personal data belong in this repository.

create extension if not exists pgcrypto;

create table bot_instances (
  bot_id uuid primary key default gen_random_uuid(),
  platform text not null check (platform in ('telegram','max')),
  environment text not null check (environment in ('staging','production')),
  public_name text not null,
  public_username text,
  platform_bot_id text not null,
  purpose text not null default 'main',
  owner_user_id uuid,
  status text not null check (status in ('discovered','token_rotated','staging','active','paused','disabled')),
  secret_reference text not null,
  webhook_host text,
  commands_version text,
  flow_version text,
  last_verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(platform, environment, platform_bot_id),
  unique(secret_reference)
);

comment on column bot_instances.secret_reference is 'Reference to secret manager; never the token value';

create table bot_start_codes (
  start_code_id uuid primary key default gen_random_uuid(),
  bot_id uuid not null references bot_instances(bot_id),
  code text not null,
  campaign_key text,
  source text,
  medium text,
  content_key text,
  landing_context text,
  valid_from timestamptz,
  valid_until timestamptz,
  status text not null check (status in ('draft','active','expired','revoked')),
  created_by uuid,
  created_at timestamptz not null default now(),
  unique(bot_id, code)
);

create table channel_identities (
  channel_identity_id uuid primary key default gen_random_uuid(),
  bot_id uuid not null references bot_instances(bot_id),
  platform_user_id text not null,
  platform_chat_id text not null,
  family_id uuid references families(family_id),
  guardian_id uuid references guardians(guardian_id),
  link_status text not null check (link_status in ('anonymous','pending','verified','revoked','blocked')),
  linked_at timestamptz,
  linked_by text,
  revoked_at timestamptz,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(bot_id, platform_chat_id)
);

create table bot_conversations (
  conversation_id uuid primary key default gen_random_uuid(),
  bot_id uuid not null references bot_instances(bot_id),
  channel_identity_id uuid not null references channel_identities(channel_identity_id),
  family_id uuid references families(family_id),
  lead_id uuid references leads(lead_id),
  enrollment_id uuid references enrollments(enrollment_id),
  start_code_id uuid references bot_start_codes(start_code_id),
  flow_key text not null,
  flow_version text not null,
  current_state text not null,
  status text not null check (status in ('active','waiting','human_active','paused','completed','suppressed','expired')),
  context jsonb not null default '{}'::jsonb,
  last_user_message_at timestamptz,
  last_bot_message_at timestamptz,
  next_action_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column bot_conversations.context is 'No tokens, passwords, payment details or unbounded PII';

create table bot_messages (
  bot_message_id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references bot_conversations(conversation_id),
  interaction_id uuid references interactions(interaction_id),
  direction text not null check (direction in ('inbound','outbound')),
  platform_message_id text,
  purpose text not null,
  template_key text,
  template_version text,
  content_reference text,
  redacted_summary text,
  reply_to_platform_message_id text,
  status text not null check (status in ('received','pending','queued','sent','delivered','read','failed','cancelled')),
  failure_code text,
  scheduled_at timestamptz,
  sent_at timestamptz,
  delivered_at timestamptz,
  created_at timestamptz not null default now(),
  unique(conversation_id, platform_message_id, direction)
);

create table bot_state_transitions (
  transition_id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references bot_conversations(conversation_id),
  from_state text,
  to_state text not null,
  trigger_type text not null,
  trigger_reference text,
  action_key text,
  idempotency_key text not null,
  transition_context jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now(),
  unique(conversation_id, idempotency_key)
);

create table bot_handoffs (
  handoff_id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references bot_conversations(conversation_id),
  case_id uuid references support_cases(case_id),
  reason text not null,
  priority text not null check (priority in ('low','normal','high','urgent')),
  summary text not null,
  assigned_to uuid,
  status text not null check (status in ('queued','assigned','human_active','resolved','returned_to_bot','closed')),
  requested_at timestamptz not null default now(),
  first_response_at timestamptz,
  resolved_at timestamptz,
  returned_to_bot_at timestamptz
);

create index bot_start_codes_active_idx on bot_start_codes(bot_id, code) where status = 'active';
create index channel_identities_guardian_idx on channel_identities(guardian_id) where link_status = 'verified';
create index bot_conversations_next_action_idx on bot_conversations(next_action_at) where status in ('active','waiting');
create index bot_conversations_family_idx on bot_conversations(family_id, updated_at desc);
create index bot_messages_conversation_time_idx on bot_messages(conversation_id, created_at desc);
create index bot_handoffs_open_idx on bot_handoffs(priority, requested_at) where status not in ('resolved','closed');
