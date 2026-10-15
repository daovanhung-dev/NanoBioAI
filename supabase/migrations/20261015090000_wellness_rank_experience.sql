begin;

create table if not exists public.wellness_rank_accounts (
  user_id uuid primary key references public.users(id) on delete cascade,
  experience_points integer not null default 0 check (experience_points >= 0),
  first_exp_at timestamptz,
  next_decay_at timestamptz,
  decay_cycle integer not null default 0 check (decay_cycle >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.wellness_rank_experience_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  event_key text not null,
  event_type text not null check (event_type in ('task_completion', 'task_undo', 'weekly_decay')),
  schedule_item_id uuid,
  source_event_id uuid,
  experience_delta integer not null,
  created_at timestamptz not null default now(),
  unique (user_id, event_key)
);

create index if not exists idx_wellness_rank_ledger_user_created
  on public.wellness_rank_experience_ledger(user_id, created_at desc);

create table if not exists public.wellness_rank_task_states (
  user_id uuid not null references public.users(id) on delete cascade,
  schedule_item_id uuid not null,
  is_awarded boolean not null default false,
  source_event_id uuid,
  updated_at timestamptz not null default now(),
  primary key (user_id, schedule_item_id)
);

alter table public.wellness_rank_accounts enable row level security;
alter table public.wellness_rank_experience_ledger enable row level security;
alter table public.wellness_rank_task_states enable row level security;
revoke all on public.wellness_rank_accounts from public, anon, authenticated;
revoke all on public.wellness_rank_experience_ledger from public, anon, authenticated;
revoke all on public.wellness_rank_task_states from public, anon, authenticated;

create or replace function public.apply_wellness_rank_due_decay(
  p_user_id uuid,
  p_now timestamptz default now()
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_account public.wellness_rank_accounts%rowtype;
  v_delta integer;
  v_cycle integer;
begin
  select * into v_account
  from public.wellness_rank_accounts
  where user_id = p_user_id
  for update;
  if not found then return; end if;

  while v_account.next_decay_at is not null and v_account.next_decay_at <= p_now loop
    v_cycle := v_account.decay_cycle + 1;
    v_delta := -least(v_account.experience_points, 100);
    v_account.experience_points := v_account.experience_points + v_delta;
    v_account.decay_cycle := v_cycle;
    v_account.next_decay_at := v_account.next_decay_at + interval '7 days';

    update public.wellness_rank_accounts
    set experience_points = v_account.experience_points,
        decay_cycle = v_account.decay_cycle,
        next_decay_at = v_account.next_decay_at,
        updated_at = p_now
    where user_id = p_user_id;

    insert into public.wellness_rank_experience_ledger(
      user_id, event_key, event_type, experience_delta, created_at
    ) values (
      p_user_id, 'weekly-decay:' || v_cycle::text, 'weekly_decay', v_delta, p_now
    ) on conflict (user_id, event_key) do nothing;
  end loop;
end;
$$;

drop function if exists public.reconcile_wellness_rank_task(uuid, uuid, boolean, uuid);

create or replace function public.reconcile_wellness_rank_task(
  p_user_id uuid,
  p_schedule_item_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_account public.wellness_rank_accounts%rowtype;
  v_state public.wellness_rank_task_states%rowtype;
  v_now timestamptz := now();
  v_delta integer;
  v_source_event_id uuid;
  v_has_state boolean;
begin
  if p_user_id is null or p_schedule_item_id is null then return; end if;

  perform pg_advisory_xact_lock(hashtextextended(
    'wellness-rank-task:' || p_user_id::text || ':' || p_schedule_item_id::text,
    0
  ));

  select evidence.id into v_source_event_id
  from (
    select p.id, p.created_at
    from public.schedule_completion_proofs p
    join public.schedule_reward_eligibilities pe on pe.id = p.eligibility_id
    where p.user_id = p_user_id
      and pe.schedule_item_id = p_schedule_item_id
      and pe.user_id = p_user_id
      and p.status = 'active'
    union all
    select h.id, h.created_at
    from public.schedule_health_checkins h
    where h.user_id = p_user_id
      and h.schedule_item_id = p_schedule_item_id
      and h.status = 'active'
  ) evidence
  order by evidence.created_at, evidence.id
  limit 1;

  if v_source_event_id is not null then
    insert into public.wellness_rank_accounts(user_id, first_exp_at, next_decay_at)
    values (p_user_id, v_now, v_now + interval '7 days')
    on conflict (user_id) do nothing;
  end if;

  select * into v_account
  from public.wellness_rank_accounts
  where user_id = p_user_id
  for update;
  if not found then return; end if;

  perform public.apply_wellness_rank_due_decay(p_user_id, v_now);
  select * into v_account from public.wellness_rank_accounts
  where user_id = p_user_id for update;

  select * into v_state
  from public.wellness_rank_task_states
  where user_id = p_user_id and schedule_item_id = p_schedule_item_id
  for update;
  v_has_state := found;

  if v_source_event_id is not null then
    if v_has_state and v_state.is_awarded then return; end if;
    insert into public.wellness_rank_task_states(
      user_id, schedule_item_id, is_awarded, source_event_id, updated_at
    ) values (p_user_id, p_schedule_item_id, true, v_source_event_id, v_now)
    on conflict (user_id, schedule_item_id) do update
      set is_awarded = true, source_event_id = excluded.source_event_id,
          updated_at = excluded.updated_at;
    update public.wellness_rank_accounts
    set experience_points = experience_points + 10, updated_at = v_now
    where user_id = p_user_id;
    insert into public.wellness_rank_experience_ledger(
      user_id, event_key, event_type, schedule_item_id, source_event_id,
      experience_delta, created_at
    ) values (
      p_user_id, 'task:' || p_schedule_item_id::text || ':' || v_source_event_id::text || ':completion',
      'task_completion', p_schedule_item_id, v_source_event_id, 10, v_now
    ) on conflict (user_id, event_key) do nothing;
    return;
  end if;

  if not v_has_state or not v_state.is_awarded then return; end if;
  v_delta := -least(v_account.experience_points, 10);
  update public.wellness_rank_accounts
  set experience_points = experience_points + v_delta, updated_at = v_now
  where user_id = p_user_id;
  insert into public.wellness_rank_experience_ledger(
    user_id, event_key, event_type, schedule_item_id, source_event_id,
    experience_delta, created_at
  ) values (
    p_user_id, 'task:' || p_schedule_item_id::text || ':' || v_state.source_event_id::text || ':undo',
    'task_undo', p_schedule_item_id, v_state.source_event_id, v_delta, v_now
  ) on conflict (user_id, event_key) do nothing;
  update public.wellness_rank_task_states
  set is_awarded = false, updated_at = v_now
  where user_id = p_user_id and schedule_item_id = p_schedule_item_id;
end;
$$;

create or replace function public.sync_wellness_rank_task_evidence()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid;
  v_schedule_item_id uuid;
begin
  v_user_id := new.user_id;
  if tg_table_name = 'schedule_completion_proofs' then
    select e.schedule_item_id into v_schedule_item_id
    from public.schedule_reward_eligibilities e
    where e.id = new.eligibility_id and e.user_id = v_user_id;
  else
    v_schedule_item_id := new.schedule_item_id;
  end if;

  perform public.reconcile_wellness_rank_task(
    v_user_id,
    v_schedule_item_id
  );
  return new;
end;
$$;

drop trigger if exists trg_rank_from_schedule_completion_proofs
  on public.schedule_completion_proofs;
create trigger trg_rank_from_schedule_completion_proofs
after insert or update of status on public.schedule_completion_proofs
for each row execute function public.sync_wellness_rank_task_evidence();

drop trigger if exists trg_rank_from_schedule_health_checkins
  on public.schedule_health_checkins;
create trigger trg_rank_from_schedule_health_checkins
after insert or update of status on public.schedule_health_checkins
for each row execute function public.sync_wellness_rank_task_evidence();

create or replace function public.get_my_wellness_rank_summary()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_account public.wellness_rank_accounts%rowtype;
  v_now timestamptz := now();
  v_level integer;
  v_title text;
  v_current_threshold integer;
  v_next_threshold integer;
begin
  if v_user_id is null then
    raise exception using errcode = 'P0001', message = 'auth_required';
  end if;

  perform public.apply_wellness_rank_due_decay(v_user_id, v_now);
  select * into v_account from public.wellness_rank_accounts
  where user_id = v_user_id;

  if not found then
    v_account.experience_points := 0;
    v_account.next_decay_at := null;
  end if;

  v_level := case
    when v_account.experience_points >= 5200 then 5
    when v_account.experience_points >= 2600 then 4
    when v_account.experience_points >= 1200 then 3
    when v_account.experience_points >= 600 then 2
    else 1
  end;
  v_title := case v_level
    when 5 then 'Tinh Tú Hộ Mệnh'
    when 4 then 'Hộ Vệ Sức Sống'
    when 3 then 'Người Gìn Giữ Nhịp Sống'
    when 2 then 'Người Ươm Nếp Lành'
    else 'Mầm An Nhiên'
  end;
  v_current_threshold := case v_level
    when 5 then 5200 when 4 then 2600 when 3 then 1200
    when 2 then 600 else 0 end;
  v_next_threshold := case v_level
    when 1 then 600 when 2 then 1200 when 3 then 2600
    when 4 then 5200 else null end;

  return jsonb_build_object(
    'rank_code', 'wellness_rank_' || v_level::text,
    'rank_level', v_level,
    'title', v_title,
    'experience_points', v_account.experience_points,
    'current_rank_threshold', v_current_threshold,
    'next_rank_threshold', v_next_threshold,
    'experience_to_next_rank', case when v_next_threshold is null then 0
      else greatest(0, v_next_threshold - v_account.experience_points) end,
    'rank_progress_exp', greatest(0, v_account.experience_points - v_current_threshold),
    'rank_progress_target', case when v_next_threshold is null then 0
      else v_next_threshold - v_current_threshold end,
    'computed_at', v_now,
    'next_decay_at', v_account.next_decay_at
  );
end;
$$;

revoke all on function public.apply_wellness_rank_due_decay(uuid, timestamptz)
  from public, anon, authenticated;
revoke all on function public.reconcile_wellness_rank_task(uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.sync_wellness_rank_task_evidence()
  from public, anon, authenticated;
revoke all on function public.get_my_wellness_rank_summary()
  from public, anon;
grant execute on function public.get_my_wellness_rank_summary() to authenticated;

commit;
