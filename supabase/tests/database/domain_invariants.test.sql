begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(19);

insert into auth.users (id, email, raw_user_meta_data)
values ('20000000-0000-4000-8000-000000000010', 'domain-test@example.test', '{}'::jsonb);

insert into public.organizations (id, name)
values ('30000000-0000-4000-8000-000000000010', 'Domain Test Organization');

insert into public.quotes (id, organization_id, status, created_by, accepted_at)
values (
  '40000000-0000-4000-8000-000000000010',
  '30000000-0000-4000-8000-000000000010',
  'accepted',
  '20000000-0000-4000-8000-000000000010',
  now()
);

insert into public.quote_versions (
  id,
  quote_id,
  version,
  status,
  currency,
  subtotal_amount,
  total_amount,
  terms,
  created_by,
  created_at
)
values (
  '41000000-0000-4000-8000-000000000010',
  '40000000-0000-4000-8000-000000000010',
  1,
  'draft',
  'COP',
  100000,
  100000,
  'Test terms',
  '20000000-0000-4000-8000-000000000010',
  now()
);

insert into public.quote_version_items (
  id,
  quote_version_id,
  line_number,
  service_catalog_id,
  service_catalog_version,
  quantity,
  service_snapshot,
  unit_amount,
  total_amount
)
values (
  '42000000-0000-4000-8000-000000000010',
  '41000000-0000-4000-8000-000000000010',
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
  accepted_by = '20000000-0000-4000-8000-000000000010',
  accepted_at = now()
where id = '41000000-0000-4000-8000-000000000010';

insert into public.quote_versions (
  id, quote_id, version, status, currency, subtotal_amount,
  total_amount, terms, created_by
)
values (
  '41000000-0000-4000-8000-000000000011',
  '40000000-0000-4000-8000-000000000010',
  2,
  'draft',
  'COP',
  100000,
  100000,
  'Draft terms',
  '20000000-0000-4000-8000-000000000010'
);

insert into public.orders (
  id,
  organization_id,
  quote_version_id,
  status,
  currency,
  subtotal_amount,
  total_amount,
  confirmed_by,
  activated_by,
  confirmed_at,
  activated_at
)
values (
  '43000000-0000-4000-8000-000000000010',
  '30000000-0000-4000-8000-000000000010',
  '41000000-0000-4000-8000-000000000010',
  'active',
  'COP',
  100000,
  100000,
  '20000000-0000-4000-8000-000000000010',
  '20000000-0000-4000-8000-000000000010',
  now(),
  now()
);

insert into public.order_items (
  id,
  order_id,
  organization_id,
  source_quote_version_item_id,
  line_number,
  service_catalog_id,
  service_catalog_version,
  quantity,
  service_snapshot,
  unit_amount,
  total_amount
)
values (
  '44000000-0000-4000-8000-000000000010',
  '43000000-0000-4000-8000-000000000010',
  '30000000-0000-4000-8000-000000000010',
  '42000000-0000-4000-8000-000000000010',
  1,
  '10000000-0000-4000-8000-000000000001',
  1,
  1,
  '{"slug":"landing-page","name":"Landing Page"}'::jsonb,
  100000,
  100000
);

insert into public.service_instances (
  id,
  organization_id,
  order_id,
  order_item_id,
  unit_number,
  service_catalog_id,
  catalog_version,
  workflow_version_id,
  service_snapshot,
  status_code
)
values (
  '45000000-0000-4000-8000-000000000010',
  '30000000-0000-4000-8000-000000000010',
  '43000000-0000-4000-8000-000000000010',
  '44000000-0000-4000-8000-000000000010',
  1,
  '10000000-0000-4000-8000-000000000001',
  1,
  '10000000-0000-4000-8000-000000000101',
  '{"slug":"landing-page","name":"Landing Page"}'::jsonb,
  'pending'
);

insert into public.project_events (
  id,
  service_instance_id,
  organization_id,
  event_type,
  to_status_code,
  title
)
values (
  '46000000-0000-4000-8000-000000000010',
  '45000000-0000-4000-8000-000000000010',
  '30000000-0000-4000-8000-000000000010',
  'project.created',
  'pending',
  'Project created'
);

insert into public.project_forms (
  id,
  service_instance_id,
  organization_id,
  form_template_id,
  form_version_id,
  status,
  opened_at
)
values (
  '47000000-0000-4000-8000-000000000010',
  '45000000-0000-4000-8000-000000000010',
  '30000000-0000-4000-8000-000000000010',
  '10000000-0000-4000-8000-000000000201',
  '10000000-0000-4000-8000-000000000301',
  'open',
  now()
);

insert into public.form_response_revisions (
  id,
  project_form_id,
  organization_id,
  revision,
  answers,
  created_by
)
values (
  '48000000-0000-4000-8000-000000000010',
  '47000000-0000-4000-8000-000000000010',
  '30000000-0000-4000-8000-000000000010',
  1,
  '{"objective":"test"}'::jsonb,
  '20000000-0000-4000-8000-000000000010'
);

insert into public.payments (
  id, order_id, organization_id, provider, idempotency_key,
  status, amount, currency
)
values (
  '4a000000-0000-4000-8000-000000000010',
  '43000000-0000-4000-8000-000000000010',
  '30000000-0000-4000-8000-000000000010',
  'manual',
  'payment-test-000010',
  'pending',
  100000,
  'COP'
);

insert into public.webhook_events (
  id, provider, external_event_id, payment_id, order_id,
  status, payload_hash, sanitized_payload
)
values (
  '4b000000-0000-4000-8000-000000000010',
  'manual',
  'event-test-000010',
  '4a000000-0000-4000-8000-000000000010',
  '43000000-0000-4000-8000-000000000010',
  'received',
  repeat('b', 64),
  '{"event":"payment.pending"}'::jsonb
);

insert into public.outbox_events (
  id, organization_id, aggregate_type, aggregate_id, event_type, payload
)
values (
  '4c000000-0000-4000-8000-000000000010',
  '30000000-0000-4000-8000-000000000010',
  'order',
  '43000000-0000-4000-8000-000000000010',
  'order.created',
  '{"order_id":"43000000-0000-4000-8000-000000000010"}'::jsonb
);

insert into public.files (
  id, organization_id, service_instance_id, created_by, purpose,
  original_name, storage_path, mime_type, status, visibility,
  upload_expires_at
)
values (
  '4d000000-0000-4000-8000-000000000010',
  '30000000-0000-4000-8000-000000000010',
  '45000000-0000-4000-8000-000000000010',
  '20000000-0000-4000-8000-000000000010',
  'client_brief',
  'brief.pdf',
  '30000000-0000-4000-8000-000000000010/45000000-0000-4000-8000-000000000010/4d000000-0000-4000-8000-000000000010',
  'application/pdf',
  'pending_upload',
  'client',
  now() + interval '15 minutes'
);

select extensions.throws_ok(
  $$update public.service_workflow_versions
    set definition = '{"states":[]}'::jsonb
    where id = '10000000-0000-4000-8000-000000000101'$$,
  '55000',
  'Published content in public.service_workflow_versions is immutable',
  'published workflow content is immutable'
);

select extensions.throws_ok(
  $$update public.quote_versions
    set terms = 'changed'
    where id = '41000000-0000-4000-8000-000000000010'$$,
  '55000',
  'Published content in public.quote_versions is immutable',
  'accepted quote version content is immutable'
);

select extensions.throws_ok(
  $$update public.quote_versions
    set status = 'published', published_at = now(), terms = 'tampered on publish'
    where id = '41000000-0000-4000-8000-000000000011'$$,
  '55000',
  'Published content in public.quote_versions is immutable',
  'publishing cannot mutate version content in the same statement'
);

select extensions.throws_ok(
  $$update public.quote_version_items
    set unit_amount = 90000, total_amount = 90000
    where id = '42000000-0000-4000-8000-000000000010'$$,
  '55000',
  'Quote version items are immutable outside draft',
  'accepted quote version items are immutable'
);

select extensions.throws_ok(
  $$update public.order_items
    set scope_snapshot = 'changed'
    where id = '44000000-0000-4000-8000-000000000010'$$,
  '55000',
  'public.order_items is append-only',
  'order items are append-only'
);

select extensions.throws_ok(
  $$update public.orders
    set total_amount = 90000, subtotal_amount = 90000
    where id = '43000000-0000-4000-8000-000000000010'$$,
  '55000',
  'Order commercial snapshot is immutable',
  'order commercial snapshot is immutable'
);

select extensions.lives_ok(
  $$update public.orders
    set activation_reason = 'manual confirmation'
    where id = '43000000-0000-4000-8000-000000000010'$$,
  'order operational metadata remains mutable'
);

select extensions.throws_ok(
  $$update public.service_instances
    set service_snapshot = '{"name":"tampered"}'::jsonb
    where id = '45000000-0000-4000-8000-000000000010'$$,
  '55000',
  'Service instance identity and snapshot are immutable',
  'service instance snapshot is immutable'
);

select extensions.lives_ok(
  $$update public.service_instances
    set status_code = 'awaiting_client_information', status_version = 2
    where id = '45000000-0000-4000-8000-000000000010'$$,
  'service instance operational state remains mutable'
);

select extensions.throws_ok(
  $$update public.project_forms
    set form_version_id = '10000000-0000-4000-8000-000000000302'
    where id = '47000000-0000-4000-8000-000000000010'$$,
  '55000',
  'Project form assignment is immutable',
  'project form version assignment is immutable'
);

select extensions.throws_ok(
  $$update public.payments
    set amount = 1
    where id = '4a000000-0000-4000-8000-000000000010'$$,
  '55000',
  'Payment identity and amount are immutable',
  'payment amount is immutable'
);

select extensions.lives_ok(
  $$update public.payments
    set status = 'processing'
    where id = '4a000000-0000-4000-8000-000000000010'$$,
  'payment processing state remains mutable'
);

select extensions.throws_ok(
  $$update public.webhook_events
    set sanitized_payload = '{}'::jsonb
    where id = '4b000000-0000-4000-8000-000000000010'$$,
  '55000',
  'Webhook identity and sanitized payload are immutable',
  'webhook sanitized payload is immutable'
);

select extensions.throws_ok(
  $$update public.outbox_events
    set payload = '{}'::jsonb
    where id = '4c000000-0000-4000-8000-000000000010'$$,
  '55000',
  'Outbox event identity and payload are immutable',
  'outbox payload is immutable'
);

select extensions.throws_ok(
  $$update public.files
    set storage_path = '30000000-0000-4000-8000-000000000010/45000000-0000-4000-8000-000000000010/4d000000-0000-4000-8000-000000000099'
    where id = '4d000000-0000-4000-8000-000000000010'$$,
  '55000',
  'File ownership and storage identity are immutable',
  'file storage path is immutable'
);

select extensions.throws_ok(
  $$update public.project_events
    set title = 'changed'
    where id = '46000000-0000-4000-8000-000000000010'$$,
  '55000',
  'public.project_events is append-only',
  'project events are append-only'
);

select extensions.throws_ok(
  $$update public.form_response_revisions
    set answers = '{}'::jsonb
    where id = '48000000-0000-4000-8000-000000000010'$$,
  '55000',
  'public.form_response_revisions is append-only',
  'form revisions are append-only'
);

select extensions.throws_ok(
  $$insert into public.service_instances (
      organization_id, order_id, order_item_id, unit_number,
      service_catalog_id, catalog_version, workflow_version_id,
      service_snapshot, status_code
    )
    values (
      '30000000-0000-4000-8000-000000000010',
      '43000000-0000-4000-8000-000000000010',
      '44000000-0000-4000-8000-000000000010',
      1,
      '10000000-0000-4000-8000-000000000001',
      1,
      '10000000-0000-4000-8000-000000000101',
      '{}'::jsonb,
      'pending'
    )$$,
  '23505',
  'duplicate key value violates unique constraint "service_instances_order_item_id_unit_number_key"',
  'order item and unit cannot create duplicate projects'
);

select extensions.throws_ok(
  $$insert into public.quote_version_items (
      quote_version_id, line_number, service_catalog_id,
      service_catalog_version, quantity, service_snapshot
    )
    values (
      '41000000-0000-4000-8000-000000000011',
      2,
      '10000000-0000-4000-8000-000000000001',
      1,
      0,
      '{}'::jsonb
    )$$,
  '23514',
  'new row for relation "quote_version_items" violates check constraint "quote_version_items_quantity_check"',
  'quantity must be positive'
);

select * from extensions.finish();
rollback;
