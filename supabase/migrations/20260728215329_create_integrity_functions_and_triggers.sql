create function app_private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create function app_private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    nullif(trim(coalesce(new.raw_user_meta_data ->> 'display_name', '')), '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

revoke all on function app_private.handle_new_auth_user() from public;
grant execute on function app_private.handle_new_auth_user() to supabase_auth_admin;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function app_private.handle_new_auth_user();

create function app_private.prevent_append_only_changes()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception using
    errcode = '55000',
    message = format('%I.%I is append-only', tg_table_schema, tg_table_name);
end;
$$;

create function app_private.protect_version_content()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  old_content jsonb;
  new_content jsonb;
begin
  if tg_op = 'DELETE' then
    if old.status <> 'draft' then
      raise exception using
        errcode = '55000',
        message = format('Published history in %I.%I cannot be deleted', tg_table_schema, tg_table_name);
    end if;
    return old;
  end if;

  if old.status <> 'draft' then
    old_content := to_jsonb(old)
      - array['status', 'published_at', 'published_by', 'accepted_at', 'accepted_by'];
    new_content := to_jsonb(new)
      - array['status', 'published_at', 'published_by', 'accepted_at', 'accepted_by'];

    if old_content is distinct from new_content then
      raise exception using
        errcode = '55000',
        message = format('Published content in %I.%I is immutable', tg_table_schema, tg_table_name);
    end if;
  end if;
  return new;
end;
$$;

create function app_private.protect_tenant_assignment()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.organization_id is distinct from old.organization_id then
    raise exception using
      errcode = '42501',
      message = format('organization_id cannot be reassigned in %I.%I', tg_table_schema, tg_table_name);
  end if;
  return new;
end;
$$;

create trigger service_workflow_versions_protect_content
  before update or delete on public.service_workflow_versions
  for each row execute function app_private.protect_version_content();

create trigger form_versions_protect_content
  before update or delete on public.form_versions
  for each row execute function app_private.protect_version_content();

create trigger quote_versions_protect_content
  before update or delete on public.quote_versions
  for each row execute function app_private.protect_version_content();

create trigger project_events_append_only
  before update or delete on public.project_events
  for each row execute function app_private.prevent_append_only_changes();

create trigger form_response_revisions_append_only
  before update or delete on public.form_response_revisions
  for each row execute function app_private.prevent_append_only_changes();

create trigger audit_events_append_only
  before update or delete on public.audit_events
  for each row execute function app_private.prevent_append_only_changes();

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'organizations', 'organization_members', 'organization_invitations',
    'staff_members', 'staff_invitations', 'service_catalog', 'form_templates',
    'milestone_templates', 'quotes', 'orders', 'payments', 'webhook_events',
    'service_instances', 'milestones', 'project_forms', 'files', 'messages',
    'notifications', 'outbox_events'
  ]
  loop
    execute format(
      'create trigger %I before update on public.%I for each row execute function app_private.set_updated_at()',
      table_name || '_set_updated_at',
      table_name
    );
  end loop;
end
$$;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'organization_members', 'organization_invitations', 'quotes', 'orders',
    'order_items', 'payments', 'service_instances', 'project_events',
    'milestones', 'project_forms', 'form_response_revisions', 'files',
    'messages'
  ]
  loop
    execute format(
      'create trigger %I before update on public.%I for each row execute function app_private.protect_tenant_assignment()',
      table_name || '_protect_tenant',
      table_name
    );
  end loop;
end
$$;
