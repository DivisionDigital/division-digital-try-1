create index audit_events_actor_user_idx
  on public.audit_events (actor_user_id);

create index files_created_by_idx
  on public.files (created_by);
create index files_project_fk_idx
  on public.files (service_instance_id, organization_id);
create index files_project_form_fk_idx
  on public.files (project_form_id, service_instance_id, organization_id);

create index form_response_revisions_created_by_idx
  on public.form_response_revisions (created_by);
create index form_response_revisions_form_fk_idx
  on public.form_response_revisions (project_form_id, organization_id);

create index form_templates_created_by_idx
  on public.form_templates (created_by);
create index form_versions_created_by_idx
  on public.form_versions (created_by);
create index form_versions_published_by_idx
  on public.form_versions (published_by);

create index messages_author_user_idx
  on public.messages (author_user_id);
create index messages_project_fk_idx
  on public.messages (service_instance_id, organization_id);

create index milestones_template_idx
  on public.milestones (milestone_template_id);
create index milestones_project_fk_idx
  on public.milestones (service_instance_id, organization_id);

create index notifications_organization_idx
  on public.notifications (organization_id);
create index notifications_service_instance_idx
  on public.notifications (service_instance_id);

create index order_items_order_fk_idx
  on public.order_items (order_id, organization_id);
create index order_items_service_catalog_idx
  on public.order_items (service_catalog_id);

create index orders_activated_by_idx
  on public.orders (activated_by);
create index orders_cancelled_by_idx
  on public.orders (cancelled_by);
create index orders_confirmed_by_idx
  on public.orders (confirmed_by);

create index organization_invitations_accepted_by_idx
  on public.organization_invitations (accepted_by);
create index organization_invitations_invited_by_idx
  on public.organization_invitations (invited_by);
create index organization_members_invited_by_idx
  on public.organization_members (invited_by);
create index organizations_created_by_idx
  on public.organizations (created_by);

create index outbox_events_organization_idx
  on public.outbox_events (organization_id);

create index payments_created_by_idx
  on public.payments (created_by);
create index payments_order_fk_idx
  on public.payments (order_id, organization_id);

create index project_events_actor_user_idx
  on public.project_events (actor_user_id);
create index project_events_project_fk_idx
  on public.project_events (service_instance_id, organization_id);

create index project_forms_form_template_idx
  on public.project_forms (form_template_id);
create index project_forms_project_fk_idx
  on public.project_forms (service_instance_id, organization_id);
create index project_forms_version_template_fk_idx
  on public.project_forms (form_version_id, form_template_id);

create index quote_versions_accepted_by_idx
  on public.quote_versions (accepted_by);
create index quote_versions_created_by_idx
  on public.quote_versions (created_by);
create index quote_versions_published_by_idx
  on public.quote_versions (published_by);

create index service_catalog_created_by_idx
  on public.service_catalog (created_by);
create index service_catalog_published_by_idx
  on public.service_catalog (published_by);

create index service_instances_order_fk_idx
  on public.service_instances (order_id, organization_id);
create index service_instances_order_item_fk_idx
  on public.service_instances (order_item_id, organization_id);
create index service_instances_service_catalog_idx
  on public.service_instances (service_catalog_id);
create index service_instances_workflow_service_fk_idx
  on public.service_instances (workflow_version_id, service_catalog_id);

create index service_workflow_versions_created_by_idx
  on public.service_workflow_versions (created_by);
create index service_workflow_versions_published_by_idx
  on public.service_workflow_versions (published_by);

create index staff_invitations_accepted_by_idx
  on public.staff_invitations (accepted_by);
create index staff_invitations_invited_by_idx
  on public.staff_invitations (invited_by);
create index staff_members_granted_by_idx
  on public.staff_members (granted_by);

create index webhook_events_order_idx
  on public.webhook_events (order_id);
create index webhook_events_payment_idx
  on public.webhook_events (payment_id);
