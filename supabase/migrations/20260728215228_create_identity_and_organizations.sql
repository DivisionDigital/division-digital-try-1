create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  phone text,
  locale text not null default 'es-CO',
  timezone text not null default 'America/Bogota',
  avatar_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_display_name_length check (
    display_name is null or char_length(display_name) between 2 and 120
  ),
  constraint profiles_phone_length check (
    phone is null or char_length(phone) between 7 and 32
  ),
  constraint profiles_locale_format check (locale ~ '^[a-z]{2}(-[A-Z]{2})?$'),
  constraint profiles_timezone_length check (char_length(timezone) between 3 and 64)
);

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  legal_type text not null default 'company',
  name text not null,
  legal_name text,
  tax_id text,
  billing_email text,
  contact_phone text,
  billing_address jsonb not null default '{}'::jsonb,
  status text not null default 'active',
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  constraint organizations_legal_type_check check (legal_type in ('person', 'company')),
  constraint organizations_name_length check (char_length(name) between 2 and 160),
  constraint organizations_legal_name_length check (
    legal_name is null or char_length(legal_name) between 2 and 200
  ),
  constraint organizations_tax_id_length check (
    tax_id is null or char_length(tax_id) between 3 and 40
  ),
  constraint organizations_billing_email_format check (
    billing_email is null
    or billing_email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'
  ),
  constraint organizations_contact_phone_length check (
    contact_phone is null or char_length(contact_phone) between 7 and 32
  ),
  constraint organizations_billing_address_object check (
    jsonb_typeof(billing_address) = 'object'
  ),
  constraint organizations_status_check check (status in ('active', 'suspended', 'archived')),
  constraint organizations_archived_at_check check (
    (status = 'archived' and archived_at is not null)
    or (status <> 'archived')
  ),
  unique (id, status)
);

create table public.organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'member',
  status text not null default 'active',
  invited_by uuid references auth.users (id) on delete set null,
  joined_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  revoked_at timestamptz,
  constraint organization_members_role_check check (role in ('owner', 'member')),
  constraint organization_members_status_check check (
    status in ('invited', 'active', 'suspended', 'revoked')
  ),
  constraint organization_members_joined_at_check check (
    status <> 'active' or joined_at is not null
  ),
  constraint organization_members_revoked_at_check check (
    status <> 'revoked' or revoked_at is not null
  ),
  unique (organization_id, user_id),
  unique (id, organization_id)
);

create table public.organization_invitations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  email text not null,
  role text not null default 'member',
  token_hash text not null,
  status text not null default 'pending',
  invited_by uuid not null references auth.users (id) on delete restrict,
  accepted_by uuid references auth.users (id) on delete set null,
  expires_at timestamptz not null,
  accepted_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint organization_invitations_email_format check (
    email = lower(email)
    and email ~ '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$'
  ),
  constraint organization_invitations_role_check check (role in ('owner', 'member')),
  constraint organization_invitations_token_hash_length check (
    char_length(token_hash) between 43 and 128
  ),
  constraint organization_invitations_status_check check (
    status in ('pending', 'accepted', 'revoked', 'expired')
  ),
  constraint organization_invitations_expiry_check check (expires_at > created_at),
  constraint organization_invitations_acceptance_check check (
    status <> 'accepted'
    or (accepted_at is not null and accepted_by is not null)
  ),
  unique (token_hash)
);

comment on table public.profiles is 'Datos de presentación; Supabase Auth sigue siendo la fuente de identidad.';
comment on table public.organization_members is 'Membresías de clientes. No contiene roles globales team/admin.';
