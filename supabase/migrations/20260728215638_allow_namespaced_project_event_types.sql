alter table public.project_events
  drop constraint project_events_type_format;

alter table public.project_events
  add constraint project_events_type_format
  check (event_type ~ '^[a-z][a-z0-9_.]{1,127}$');
