begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(17);

insert into auth.users (id, email, raw_user_meta_data)
values
  ('20000000-0000-4000-8000-000000000001', 'client-a@example.test', '{}'::jsonb),
  ('20000000-0000-4000-8000-000000000002', 'client-b@example.test', '{}'::jsonb),
  ('20000000-0000-4000-8000-000000000003', 'team@example.test', '{}'::jsonb),
  ('20000000-0000-4000-8000-000000000004', 'admin@example.test', '{}'::jsonb);

insert into public.organizations (id, name)
values
  ('30000000-0000-4000-8000-000000000001', 'Organization A'),
  ('30000000-0000-4000-8000-000000000002', 'Organization B');

insert into public.organization_members (organization_id, user_id, role, status, joined_at)
values
  ('30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'owner', 'active', now()),
  ('30000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000002', 'owner', 'active', now());

insert into public.staff_members (user_id, role, status)
values
  ('20000000-0000-4000-8000-000000000003', 'team', 'active'),
  ('20000000-0000-4000-8000-000000000004', 'admin', 'active');

insert into public.quotes (id, organization_id, status, created_by, accepted_at)
values (
  '40000000-0000-4000-8000-000000000001',
  '30000000-0000-4000-8000-000000000001',
  'accepted',
  '20000000-0000-4000-8000-000000000001',
  now()
);

insert into public.quote_versions (
  id, quote_id, version, status, currency, subtotal_amount, total_amount,
  terms, created_by
)
values (
  '41000000-0000-4000-8000-000000000001',
  '40000000-0000-4000-8000-000000000001',
  1,
  'draft',
  'COP',
  100000,
  100000,
  'RLS fixture',
  '20000000-0000-4000-8000-000000000001'
);

insert into public.quote_version_items (
  id, quote_version_id, line_number, service_catalog_id,
  service_catalog_version, quantity, service_snapshot, unit_amount, total_amount
)
values (
  '42000000-0000-4000-8000-000000000001',
  '41000000-0000-4000-8000-000000000001',
  1,
  '10000000-0000-4000-8000-000000000001',
  1,
  1,
  '{"slug":"landing-page","name":"Landing Page"}'::jsonb,
  100000,
  100000
);

update public.quote_versions
set
  status = 'accepted',
  published_at = now(),
  accepted_by = '20000000-0000-4000-8000-000000000001',
  accepted_at = now()
where id = '41000000-0000-4000-8000-000000000001';

insert into public.orders (
  id, organization_id, quote_version_id, status, currency,
  subtotal_amount, total_amount, confirmed_by, activated_by,
  confirmed_at, activated_at
)
values (
  '43000000-0000-4000-8000-000000000001',
  '30000000-0000-4000-8000-000000000001',
  '41000000-0000-4000-8000-000000000001',
  'active',
  'COP',
  100000,
  100000,
  '20000000-0000-4000-8000-000000000004',
  '20000000-0000-4000-8000-000000000004',
  now(),
  now()
);

insert into public.order_items (
  id, order_id, organization_id, source_quote_version_item_id,
  line_number, service_catalog_id, service_catalog_version, quantity,
  service_snapshot, unit_amount, total_amount
)
values (
  '44000000-0000-4000-8000-000000000001',
  '43000000-0000-4000-8000-000000000001',
  '30000000-0000-4000-8000-000000000001',
  '42000000-0000-4000-8000-000000000001',
  1,
  '10000000-0000-4000-8000-000000000001',
  1,
  1,
  '{"slug":"landing-page","name":"Landing Page"}'::jsonb,
  100000,
  100000
);

insert into public.service_instances (
  id, organization_id, order_id, order_item_id, unit_number,
  service_catalog_id, catalog_version, workflow_version_id,
  service_snapshot, status_code
)
values (
  '45000000-0000-4000-8000-000000000001',
  '30000000-0000-4000-8000-000000000001',
  '43000000-0000-4000-8000-000000000001',
  '44000000-0000-4000-8000-000000000001',
  1,
  '10000000-0000-4000-8000-000000000001',
  1,
  '10000000-0000-4000-8000-000000000101',
  '{"slug":"landing-page","name":"Landing Page"}'::jsonb,
  'pending'
);

insert into public.files (
  id, organization_id, service_instance_id, created_by, purpose,
  original_name, storage_path, mime_type, status, visibility,
  upload_expires_at
)
values (
  '49000000-0000-4000-8000-000000000001',
  '30000000-0000-4000-8000-000000000001',
  '45000000-0000-4000-8000-000000000001',
  '20000000-0000-4000-8000-000000000001',
  'client_brief',
  'brief.pdf',
  '30000000-0000-4000-8000-000000000001/45000000-0000-4000-8000-000000000001/49000000-0000-4000-8000-000000000001',
  'application/pdf',
  'pending_upload',
  'client',
  now() + interval '15 minutes'
);

-- Private Data API grants are intentionally absent in production. Grant the
-- minimum read scope inside this transaction only so the RLS policies can be
-- regression-tested independently; rollback removes these grants.
grant select on public.organizations, public.service_instances
  to authenticated;

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"20000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

select extensions.is(
  (select count(*)::integer from public.organizations),
  1,
  'client A sees one organization'
);

select extensions.is(
  (
    select count(*)::integer
    from public.organizations
    where id = '30000000-0000-4000-8000-000000000002'
  ),
  0,
  'client A cannot see organization B'
);

select extensions.ok(
  not app_private.is_staff(array['team', 'admin']::text[]),
  'client is not staff'
);

select extensions.ok(
  app_private.is_org_owner('30000000-0000-4000-8000-000000000001'),
  'organization owner is recognized'
);

select extensions.ok(
  not app_private.is_org_owner('30000000-0000-4000-8000-000000000002'),
  'organization owner does not gain authority in another tenant'
);

select extensions.is(
  (select count(*)::integer from public.service_instances),
  1,
  'client A sees its project'
);

select extensions.lives_ok(
  $$insert into storage.objects (bucket_id, name, owner_id)
    values (
      'project-files',
      '30000000-0000-4000-8000-000000000001/45000000-0000-4000-8000-000000000001/49000000-0000-4000-8000-000000000001',
      '20000000-0000-4000-8000-000000000001'
    )$$,
  'client A can upload only to its pending authorized path'
);

select extensions.is(
  (
    select count(*)::integer
    from storage.objects
    where bucket_id = 'project-files'
  ),
  1,
  'uploader can read its own non-expired pending object'
);

select extensions.throws_ok(
  $$insert into storage.objects (bucket_id, name, owner_id)
    values (
      'project-files',
      '30000000-0000-4000-8000-000000000002/45000000-0000-4000-8000-000000000099/49000000-0000-4000-8000-000000000099',
      '20000000-0000-4000-8000-000000000001'
    )$$,
  '42501',
  'new row violates row-level security policy for table "objects"',
  'client A cannot upload without authorized file metadata'
);

reset role;

update public.files
set upload_expires_at = now() - interval '1 minute'
where id = '49000000-0000-4000-8000-000000000001';

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"20000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

select extensions.is(
  (
    select count(*)::integer
    from storage.objects
    where bucket_id = 'project-files'
  ),
  0,
  'expired pending upload is no longer readable'
);

reset role;

update public.files
set
  status = 'available',
  size_bytes = 1024,
  sha256 = repeat('a', 64),
  available_at = now()
where id = '49000000-0000-4000-8000-000000000001';

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"20000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

select extensions.is(
  (
    select count(*)::integer
    from storage.objects
    where bucket_id = 'project-files'
  ),
  1,
  'client A can read its available storage object'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"20000000-0000-4000-8000-000000000002","role":"authenticated"}',
  true
);

select extensions.is(
  (
    select count(*)::integer
    from storage.objects
    where bucket_id = 'project-files'
  ),
  0,
  'client B cannot read client A storage objects'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"20000000-0000-4000-8000-000000000003","role":"authenticated"}',
  true
);

select extensions.is(
  (select count(*)::integer from public.organizations),
  2,
  'team sees all business organizations'
);

select extensions.ok(
  app_private.is_staff(array['team', 'admin']::text[]),
  'team has staff scope'
);

select extensions.ok(
  not app_private.is_admin(),
  'team cannot activate as admin'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"20000000-0000-4000-8000-000000000004","role":"authenticated"}',
  true
);

select extensions.ok(
  app_private.is_admin(),
  'admin has activate-project authority'
);

select extensions.is(
  (select count(*)::integer from public.organizations),
  2,
  'admin sees all business organizations'
);

select * from extensions.finish();
rollback;
