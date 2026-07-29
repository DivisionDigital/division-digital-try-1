create table public.files (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  service_instance_id uuid not null,
  project_form_id uuid,
  created_by uuid not null references auth.users (id) on delete restrict,
  purpose text not null,
  original_name text not null,
  storage_bucket text not null default 'project-files',
  storage_path text not null,
  mime_type text not null,
  size_bytes bigint,
  sha256 text,
  status text not null default 'pending_upload',
  visibility text not null default 'client',
  metadata jsonb not null default '{}'::jsonb,
  upload_expires_at timestamptz,
  available_at timestamptz,
  quarantined_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint files_project_fk foreign key (service_instance_id, organization_id)
    references public.service_instances (id, organization_id) on delete restrict,
  constraint files_project_form_fk
    foreign key (project_form_id, service_instance_id, organization_id)
    references public.project_forms (id, service_instance_id, organization_id) on delete restrict,
  constraint files_purpose_format check (purpose ~ '^[a-z][a-z0-9_]{1,63}$'),
  constraint files_original_name_length check (char_length(original_name) between 1 and 255),
  constraint files_storage_bucket_check check (storage_bucket = 'project-files'),
  constraint files_storage_path_format check (
    storage_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}$'
  ),
  constraint files_mime_type_check check (
    mime_type in ('application/pdf', 'image/jpeg', 'image/png', 'image/webp')
  ),
  constraint files_size_check check (
    size_bytes is null or size_bytes between 1 and 26214400
  ),
  constraint files_sha256_format check (
    sha256 is null or sha256 ~ '^[a-f0-9]{64}$'
  ),
  constraint files_status_check check (
    status in ('pending_upload', 'available', 'quarantined', 'deleted')
  ),
  constraint files_visibility_check check (visibility in ('client', 'internal')),
  constraint files_metadata_object check (jsonb_typeof(metadata) = 'object'),
  constraint files_available_at_check check (
    status <> 'available'
    or (available_at is not null and size_bytes is not null and sha256 is not null)
  ),
  constraint files_quarantined_at_check check (
    status <> 'quarantined' or quarantined_at is not null
  ),
  constraint files_deleted_at_check check (
    status <> 'deleted' or deleted_at is not null
  ),
  unique (storage_bucket, storage_path)
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  service_instance_id uuid not null,
  author_user_id uuid not null references auth.users (id) on delete restrict,
  visibility text not null default 'client',
  body text not null,
  status text not null default 'published',
  edited_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint messages_project_fk foreign key (service_instance_id, organization_id)
    references public.service_instances (id, organization_id) on delete restrict,
  constraint messages_visibility_check check (visibility in ('client', 'internal')),
  constraint messages_body_length check (char_length(body) between 1 and 10000),
  constraint messages_status_check check (status in ('published', 'edited', 'deleted')),
  constraint messages_edited_at_check check (
    status <> 'edited' or edited_at is not null
  ),
  constraint messages_deleted_at_check check (
    status <> 'deleted' or deleted_at is not null
  )
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  organization_id uuid references public.organizations (id) on delete restrict,
  service_instance_id uuid references public.service_instances (id) on delete restrict,
  type text not null,
  title text not null,
  body text not null default '',
  data jsonb not null default '{}'::jsonb,
  status text not null default 'unread',
  delivered_at timestamptz,
  read_at timestamptz,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint notifications_type_format check (type ~ '^[a-z][a-z0-9_]{1,63}$'),
  constraint notifications_title_length check (char_length(title) between 1 and 200),
  constraint notifications_body_length check (char_length(body) <= 4000),
  constraint notifications_data_object check (jsonb_typeof(data) = 'object'),
  constraint notifications_status_check check (status in ('unread', 'read', 'archived')),
  constraint notifications_read_at_check check (
    status <> 'read' or read_at is not null
  ),
  constraint notifications_archived_at_check check (
    status <> 'archived' or archived_at is not null
  )
);

comment on table public.files is
  'Metadata y ownership; los bytes viven exclusivamente en Storage privado.';
