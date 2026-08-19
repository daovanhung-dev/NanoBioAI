-- NanoBioAI - account suspension enforcement for Admin user operations.
-- Apply to an existing Supabase environment after the current Admin schema.
-- The canonical rebuild source on 2026-08-19 is docs/supabase/setup.sql + seed_data.sql.

begin;

create or replace function public.admin_update_user_status(
  p_user_id uuid,
  p_status text,
  p_reason text,
  p_idempotency_key text
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.admin_assert_permission('users.write');

  if p_status not in ('active', 'suspended', 'closed') then
    raise exception 'INVALID_USER_STATUS' using errcode = '22023';
  end if;

  update public.users
  set admin_status = p_status, updated_at = now()
  where id = p_user_id;

  if not found then
    raise exception 'USER_NOT_FOUND' using errcode = 'P0002';
  end if;

  -- public.users.admin_status is the operational source used by NanoBio.
  -- Mirror it into Supabase Auth so a suspended/closed user cannot create a
  -- new password session. Existing Auth sessions are removed immediately.
  if p_status in ('suspended', 'closed') then
    update auth.users
    set banned_until = now() + interval '100 years',
        updated_at = now()
    where id = p_user_id;

    delete from auth.sessions
    where user_id = p_user_id;
  else
    update auth.users
    set banned_until = null,
        updated_at = now()
    where id = p_user_id;
  end if;

  perform public.admin_write_audit(
    'admin_update_user_status',
    'user',
    p_user_id::text,
    p_reason,
    p_idempotency_key,
    jsonb_build_object(
      'status', p_status,
      'auth_enforced', true
    )
  );

  return query select true, 'Da cap nhat trang thai nguoi dung.';
end;
$$;

grant execute on function public.admin_update_user_status(
  uuid,
  text,
  text,
  text
) to authenticated;

commit;
