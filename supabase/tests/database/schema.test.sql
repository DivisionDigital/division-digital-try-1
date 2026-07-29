begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(8);

select extensions.has_table('public', 'organizations', 'organizations exists');
select extensions.has_table('public', 'staff_members', 'staff authority is separate');
select extensions.has_table('public', 'service_instances', 'project persistence exists');
select extensions.has_table('public', 'form_response_revisions', 'form revisions exist');
select extensions.has_table('public', 'outbox_events', 'outbox exists');

select extensions.ok(
  (
    select relrowsecurity
    from pg_class
    where oid = 'public.organizations'::regclass
  ),
  'organizations has RLS'
);

select extensions.ok(
  not has_table_privilege('authenticated', 'public.orders', 'UPDATE'),
  'authenticated cannot mutate orders directly'
);

select extensions.ok(
  not has_table_privilege('anon', 'public.profiles', 'SELECT'),
  'anon cannot read profiles'
);

select * from extensions.finish();
rollback;
