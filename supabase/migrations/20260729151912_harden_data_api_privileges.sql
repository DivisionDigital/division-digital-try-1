-- Private business data is consumed through the application API, not directly
-- from browser Data API clients. Grants and RLS intentionally remain separate
-- layers of protection.

revoke all privileges on all tables in schema public
  from anon, authenticated, service_role;
revoke all privileges on all sequences in schema public
  from anon, authenticated, service_role;
revoke execute on all functions in schema public
  from public, anon, authenticated, service_role;

-- Remove the column-level grants declared by the initial migration. A table
-- revoke does not necessarily remove privileges granted on individual columns.
revoke update (display_name, phone, locale, timezone, avatar_path)
  on public.profiles from authenticated;
revoke update (name, legal_name, tax_id, billing_email, contact_phone, billing_address)
  on public.organizations from authenticated;
revoke insert (organization_id, requested_start_date, customer_note, idempotency_key, created_by)
  on public.quotes from authenticated;
revoke insert (organization_id, service_instance_id, author_user_id, visibility, body)
  on public.messages from authenticated;
revoke update (status, read_at, archived_at)
  on public.notifications from authenticated;

alter default privileges for role postgres in schema public
  revoke all privileges on tables from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke all privileges on sequences from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke execute on functions from public, anon, authenticated, service_role;
alter default privileges for role postgres in schema app_private
  revoke execute on functions from public, anon, authenticated, service_role;

grant usage on schema public to anon, authenticated, service_role;

-- The public catalog intentionally excludes configuration, ownership and
-- operational columns. Row policies further restrict this to published rows.
grant select (id, slug, name, description, version, published_at)
  on public.service_catalog to anon, authenticated;

-- Server-only Data API adapter. No DELETE, TRUNCATE, REFERENCES or TRIGGER is
-- granted. Append-only and immutable tables receive no UPDATE privilege.
grant select, insert on table
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
to service_role;

grant update on table
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
  public.payments,
  public.webhook_events,
  public.service_instances,
  public.milestones,
  public.project_forms,
  public.files,
  public.messages,
  public.notifications,
  public.outbox_events
to service_role;

create or replace function app_private.is_org_owner(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null
    and exists (
      select 1
      from public.organization_members membership
      where membership.organization_id = target_organization_id
        and membership.user_id = (select auth.uid())
        and membership.role = 'owner'
        and membership.status = 'active'
    );
$$;

revoke all on function app_private.is_org_owner(uuid)
  from public, anon, authenticated, service_role;
grant execute on function app_private.is_org_owner(uuid) to authenticated;

drop policy if exists organizations_update_member_or_staff
  on public.organizations;
drop policy if exists organizations_update_owner_or_staff
  on public.organizations;

create policy organizations_update_owner_or_staff
  on public.organizations for update to authenticated
  using (
    (select app_private.is_org_owner(id))
    or (select app_private.is_staff(array['team', 'admin']::text[]))
  )
  with check (
    (select app_private.is_org_owner(id))
    or (select app_private.is_staff(array['team', 'admin']::text[]))
  );

drop policy if exists service_catalog_select_published_or_staff
  on public.service_catalog;
drop policy if exists service_catalog_select_published_authenticated
  on public.service_catalog;

create policy service_catalog_select_published_authenticated
  on public.service_catalog for select to authenticated
  using (status = 'published' and visibility = 'public');

comment on function app_private.is_org_owner(uuid) is
  'Checks active organization ownership without trusting user-editable JWT metadata.';
