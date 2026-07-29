create table public.quotes (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  status text not null default 'pending_review',
  requested_start_date date,
  customer_note text,
  idempotency_key text,
  created_by uuid not null references auth.users (id) on delete restrict,
  accepted_at timestamptz,
  rejected_at timestamptz,
  expired_at timestamptz,
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint quotes_status_check check (
    status in (
      'pending_review', 'draft', 'published', 'accepted',
      'rejected', 'expired', 'cancelled'
    )
  ),
  constraint quotes_customer_note_length check (
    customer_note is null or char_length(customer_note) <= 4000
  ),
  constraint quotes_idempotency_key_length check (
    idempotency_key is null or char_length(idempotency_key) between 8 and 128
  ),
  constraint quotes_accepted_at_check check (
    status <> 'accepted' or accepted_at is not null
  ),
  constraint quotes_rejected_at_check check (
    status <> 'rejected' or rejected_at is not null
  ),
  constraint quotes_expired_at_check check (
    status <> 'expired' or expired_at is not null
  ),
  constraint quotes_cancelled_at_check check (
    status <> 'cancelled' or cancelled_at is not null
  ),
  unique (id, organization_id)
);

create table public.quote_versions (
  id uuid primary key default gen_random_uuid(),
  quote_id uuid not null references public.quotes (id) on delete restrict,
  version integer not null,
  status text not null default 'draft',
  currency text not null default 'COP',
  subtotal_amount numeric(12,2) not null default 0,
  discount_amount numeric(12,2) not null default 0,
  tax_amount numeric(12,2) not null default 0,
  total_amount numeric(12,2) not null default 0,
  terms text not null default '',
  internal_note text,
  valid_until timestamptz,
  created_by uuid not null references auth.users (id) on delete restrict,
  published_by uuid references auth.users (id) on delete set null,
  accepted_by uuid references auth.users (id) on delete set null,
  published_at timestamptz,
  accepted_at timestamptz,
  created_at timestamptz not null default now(),
  constraint quote_versions_version_positive check (version > 0),
  constraint quote_versions_status_check check (
    status in ('draft', 'published', 'superseded', 'accepted', 'rejected', 'expired')
  ),
  constraint quote_versions_currency_format check (currency ~ '^[A-Z]{3}$'),
  constraint quote_versions_amounts_nonnegative check (
    subtotal_amount >= 0
    and discount_amount >= 0
    and tax_amount >= 0
    and total_amount >= 0
  ),
  constraint quote_versions_discount_limit check (discount_amount <= subtotal_amount),
  constraint quote_versions_total_check check (
    total_amount = subtotal_amount - discount_amount + tax_amount
  ),
  constraint quote_versions_terms_length check (char_length(terms) <= 10000),
  constraint quote_versions_internal_note_length check (
    internal_note is null or char_length(internal_note) <= 4000
  ),
  constraint quote_versions_published_at_check check (
    status not in ('published', 'superseded', 'accepted', 'rejected', 'expired')
    or published_at is not null
  ),
  constraint quote_versions_accepted_at_check check (
    status <> 'accepted' or (accepted_at is not null and accepted_by is not null)
  ),
  unique (quote_id, version)
);

create table public.quote_version_items (
  id uuid primary key default gen_random_uuid(),
  quote_version_id uuid not null references public.quote_versions (id) on delete restrict,
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
  constraint quote_version_items_line_positive check (line_number > 0),
  constraint quote_version_items_catalog_version_positive check (service_catalog_version > 0),
  constraint quote_version_items_quantity_check check (quantity between 1 and 99),
  constraint quote_version_items_snapshot_object check (jsonb_typeof(service_snapshot) = 'object'),
  constraint quote_version_items_scope_length check (char_length(scope_snapshot) <= 10000),
  constraint quote_version_items_amounts_nonnegative check (
    unit_amount >= 0
    and discount_amount >= 0
    and tax_amount >= 0
    and total_amount >= 0
  ),
  constraint quote_version_items_discount_limit check (
    discount_amount <= unit_amount * quantity
  ),
  constraint quote_version_items_total_check check (
    total_amount = unit_amount * quantity - discount_amount + tax_amount
  ),
  unique (quote_version_id, line_number)
);

create unique index quotes_creator_idempotency_unique
  on public.quotes (created_by, idempotency_key)
  where idempotency_key is not null;

comment on table public.quote_versions is
  'Snapshot comercial: su contenido queda inmutable al salir de draft.';
