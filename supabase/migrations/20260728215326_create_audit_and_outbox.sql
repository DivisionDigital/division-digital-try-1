create table public.audit_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations (id) on delete restrict,
  actor_user_id uuid references auth.users (id) on delete set null,
  actor_type text not null default 'user',
  action text not null,
  resource_type text not null,
  resource_id uuid,
  result text not null,
  correlation_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint audit_events_actor_type_check check (actor_type in ('user', 'system', 'webhook')),
  constraint audit_events_action_format check (action ~ '^[a-z][a-z0-9_.]{1,127}$'),
  constraint audit_events_resource_type_format check (
    resource_type ~ '^[a-z][a-z0-9_]{1,63}$'
  ),
  constraint audit_events_result_check check (result in ('success', 'failure', 'denied')),
  constraint audit_events_metadata_object check (jsonb_typeof(metadata) = 'object')
);

create table public.outbox_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations (id) on delete restrict,
  aggregate_type text not null,
  aggregate_id uuid not null,
  event_type text not null,
  payload jsonb not null,
  status text not null default 'pending',
  attempt_count integer not null default 0,
  available_at timestamptz not null default now(),
  locked_at timestamptz,
  locked_by text,
  published_at timestamptz,
  last_error_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint outbox_events_aggregate_type_format check (
    aggregate_type ~ '^[a-z][a-z0-9_]{1,63}$'
  ),
  constraint outbox_events_event_type_format check (
    event_type ~ '^[a-z][a-z0-9_.]{1,127}$'
  ),
  constraint outbox_events_payload_object check (jsonb_typeof(payload) = 'object'),
  constraint outbox_events_status_check check (
    status in ('pending', 'processing', 'published', 'failed', 'dead_letter')
  ),
  constraint outbox_events_attempt_count_check check (attempt_count >= 0),
  constraint outbox_events_published_at_check check (
    status <> 'published' or published_at is not null
  )
);

comment on table public.audit_events is
  'Auditoría append-only sin contraseñas, tokens, firmas ni documentos completos.';
comment on table public.outbox_events is
  'Efectos externos reintentables; su publicación ocurre fuera de la transacción de negocio.';
