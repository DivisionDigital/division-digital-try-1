create function app_private.is_org_member(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.organization_members membership
    where membership.organization_id = target_organization_id
      and membership.user_id = (select auth.uid())
      and membership.status = 'active'
  );
$$;

create function app_private.is_staff(allowed_roles text[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.staff_members staff
    where staff.user_id = (select auth.uid())
      and staff.status = 'active'
      and staff.role = any(allowed_roles)
  );
$$;

create function app_private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select app_private.is_staff(array['admin']::text[]);
$$;

revoke execute on all functions in schema app_private from public;
grant usage on schema app_private to authenticated;
grant execute on function app_private.is_org_member(uuid) to authenticated;
grant execute on function app_private.is_staff(text[]) to authenticated;
grant execute on function app_private.is_admin() to authenticated;
grant execute on function app_private.handle_new_auth_user() to supabase_auth_admin;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'profiles', 'organizations', 'organization_members', 'organization_invitations',
    'staff_members', 'staff_invitations', 'service_catalog',
    'service_workflow_versions', 'form_templates', 'form_versions',
    'milestone_templates', 'quotes', 'quote_versions', 'quote_version_items',
    'orders', 'order_items', 'payments', 'webhook_events', 'service_instances',
    'project_events', 'milestones', 'project_forms', 'form_response_revisions',
    'files', 'messages', 'notifications', 'audit_events', 'outbox_events'
  ]
  loop
    execute format('alter table public.%I enable row level security', table_name);
  end loop;
end
$$;

revoke all on all tables in schema public from anon, authenticated;
alter default privileges for role postgres in schema public
  revoke all on tables from anon, authenticated;

grant select on public.service_catalog to anon;

grant select on table
  public.profiles,
  public.organizations,
  public.organization_members,
  public.organization_invitations,
  public.staff_members,
  public.staff_invitations,
  public.service_catalog,
  public.service_workflow_versions,
  public.form_templates,
  public.form_versions,
  public.milestone_templates,
  public.quotes,
  public.quote_versions,
  public.quote_version_items,
  public.orders,
  public.order_items,
  public.payments,
  public.webhook_events,
  public.service_instances,
  public.project_events,
  public.milestones,
  public.project_forms,
  public.form_response_revisions,
  public.files,
  public.messages,
  public.notifications,
  public.audit_events,
  public.outbox_events
to authenticated;

grant update (display_name, phone, locale, timezone, avatar_path)
  on public.profiles to authenticated;
grant update (name, legal_name, tax_id, billing_email, contact_phone, billing_address)
  on public.organizations to authenticated;
grant insert (organization_id, requested_start_date, customer_note, idempotency_key, created_by)
  on public.quotes to authenticated;
grant insert (organization_id, service_instance_id, author_user_id, visibility, body)
  on public.messages to authenticated;
grant update (status, read_at, archived_at)
  on public.notifications to authenticated;

create policy profiles_select_self_or_staff
  on public.profiles for select to authenticated
  using (
    id = (select auth.uid())
    or (select app_private.is_staff(array['team', 'admin']::text[]))
  );

create policy profiles_update_self_or_staff
  on public.profiles for update to authenticated
  using (
    id = (select auth.uid())
    or (select app_private.is_staff(array['team', 'admin']::text[]))
  )
  with check (
    id = (select auth.uid())
    or (select app_private.is_staff(array['team', 'admin']::text[]))
  );

create policy organizations_select_member_or_staff
  on public.organizations for select to authenticated
  using (
    (select app_private.is_org_member(id))
    or (select app_private.is_staff(array['team', 'admin']::text[]))
  );

create policy organizations_update_member_or_staff
  on public.organizations for update to authenticated
  using (
    (select app_private.is_org_member(id))
    or (select app_private.is_staff(array['team', 'admin']::text[]))
  )
  with check (
    (select app_private.is_org_member(id))
    or (select app_private.is_staff(array['team', 'admin']::text[]))
  );

create policy organization_members_select_scope
  on public.organization_members for select to authenticated
  using (
    (select app_private.is_org_member(organization_id))
    or (select app_private.is_staff(array['team', 'admin']::text[]))
  );

create policy organization_invitations_select_staff
  on public.organization_invitations for select to authenticated
  using ((select app_private.is_staff(array['team', 'admin']::text[])));

create policy staff_members_select_staff
  on public.staff_members for select to authenticated
  using (
    user_id = (select auth.uid())
    or (select app_private.is_staff(array['team', 'admin']::text[]))
  );

create policy staff_invitations_select_admin
  on public.staff_invitations for select to authenticated
  using ((select app_private.is_admin()));

create policy service_catalog_select_published_anon
  on public.service_catalog for select to anon
  using (status = 'published' and visibility = 'public');

create policy service_catalog_select_published_or_staff
  on public.service_catalog for select to authenticated
  using (
    (status = 'published' and visibility = 'public')
    or (select app_private.is_staff(array['team', 'admin']::text[]))
  );

create policy workflow_versions_select_project_or_staff
  on public.service_workflow_versions for select to authenticated
  using (
    (select app_private.is_staff(array['team', 'admin']::text[]))
    or exists (
      select 1
      from public.service_instances project
      where project.workflow_version_id = service_workflow_versions.id
        and (select app_private.is_org_member(project.organization_id))
    )
  );

create policy form_templates_select_project_or_staff
  on public.form_templates for select to authenticated
  using (
    (select app_private.is_staff(array['team', 'admin']::text[]))
    or exists (
      select 1
      from public.project_forms project_form
      where project_form.form_template_id = form_templates.id
        and (select app_private.is_org_member(project_form.organization_id))
    )
  );

create policy form_versions_select_project_or_staff
  on public.form_versions for select to authenticated
  using (
    (select app_private.is_staff(array['team', 'admin']::text[]))
    or exists (
      select 1
      from public.project_forms project_form
      where project_form.form_version_id = form_versions.id
        and (select app_private.is_org_member(project_form.organization_id))
    )
  );

create policy milestone_templates_select_staff
  on public.milestone_templates for select to authenticated
  using ((select app_private.is_staff(array['team', 'admin']::text[])));

create policy quotes_select_scope
  on public.quotes for select to authenticated
  using (
    (select app_private.is_org_member(organization_id))
    or (select app_private.is_staff(array['team', 'admin']::text[]))
  );

create policy quotes_insert_member_or_staff
  on public.quotes for insert to authenticated
  with check (
    created_by = (select auth.uid())
    and (
      (select app_private.is_org_member(organization_id))
      or (select app_private.is_staff(array['team', 'admin']::text[]))
    )
  );

create policy quote_versions_select_scope
  on public.quote_versions for select to authenticated
  using (
    exists (
      select 1
      from public.quotes quote
      where quote.id = quote_versions.quote_id
        and (
          (select app_private.is_org_member(quote.organization_id))
          or (select app_private.is_staff(array['team', 'admin']::text[]))
        )
    )
  );

create policy quote_version_items_select_scope
  on public.quote_version_items for select to authenticated
  using (
    exists (
      select 1
      from public.quote_versions quote_version
      join public.quotes quote on quote.id = quote_version.quote_id
      where quote_version.id = quote_version_items.quote_version_id
        and (
          (select app_private.is_org_member(quote.organization_id))
          or (select app_private.is_staff(array['team', 'admin']::text[]))
        )
    )
  );

create policy orders_select_scope
  on public.orders for select to authenticated
  using (
    (select app_private.is_org_member(organization_id))
    or (select app_private.is_staff(array['team', 'admin']::text[]))
  );

create policy order_items_select_scope
  on public.order_items for select to authenticated
  using (
    (select app_private.is_org_member(organization_id))
    or (select app_private.is_staff(array['team', 'admin']::text[]))
  );

create policy payments_select_staff
  on public.payments for select to authenticated
  using ((select app_private.is_staff(array['team', 'admin']::text[])));

create policy webhook_events_select_staff
  on public.webhook_events for select to authenticated
  using ((select app_private.is_staff(array['team', 'admin']::text[])));

create policy service_instances_select_scope
  on public.service_instances for select to authenticated
  using (
    (select app_private.is_org_member(organization_id))
    or (select app_private.is_staff(array['team', 'admin']::text[]))
  );

create policy project_events_select_scope
  on public.project_events for select to authenticated
  using (
    (select app_private.is_staff(array['team', 'admin']::text[]))
    or (
      visibility = 'client'
      and (select app_private.is_org_member(organization_id))
    )
  );

create policy milestones_select_scope
  on public.milestones for select to authenticated
  using (
    (select app_private.is_staff(array['team', 'admin']::text[]))
    or (
      visible_to_client
      and (select app_private.is_org_member(organization_id))
    )
  );

create policy project_forms_select_scope
  on public.project_forms for select to authenticated
  using (
    (select app_private.is_org_member(organization_id))
    or (select app_private.is_staff(array['team', 'admin']::text[]))
  );

create policy form_response_revisions_select_scope
  on public.form_response_revisions for select to authenticated
  using (
    (select app_private.is_org_member(organization_id))
    or (select app_private.is_staff(array['team', 'admin']::text[]))
  );

create policy files_select_scope
  on public.files for select to authenticated
  using (
    (select app_private.is_staff(array['team', 'admin']::text[]))
    or (
      visibility = 'client'
      and (select app_private.is_org_member(organization_id))
    )
  );

create policy messages_select_scope
  on public.messages for select to authenticated
  using (
    (select app_private.is_staff(array['team', 'admin']::text[]))
    or (
      visibility = 'client'
      and (select app_private.is_org_member(organization_id))
    )
  );

create policy messages_insert_scope
  on public.messages for insert to authenticated
  with check (
    author_user_id = (select auth.uid())
    and (
      (
        visibility = 'client'
        and (select app_private.is_org_member(organization_id))
      )
      or (select app_private.is_staff(array['team', 'admin']::text[]))
    )
  );

create policy notifications_select_own
  on public.notifications for select to authenticated
  using (user_id = (select auth.uid()));

create policy notifications_update_own
  on public.notifications for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy audit_events_select_staff
  on public.audit_events for select to authenticated
  using ((select app_private.is_staff(array['team', 'admin']::text[])));

create policy outbox_events_select_admin
  on public.outbox_events for select to authenticated
  using ((select app_private.is_admin()));

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'project-files',
  'project-files',
  false,
  26214400,
  array['application/pdf', 'image/jpeg', 'image/png', 'image/webp']::text[]
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy project_files_insert_authorized
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'project-files'
    and exists (
      select 1
      from public.files file_record
      where file_record.storage_bucket = bucket_id
        and file_record.storage_path = name
        and file_record.status = 'pending_upload'
        and file_record.created_by = (select auth.uid())
        and (
          (select app_private.is_org_member(file_record.organization_id))
          or (select app_private.is_staff(array['team', 'admin']::text[]))
        )
    )
  );

create policy project_files_select_authorized
  on storage.objects for select to authenticated
  using (
    bucket_id = 'project-files'
    and exists (
      select 1
      from public.files file_record
      where file_record.storage_bucket = bucket_id
        and file_record.storage_path = name
        and file_record.status = 'available'
        and (
          (select app_private.is_staff(array['team', 'admin']::text[]))
          or (
            file_record.visibility = 'client'
            and (select app_private.is_org_member(file_record.organization_id))
          )
        )
    )
  );

comment on function app_private.is_org_member(uuid) is
  'Comprueba membresía activa del usuario autenticado sin confiar en user_metadata.';
comment on function app_private.is_staff(text[]) is
  'Comprueba autoridad global desde staff_members, separada de organizaciones cliente.';
