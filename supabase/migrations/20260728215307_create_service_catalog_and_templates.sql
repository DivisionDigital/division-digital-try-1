create table public.service_catalog (
  id uuid primary key default gen_random_uuid(),
  slug text not null,
  name text not null,
  description text not null default '',
  status text not null default 'draft',
  visibility text not null default 'public',
  configuration jsonb not null default '{}'::jsonb,
  version integer not null default 1,
  created_by uuid references auth.users (id) on delete set null,
  published_by uuid references auth.users (id) on delete set null,
  published_at timestamptz,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint service_catalog_slug_format check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  constraint service_catalog_slug_length check (char_length(slug) between 3 and 80),
  constraint service_catalog_name_length check (char_length(name) between 2 and 120),
  constraint service_catalog_description_length check (char_length(description) <= 4000),
  constraint service_catalog_status_check check (status in ('draft', 'published', 'archived')),
  constraint service_catalog_visibility_check check (visibility in ('public', 'internal')),
  constraint service_catalog_configuration_object check (jsonb_typeof(configuration) = 'object'),
  constraint service_catalog_version_positive check (version > 0),
  constraint service_catalog_published_at_check check (
    status <> 'published' or published_at is not null
  ),
  constraint service_catalog_archived_at_check check (
    status <> 'archived' or archived_at is not null
  ),
  unique (slug),
  unique (id, version)
);

create table public.service_workflow_versions (
  id uuid primary key default gen_random_uuid(),
  service_catalog_id uuid not null references public.service_catalog (id) on delete restrict,
  version integer not null,
  status text not null default 'draft',
  initial_status_code text not null,
  definition jsonb not null,
  created_by uuid references auth.users (id) on delete set null,
  published_by uuid references auth.users (id) on delete set null,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  constraint service_workflow_versions_version_positive check (version > 0),
  constraint service_workflow_versions_status_check check (
    status in ('draft', 'published', 'retired')
  ),
  constraint service_workflow_versions_initial_code_format check (
    initial_status_code ~ '^[a-z][a-z0-9_]{1,63}$'
  ),
  constraint service_workflow_versions_definition_object check (
    jsonb_typeof(definition) = 'object'
  ),
  constraint service_workflow_versions_published_at_check check (
    status <> 'published' or published_at is not null
  ),
  unique (service_catalog_id, version),
  unique (id, service_catalog_id)
);

create table public.form_templates (
  id uuid primary key default gen_random_uuid(),
  service_catalog_id uuid not null references public.service_catalog (id) on delete restrict,
  key text not null,
  title text not null,
  description text not null default '',
  stage text not null default 'onboarding',
  required boolean not null default true,
  sort_order integer not null default 0,
  status text not null default 'active',
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  constraint form_templates_key_format check (key ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  constraint form_templates_key_length check (char_length(key) between 2 and 80),
  constraint form_templates_title_length check (char_length(title) between 2 and 160),
  constraint form_templates_description_length check (char_length(description) <= 2000),
  constraint form_templates_stage_format check (stage ~ '^[a-z][a-z0-9_]{1,63}$'),
  constraint form_templates_sort_order_nonnegative check (sort_order >= 0),
  constraint form_templates_status_check check (status in ('active', 'archived')),
  constraint form_templates_archived_at_check check (
    status <> 'archived' or archived_at is not null
  ),
  unique (service_catalog_id, key),
  unique (id, service_catalog_id)
);

create table public.form_versions (
  id uuid primary key default gen_random_uuid(),
  form_template_id uuid not null references public.form_templates (id) on delete restrict,
  version integer not null,
  status text not null default 'draft',
  definition jsonb not null,
  validation_schema jsonb,
  created_by uuid references auth.users (id) on delete set null,
  published_by uuid references auth.users (id) on delete set null,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  constraint form_versions_version_positive check (version > 0),
  constraint form_versions_status_check check (status in ('draft', 'published', 'retired')),
  constraint form_versions_definition_object check (jsonb_typeof(definition) = 'object'),
  constraint form_versions_validation_schema_object check (
    validation_schema is null or jsonb_typeof(validation_schema) = 'object'
  ),
  constraint form_versions_published_at_check check (
    status <> 'published' or published_at is not null
  ),
  unique (form_template_id, version),
  unique (id, form_template_id)
);

create table public.milestone_templates (
  id uuid primary key default gen_random_uuid(),
  service_catalog_id uuid not null references public.service_catalog (id) on delete restrict,
  key text not null,
  title text not null,
  description text not null default '',
  sort_order integer not null default 0,
  due_offset_days integer,
  visible_to_client boolean not null default true,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint milestone_templates_key_format check (key ~ '^[a-z][a-z0-9_]{1,63}$'),
  constraint milestone_templates_title_length check (char_length(title) between 2 and 160),
  constraint milestone_templates_description_length check (char_length(description) <= 2000),
  constraint milestone_templates_sort_order_nonnegative check (sort_order >= 0),
  constraint milestone_templates_due_offset_check check (
    due_offset_days is null or due_offset_days between 0 and 3650
  ),
  constraint milestone_templates_status_check check (status in ('active', 'archived')),
  unique (service_catalog_id, key)
);

comment on table public.service_workflow_versions is
  'Máquinas de estado inmutables una vez publicadas.';
comment on table public.form_versions is
  'Definiciones JSONB inmutables una vez publicadas; no almacena respuestas.';
