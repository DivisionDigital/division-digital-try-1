create table public.service_instances (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  order_id uuid not null,
  order_item_id uuid not null,
  unit_number integer not null,
  service_catalog_id uuid not null references public.service_catalog (id) on delete restrict,
  catalog_version integer not null,
  workflow_version_id uuid not null,
  service_snapshot jsonb not null,
  status_code text not null,
  status_version integer not null default 1,
  progress_percent numeric(5,2) not null default 0,
  assigned_staff_user_id uuid references public.staff_members (user_id) on delete set null,
  starts_at timestamptz,
  due_at timestamptz,
  completed_at timestamptz,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint service_instances_order_fk foreign key (order_id, organization_id)
    references public.orders (id, organization_id) on delete restrict,
  constraint service_instances_order_item_fk foreign key (order_item_id, organization_id)
    references public.order_items (id, organization_id) on delete restrict,
  constraint service_instances_workflow_service_fk
    foreign key (workflow_version_id, service_catalog_id)
    references public.service_workflow_versions (id, service_catalog_id) on delete restrict,
  constraint service_instances_unit_positive check (unit_number > 0),
  constraint service_instances_catalog_version_positive check (catalog_version > 0),
  constraint service_instances_snapshot_object check (jsonb_typeof(service_snapshot) = 'object'),
  constraint service_instances_status_code_format check (
    status_code ~ '^[a-z][a-z0-9_]{1,63}$'
  ),
  constraint service_instances_status_version_positive check (status_version > 0),
  constraint service_instances_progress_check check (
    progress_percent between 0 and 100
  ),
  constraint service_instances_dates_check check (
    due_at is null or starts_at is null or due_at >= starts_at
  ),
  unique (order_item_id, unit_number),
  unique (id, organization_id)
);

create table public.project_events (
  id uuid primary key default gen_random_uuid(),
  service_instance_id uuid not null,
  organization_id uuid not null,
  event_type text not null,
  from_status_code text,
  to_status_code text,
  visibility text not null default 'client',
  title text not null,
  message text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  actor_user_id uuid references auth.users (id) on delete set null,
  correlation_id uuid,
  created_at timestamptz not null default now(),
  constraint project_events_project_fk foreign key (service_instance_id, organization_id)
    references public.service_instances (id, organization_id) on delete restrict,
  constraint project_events_type_format check (event_type ~ '^[a-z][a-z0-9_.]{1,127}$'),
  constraint project_events_from_status_format check (
    from_status_code is null or from_status_code ~ '^[a-z][a-z0-9_]{1,63}$'
  ),
  constraint project_events_to_status_format check (
    to_status_code is null or to_status_code ~ '^[a-z][a-z0-9_]{1,63}$'
  ),
  constraint project_events_visibility_check check (visibility in ('client', 'internal')),
  constraint project_events_title_length check (char_length(title) between 1 and 200),
  constraint project_events_message_length check (char_length(message) <= 10000),
  constraint project_events_metadata_object check (jsonb_typeof(metadata) = 'object')
);

create table public.milestones (
  id uuid primary key default gen_random_uuid(),
  service_instance_id uuid not null,
  organization_id uuid not null,
  milestone_template_id uuid references public.milestone_templates (id) on delete set null,
  title text not null,
  description text not null default '',
  status text not null default 'pending',
  sort_order integer not null default 0,
  visible_to_client boolean not null default true,
  due_at timestamptz,
  completed_at timestamptz,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint milestones_project_fk foreign key (service_instance_id, organization_id)
    references public.service_instances (id, organization_id) on delete restrict,
  constraint milestones_title_length check (char_length(title) between 2 and 160),
  constraint milestones_description_length check (char_length(description) <= 4000),
  constraint milestones_status_check check (
    status in ('pending', 'in_progress', 'completed', 'cancelled', 'archived')
  ),
  constraint milestones_sort_order_nonnegative check (sort_order >= 0),
  constraint milestones_completed_at_check check (
    status <> 'completed' or completed_at is not null
  ),
  constraint milestones_archived_at_check check (
    status <> 'archived' or archived_at is not null
  ),
  unique (id, organization_id)
);

comment on table public.service_instances is
  'Persistencia del agregado Project; exactamente una fila por ítem y unidad contratada.';
