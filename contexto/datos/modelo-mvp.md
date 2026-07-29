# Modelo de datos inicial del MVP

**Estado:** diseño lógico implementado y validado
**Fecha:** 2026-07-28
**Relacionado:** [Modelo relacional del portal](./modelo-relacional.md), [modelo físico](./modelo-fisico-supabase.md), [matriz de permisos](../seguridad/matriz-permisos.md) y [ADR-005](../decisiones/ADR-005-proyectos-por-servicio-y-formularios-configurables.md)

Este documento conserva el diseño lógico. Los nombres, tipos, constraints e índices ejecutables están en `supabase/migrations/` y se detallan en el modelo físico.

## 1. Convenciones comunes

- IDs de negocio: `uuid` generado en servidor.
- Fechas: `timestamptz` en UTC.
- Dinero: `numeric(12,2)` más `currency`; nunca `float`.
- Estados: `text` con `CHECK` o catálogo versionado cuando sean configurables.
- Historia comercial y operativa: no borrar físicamente; usar estados y eventos append-only.
- Recursos de negocio: `organization_id` directo o una ruta de ownership inequívoca.
- Toda tabla expuesta tendrá RLS, grants revisados y pruebas de aislamiento.

## 2. Inventario inicial

| Tabla propuesta | Propósito | Invariantes principales |
| --- | --- | --- |
| `profiles` | Perfil asociado a la identidad | `id` vinculado al proveedor de identidad |
| `organizations` | Cliente o empresa contratante | estado y datos de contacto propios |
| `organization_members` | Usuarios cliente por organización | `UNIQUE(organization_id, user_id)`; solo `owner|member` |
| `organization_invitations` | Invitaciones de organización | Nunca concede autoridad global |
| `staff_members` | Autoridad interna global | Solo `team|admin`; `admin` activa proyectos |
| `staff_invitations` | Invitaciones internas | Separadas de las invitaciones cliente |
| `service_catalog` | Tipo configurable de servicio | `slug` único, publicación, descripción y configuración |
| `service_workflow_versions` | Estados y transiciones de un servicio | versión publicada e inmutable; definición validada |
| `form_templates` | Formulario reusable de un servicio | servicio, clave estable, orden y obligatoriedad |
| `form_versions` | Definición publicada del formulario | versión inmutable, `definition jsonb` validada |
| `quotes` | Solicitud y agregado de cotización | organización, estado actual y versión vigente |
| `quote_versions` | Snapshot negociable de una cotización | versión inmutable; cliente acepta una versión exacta |
| `quote_version_items` | Servicios, cantidades y alcance cotizado | `service_catalog_id`, cantidad positiva, precio y snapshot |
| `orders` | Acuerdo confirmado para activar | referencia a versión aceptada y estado de activación |
| `order_items` | Snapshot de lo contratado | servicio, cantidad, alcance y precio congelados |
| `payments` | Intentos y confirmaciones futuras | referencia externa idempotente, importe y moneda |
| `webhook_events` | Eventos externos recibidos | `UNIQUE(provider, external_event_id)`, estado de procesamiento |
| `service_instances` | Proyecto concreto de un servicio | uno por `order_item_id` y unidad; organización y workflow fijados |
| `project_events` | Historial del proyecto | estado anterior/nuevo, actor, timestamp y correlation ID |
| `project_forms` | Formulario provisionado para un proyecto | plantilla y versión fijadas; estado propio por proyecto |
| `form_response_revisions` | Revisiones de respuestas | `UNIQUE(project_form_id, revision)`; nunca sobrescribir historia |
| `milestones` | Hitos configurados o creados para el proyecto | orden, estado y fechas auditables |
| `files` | Metadata de archivos privados | ownership, MIME, tamaño, checksum y `storage_key` |
| `messages` | Comunicación ligada al proyecto | autor, visibilidad y organización verificables |
| `notifications` | Avisos del portal por usuario | estados, lectura y archivo controlados |
| `audit_events` | Auditoría de acciones sensibles | actor, recurso, resultado y metadata sin secretos |
| `outbox_events` | Efectos externos reintentables | evento transaccional, estado, intentos y timestamps |

`service_instances` es la persistencia del agregado de dominio `Project`. La API y la interfaz pueden usar el término `project`, mientras que el adaptador PostgreSQL conserva el nombre físico definido aquí.

## 3. Relaciones esenciales

```text
profiles 1---N organization_members N---1 organizations
organizations 1---N quotes 1---N quote_versions 1---N quote_version_items
quote_versions 1---0..1 orders 1---N order_items
orders 1---N payments
orders 1---N service_instances N---1 service_catalog
service_catalog 1---N service_workflow_versions
service_catalog 1---N form_templates 1---N form_versions
service_instances 1---N project_forms N---1 form_versions
project_forms 1---N form_response_revisions
service_instances 1---N project_events
service_instances 1---N milestones
service_instances 1---N files
service_instances 1---N messages
```

Una misma cotización puede incluir varias unidades del mismo servicio. Cada unidad produce un `service_instances` diferente. No se debe usar una sola fila por cliente/servicio ni una bandera global `has_service`.

## 4. Configuración extensible del catálogo

`service_catalog` debe permitir configurar, sin cambios de código de dominio:

- nombre, slug, descripción y estado de publicación;
- configuración comercial y operativa validada;
- workflow publicado por defecto;
- formularios requeridos, opcionales, orden y etapa;
- hitos iniciales y reglas de fechas;
- visibilidad para catálogo público o solo panel interno.

La configuración variable puede vivir en JSONB controlado. Los estados y transiciones deben tener una definición versionada con esta forma conceptual:

```text
workflow_version
├── states: code, label, visibility, terminal
└── transitions: from, to, actor/capability, reason_required
```

El dominio valida la definición al publicarla y valida cada transición contra la versión fijada en el proyecto. `status_code` se mantiene como columna relacional para consultas del dashboard; el historial se guarda en `project_events`.

## 5. Provisionamiento automático de proyectos

El caso de uso `ActivateOrder` debe ejecutarse en una transacción corta y con autorización `admin`:

1. Verificar que la orden pertenece a la organización, la cotización fue aceptada por el cliente y la versión no fue reemplazada.
2. Verificar las precondiciones comerciales definidas: confirmación administrativa y, si en el futuro aplica, pago elegible.
3. Bloquear la orden o usar una restricción única para impedir doble activación.
4. Crear un proyecto por cada `order_item` y unidad contratada, copiando el snapshot del servicio y fijando workflow.
5. Crear automáticamente un `project_form` por cada `form_template` publicado aplicable al servicio y fijar su `form_version`.
6. Crear hitos iniciales y el primer `project_event`.
7. Marcar la orden como activa, registrar auditoría y publicar notificaciones mediante `outbox_events` después de confirmar la transacción.

La clave de idempotencia conceptual es `(order_item_id, unit_number)`. Repetir la solicitud devuelve los proyectos existentes y nunca duplica proyectos, formularios, hitos ni notificaciones.

## 6. Formularios por proyecto

Los formularios pertenecen a `project_forms`, no al cliente ni únicamente al catálogo. La plantilla y su versión son reutilizables; la instancia, estado, disponibilidad y respuestas son privadas del proyecto.

Estados sugeridos de `project_forms`:

```text
pending -> open -> submitted -> changes_requested -> submitted -> locked
```

El cliente puede abrir, guardar borradores y editar mientras la instancia esté abierta. Cada guardado relevante crea una fila en `form_response_revisions` con `answers jsonb`, número de revisión, actor y timestamp. Al enviar, el servidor valida que las respuestas cumplen la definición de la versión fijada y que el usuario pertenece a la organización del proyecto.

No se usará EAV ni un formulario gigante por cliente. Si una respuesta se vuelve necesaria para búsquedas o reportes frecuentes, se extraerá a una columna o entidad mediante migración.

## 7. Ciclo de vida de proyectos

El catálogo puede definir workflows distintos. El workflow inicial recomendado es:

```text
pending
  -> awaiting_client_information
  -> information_received
  -> in_progress
  -> in_review
  -> corrections
  -> completed
  -> archived
```

Las transiciones se validan en el dominio según actor, capability, estado actual y motivo. El cliente solo puede leer estados visibles; no puede cambiar estado interno, fechas, responsable ni hitos del equipo. Equipo puede operar el proyecto según la matriz; la activación inicial queda reservada a `admin`.

## 8. Reglas que deben vivir en la base y el dominio

- Una membresía no puede repetirse para la misma organización y usuario.
- El cliente puede registrarse antes de tener servicios y consultar cotizaciones propias.
- Una cotización aceptada referencia una `quote_version` inmutable.
- Una orden conserva el snapshot de lo aceptado y no se recalcula desde el catálogo actual.
- Una orden solo se activa mediante el caso de uso autorizado; el cliente nunca puede hacerlo.
- Cada unidad contratada crea exactamente un proyecto independiente.
- Un proyecto pertenece a una organización, un servicio de catálogo y una orden.
- Un formulario de proyecto apunta a una versión concreta y no cambia silenciosamente de versión.
- Las revisiones de respuestas, eventos, auditoría y pagos no se editan desde el portal del cliente.
- Un archivo debe tener ownership verificable antes de permitir lectura, reemplazo o descarga.
- Los pagos futuros no pueden cambiar el importe, organización o servicios de una orden desde el navegador.

## 9. Índices iniciales a validar

- membresías por `(user_id, status)` y `(organization_id, status)`;
- cotizaciones por `(organization_id, status, updated_at desc)`;
- versiones e ítems por `quote_id` y `quote_version_id`;
- órdenes por `(organization_id, activation_status)`;
- proyectos por `(organization_id, status_code, updated_at desc)`;
- proyectos por `(order_id, order_item_id, unit_number)` único;
- formularios por `(project_id, status)` y `(organization_id, status)`;
- eventos por `(project_id, created_at desc)`;
- archivos por `(organization_id, project_id)`;
- pagos por referencia externa única y estado;
- outbox por estado y próximo intento.

Los índices definitivos se confirmarán con `EXPLAIN (ANALYZE, BUFFERS)` y consultas reales del dashboard.

## 10. Secuencia recomendada de migraciones

1. perfiles, organizaciones y membresías;
2. catálogo, workflows y plantillas/versiones de formularios;
3. cotizaciones, versiones e ítems;
4. órdenes, ítems de orden y activación administrativa;
5. proyectos, eventos y hitos;
6. formularios de proyecto y revisiones de respuestas;
7. archivos, mensajes, auditoría y outbox;
8. pagos/webhooks como adaptador opcional, sin alterar el caso de uso de activación;
9. RLS, grants, índices y pruebas de aislamiento;
10. notificaciones y optimizaciones posteriores.

La estructura permite habilitar pagos automáticos después porque `payments`, `webhook_events` y el puerto `PaymentProvider` se conectan a órdenes existentes; no obliga a rediseñar proyectos, formularios ni workflows.
