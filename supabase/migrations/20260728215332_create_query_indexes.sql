create index organization_members_user_status_idx
  on public.organization_members (user_id, status);
create index organization_members_organization_status_idx
  on public.organization_members (organization_id, status);
create unique index organization_invitations_pending_email_unique
  on public.organization_invitations (organization_id, lower(email))
  where status = 'pending';
create unique index staff_invitations_pending_email_unique
  on public.staff_invitations (lower(email))
  where status = 'pending';

create index service_catalog_status_visibility_idx
  on public.service_catalog (status, visibility);
create unique index service_workflow_versions_one_published
  on public.service_workflow_versions (service_catalog_id)
  where status = 'published';
create index form_templates_service_status_sort_idx
  on public.form_templates (service_catalog_id, status, sort_order);
create unique index form_versions_one_published
  on public.form_versions (form_template_id)
  where status = 'published';
create index milestone_templates_service_status_sort_idx
  on public.milestone_templates (service_catalog_id, status, sort_order);

create index quotes_organization_status_updated_idx
  on public.quotes (organization_id, status, updated_at desc);
create index quote_versions_quote_status_version_idx
  on public.quote_versions (quote_id, status, version desc);
create index quote_version_items_service_idx
  on public.quote_version_items (service_catalog_id);

create index orders_organization_status_updated_idx
  on public.orders (organization_id, status, updated_at desc);
create index order_items_order_idx
  on public.order_items (order_id, line_number);
create index payments_order_status_idx
  on public.payments (order_id, status, created_at desc);
create index payments_organization_status_idx
  on public.payments (organization_id, status, created_at desc);
create index webhook_events_retry_idx
  on public.webhook_events (status, next_attempt_at)
  where status in ('received', 'failed');

create index service_instances_org_status_updated_idx
  on public.service_instances (organization_id, status_code, updated_at desc);
create index service_instances_assigned_status_idx
  on public.service_instances (assigned_staff_user_id, status_code)
  where assigned_staff_user_id is not null;
create index project_events_project_created_idx
  on public.project_events (service_instance_id, created_at desc, id desc);
create index milestones_project_status_sort_idx
  on public.milestones (service_instance_id, status, sort_order);
create index project_forms_project_status_sort_idx
  on public.project_forms (service_instance_id, status, sort_order);
create index project_forms_org_status_idx
  on public.project_forms (organization_id, status);
create index form_response_revisions_form_revision_idx
  on public.form_response_revisions (project_form_id, revision desc);

create index files_project_status_created_idx
  on public.files (service_instance_id, status, created_at desc);
create index files_org_project_idx
  on public.files (organization_id, service_instance_id);
create index messages_project_created_idx
  on public.messages (service_instance_id, created_at desc, id desc);
create index notifications_user_status_created_idx
  on public.notifications (user_id, status, created_at desc);
create index notifications_user_unread_idx
  on public.notifications (user_id, created_at desc)
  where status = 'unread';
create index audit_events_resource_created_idx
  on public.audit_events (resource_type, resource_id, created_at desc);
create index audit_events_org_created_idx
  on public.audit_events (organization_id, created_at desc)
  where organization_id is not null;
create index outbox_events_dispatch_idx
  on public.outbox_events (available_at, created_at)
  where status in ('pending', 'failed');
