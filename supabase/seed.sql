insert into public.service_catalog (
  id,
  slug,
  name,
  description,
  status,
  visibility,
  configuration,
  version,
  published_at
)
values (
  '10000000-0000-4000-8000-000000000001',
  'landing-page',
  'Landing Page',
  'Diseño y desarrollo de una página de aterrizaje orientada a conversión.',
  'published',
  'public',
  '{
    "default_currency": "COP",
    "delivery_model": "project",
    "max_units_per_order_item": 99
  }'::jsonb,
  1,
  '2026-07-28T00:00:00Z'
)
on conflict (id) do update
set
  slug = excluded.slug,
  name = excluded.name,
  description = excluded.description,
  status = excluded.status,
  visibility = excluded.visibility,
  configuration = excluded.configuration,
  version = excluded.version,
  published_at = excluded.published_at;

insert into public.service_workflow_versions (
  id,
  service_catalog_id,
  version,
  status,
  initial_status_code,
  definition,
  published_at
)
values (
  '10000000-0000-4000-8000-000000000101',
  '10000000-0000-4000-8000-000000000001',
  1,
  'published',
  'pending',
  '{
    "states": [
      {"code":"pending","label":"Pendiente","visibility":"client","terminal":false},
      {"code":"awaiting_client_information","label":"Esperando información","visibility":"client","terminal":false},
      {"code":"information_received","label":"Información recibida","visibility":"client","terminal":false},
      {"code":"in_progress","label":"En progreso","visibility":"client","terminal":false},
      {"code":"in_review","label":"En revisión","visibility":"client","terminal":false},
      {"code":"corrections","label":"Correcciones","visibility":"client","terminal":false},
      {"code":"completed","label":"Completado","visibility":"client","terminal":true},
      {"code":"archived","label":"Archivado","visibility":"internal","terminal":true}
    ],
    "transitions": [
      {"from":"pending","to":"awaiting_client_information","capability":"project:transition"},
      {"from":"awaiting_client_information","to":"information_received","capability":"project:transition"},
      {"from":"information_received","to":"in_progress","capability":"project:transition"},
      {"from":"in_progress","to":"in_review","capability":"project:transition"},
      {"from":"in_review","to":"corrections","capability":"project:transition","reason_required":true},
      {"from":"corrections","to":"in_review","capability":"project:transition"},
      {"from":"in_review","to":"completed","capability":"project:transition"},
      {"from":"completed","to":"archived","capability":"project:archive","reason_required":true}
    ]
  }'::jsonb,
  '2026-07-28T00:00:00Z'
)
on conflict (id) do update
set
  status = excluded.status,
  initial_status_code = excluded.initial_status_code,
  definition = excluded.definition,
  published_at = excluded.published_at;

insert into public.form_templates (
  id,
  service_catalog_id,
  key,
  title,
  description,
  stage,
  required,
  sort_order,
  status
)
values
(
  '10000000-0000-4000-8000-000000000201',
  '10000000-0000-4000-8000-000000000001',
  'business-brief',
  'Briefing de negocio',
  'Objetivos, audiencia y alcance funcional de la landing.',
  'onboarding',
  true,
  10,
  'active'
),
(
  '10000000-0000-4000-8000-000000000202',
  '10000000-0000-4000-8000-000000000001',
  'content-and-brand-assets',
  'Contenidos e identidad',
  'Estado y entrega de los contenidos y activos visuales.',
  'onboarding',
  true,
  20,
  'active'
)
on conflict (id) do update
set
  title = excluded.title,
  description = excluded.description,
  stage = excluded.stage,
  required = excluded.required,
  sort_order = excluded.sort_order,
  status = excluded.status;

insert into public.form_versions (
  id,
  form_template_id,
  version,
  status,
  definition,
  validation_schema,
  published_at
)
values
(
  '10000000-0000-4000-8000-000000000301',
  '10000000-0000-4000-8000-000000000201',
  1,
  'published',
  '{
    "schema_version": 1,
    "sections": [
      {
        "key": "strategy",
        "title": "Estrategia",
        "fields": [
          {"key":"objective","type":"textarea","label":"Objetivo principal","required":true,"max_length":2000},
          {"key":"value_proposition","type":"textarea","label":"Propuesta de valor","required":true,"max_length":2000},
          {"key":"target_audience","type":"textarea","label":"Audiencia objetivo","required":true,"max_length":2000},
          {"key":"primary_cta","type":"text","label":"Llamado a la acción principal","required":true,"max_length":160}
        ]
      },
      {
        "key": "scope",
        "title": "Alcance",
        "fields": [
          {"key":"sections","type":"string_array","label":"Secciones esperadas","required":true,"max_items":20},
          {"key":"reference_urls","type":"url_array","label":"Referencias","required":false,"max_items":10},
          {"key":"integrations","type":"string_array","label":"Integraciones requeridas","required":false,"max_items":20},
          {"key":"domain","type":"hostname","label":"Dominio previsto","required":false},
          {"key":"target_date","type":"date","label":"Fecha objetivo","required":false}
        ]
      }
    ]
  }'::jsonb,
  '{
    "type":"object",
    "additionalProperties":false,
    "required":["objective","value_proposition","target_audience","primary_cta","sections"]
  }'::jsonb,
  '2026-07-28T00:00:00Z'
),
(
  '10000000-0000-4000-8000-000000000302',
  '10000000-0000-4000-8000-000000000202',
  1,
  'published',
  '{
    "schema_version": 1,
    "sections": [
      {
        "key": "brand",
        "title": "Identidad visual",
        "fields": [
          {"key":"has_logo","type":"boolean","label":"¿Cuenta con logotipo?","required":true},
          {"key":"has_brand_guide","type":"boolean","label":"¿Cuenta con manual de marca?","required":true},
          {"key":"brand_colors","type":"string_array","label":"Colores de marca","required":false,"max_items":10},
          {"key":"brand_fonts","type":"string_array","label":"Tipografías","required":false,"max_items":10}
        ]
      },
      {
        "key": "content",
        "title": "Contenidos",
        "fields": [
          {"key":"copy_status","type":"select","label":"Estado de los textos","required":true,"options":["ready","partial","not_started"]},
          {"key":"image_status","type":"select","label":"Estado de las imágenes","required":true,"options":["ready","partial","not_started"]},
          {"key":"required_file_purposes","type":"readonly_list","value":["logo","brand_guide","images","copy_document"]}
        ]
      }
    ]
  }'::jsonb,
  '{
    "type":"object",
    "additionalProperties":false,
    "required":["has_logo","has_brand_guide","copy_status","image_status"]
  }'::jsonb,
  '2026-07-28T00:00:00Z'
)
on conflict (id) do update
set
  status = excluded.status,
  definition = excluded.definition,
  validation_schema = excluded.validation_schema,
  published_at = excluded.published_at;

insert into public.milestone_templates (
  id,
  service_catalog_id,
  key,
  title,
  description,
  sort_order,
  due_offset_days,
  visible_to_client,
  status
)
values
(
  '10000000-0000-4000-8000-000000000401',
  '10000000-0000-4000-8000-000000000001',
  'information_complete',
  'Información completa',
  'El equipo recibió y validó el briefing y los activos iniciales.',
  10,
  5,
  true,
  'active'
),
(
  '10000000-0000-4000-8000-000000000402',
  '10000000-0000-4000-8000-000000000001',
  'first_review',
  'Primera revisión',
  'La primera versión queda disponible para revisión.',
  20,
  15,
  true,
  'active'
),
(
  '10000000-0000-4000-8000-000000000403',
  '10000000-0000-4000-8000-000000000001',
  'delivery',
  'Entrega',
  'La landing aprobada queda entregada.',
  30,
  25,
  true,
  'active'
)
on conflict (id) do update
set
  title = excluded.title,
  description = excluded.description,
  sort_order = excluded.sort_order,
  due_offset_days = excluded.due_offset_days,
  visible_to_client = excluded.visible_to_client,
  status = excluded.status;
