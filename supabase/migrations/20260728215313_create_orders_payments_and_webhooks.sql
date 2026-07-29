create table public.orders (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  quote_version_id uuid not null unique references public.quote_versions (id) on delete restrict,
  status text not null default 'pending_confirmation',
  payment_requirement text not null default 'none',
  currency text not null default 'COP',
  subtotal_amount numeric(12,2) not null default 0,
  discount_amount numeric(12,2) not null default 0,
  tax_amount numeric(12,2) not null default 0,
  total_amount numeric(12,2) not null default 0,
  confirmed_by uuid references auth.users (id) on delete set null,
  activated_by uuid references auth.users (id) on delete set null,
  cancelled_by uuid references auth.users (id) on delete set null,
  confirmation_reason text,
  activation_reason text,
  cancellation_reason text,
  confirmed_at timestamptz,
  activated_at timestamptz,
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint orders_status_check check (
    status in ('pending_confirmation', 'confirmed', 'active', 'cancelled')
  ),
  constraint orders_payment_requirement_check check (
    payment_requirement in ('none', 'manual', 'required')
  ),
  constraint orders_currency_format check (currency ~ '^[A-Z]{3}$'),
  constraint orders_amounts_nonnegative check (
    subtotal_amount >= 0
    and discount_amount >= 0
    and tax_amount >= 0
    and total_amount >= 0
  ),
  constraint orders_discount_limit check (discount_amount <= subtotal_amount),
  constraint orders_total_check check (
    total_amount = subtotal_amount - discount_amount + tax_amount
  ),
  constraint orders_confirmed_at_check check (
    status not in ('confirmed', 'active')
    or (confirmed_at is not null and confirmed_by is not null)
  ),
  constraint orders_activated_at_check check (
    status <> 'active'
    or (activated_at is not null and activated_by is not null)
  ),
  constraint orders_cancelled_at_check check (
    status <> 'cancelled'
    or (cancelled_at is not null and cancelled_by is not null)
  ),
  unique (id, organization_id)
);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null,
  organization_id uuid not null,
  source_quote_version_item_id uuid not null unique
    references public.quote_version_items (id) on delete restrict,
  line_number integer not null,
  service_catalog_id uuid not null references public.service_catalog (id) on delete restrict,
  service_catalog_version integer not null,
  quantity integer not null,
  service_snapshot jsonb not null,
  scope_snapshot text not null default '',
  unit_amount numeric(12,2) not null default 0,
  discount_amount numeric(12,2) not null default 0,
  tax_amount numeric(12,2) not null default 0,
  total_amount numeric(12,2) not null default 0,
  created_at timestamptz not null default now(),
  constraint order_items_order_fk foreign key (order_id, organization_id)
    references public.orders (id, organization_id) on delete restrict,
  constraint order_items_line_positive check (line_number > 0),
  constraint order_items_catalog_version_positive check (service_catalog_version > 0),
  constraint order_items_quantity_check check (quantity between 1 and 99),
  constraint order_items_snapshot_object check (jsonb_typeof(service_snapshot) = 'object'),
  constraint order_items_scope_length check (char_length(scope_snapshot) <= 10000),
  constraint order_items_amounts_nonnegative check (
    unit_amount >= 0
    and discount_amount >= 0
    and tax_amount >= 0
    and total_amount >= 0
  ),
  constraint order_items_discount_limit check (discount_amount <= unit_amount * quantity),
  constraint order_items_total_check check (
    total_amount = unit_amount * quantity - discount_amount + tax_amount
  ),
  unique (order_id, line_number),
  unique (id, organization_id)
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null,
  organization_id uuid not null,
  provider text not null,
  external_reference text,
  idempotency_key text not null,
  status text not null default 'pending',
  amount numeric(12,2) not null,
  currency text not null default 'COP',
  provider_metadata jsonb not null default '{}'::jsonb,
  failure_code text,
  confirmed_at timestamptz,
  failed_at timestamptz,
  refunded_at timestamptz,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint payments_order_fk foreign key (order_id, organization_id)
    references public.orders (id, organization_id) on delete restrict,
  constraint payments_provider_format check (provider ~ '^[a-z][a-z0-9_-]{1,63}$'),
  constraint payments_external_reference_length check (
    external_reference is null or char_length(external_reference) between 1 and 200
  ),
  constraint payments_idempotency_length check (
    char_length(idempotency_key) between 8 and 128
  ),
  constraint payments_status_check check (
    status in (
      'pending', 'processing', 'confirmed', 'failed',
      'cancelled', 'refunded', 'chargeback'
    )
  ),
  constraint payments_amount_positive check (amount > 0),
  constraint payments_currency_format check (currency ~ '^[A-Z]{3}$'),
  constraint payments_provider_metadata_object check (
    jsonb_typeof(provider_metadata) = 'object'
  ),
  constraint payments_confirmed_at_check check (
    status not in ('confirmed', 'refunded', 'chargeback') or confirmed_at is not null
  ),
  unique (provider, idempotency_key)
);

create unique index payments_provider_reference_unique
  on public.payments (provider, external_reference)
  where external_reference is not null;

create table public.webhook_events (
  id uuid primary key default gen_random_uuid(),
  provider text not null,
  external_event_id text not null,
  payment_id uuid references public.payments (id) on delete set null,
  order_id uuid references public.orders (id) on delete set null,
  status text not null default 'received',
  payload_hash text not null,
  sanitized_payload jsonb not null default '{}'::jsonb,
  attempt_count integer not null default 0,
  next_attempt_at timestamptz,
  processed_at timestamptz,
  last_error_code text,
  received_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint webhook_events_provider_format check (provider ~ '^[a-z][a-z0-9_-]{1,63}$'),
  constraint webhook_events_external_id_length check (
    char_length(external_event_id) between 1 and 200
  ),
  constraint webhook_events_status_check check (
    status in ('received', 'processing', 'processed', 'failed', 'ignored')
  ),
  constraint webhook_events_payload_hash_format check (
    payload_hash ~ '^[a-f0-9]{64}$'
  ),
  constraint webhook_events_payload_object check (
    jsonb_typeof(sanitized_payload) = 'object'
  ),
  constraint webhook_events_attempt_count_check check (attempt_count >= 0),
  unique (provider, external_event_id)
);

comment on table public.webhook_events is
  'Eventos externos sanitizados; nunca almacena firmas, secretos ni datos completos de pago.';
