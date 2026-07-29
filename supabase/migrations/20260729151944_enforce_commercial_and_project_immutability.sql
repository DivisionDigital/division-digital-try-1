-- Publishing is a state-only operation. Content must be finalized while the
-- record is still in draft and cannot change in the publishing statement.
create or replace function app_private.protect_version_content()
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
        message = format(
          'Published history in %I.%I cannot be deleted',
          tg_table_schema,
          tg_table_name
        );
    end if;
    return old;
  end if;

  if old.status <> 'draft' or new.status <> 'draft' then
    old_content := to_jsonb(old)
      - array['status', 'published_at', 'published_by', 'accepted_at', 'accepted_by'];
    new_content := to_jsonb(new)
      - array['status', 'published_at', 'published_by', 'accepted_at', 'accepted_by'];

    if old_content is distinct from new_content then
      raise exception using
        errcode = '55000',
        message = format(
          'Published content in %I.%I is immutable',
          tg_table_schema,
          tg_table_name
        );
    end if;
  end if;

  return new;
end;
$$;

create function app_private.protect_quote_version_item()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  parent_status text;
begin
  if tg_op = 'UPDATE'
     and new.quote_version_id is distinct from old.quote_version_id then
    raise exception using
      errcode = '55000',
      message = 'quote_version_id is immutable';
  end if;

  select version_record.status
  into parent_status
  from public.quote_versions version_record
  where version_record.id = case
    when tg_op = 'INSERT' then new.quote_version_id
    else old.quote_version_id
  end;

  if parent_status is distinct from 'draft' then
    raise exception using
      errcode = '55000',
      message = 'Quote version items are immutable outside draft';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create function app_private.protect_order_snapshot()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.organization_id is distinct from old.organization_id
     or new.quote_version_id is distinct from old.quote_version_id
     or new.payment_requirement is distinct from old.payment_requirement
     or new.currency is distinct from old.currency
     or new.subtotal_amount is distinct from old.subtotal_amount
     or new.discount_amount is distinct from old.discount_amount
     or new.tax_amount is distinct from old.tax_amount
     or new.total_amount is distinct from old.total_amount then
    raise exception using
      errcode = '55000',
      message = 'Order commercial snapshot is immutable';
  end if;
  return new;
end;
$$;

create function app_private.protect_service_instance_snapshot()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.organization_id is distinct from old.organization_id
     or new.order_id is distinct from old.order_id
     or new.order_item_id is distinct from old.order_item_id
     or new.unit_number is distinct from old.unit_number
     or new.service_catalog_id is distinct from old.service_catalog_id
     or new.catalog_version is distinct from old.catalog_version
     or new.workflow_version_id is distinct from old.workflow_version_id
     or new.service_snapshot is distinct from old.service_snapshot then
    raise exception using
      errcode = '55000',
      message = 'Service instance identity and snapshot are immutable';
  end if;
  return new;
end;
$$;

create function app_private.protect_project_form_assignment()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.service_instance_id is distinct from old.service_instance_id
     or new.organization_id is distinct from old.organization_id
     or new.form_template_id is distinct from old.form_template_id
     or new.form_version_id is distinct from old.form_version_id
     or new.required is distinct from old.required
     or new.stage is distinct from old.stage
     or new.sort_order is distinct from old.sort_order then
    raise exception using
      errcode = '55000',
      message = 'Project form assignment is immutable';
  end if;
  return new;
end;
$$;

create function app_private.protect_payment_identity()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.order_id is distinct from old.order_id
     or new.organization_id is distinct from old.organization_id
     or new.provider is distinct from old.provider
     or new.idempotency_key is distinct from old.idempotency_key
     or new.amount is distinct from old.amount
     or new.currency is distinct from old.currency
     or (
       old.external_reference is not null
       and new.external_reference is distinct from old.external_reference
     ) then
    raise exception using
      errcode = '55000',
      message = 'Payment identity and amount are immutable';
  end if;
  return new;
end;
$$;

create function app_private.protect_webhook_payload()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.provider is distinct from old.provider
     or new.external_event_id is distinct from old.external_event_id
     or new.payload_hash is distinct from old.payload_hash
     or new.sanitized_payload is distinct from old.sanitized_payload
     or new.received_at is distinct from old.received_at then
    raise exception using
      errcode = '55000',
      message = 'Webhook identity and sanitized payload are immutable';
  end if;
  return new;
end;
$$;

create function app_private.protect_outbox_payload()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.organization_id is distinct from old.organization_id
     or new.aggregate_type is distinct from old.aggregate_type
     or new.aggregate_id is distinct from old.aggregate_id
     or new.event_type is distinct from old.event_type
     or new.payload is distinct from old.payload
     or new.created_at is distinct from old.created_at then
    raise exception using
      errcode = '55000',
      message = 'Outbox event identity and payload are immutable';
  end if;
  return new;
end;
$$;

create function app_private.protect_file_identity()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.organization_id is distinct from old.organization_id
     or new.service_instance_id is distinct from old.service_instance_id
     or new.project_form_id is distinct from old.project_form_id
     or new.created_by is distinct from old.created_by
     or new.purpose is distinct from old.purpose
     or new.storage_bucket is distinct from old.storage_bucket
     or new.storage_path is distinct from old.storage_path
     or new.mime_type is distinct from old.mime_type then
    raise exception using
      errcode = '55000',
      message = 'File ownership and storage identity are immutable';
  end if;
  return new;
end;
$$;

create trigger quote_version_items_protect_content
  before insert or update or delete on public.quote_version_items
  for each row execute function app_private.protect_quote_version_item();

create trigger order_items_append_only
  before update or delete on public.order_items
  for each row execute function app_private.prevent_append_only_changes();

create trigger orders_protect_snapshot
  before update on public.orders
  for each row execute function app_private.protect_order_snapshot();

create trigger service_instances_protect_snapshot
  before update on public.service_instances
  for each row execute function app_private.protect_service_instance_snapshot();

create trigger project_forms_protect_assignment
  before update on public.project_forms
  for each row execute function app_private.protect_project_form_assignment();

create trigger payments_protect_identity
  before update on public.payments
  for each row execute function app_private.protect_payment_identity();

create trigger webhook_events_protect_payload
  before update on public.webhook_events
  for each row execute function app_private.protect_webhook_payload();

create trigger outbox_events_protect_payload
  before update on public.outbox_events
  for each row execute function app_private.protect_outbox_payload();

create trigger files_protect_identity
  before update on public.files
  for each row execute function app_private.protect_file_identity();

revoke execute on function app_private.protect_quote_version_item()
  from public, anon, authenticated, service_role;
revoke execute on function app_private.protect_order_snapshot()
  from public, anon, authenticated, service_role;
revoke execute on function app_private.protect_service_instance_snapshot()
  from public, anon, authenticated, service_role;
revoke execute on function app_private.protect_project_form_assignment()
  from public, anon, authenticated, service_role;
revoke execute on function app_private.protect_payment_identity()
  from public, anon, authenticated, service_role;
revoke execute on function app_private.protect_webhook_payload()
  from public, anon, authenticated, service_role;
revoke execute on function app_private.protect_outbox_payload()
  from public, anon, authenticated, service_role;
revoke execute on function app_private.protect_file_identity()
  from public, anon, authenticated, service_role;
