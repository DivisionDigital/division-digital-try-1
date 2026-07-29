begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(18);

select extensions.is(
  (
    select count(*)::integer
    from pg_class relation
    join pg_namespace namespace on namespace.oid = relation.relnamespace
    where namespace.nspname = 'public'
      and relation.relkind = 'r'
  ),
  28,
  'public contains the expected 28 base tables'
);

select extensions.is(
  (
    select count(*)::integer
    from pg_class relation
    join pg_namespace namespace on namespace.oid = relation.relnamespace
    where namespace.nspname = 'public'
      and relation.relkind = 'r'
      and relation.relrowsecurity
  ),
  28,
  'all public base tables have RLS enabled'
);

select extensions.is(
  (
    select count(distinct tablename)::integer
    from pg_policies
    where schemaname = 'public'
  ),
  28,
  'all public base tables have at least one policy'
);

select extensions.ok(
  not has_any_column_privilege('anon', 'public.profiles', 'SELECT')
  and not has_any_column_privilege('authenticated', 'public.profiles', 'SELECT'),
  'profiles are not exposed directly through Data API roles'
);

select extensions.ok(
  not has_any_column_privilege('authenticated', 'public.quote_versions', 'SELECT')
  and not has_any_column_privilege('authenticated', 'public.organization_invitations', 'SELECT')
  and not has_any_column_privilege('authenticated', 'public.webhook_events', 'SELECT')
  and not has_any_column_privilege('authenticated', 'public.outbox_events', 'SELECT'),
  'commercial notes, invitation hashes and event payloads are not directly selectable'
);

select extensions.ok(
  has_column_privilege('anon', 'public.service_catalog', 'id', 'SELECT')
  and has_column_privilege('authenticated', 'public.service_catalog', 'name', 'SELECT')
  and not has_column_privilege('anon', 'public.service_catalog', 'configuration', 'SELECT')
  and not has_column_privilege('authenticated', 'public.service_catalog', 'created_by', 'SELECT'),
  'catalog Data API access is restricted to the safe column allowlist'
);

select extensions.ok(
  (
    select bool_and(
      has_table_privilege('service_role', format('public.%I', table_name), 'SELECT')
      and has_table_privilege('service_role', format('public.%I', table_name), 'INSERT')
    )
    from (
      values
        ('profiles'), ('organizations'), ('organization_members'),
        ('organization_invitations'), ('staff_members'), ('staff_invitations'),
        ('service_catalog'), ('service_workflow_versions'), ('form_templates'),
        ('form_versions'), ('milestone_templates'), ('quotes'), ('quote_versions'),
        ('quote_version_items'), ('orders'), ('order_items'), ('payments'),
        ('webhook_events'), ('service_instances'), ('project_events'), ('milestones'),
        ('project_forms'), ('form_response_revisions'), ('files'), ('messages'),
        ('notifications'), ('audit_events'), ('outbox_events')
    ) expected(table_name)
  ),
  'service_role has explicit server-side select and insert access'
);

select extensions.ok(
  (
    select bool_and(
      not has_table_privilege(
        'service_role',
        format('public.%I', table_name),
        privilege_name
      )
    )
    from (
      values
        ('profiles', 'DELETE'),
        ('profiles', 'TRUNCATE'),
        ('profiles', 'REFERENCES'),
        ('profiles', 'TRIGGER'),
        ('orders', 'DELETE'),
        ('orders', 'TRUNCATE'),
        ('orders', 'REFERENCES'),
        ('orders', 'TRIGGER'),
        ('audit_events', 'DELETE'),
        ('outbox_events', 'DELETE')
    ) denied(table_name, privilege_name)
  ),
  'service_role has no destructive or schema-authoring table privileges'
);

select extensions.ok(
  not has_table_privilege('service_role', 'public.order_items', 'UPDATE')
  and not has_table_privilege('service_role', 'public.project_events', 'UPDATE')
  and not has_table_privilege('service_role', 'public.form_response_revisions', 'UPDATE')
  and not has_table_privilege('service_role', 'public.audit_events', 'UPDATE'),
  'append-only tables do not grant service_role update'
);

select extensions.ok(
  not exists (
    select 1
    from pg_default_acl defaults
    join pg_roles owner_role on owner_role.oid = defaults.defaclrole
    join pg_namespace namespace on namespace.oid = defaults.defaclnamespace
    where owner_role.rolname = 'postgres'
      and namespace.nspname = 'public'
      and defaults.defaclacl::text ~ '(anon|authenticated|service_role)'
  ),
  'postgres public default ACL does not auto-expose future objects'
);

select extensions.ok(
  (
    select prosecdef
      and coalesce(proconfig, array[]::text[]) @> array['search_path=""']
    from pg_proc
    where oid = 'app_private.is_org_owner(uuid)'::regprocedure
  ),
  'organization owner helper is security definer with an empty search_path'
);

select extensions.ok(
  (
    select prosecdef
      and coalesce(proconfig, array[]::text[]) @> array['search_path=""']
    from pg_proc
    where oid = 'app_private.can_upload_project_file(text,text)'::regprocedure
  ),
  'storage upload helper is security definer with an empty search_path'
);

select extensions.ok(
  not has_function_privilege(
    'anon',
    'app_private.can_upload_project_file(text,text)',
    'EXECUTE'
  )
  and has_function_privilege(
    'authenticated',
    'app_private.can_upload_project_file(text,text)',
    'EXECUTE'
  ),
  'storage authorization helper is executable only by authenticated clients'
);

select extensions.is(
  (
    select count(*)::integer
    from pg_policies
    where schemaname = 'public'
      and tablename = 'organizations'
      and policyname = 'organizations_update_owner_or_staff'
  ),
  1,
  'organization updates use the owner-or-staff defense-in-depth policy'
);

select extensions.is(
  (
    select count(*)::integer
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname in (
        'project_files_insert_authorized',
        'project_files_select_authorized'
      )
  ),
  2,
  'project file Storage policies are installed'
);

set local role anon;

select extensions.lives_ok(
  $$select id, slug, name, description, version, published_at
    from public.service_catalog$$,
  'anon can read only the public catalog projection'
);

select extensions.throws_ok(
  $$select configuration from public.service_catalog$$,
  '42501',
  'permission denied for table service_catalog',
  'anon cannot read catalog configuration'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

select extensions.throws_ok(
  $$select internal_note from public.quote_versions$$,
  '42501',
  'permission denied for table quote_versions',
  'authenticated cannot read private quote columns directly'
);

select * from extensions.finish();
rollback;
