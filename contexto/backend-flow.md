# Flujo funcional y de negocio del backend

**Estado:** diseño aprobado; infraestructura de datos implementada y backend pendiente
**Fecha:** 2026-07-28
**Fuente principal:** requisitos funcionales de División Digital, `arquitectura.md`, `modelo-mvp.md` y ADR-003/ADR-005.

Este documento describe el flujo que debe implementar el backend. Los endpoints continúan pendientes; el esquema, las migraciones y los controles de datos que lo soportan ya están implementados en `supabase/` y documentados en `datos/modelo-fisico-supabase.md`.

## 1. Contexto del producto

División Digital gestiona la prestación de servicios digitales personalizados. No es un e-commerce tradicional: el cliente no compra un producto cerrado desde la landing, sino que solicita una cotización para uno o varios servicios y luego los proyectos se gestionan desde la plataforma.

El catálogo puede incluir desarrollo web, landing pages, e-commerce, marketing digital, gestión de e-commerce, publicidad, video ads, SEO y nuevos servicios configurables.

## 2. Actores

| Actor | Responsabilidad |
|---|---|
| `anonymous` | Consulta landing y catálogo público |
| `client` | Se registra, solicita cotizaciones, acepta propuestas y opera sus proyectos |
| `team` | Revisa cotizaciones y gestiona la operación diaria |
| `admin` | Ejecuta activaciones y acciones administrativas sensibles |
| `system` | Ejecuta webhooks, outbox y tareas server-side explícitas |

Un cliente puede existir sin servicios contratados. La ausencia de proyectos no impide consultar perfil ni cotizaciones propias.

## 3. Flujo principal

### Registro

1. El cliente crea una cuenta.
2. Verifica su correo mediante el proveedor de identidad.
3. El backend crea o valida `profile`, `organization` y membresía `client`.
4. El cliente entra al portal aunque todavía no tenga proyectos.

El registro debe tener rate limiting, mensajes que no permitan enumerar correos y sesión server-side.

### Solicitud y negociación de cotización

1. El cliente selecciona uno o varios servicios y puede indicar cantidades o necesidades.
2. El backend crea una `quote` en estado `pending_review`.
3. El equipo revisa la solicitud desde el panel.
4. Puede agregar, quitar o modificar servicios, alcance, cantidades, precios y vigencia.
5. Cada propuesta visible al cliente se guarda como `quote_version` inmutable.
6. El cliente acepta una versión concreta.

Aceptar una cotización no modifica el catálogo ni permite al cliente alterar precio, alcance o servicios.

### Confirmación y activación

1. Un administrador revisa la versión aceptada.
2. El sistema crea una `order` con snapshot comercial.
3. El administrador ejecuta `ActivateOrder`.
4. El sistema crea un proyecto por cada ítem y unidad contratada.
5. Para cada proyecto provisiona workflow, formularios, hitos y estado inicial.
6. Registra auditoría, eventos y notificaciones en outbox.
7. Los proyectos aparecen automáticamente en `Mis Servicios`.

La operación es transaccional e idempotente. El administrador no crea proyectos ni formularios manualmente.

### Operación del proyecto

El cliente consulta cada proyecto de forma independiente, completa formularios, guarda respuestas, sube archivos y recibe actualizaciones. El equipo gestiona estado, hitos, solicitudes, archivos, mensajes y revisiones.

Los formularios, archivos y mensajes pertenecen al proyecto, no únicamente al cliente.

### Pagos futuros

Los pagos se integrarán mediante un puerto y un adaptador. Un webhook válido podrá registrar el pago y marcar la orden como elegible según la política comercial. No podrá activar proyectos directamente ni conceder acceso por una página de retorno.

## 4. Reglas de negocio obligatorias

- Un cliente puede tener múltiples cotizaciones.
- Una cotización puede contener múltiples servicios.
- Un cliente puede contratar el mismo servicio varias veces.
- Cada servicio/unidad contratada genera un proyecto independiente.
- Cada proyecto fija la versión de catálogo, workflow y formularios que recibió.
- Los proyectos no se crean desde el frontend.
- Solo `admin` tiene `activate_projects` en el MVP.
- Las respuestas, estados, pagos y acciones sensibles conservan historial.
- Un cliente nunca puede acceder a recursos de otra organización aunque conozca el UUID.
- El catálogo puede evolucionar sin modificar proyectos históricos.
- Los formularios nuevos se provisionan por configuración publicada, no mediante lógica `if/else` por servicio.

## 5. Fuentes de verdad

| Información | Fuente de verdad |
|---|---|
| Identidad | Proveedor de identidad y sesión server-side |
| Membresía y organización | PostgreSQL |
| Cotización vigente | `quote` + `quote_version` |
| Lo contratado | `order` + `order_items` |
| Proyecto activo | `service_instances` / agregado `Project` |
| Estado actual | Columna de estado del recurso |
| Historial | Eventos append-only y auditoría |
| Definición de formulario | `form_version.definition` |
| Respuestas | Revisiones de respuesta del proyecto |
| Archivos | Object storage privado + metadata PostgreSQL |
| Efectos externos | `outbox_events` |

## 6. Fallos y reintentos

- Una activación repetida debe devolver el resultado existente.
- Un formulario repetido debe ser seguro mediante revisión o idempotency key.
- Un webhook repetido debe registrarse una sola vez por proveedor/evento.
- Las notificaciones fallidas deben reintentarse fuera de la transacción principal.
- Los errores de autorización deben diferenciar sesión ausente (`401`) de permiso insuficiente (`403`).
- Los recursos que no deben revelarse pueden responder `404` para evitar enumeración.
