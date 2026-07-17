-- Commit de xuat: feat(m30): them Nabi companion notification contract
-- Draft non-destructive migration. Review in sandbox before production.

begin;

insert into public.admin_permissions (code, description)
values
  ('notifications.read', 'Read Nabi notification catalog and metrics.'),
  ('notifications.write', 'Version and activate Nabi notification catalog.')
on conflict (code) do update
set description = excluded.description, is_active = true;

create table if not exists public.nabi_notification_definitions (
  id uuid primary key default gen_random_uuid(),
  notification_id text not null,
  content_version integer not null check (content_version > 0),
  category text not null check (category in (
    'contextual', 'milestone', 'subscription', 'retention',
    'reward', 'report', 'care', 'profile'
  )),
  priority integer not null check (priority between 0 and 1000),
  policy_key text not null,
  primary_action_key text not null,
  secondary_action_key text,
  allowed_channels text[] not null default array['in_app']::text[],
  title_template text not null default 'Nabi nhắn bạn',
  body_template text not null,
  config jsonb not null default '{}'::jsonb,
  effective_from timestamptz,
  effective_until timestamptz,
  status text not null default 'draft'
    check (status in ('draft', 'active', 'archived')),
  reason text not null,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (notification_id, content_version)
);

create unique index if not exists idx_nabi_notification_one_active
  on public.nabi_notification_definitions(notification_id)
  where status = 'active';

create table if not exists public.nabi_notification_user_states (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  notification_id text not null,
  content_version integer not null,
  source_event_id text not null,
  status text not null check (status in (
    'eligible', 'queued', 'presented', 'collapsed', 'opened', 'deferred',
    'actioned', 'converted', 'expired', 'cancelled', 'failed'
  )),
  eligible_at timestamptz not null,
  presented_at timestamptz,
  opened_at timestamptz,
  deferred_until timestamptz,
  actioned_at timestamptz,
  converted_at timestamptz,
  expires_at timestamptz,
  display_count integer not null default 0 check (display_count >= 0),
  dismiss_count integer not null default 0 check (dismiss_count >= 0),
  primary_click_count integer not null default 0 check (primary_click_count >= 0),
  secondary_click_count integer not null default 0 check (secondary_click_count >= 0),
  last_session_id text,
  last_screen_key text,
  membership_plan text,
  billing_cycle text,
  safe_metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, notification_id, source_event_id, content_version)
);

create index if not exists idx_nabi_notification_state_user_status
  on public.nabi_notification_user_states(user_id, status, eligible_at desc);

create table if not exists public.nabi_notification_preferences (
  user_id uuid primary key references public.users(id) on delete cascade,
  proactive_in_app_enabled boolean not null default true,
  push_enabled boolean not null default false,
  analytics_upload_enabled boolean not null default false,
  quiet_start_minutes integer check (quiet_start_minutes between 0 and 1439),
  quiet_end_minutes integer check (quiet_end_minutes between 0 and 1439),
  updated_at timestamptz not null default now()
);

create table if not exists public.nabi_notification_events (
  id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  occurrence_id uuid references public.nabi_notification_user_states(id) on delete set null,
  notification_id text not null,
  event_name text not null check (event_name in (
    'nabi_notification_eligible', 'nabi_notification_shown',
    'nabi_notification_opened', 'nabi_notification_dismissed',
    'nabi_notification_primary_clicked', 'nabi_notification_secondary_clicked',
    'nabi_upgrade_page_viewed', 'nabi_checkout_started',
    'nabi_conversion_completed', 'nabi_notification_failed'
  )),
  session_id text,
  screen_key text,
  app_version text,
  result_code text,
  safe_metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_nabi_notification_events_user_created
  on public.nabi_notification_events(user_id, created_at desc);
create index if not exists idx_nabi_notification_events_retention
  on public.nabi_notification_events(created_at);

alter table public.nabi_notification_definitions enable row level security;
alter table public.nabi_notification_user_states enable row level security;
alter table public.nabi_notification_preferences enable row level security;
alter table public.nabi_notification_events enable row level security;

drop policy if exists nabi_notification_definitions_read_active
  on public.nabi_notification_definitions;
create policy nabi_notification_definitions_read_active
  on public.nabi_notification_definitions for select to authenticated
  using (
    status = 'active'
    and (effective_from is null or effective_from <= now())
    and (effective_until is null or effective_until > now())
  );

drop policy if exists nabi_notification_state_read_own
  on public.nabi_notification_user_states;
create policy nabi_notification_state_read_own
  on public.nabi_notification_user_states for select to authenticated
  using (user_id = auth.uid());

drop policy if exists nabi_notification_preferences_read_own
  on public.nabi_notification_preferences;
create policy nabi_notification_preferences_read_own
  on public.nabi_notification_preferences for select to authenticated
  using (user_id = auth.uid());

drop policy if exists nabi_notification_events_read_own
  on public.nabi_notification_events;
create policy nabi_notification_events_read_own
  on public.nabi_notification_events for select to authenticated
  using (user_id = auth.uid());

create or replace function public.get_active_nabi_notification_definitions()
returns setof public.nabi_notification_definitions
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select d.*
  from public.nabi_notification_definitions d
  where auth.uid() is not null
    and d.status = 'active'
    and (d.effective_from is null or d.effective_from <= now())
    and (d.effective_until is null or d.effective_until > now())
  order by d.priority desc, d.notification_id, d.content_version desc
$$;

create or replace function public.claim_nabi_notification_occurrence(
  p_notification_id text,
  p_content_version integer,
  p_source_event_id text,
  p_status text,
  p_eligible_at timestamptz,
  p_expires_at timestamptz default null,
  p_safe_metadata jsonb default '{}'::jsonb
)
returns public.nabi_notification_user_states
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_state public.nabi_notification_user_states%rowtype;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;
  if p_status not in ('eligible', 'queued') then
    raise exception 'INVALID_NOTIFICATION_STATE' using errcode = '22023';
  end if;
  if nullif(btrim(coalesce(p_notification_id, '')), '') is null
     or nullif(btrim(coalesce(p_source_event_id, '')), '') is null
     or p_content_version <= 0 then
    raise exception 'INVALID_NOTIFICATION_CLAIM' using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.nabi_notification_definitions d
    where d.notification_id = btrim(p_notification_id)
      and d.content_version = p_content_version
      and d.status = 'active'
      and (d.effective_from is null or d.effective_from <= now())
      and (d.effective_until is null or d.effective_until > now())
  ) then
    raise exception 'NOTIFICATION_DEFINITION_INACTIVE' using errcode = '22023';
  end if;

  insert into public.nabi_notification_user_states (
    user_id, notification_id, content_version, source_event_id, status,
    eligible_at, expires_at, safe_metadata
  ) values (
    v_user_id, btrim(p_notification_id), p_content_version,
    btrim(p_source_event_id), p_status, p_eligible_at, p_expires_at,
    coalesce(p_safe_metadata, '{}'::jsonb)
  )
  on conflict (user_id, notification_id, source_event_id, content_version)
  do update set updated_at = public.nabi_notification_user_states.updated_at
  returning * into v_state;

  return v_state;
end;
$$;

create or replace function public.upsert_my_nabi_notification_preferences(
  p_proactive_in_app_enabled boolean,
  p_push_enabled boolean,
  p_analytics_upload_enabled boolean,
  p_quiet_start_minutes integer default null,
  p_quiet_end_minutes integer default null
)
returns public.nabi_notification_preferences
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_preferences public.nabi_notification_preferences%rowtype;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;
  if p_quiet_start_minutes is not null and p_quiet_start_minutes not between 0 and 1439 then
    raise exception 'INVALID_QUIET_START' using errcode = '22023';
  end if;
  if p_quiet_end_minutes is not null and p_quiet_end_minutes not between 0 and 1439 then
    raise exception 'INVALID_QUIET_END' using errcode = '22023';
  end if;

  insert into public.nabi_notification_preferences (
    user_id, proactive_in_app_enabled, push_enabled,
    analytics_upload_enabled, quiet_start_minutes, quiet_end_minutes, updated_at
  ) values (
    v_user_id, p_proactive_in_app_enabled, p_push_enabled,
    p_analytics_upload_enabled, p_quiet_start_minutes, p_quiet_end_minutes, now()
  )
  on conflict (user_id) do update set
    proactive_in_app_enabled = excluded.proactive_in_app_enabled,
    push_enabled = excluded.push_enabled,
    analytics_upload_enabled = excluded.analytics_upload_enabled,
    quiet_start_minutes = excluded.quiet_start_minutes,
    quiet_end_minutes = excluded.quiet_end_minutes,
    updated_at = now()
  returning * into v_preferences;

  return v_preferences;
end;
$$;

create or replace function public.record_nabi_notification_events(p_events jsonb)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_event jsonb;
  v_count integer := 0;
  v_event_name text;
  v_occurrence_id uuid;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;
  if jsonb_typeof(coalesce(p_events, '[]'::jsonb)) <> 'array'
     or jsonb_array_length(coalesce(p_events, '[]'::jsonb)) > 100 then
    raise exception 'INVALID_EVENT_BATCH' using errcode = '22023';
  end if;
  if not coalesce((
    select p.analytics_upload_enabled
    from public.nabi_notification_preferences p
    where p.user_id = v_user_id
  ), false) then
    return 0;
  end if;

  for v_event in select value from jsonb_array_elements(p_events)
  loop
    v_event_name := v_event ->> 'event_name';
    if v_event_name not in (
      'nabi_notification_eligible', 'nabi_notification_shown',
      'nabi_notification_opened', 'nabi_notification_dismissed',
      'nabi_notification_primary_clicked', 'nabi_notification_secondary_clicked',
      'nabi_upgrade_page_viewed', 'nabi_checkout_started',
      'nabi_conversion_completed', 'nabi_notification_failed'
    ) then
      continue;
    end if;
    v_occurrence_id := nullif(v_event ->> 'occurrence_id', '')::uuid;
    if v_occurrence_id is not null and not exists (
      select 1 from public.nabi_notification_user_states s
      where s.id = v_occurrence_id and s.user_id = v_user_id
    ) then
      continue;
    end if;

    insert into public.nabi_notification_events (
      id, user_id, occurrence_id, notification_id, event_name,
      session_id, screen_key, app_version, result_code, safe_metadata, created_at
    ) values (
      (v_event ->> 'id')::uuid,
      v_user_id,
      v_occurrence_id,
      coalesce(v_event ->> 'notification_id', 'unknown'),
      v_event_name,
      nullif(v_event ->> 'session_id', ''),
      nullif(v_event ->> 'screen_key', ''),
      nullif(v_event ->> 'app_version', ''),
      nullif(v_event ->> 'result_code', ''),
      coalesce(v_event -> 'safe_metadata', '{}'::jsonb),
      coalesce(nullif(v_event ->> 'created_at', '')::timestamptz, now())
    ) on conflict (id) do nothing;
    if found then v_count := v_count + 1; end if;
  end loop;
  return v_count;
end;
$$;

create or replace function public.admin_upsert_nabi_notification_definition(
  p_notification_id text,
  p_content_version integer,
  p_category text,
  p_priority integer,
  p_policy_key text,
  p_primary_action_key text,
  p_secondary_action_key text,
  p_allowed_channels text[],
  p_title_template text,
  p_body_template text,
  p_config jsonb,
  p_status text,
  p_reason text,
  p_idempotency_key text
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_id uuid;
begin
  perform public.admin_assert_permission('notifications.write');
  if nullif(btrim(coalesce(p_reason, '')), '') is null
     or nullif(btrim(coalesce(p_idempotency_key, '')), '') is null then
    raise exception 'ADMIN_REASON_AND_IDEMPOTENCY_REQUIRED' using errcode = '22023';
  end if;
  if p_status not in ('draft', 'active', 'archived')
     or p_category not in ('contextual', 'milestone', 'subscription', 'retention', 'reward', 'report', 'care', 'profile')
     or not p_policy_key = any(array[
       'free_plan_limit', 'free_chat_limit', 'first_streak_7', 'expert_locked',
       'map365_locked', 'weekly_report_locked', 'expert_recommended',
       'plus_day_7', 'plus_day_15', 'plus_expiry_5', 'plus_expiry_1',
       'streak_6', 'rescue_card', 'reward_ready', 'report_ready',
       'invite_available', 'care_near_sleep', 'return_72h', 'partial_day', 'profile_stale'
     ])
     or not p_primary_action_key = any(array[
       'membership_compare', 'membership_payment', 'achievement', 'expert_benefit',
       'map365', 'weekly_report', 'easiest_task', 'rescue_card_confirm',
       'reward_box', 'user_invite', 'dashboard_today', 'today_tasks', 'partial_profile'
     ])
     or exists (
       select 1 from unnest(coalesce(p_allowed_channels, array[]::text[])) channel
       where channel not in ('in_app', 'os_local')
     ) then
    raise exception 'INVALID_NOTIFICATION_DEFINITION' using errcode = '22023';
  end if;

  if p_status = 'active' then
    update public.nabi_notification_definitions
    set status = 'archived'
    where notification_id = btrim(p_notification_id) and status = 'active';
  end if;

  insert into public.nabi_notification_definitions (
    notification_id, content_version, category, priority, policy_key,
    primary_action_key, secondary_action_key, allowed_channels,
    title_template, body_template, config, status, reason, created_by
  ) values (
    btrim(p_notification_id), p_content_version, p_category, p_priority,
    p_policy_key, p_primary_action_key, nullif(btrim(coalesce(p_secondary_action_key, '')), ''),
    p_allowed_channels, p_title_template, p_body_template,
    coalesce(p_config, '{}'::jsonb), p_status, btrim(p_reason), auth.uid()
  )
  on conflict (notification_id, content_version) do update set
    category = excluded.category,
    priority = excluded.priority,
    policy_key = excluded.policy_key,
    primary_action_key = excluded.primary_action_key,
    secondary_action_key = excluded.secondary_action_key,
    allowed_channels = excluded.allowed_channels,
    title_template = excluded.title_template,
    body_template = excluded.body_template,
    config = excluded.config,
    status = excluded.status,
    reason = excluded.reason
  returning id into v_id;

  perform public.admin_write_audit(
    'nabi_notification_definition_upsert', 'nabi_notification_definition',
    btrim(p_notification_id), btrim(p_reason), btrim(p_idempotency_key),
    jsonb_build_object('content_version', p_content_version, 'status', p_status)
  );
  return v_id;
end;
$$;

revoke all on table public.nabi_notification_definitions from anon, authenticated;
revoke all on table public.nabi_notification_user_states from anon, authenticated;
revoke all on table public.nabi_notification_preferences from anon, authenticated;
revoke all on table public.nabi_notification_events from anon, authenticated;
grant select on public.nabi_notification_definitions to authenticated;
grant select on public.nabi_notification_user_states to authenticated;
grant select on public.nabi_notification_preferences to authenticated;
grant select on public.nabi_notification_events to authenticated;

revoke all on function public.get_active_nabi_notification_definitions() from public, anon;
revoke all on function public.claim_nabi_notification_occurrence(text, integer, text, text, timestamptz, timestamptz, jsonb) from public, anon;
revoke all on function public.upsert_my_nabi_notification_preferences(boolean, boolean, boolean, integer, integer) from public, anon;
revoke all on function public.record_nabi_notification_events(jsonb) from public, anon;
revoke all on function public.admin_upsert_nabi_notification_definition(text, integer, text, integer, text, text, text, text[], text, text, jsonb, text, text, text) from public, anon;
grant execute on function public.get_active_nabi_notification_definitions() to authenticated;
grant execute on function public.claim_nabi_notification_occurrence(text, integer, text, text, timestamptz, timestamptz, jsonb) to authenticated;
grant execute on function public.upsert_my_nabi_notification_preferences(boolean, boolean, boolean, integer, integer) to authenticated;
grant execute on function public.record_nabi_notification_events(jsonb) to authenticated;
grant execute on function public.admin_upsert_nabi_notification_definition(text, integer, text, integer, text, text, text, text[], text, text, jsonb, text, text, text) to authenticated;

insert into public.system_config_versions (
  config_key, config_value, status, reason, created_by
)
select
  'nabi_companion_notifications_rollout',
  '{"enabled": false, "in_app_enabled": false, "os_local_enabled": false}'::jsonb,
  'active',
  'M30 rollout remains disabled until sandbox and device acceptance pass.',
  null
where not exists (
  select 1 from public.system_config_versions
  where config_key = 'nabi_companion_notifications_rollout' and status = 'active'
);

commit;
