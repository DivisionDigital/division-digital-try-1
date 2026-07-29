create function app_private.can_upload_project_file(
  target_bucket text,
  target_path text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null
    and exists (
      select 1
      from public.files file_record
      where file_record.storage_bucket = target_bucket
        and file_record.storage_path = target_path
        and file_record.status = 'pending_upload'
        and file_record.created_by = (select auth.uid())
        and file_record.upload_expires_at is not null
        and file_record.upload_expires_at > now()
        and (
          exists (
            select 1
            from public.organization_members membership
            where membership.organization_id = file_record.organization_id
              and membership.user_id = (select auth.uid())
              and membership.status = 'active'
          )
          or exists (
            select 1
            from public.staff_members staff
            where staff.user_id = (select auth.uid())
              and staff.status = 'active'
              and staff.role in ('team', 'admin')
          )
        )
    );
$$;

create function app_private.can_read_project_file(
  target_bucket text,
  target_path text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null
    and exists (
      select 1
      from public.files file_record
      where file_record.storage_bucket = target_bucket
        and file_record.storage_path = target_path
        and (
          (
            file_record.status = 'pending_upload'
            and file_record.created_by = (select auth.uid())
            and file_record.upload_expires_at is not null
            and file_record.upload_expires_at > now()
          )
          or (
            file_record.status = 'available'
            and (
              exists (
                select 1
                from public.staff_members staff
                where staff.user_id = (select auth.uid())
                  and staff.status = 'active'
                  and staff.role in ('team', 'admin')
              )
              or (
                file_record.visibility = 'client'
                and exists (
                  select 1
                  from public.organization_members membership
                  where membership.organization_id = file_record.organization_id
                    and membership.user_id = (select auth.uid())
                    and membership.status = 'active'
                )
              )
            )
          )
        )
    );
$$;

revoke all on function app_private.can_upload_project_file(text, text)
  from public, anon, authenticated, service_role;
revoke all on function app_private.can_read_project_file(text, text)
  from public, anon, authenticated, service_role;
grant execute on function app_private.can_upload_project_file(text, text)
  to authenticated;
grant execute on function app_private.can_read_project_file(text, text)
  to authenticated;

drop policy if exists project_files_insert_authorized on storage.objects;
drop policy if exists project_files_select_authorized on storage.objects;

create policy project_files_insert_authorized
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'project-files'
    and (select app_private.can_upload_project_file(bucket_id, name))
  );

create policy project_files_select_authorized
  on storage.objects for select to authenticated
  using (
    bucket_id = 'project-files'
    and (select app_private.can_read_project_file(bucket_id, name))
  );

comment on function app_private.can_upload_project_file(text, text) is
  'Authorizes a non-expired server-created project upload intent for the current user.';
comment on function app_private.can_read_project_file(text, text) is
  'Authorizes pending-owner or available project file reads without exposing files through Data API.';
