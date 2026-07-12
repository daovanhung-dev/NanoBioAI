-- NanoBio migration 15: Auth V2 signup/referral atomic contract.
-- Non-destructive: replaces only the auth signup trigger function and keeps
-- existing tables/data. Apply to sandbox first. Do not execute config.sql on
-- remote/production.

begin;

create or replace function public.handle_auth_user_created()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_is_anonymous boolean;
  v_product_status public.nb_product_access_status;
  v_referral_code text;
  v_device_hash text;
  v_phone text;
  v_referrer_id uuid;
  v_referrer_email text;
  v_referrer_phone text;
begin
  v_is_anonymous := coalesce(
    (new.raw_app_meta_data ->> 'provider') = 'anonymous',
    new.email is null and new.phone is null
  );
  v_product_status := case when v_is_anonymous then 'guest' else 'free' end;
  v_referral_code := upper(
    nullif(btrim(new.raw_user_meta_data ->> 'referral_code'), '')
  );
  v_device_hash := nullif(
    btrim(new.raw_user_meta_data ->> 'device_fingerprint'),
    ''
  );
  v_phone := coalesce(
    nullif(btrim(new.phone), ''),
    nullif(btrim(new.raw_user_meta_data ->> 'phone'), '')
  );

  -- All referral checks happen inside the auth.users insert transaction. Any
  -- exception below rolls back auth.users, public.users and the self subject.
  if v_referral_code is not null then
    if v_is_anonymous then
      raise exception using errcode = 'P0001', message = 'invalid_referral_code';
    end if;

    if v_device_hash is null then
      raise exception using errcode = 'P0001', message = 'referral_device_missing';
    end if;

    select
      rc.sale_user_id,
      u.email,
      u.phone
    into
      v_referrer_id,
      v_referrer_email,
      v_referrer_phone
    from public.referral_codes rc
    join public.sale_profiles sp
      on sp.user_id = rc.sale_user_id
     and sp.status = 'active'
    join public.users u
      on u.id = rc.sale_user_id
    where upper(rc.code) = v_referral_code
      and rc.status = 'active'
    limit 1;

    if v_referrer_id is null then
      raise exception using errcode = 'P0001', message = 'invalid_referral_code';
    end if;

    if v_referrer_id = new.id then
      raise exception using errcode = 'P0001', message = 'referral_collision';
    end if;

    if new.email is not null
       and v_referrer_email is not null
       and lower(new.email) = lower(v_referrer_email) then
      raise exception using errcode = 'P0001', message = 'referral_collision';
    end if;

    if v_phone is not null
       and v_referrer_phone is not null
       and v_phone = v_referrer_phone then
      raise exception using errcode = 'P0001', message = 'referral_collision';
    end if;

    if exists (
      select 1
      from public.sale_profiles sp
      where sp.user_id = v_referrer_id
        and sp.participation_device_hash = v_device_hash
    ) then
      raise exception using errcode = 'P0001', message = 'referral_collision';
    end if;

    if exists (
      select 1
      from public.referral_relationships rr
      where rr.status = 'active'
        and rr.device_hash = v_device_hash
    ) then
      raise exception using errcode = 'P0001', message = 'referral_already_used';
    end if;

    if new.email is not null and exists (
      select 1
      from public.referral_relationships rr
      join public.users referred on referred.id = rr.referred_user_id
      where rr.status = 'active'
        and referred.email is not null
        and lower(referred.email) = lower(new.email)
    ) then
      raise exception using errcode = 'P0001', message = 'referral_already_used';
    end if;

    if v_phone is not null and exists (
      select 1
      from public.referral_relationships rr
      join public.users referred on referred.id = rr.referred_user_id
      where rr.status = 'active'
        and referred.phone = v_phone
    ) then
      raise exception using errcode = 'P0001', message = 'referral_already_used';
    end if;
  end if;

  insert into public.users (
    id,
    email,
    phone,
    full_name,
    avatar_url,
    subscription_tier,
    product_access_status,
    is_anonymous
  )
  values (
    new.id,
    new.email,
    v_phone,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', '')
    ),
    nullif(new.raw_user_meta_data ->> 'avatar_url', ''),
    'free',
    v_product_status,
    v_is_anonymous
  )
  on conflict (id) do update
  set
    email = excluded.email,
    phone = coalesce(excluded.phone, public.users.phone),
    full_name = coalesce(public.users.full_name, excluded.full_name),
    avatar_url = coalesce(public.users.avatar_url, excluded.avatar_url),
    product_access_status = excluded.product_access_status,
    is_anonymous = excluded.is_anonymous,
    updated_at = now();

  insert into public.health_subjects (
    owner_user_id,
    linked_user_id,
    subject_type,
    display_name,
    relationship
  )
  values (
    new.id,
    new.id,
    'self',
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', ''),
      new.email,
      'Bạn'
    ),
    'self'
  )
  on conflict (owner_user_id) where subject_type = 'self'
  do update
  set
    linked_user_id = excluded.linked_user_id,
    display_name = coalesce(public.health_subjects.display_name, excluded.display_name),
    is_active = true,
    updated_at = now();

  if v_referral_code is not null then
    insert into public.referral_relationships (
      referrer_user_id,
      referred_user_id,
      referral_code,
      source,
      status,
      device_hash,
      metadata
    )
    values (
      v_referrer_id,
      new.id,
      v_referral_code,
      'signup',
      'active',
      v_device_hash,
      jsonb_build_object(
        'contract_version', 'auth_v2_atomic_signup_v1',
        'policy', 'direct_only',
        'validated_at', now()
      )
    );
  end if;

  return new;
end;
$$;

-- Recreate explicitly so environments with a stale trigger binding use the
-- latest function contract without changing any table.
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_auth_user_created();

commit;
