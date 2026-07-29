create table public.project_forms (
  id uuid primary key default gen_random_uuid(),
  service_instance_id uuid not null,
  organization_id uuid not null,
  form_template_id uuid not null references public.form_templates (id) on delete restrict,
  form_version_id uuid not null,
  status text not null default 'pending',
  required boolean not null default true,
  stage text not null default 'onboarding',
  sort_order integer not null default 0,
  opened_at timestamptz,
  submitted_at timestamptz,
  changes_requested_at timestamptz,
  locked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint project_forms_project_fk foreign key (service_instance_id, organization_id)
    references public.service_instances (id, organization_id) on delete restrict,
  constraint project_forms_version_template_fk foreign key (form_version_id, form_template_id)
    references public.form_versions (id, form_template_id) on delete restrict,
  constraint project_forms_status_check check (
    status in ('pending', 'open', 'submitted', 'changes_requested', 'locked')
  ),
  constraint project_forms_stage_format check (stage ~ '^[a-z][a-z0-9_]{1,63}$'),
  constraint project_forms_sort_order_nonnegative check (sort_order >= 0),
  constraint project_forms_opened_at_check check (
    status = 'pending' or opened_at is not null
  ),
  constraint project_forms_submitted_at_check check (
    status not in ('submitted', 'locked') or submitted_at is not null
  ),
  constraint project_forms_changes_requested_at_check check (
    status <> 'changes_requested' or changes_requested_at is not null
  ),
  constraint project_forms_locked_at_check check (
    status <> 'locked' or locked_at is not null
  ),
  unique (service_instance_id, form_template_id),
  unique (id, organization_id),
  unique (id, service_instance_id, organization_id)
);

create table public.form_response_revisions (
  id uuid primary key default gen_random_uuid(),
  project_form_id uuid not null,
  organization_id uuid not null,
  revision integer not null,
  answers jsonb not null,
  status text not null default 'draft',
  idempotency_key text,
  created_by uuid not null references auth.users (id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint form_response_revisions_form_fk foreign key (project_form_id, organization_id)
    references public.project_forms (id, organization_id) on delete restrict,
  constraint form_response_revisions_revision_positive check (revision > 0),
  constraint form_response_revisions_answers_object check (jsonb_typeof(answers) = 'object'),
  constraint form_response_revisions_status_check check (status in ('draft', 'submitted')),
  constraint form_response_revisions_idempotency_length check (
    idempotency_key is null or char_length(idempotency_key) between 8 and 128
  ),
  unique (project_form_id, revision)
);

create unique index form_response_revisions_idempotency_unique
  on public.form_response_revisions (project_form_id, idempotency_key)
  where idempotency_key is not null;

comment on table public.form_response_revisions is
  'Revisiones append-only; una respuesta histórica nunca se sobrescribe.';
