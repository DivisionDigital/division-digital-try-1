create table public.staff_members (
  user_id uuid primary key references auth.users (id) on delete cascade,
  role text not null,
  status text not null default 'active',
  granted_by uuid references auth.users (id) on delete set null,
  granted_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  revoked_at timestamptz,
  constraint staff_members_role_check check (role in ('team', 'admin')),
  constraint staff_members_status_check check (status in ('active', 'suspended', 'revoked')),
  constraint staff_members_revoked_at_check check (
    status <> 'revoked' or revoked_at is not null
  )
);

create table public.staff_invitations (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  role text not null,
  token_hash text not null,
  status text not null default 'pending',
  invited_by uuid not null references auth.users (id) on delete restrict,
  accepted_by uuid references auth.users (id) on delete set null,
  expires_at timestamptz not null,
  accepted_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint staff_invitations_email_format check (
    email = lower(email)
    and email ~ '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$'
  ),
  constraint staff_invitations_role_check check (role in ('team', 'admin')),
  constraint staff_invitations_token_hash_length check (
    char_length(token_hash) between 43 and 128
  ),
  constraint staff_invitations_status_check check (
    status in ('pending', 'accepted', 'revoked', 'expired')
  ),
  constraint staff_invitations_expiry_check check (expires_at > created_at),
  constraint staff_invitations_acceptance_check check (
    status <> 'accepted'
    or (accepted_at is not null and accepted_by is not null)
  ),
  unique (token_hash)
);

comment on table public.staff_members is
  'Autoridad interna global separada de las membresías de organizaciones cliente.';
