# Diseño de la API del backend

**Estado:** contrato técnico aprobado; ajustes de autoridad incorporados
**Fecha:** 2026-07-29
**Versión propuesta:** `v1`
**Implementación:** infraestructura de datos completada; endpoints no iniciados

Este documento define el contrato aprobado entre Astro y el futuro backend. No contiene endpoints implementados. El esquema, Auth, Storage y RLS que soportan el contrato ya están versionados en `supabase/`.

## 1. Decisiones generales

- La API propia es la única frontera entre frontend y dominio.
- Perfiles, organizaciones, cotizaciones, órdenes, proyectos, invitaciones, pagos, auditoría, webhooks y outbox no se exponen mediante Data API a `anon` ni `authenticated`.
- La única consulta directa permitida es la proyección pública `id, slug, name, description, version, published_at` de servicios publicados. Auth y Storage conservan sus APIs específicas con políticas.
- La API usa `/api/v1` como prefijo versionado.
- El dominio usa `Project`; la persistencia puede usar `service_instances`.
- La API expone únicamente `/projects`; no se duplicará con `/service-instances`.
- Los formularios se acceden dentro del proyecto; no habrá un CRUD global de respuestas que permita perder el alcance de ownership.
- Los comandos de negocio se expresan como acciones explícitas (`accept`, `activate`, `submit`, `transition`) porque validan estados y permisos, no son simples ediciones de columnas.
- No se exponen proveedores directamente desde el navegador.
- Las respuestas son DTOs versionables, no filas de PostgreSQL ni objetos SDK.
- Los pagos son opcionales en el MVP; un webhook futuro confirma evidencia de pago, pero no activa proyectos por sí solo.

## 2. Roles y capacidades

| Rol | Alcance | Capacidades relevantes |
|---|---|---|
| `anonymous` | Público | catálogo publicado, registro, login, recuperación |
| `client` | `own_user`/`own_org` | perfil, cotizaciones propias, aceptación, proyectos y formularios propios |
| `team` | `all_business` | operación de cotizaciones, órdenes, proyectos, formularios, archivos y mensajes |
| `admin` | `all_business` | capacidades de `team` más `activate_projects` y reconciliaciones sensibles |
| `system` | `system_only` | webhooks, jobs, outbox y casos de uso internos explícitos |

Las membresías cliente se resuelven desde `organization_members` (`owner|member`) y la autoridad interna desde `staff_members` (`team|admin`). Nunca se aceptan roles desde el body, query string, headers del cliente o `user_metadata`.

## 3. Autenticación y headers

### Sesiones de usuario

- Las rutas de usuario usan sesión server-side mediante cookie `HttpOnly`, `Secure` y `SameSite` adecuada.
- Las páginas `/app` y `/equipo` y sus datos son dinámicos y no deben cachearse como contenido público.
- Las mutaciones basadas en cookie validan CSRF mediante token y/o `Origin` allowlist.
- `Authorization: Bearer` podrá usarse para clientes no browser únicamente si el adaptador de runtime lo exige; no se mezclará sin una decisión documentada.

### Headers comunes

| Header | Tipo | Uso |
|---|---|---|
| `Content-Type` | `string` | `application/json` para comandos JSON |
| `Accept` | `string` | `application/json` |
| `X-Request-Id` | `string` opcional | correlation ID del cliente; el servidor valida formato y puede reemplazarlo |
| `Idempotency-Key` | `string` requerido en comandos repetibles | evita duplicados por reintento |
| `If-Match` | `string` opcional | control optimista de versión cuando aplique |
| `X-CSRF-Token` | `string` | requerido en mutaciones con cookie según el runtime |

Los webhooks no usan sesión de usuario. Usan la firma y headers específicos del proveedor sobre el cuerpo crudo.

## 4. Respuestas y errores comunes

### Respuesta exitosa

```json
{
  "data": {},
  "meta": {
    "requestId": "req_01JAPI00000000000000000000"
  },
  "error": null
}
```

Las listas usan:

```json
{
  "data": [],
  "meta": {
    "requestId": "req_01JAPI00000000000000000000",
    "page": 1,
    "pageSize": 25,
    "hasNext": false
  },
  "error": null
}
```

### Error

```json
{
  "data": null,
  "meta": {
    "requestId": "req_01JAPI00000000000000000000"
  },
  "error": {
    "code": "PROJECT_TRANSITION_NOT_ALLOWED",
    "message": "La operación no está permitida en el estado actual.",
    "details": []
  }
}
```

La API no devuelve stack traces, SQL, secrets, tokens ni PII innecesaria.

| Código | Uso |
|---:|---|
| `200` | consulta o comando completado |
| `201` | recurso creado |
| `202` | operación aceptada para procesamiento posterior |
| `204` | operación sin body |
| `302` | callback de autenticación o redirección controlada |
| `400` | request mal formado |
| `401` | no existe sesión válida |
| `403` | sesión válida sin permiso |
| `404` | recurso inexistente o que no debe revelarse |
| `409` | conflicto de estado, versión o idempotencia |
| `422` | datos estructuralmente válidos pero inválidos para el negocio |
| `429` | rate limit |
| `500` | error interno genérico |
| `502`/`503` | proveedor externo no disponible |

## 5. Paginación, filtros y concurrencia

- Query params estándar: `page`, `pageSize`, `sort`, `order`, `status`, `from`, `to`, `q`.
- `pageSize` permitido: `1..100`; valor por defecto `25`.
- Los filtros se validan por módulo; no existe filtrado arbitrario por columna.
- Las mutaciones de estado reciben `expectedVersion` o `If-Match` cuando exista riesgo de edición concurrente.
- Las respuestas de lista no incluyen campos sensibles ni relaciones completas innecesarias.
- Los IDs son UUID opacos.

## 6. DTOs principales

### `QuoteSummary`

```json
{
  "id": "uuid",
  "status": "awaiting_client_acceptance",
  "currentVersion": 2,
  "currency": "COP",
  "total": "4500000.00",
  "validUntil": "2026-08-31T23:59:59Z",
  "updatedAt": "2026-07-28T15:00:00Z"
}
```

### `ProjectSummary`

```json
{
  "id": "uuid",
  "service": { "id": "uuid", "slug": "landing-page", "name": "Landing Page" },
  "status": { "code": "awaiting_client_information", "label": "Esperando información" },
  "progress": 20,
  "pendingForms": 1,
  "nextAction": "Completar información de empresa",
  "updatedAt": "2026-07-28T15:00:00Z"
}
```

### `FormSummary`

```json
{
  "id": "uuid",
  "templateKey": "company-information",
  "title": "Información de la empresa",
  "status": "open",
  "required": true,
  "formVersion": 1,
  "updatedAt": "2026-07-28T15:00:00Z"
}
```

---

# 7. Módulo Auth

## POST `/api/v1/auth/register`

- **Descripción:** inicia el registro de un cliente.
- **Auth:** público; rate limited.
- **Body:** `email: string email`, `password: string` mínimo 12 caracteres, `displayName: string` 2–120, `organizationName: string` 2–160, `termsAccepted: boolean` obligatorio `true`.
- **Headers:** `Content-Type`, `X-Request-Id`; CSRF si el registro usa cookie.
- **Respuesta:** `202` con `{ "registrationId": "opaque", "next": "verify_email" }`.
- **Error:** `400 INVALID_REQUEST`, `422 TERMS_NOT_ACCEPTED`, `429 RATE_LIMITED`.
- **Validaciones:** normalizar email; bloquear passwords comprometidos; límites de longitud; no aceptar rol, `organizationId` ni permisos.
- **Reglas:** crear la identidad y la organización/membresía solo según el flujo de verificación del proveedor; no revelar si el correo ya existe.
- **Dependencias:** `IdentityProvider`, `Profile`, `Organization`, `OrganizationMember`, auditoría mínima.
- **Casos especiales:** reintentos deben devolver respuesta genérica; no crear organizaciones duplicadas; no registrar password ni token.

## POST `/api/v1/auth/login`

- **Descripción:** inicia sesión server-side.
- **Auth:** público; rate limited.
- **Body:** `email: string email`, `password: string`.
- **Respuesta:** `200` con sesión resumida y cookie; `{ "user": { "id": "uuid", "roles": ["client"] }, "redirectTo": "/app" }`.
- **Error:** `401 INVALID_CREDENTIALS`, `423 ACCOUNT_LOCKED`, `429 RATE_LIMITED`.
- **Validaciones:** formato, límites, MFA si aplica; respuesta indistinguible para email inexistente.
- **Reglas:** validar identidad en proveedor, crear/refrescar cookie segura y obtener membresías desde backend.
- **Dependencias:** `IdentityProvider`, sesiones, perfiles y membresías.
- **Casos especiales:** sesión expirada, refresh fallido, múltiples pestañas y MFA administrativa.

## POST `/api/v1/auth/logout`

- **Descripción:** invalida la sesión actual.
- **Auth:** requerida; cualquier usuario autenticado.
- **Body:** ninguno.
- **Respuesta:** `204` y limpieza de cookie.
- **Error:** `401 SESSION_REQUIRED`.
- **Validaciones:** verificar sesión y CSRF.
- **Reglas:** invalidar sesión en proveedor y limpiar cookies; no confiar solo en borrar datos del navegador.
- **Dependencias:** sesión e `IdentityProvider`.
- **Casos especiales:** logout repetido debe ser seguro.

## GET `/api/v1/auth/session`

- **Descripción:** devuelve el actor y el contexto de sesión actual.
- **Auth:** requerida.
- **Params:** ninguno.
- **Respuesta:** `200` con `{ "user": { "id": "uuid", "email": "masked-or-authorized" }, "memberships": [], "capabilities": [] }`.
- **Error:** `401 SESSION_REQUIRED`.
- **Validaciones:** consultar sesión vigente en servidor; no aceptar identidad desde query.
- **Reglas:** las capabilities se calculan desde membresías cliente y autoridad staff controladas por servidor.
- **Dependencias:** `IdentityProvider`, `Profile`, `OrganizationMember`, `StaffMember`.
- **Casos especiales:** token válido localmente pero sesión revocada debe rechazarse.

## GET `/api/v1/auth/callback`

- **Descripción:** procesa callback PKCE del proveedor.
- **Auth:** flujo de proveedor; no requiere sesión previa.
- **Query:** `code: string`, `state: string`, `returnTo?: string` solo path interno.
- **Respuesta:** `302` a `/app`, `/equipo` o path interno allowlisted.
- **Error:** `400 CALLBACK_INVALID`, `409 CALLBACK_REPLAY`, `302` a error genérico.
- **Validaciones:** allowlist exacta, intercambio de código una sola vez, `state`, PKCE y `returnTo` interno.
- **Reglas:** crear/validar perfil y membresía según el flujo; nunca conceder proyecto por query string.
- **Dependencias:** `IdentityProvider`, perfiles, membresías, sesión.
- **Casos especiales:** callback repetido, código expirado, URL externa y navegador sin cookies.

## POST `/api/v1/auth/recovery`

- **Descripción:** solicita recuperación de cuenta.
- **Auth:** público; rate limited.
- **Body:** `email: string email`, `returnTo?: string` path interno.
- **Respuesta:** `202` siempre con `{ "message": "Si la cuenta existe, se enviaron instrucciones." }`.
- **Error:** `400 INVALID_REQUEST`, `429 RATE_LIMITED`.
- **Validaciones:** email y return path allowlisted; no registrar token.
- **Reglas:** no revelar existencia de cuenta; usar enlace temporal de un solo uso.
- **Dependencias:** `IdentityProvider`, notificación.
- **Casos especiales:** email inexistente y repetición deben tener respuesta equivalente.

## POST `/api/v1/auth/reset`

- **Descripción:** completa recuperación con token temporal.
- **Auth:** token temporal del proveedor.
- **Body:** `token: string`, `newPassword: string` mínimo 12.
- **Respuesta:** `204`.
- **Error:** `400 INVALID_TOKEN`, `422 WEAK_PASSWORD`, `429 RATE_LIMITED`.
- **Validaciones:** token de un solo uso, password comprometido y expiración.
- **Reglas:** invalidar sesiones anteriores según política y no almacenar token.
- **Dependencias:** `IdentityProvider`.
- **Casos especiales:** token repetido, expirado o callback manipulado.

---

# 8. Módulo Users, Profile y Organizations

## GET `/api/v1/me`

- **Descripción:** devuelve perfil y resumen de pertenencias del usuario actual.
- **Auth:** requerida; cliente, team o admin.
- **Params:** ninguno.
- **Respuesta:** `200` con `{ "id": "uuid", "displayName": "...", "email": "...", "memberships": [] }`.
- **Error:** `401 SESSION_REQUIRED`.
- **Validaciones:** identidad server-side.
- **Reglas:** devolver solo campos permitidos.
- **Dependencias:** `Profile`, `OrganizationMember`, `Organization`.
- **Casos especiales:** perfil incompleto se devuelve con estado de onboarding, no se crea desde el frontend.

## PATCH `/api/v1/me`

- **Descripción:** actualiza campos permitidos del perfil propio.
- **Auth:** requerida; `profile:update`.
- **Body:** `displayName?: string` 2–120, `phone?: string` formato E.164 o local normalizado, `jobTitle?: string` 0–120, `notificationPreferences?: object` allowlist.
- **Respuesta:** `200` con perfil actualizado.
- **Error:** `401`, `422 PROFILE_FIELD_INVALID`, `409 PROFILE_VERSION_CONFLICT`.
- **Validaciones:** rechazar campos desconocidos; no aceptar `role`, `organizationId`, `userId`, email o estado de verificación.
- **Reglas:** aplicar `If-Match`/versión si existe concurrencia; auditar cambios sensibles.
- **Dependencias:** `Profile`, sesión, auditoría.
- **Casos especiales:** cambio de email va por flujo del proveedor, no por este endpoint.

## GET `/api/v1/me/organizations`

- **Descripción:** lista organizaciones del usuario actual.
- **Auth:** requerida.
- **Query:** `page`, `pageSize`.
- **Respuesta:** `200` lista de organizaciones y membresías.
- **Error:** `401`.
- **Validaciones:** paginación estándar.
- **Reglas:** solo membresías activas o históricas permitidas; no exponer organizaciones ajenas.
- **Dependencias:** `OrganizationMember`, `Organization`.
- **Casos especiales:** el MVP puede tener una organización; el contrato soporta múltiples.

## GET `/api/v1/organizations/{organizationId}`

- **Descripción:** consulta una organización autorizada.
- **Auth:** cliente miembro de la organización; team/admin interno.
- **Path:** `organizationId: uuid`.
- **Respuesta:** `200` resumen de organización.
- **Error:** `401`, `403`, `404 ORGANIZATION_NOT_FOUND`.
- **Validaciones:** UUID y pertenencia real.
- **Reglas:** cliente recibe solo campos permitidos; team/admin recibe alcance operativo.
- **Dependencias:** `Organization`, `OrganizationMember`, RLS.
- **Casos especiales:** responder `404` cuando revelar existencia produzca fuga de tenant.

## PATCH `/api/v1/organizations/{organizationId}`

- **Descripción:** actualiza datos editables de la organización.
- **Auth:** cliente con `organization:update_limited`; team/admin con `organization:manage`.
- **Path:** `organizationId: uuid`; **Body:** `name?: string` 2–160, `contactPhone?: string`, `billingData?: object` según allowlist.
- **Respuesta:** `200` organización actualizada.
- **Error:** `403`, `404`, `409 ORGANIZATION_VERSION_CONFLICT`, `422 ORGANIZATION_FIELD_INVALID`.
- **Validaciones:** no aceptar `ownerId`, estado, roles ni organización nueva desde el cliente.
- **Reglas:** auditar cambios y aplicar scope de membresía.
- **Dependencias:** `Organization`, membresías, auditoría.
- **Casos especiales:** cambio de datos fiscales puede requerir revisión interna.

## GET `/api/v1/organizations/{organizationId}/members`

- **Descripción:** lista miembros de una organización.
- **Auth:** team/admin; cliente solo con lectura limitada si se aprueba esa capacidad.
- **Path:** `organizationId: uuid`; **Query:** `page`, `pageSize`, `status`.
- **Respuesta:** `200` miembros sin secretos.
- **Error:** `403`, `404`.
- **Validaciones:** filtros allowlisted.
- **Reglas:** roles y estado se leen desde membresías reales; no desde metadata editable.
- **Dependencias:** `OrganizationMember`, `Profile`, RLS.
- **Casos especiales:** ningún usuario puede autoelevarse o eliminar controles propios.

## POST `/api/v1/organizations/{organizationId}/invitations`

- **Descripción:** invita un miembro cliente adicional a una organización.
- **Auth:** `owner` autorizado o team/admin con `membership:invite`.
- **Path:** `organizationId: uuid`; **Body:** `email: string email`, `role: owner|member`, `expiresInHours: integer 1–168`.
- **Respuesta:** `202` con invitación opaca y expiración.
- **Error:** `403`, `409 INVITATION_EXISTS`, `422 ROLE_NOT_ALLOWED`, `429`.
- **Validaciones:** rechazar `team`, `admin` y cualquier capability global; validar email y expiración.
- **Reglas:** no enviar secretos en response; notificar mediante outbox; registrar auditoría.
- **Dependencias:** organización, membresía, identidad, notificaciones, outbox.
- **Casos especiales:** invitación repetida se renueva o se rechaza según policy, nunca duplica membresías.

## POST `/api/v1/staff/invitations`

- **Descripción:** invita personal interno con autoridad global.
- **Auth:** solo `admin` con `staff:invite`.
- **Body:** `email: string email`, `role: team|admin`, `expiresInHours: integer 1–168`.
- **Respuesta:** `202` con invitación opaca y expiración.
- **Error:** `403`, `409 INVITATION_EXISTS`, `422 ROLE_NOT_ALLOWED`, `429`.
- **Validaciones:** autoridad del actor desde `staff_members`; email, rol y expiración allowlisted.
- **Reglas:** nunca asociar esta autoridad a `organization_members`; token hasheado, auditoría y notificación por outbox.
- **Dependencias:** identidad, `staff_invitations`, `staff_members`, auditoría y outbox.
- **Casos especiales:** ningún `owner` de organización puede invitar staff.

## POST `/api/v1/invitations/{invitationId}/accept`

- **Descripción:** acepta una invitación válida.
- **Auth:** sesión verificada del email invitado.
- **Path:** `invitationId: uuid`; **Body:** `token: string` o código gestionado por proveedor.
- **Respuesta:** `200` membresía creada/activada.
- **Error:** `401`, `403 INVITATION_EMAIL_MISMATCH`, `409 INVITATION_ALREADY_USED`, `410 INVITATION_EXPIRED`.
- **Validaciones:** token, email, expiración y uso único.
- **Reglas:** crear membresía con rol preautorizado; no cambiar organización desde el body.
- **Dependencias:** identidad, invitación, organización, membresía.
- **Casos especiales:** aceptar dos veces es seguro y no duplica membresía.

## GET `/api/v1/users` y GET `/api/v1/users/{userId}`

- **Descripción:** búsqueda y detalle operativo de usuarios.
- **Auth:** team/admin; `users:read`.
- **Path:** `userId: uuid` en detalle; **Query:** `q?: string` 2–100, `organizationId?: uuid`, `role?: string`, `page`, `pageSize`.
- **Respuesta:** `200` usuarios con perfil y membresías autorizadas.
- **Error:** `403`, `404`.
- **Validaciones:** filtros y campos allowlisted; no búsquedas arbitrarias por datos sensibles.
- **Reglas:** no mostrar credenciales, tokens, metadata privada ni secretos.
- **Dependencias:** `Profile`, organizaciones, membresías.
- **Casos especiales:** limitar resultados y aplicar rate limit para evitar enumeración.

---

# 9. Módulo Services / Catalog

## GET `/api/v1/services`

- **Descripción:** lista servicios publicados o catálogo interno.
- **Auth:** público para publicados; team/admin para borradores.
- **Query:** `q?: string`, `status?: published|draft|archived`, `page`, `pageSize`.
- **Respuesta:** `200` lista de servicios con slug, nombre, descripción y configuración pública.
- **Error:** `400 INVALID_FILTER`, `401/403` para filtros internos.
- **Validaciones:** no exponer configuración interna a público.
- **Reglas:** público solo ve servicios publicados; team/admin puede filtrar estados internos.
- **Dependencias:** `ServiceDefinition`, RLS/policy de publicación.
- **Casos especiales:** un servicio archivado no desaparece de proyectos históricos.

## GET `/api/v1/services/{serviceId}`

- **Descripción:** detalle de un servicio del catálogo.
- **Auth:** público si publicado; team/admin para cualquier estado.
- **Path:** `serviceId: uuid`.
- **Respuesta:** `200` servicio y resumen de formularios/workflow visible según actor.
- **Error:** `404 SERVICE_NOT_FOUND`, `403`.
- **Validaciones:** UUID y publicación.
- **Reglas:** no devolver secretos ni configuración de infraestructura.
- **Dependencias:** `ServiceDefinition`, `WorkflowDefinition`, `FormTemplate`.
- **Casos especiales:** no cambiará la configuración de proyectos existentes.

## POST `/api/v1/services`

- **Descripción:** crea una definición de servicio.
- **Auth:** team/admin con `catalog:manage`.
- **Body:** `slug: string` lower-kebab 3–80, `name: string` 2–120, `description: string` 0–4000, `public: boolean`, `configuration: object` validado.
- **Respuesta:** `201` servicio en `draft`.
- **Error:** `403`, `409 SERVICE_SLUG_EXISTS`, `422 SERVICE_CONFIGURATION_INVALID`.
- **Validaciones:** slug único, campos obligatorios, configuración contra schema.
- **Reglas:** crear en borrador; no publicar workflow/formulario inexistente.
- **Dependencias:** `ServiceDefinition`, auditoría.
- **Casos especiales:** repetir `Idempotency-Key` devuelve el servicio existente.

## PATCH `/api/v1/services/{serviceId}`

- **Descripción:** modifica configuración editable de un servicio.
- **Auth:** team/admin con `catalog:manage`.
- **Path:** `serviceId: uuid`; **Body:** campos editables y `expectedVersion: integer`.
- **Respuesta:** `200` servicio actualizado.
- **Error:** `403`, `404`, `409 SERVICE_VERSION_CONFLICT`, `422`.
- **Validaciones:** rechazar cambios que invaliden proyectos existentes; campos allowlisted.
- **Reglas:** cambios publicados crean nueva versión cuando afecten workflow o formularios.
- **Dependencias:** catálogo, workflows, formularios, auditoría.
- **Casos especiales:** no borrar físicamente un servicio usado históricamente.

## POST `/api/v1/services/{serviceId}/publish`

- **Descripción:** publica un servicio listo para catálogo.
- **Auth:** admin con `catalog:publish`.
- **Path:** `serviceId: uuid`; **Body:** `expectedVersion: integer`.
- **Respuesta:** `200` servicio publicado.
- **Error:** `403`, `409 PUBLISH_CONFLICT`, `422 SERVICE_NOT_READY`.
- **Validaciones:** nombre, slug, workflow publicado y formularios válidos.
- **Reglas:** solo servicios completos son visibles públicamente; auditar actor y versión.
- **Dependencias:** servicio, workflow, formularios.
- **Casos especiales:** publicación repetida es idempotente.

## GET `/api/v1/services/{serviceId}/workflow-versions`

- **Descripción:** lista workflows del servicio.
- **Auth:** team/admin; cliente solo recibe el workflow fijado de su proyecto mediante `/projects`.
- **Path:** `serviceId: uuid`; **Query:** `status`, `page`, `pageSize`.
- **Respuesta:** `200` versiones y estado de publicación.
- **Error:** `403`, `404`.
- **Validaciones:** paginación y filtros allowlisted.
- **Reglas:** una versión publicada es inmutable para nuevos proyectos.
- **Dependencias:** `ServiceDefinition`, `WorkflowDefinition`.
- **Casos especiales:** no eliminar versiones usadas por proyectos.

## POST `/api/v1/services/{serviceId}/workflow-versions`

- **Descripción:** crea una versión de workflow.
- **Auth:** team/admin con `workflow:manage`.
- **Body:** `states: array`, `transitions: array`, `version: integer`, `configuration: object`.
- **Respuesta:** `201` workflow en borrador.
- **Error:** `403`, `409 WORKFLOW_VERSION_EXISTS`, `422 WORKFLOW_INVALID`.
- **Validaciones:** estado inicial único, transiciones existentes, estados terminales, capabilities válidas y ausencia de ciclos prohibidos según policy.
- **Reglas:** validar máquina de estados al crear; no depender de `if/else` por servicio.
- **Dependencias:** servicio, catálogo, auditoría.
- **Casos especiales:** una versión usada no se modifica; se crea otra.

## POST `/api/v1/services/{serviceId}/workflow-versions/{versionId}/publish`

- **Descripción:** publica un workflow validado.
- **Auth:** admin con `workflow:publish`.
- **Path:** `serviceId: uuid`, `versionId: uuid`.
- **Respuesta:** `200` workflow publicado.
- **Error:** `403`, `404`, `409 WORKFLOW_ALREADY_PUBLISHED`, `422 WORKFLOW_INVALID`.
- **Validaciones:** pertenencia al servicio y definición completa.
- **Reglas:** proyectos existentes conservan su versión; futuros proyectos usan la publicada.
- **Dependencias:** servicio, workflow, auditoría.
- **Casos especiales:** publicación repetida devuelve versión actual.

## GET `/api/v1/services/{serviceId}/form-templates`

- **Descripción:** lista formularios configurados para un servicio.
- **Auth:** team/admin; cliente solo ve formularios ya provisionados en su proyecto.
- **Path:** `serviceId: uuid`; **Query:** `status`, `page`, `pageSize`.
- **Respuesta:** `200` plantillas sin respuestas de clientes.
- **Error:** `403`, `404`.
- **Validaciones:** pertenencia y filtros.
- **Reglas:** las plantillas son reusables; la instancia del cliente se crea en activación.
- **Dependencias:** servicio, `FormTemplate`, `FormVersion`.
- **Casos especiales:** no exponer `definition` privada a clientes fuera de un proyecto.

## POST `/api/v1/services/{serviceId}/form-templates`

- **Descripción:** crea una plantilla de formulario.
- **Auth:** team/admin con `forms:manage`.
- **Body:** `key: string` lower-kebab, `title: string` 2–160, `required: boolean`, `stage: string`, `sortOrder: integer >=0`.
- **Respuesta:** `201` plantilla en borrador.
- **Error:** `403`, `409 FORM_TEMPLATE_KEY_EXISTS`, `422 FORM_TEMPLATE_INVALID`.
- **Validaciones:** key única por servicio, etapa permitida y límites.
- **Reglas:** no crear formularios directamente en un proyecto desde la UI.
- **Dependencias:** servicio, plantilla, auditoría.
- **Casos especiales:** cambiar key después de uso requiere nueva plantilla o alias documentado.

## POST `/api/v1/services/{serviceId}/form-templates/{templateId}/versions`

- **Descripción:** crea una versión de definición de formulario.
- **Auth:** team/admin con `forms:manage`.
- **Path:** `serviceId: uuid`, `templateId: uuid`; **Body:** `version: integer`, `definition: object`, `validationSchema?: object`.
- **Respuesta:** `201` versión de formulario en borrador.
- **Error:** `403`, `404`, `409 FORM_VERSION_EXISTS`, `422 FORM_DEFINITION_INVALID`.
- **Validaciones:** tipos permitidos, campos únicos, tamaño máximo, reglas compatibles y sin scripts/HTML ejecutable.
- **Reglas:** la definición es inmutable después de publicar; respuestas validan contra la versión fijada.
- **Dependencias:** servicio, plantilla, `FormVersion`.
- **Casos especiales:** no cambiar versión de formularios ya provisionados.

## POST `/api/v1/services/{serviceId}/form-templates/{templateId}/versions/{versionId}/publish`

- **Descripción:** publica la versión de formulario.
- **Auth:** admin con `forms:publish`.
- **Path:** `serviceId: uuid`, `templateId: uuid`, `versionId: uuid`.
- **Respuesta:** `200` versión publicada.
- **Error:** `403`, `404`, `409 FORM_VERSION_ALREADY_PUBLISHED`, `422 FORM_DEFINITION_INVALID`.
- **Validaciones:** schema completo y compatible con el servicio.
- **Reglas:** solo proyectos futuros reciben automáticamente esta versión.
- **Dependencias:** catálogo, plantilla, versión, auditoría.
- **Casos especiales:** publicación repetida es idempotente.

---

# 10. Módulo Quotes

## GET `/api/v1/quotes`

- **Descripción:** lista cotizaciones del actor.
- **Auth:** cliente con `quote:read` para `own_org`; team/admin con `quote:read_all`.
- **Query:** `status`, `organizationId` solo interno, `page`, `pageSize`, `sort`, `from`, `to`.
- **Respuesta:** `200` lista de `QuoteSummary`.
- **Error:** `401`, `403`, `400 INVALID_FILTER`.
- **Validaciones:** filtros allowlisted y scope interno.
- **Reglas:** cliente nunca puede cambiar organización con query; team/admin filtra según policy.
- **Dependencias:** `Quote`, `QuoteVersion`, organización, RLS.
- **Casos especiales:** una organización sin cotizaciones devuelve lista vacía, no error.

## POST `/api/v1/quotes`

- **Descripción:** crea solicitud de cotización.
- **Auth:** cliente autenticado con `quote:create`; opcionalmente team/admin para crear en nombre de una organización autorizada.
- **Body:** `items: array[1..20]` con `serviceId: uuid`, `quantity: integer 1..99`, `customerNote?: string 0..4000`; `requestedStartDate?: date`.
- **Respuesta:** `201` quote en `pending_review` con ítems iniciales.
- **Error:** `401`, `403`, `422 SERVICE_NOT_AVAILABLE`, `429`.
- **Validaciones:** servicios publicados, cantidades positivas, límites, organización derivada de sesión.
- **Reglas:** no aceptar precio final ni estado desde el cliente; registrar actor y timestamp.
- **Dependencias:** organización, catálogo, `Quote`, `QuoteVersion` inicial opcional.
- **Casos especiales:** `Idempotency-Key` evita duplicar solicitud; un servicio repetido puede consolidarse o conservar líneas según policy.

## GET `/api/v1/quotes/{quoteId}`

- **Descripción:** detalle de una cotización autorizada.
- **Auth:** cliente dueño de organización; team/admin autorizado.
- **Path:** `quoteId: uuid`.
- **Respuesta:** `200` cotización, estado, versión vigente y timeline permitido.
- **Error:** `401`, `403`, `404 QUOTE_NOT_FOUND`.
- **Validaciones:** UUID y ownership real.
- **Reglas:** el cliente no ve notas internas ni precios/metadata restringidos.
- **Dependencias:** quote, versiones, organización, auditoría.
- **Casos especiales:** ocultar existencia de otra organización con `404`.

## GET `/api/v1/quotes/{quoteId}/versions` y GET `/api/v1/quotes/{quoteId}/versions/{versionId}`

- **Descripción:** lista o consulta una versión de cotización.
- **Auth:** cliente de la organización; team/admin.
- **Path:** `quoteId: uuid`, `versionId: uuid` en detalle; **Query:** `page`, `pageSize` en lista.
- **Respuesta:** `200` versiones inmutables con ítems, snapshots, total, moneda, vigencia y estado.
- **Error:** `403`, `404 QUOTE_VERSION_NOT_FOUND`.
- **Validaciones:** versión debe pertenecer a la cotización.
- **Reglas:** el cliente solo puede aceptar una versión publicada y vigente.
- **Dependencias:** quote, `QuoteVersion`, `QuoteVersionItem`.
- **Casos especiales:** versiones históricas no se editan ni se eliminan.

## POST `/api/v1/quotes/{quoteId}/versions`

- **Descripción:** crea una nueva versión negociada.
- **Auth:** team/admin con `quote:manage`.
- **Path:** `quoteId: uuid`; **Body:** `items: array[1..50]` con `serviceId`, `quantity`, `scopeSnapshot: string 0..10000`, `unitAmount: decimal >=0`, `currency: string ISO-4217`, `validUntil: datetime`, `notes?: string`.
- **Respuesta:** `201` versión en `draft`.
- **Error:** `403`, `404`, `409 QUOTE_NOT_EDITABLE`, `422 QUOTE_VERSION_INVALID`.
- **Validaciones:** moneda, importes exactos, vigencia futura, servicios válidos, total calculado en servidor.
- **Reglas:** nunca tomar total enviado como fuente; congelar snapshot y generar número incremental.
- **Dependencias:** quote, catálogo, ítems, auditoría.
- **Casos especiales:** concurrencia protegida por versión de quote; no modificar versión aceptada.

## POST `/api/v1/quotes/{quoteId}/versions/{versionId}/publish`

- **Descripción:** publica una versión para aceptación.
- **Auth:** team/admin con `quote:publish`.
- **Path:** `quoteId: uuid`, `versionId: uuid`; **Body:** `expectedVersion: integer`.
- **Respuesta:** `200` versión en `awaiting_client_acceptance` y notificación en outbox.
- **Error:** `403`, `404`, `409 QUOTE_VERSION_CONFLICT`, `422 QUOTE_VERSION_INVALID`.
- **Validaciones:** ítems, totales, vigencia y versión perteneciente a la quote.
- **Reglas:** publicar una nueva versión reemplaza la vigente para aceptación, pero no borra historial.
- **Dependencias:** quote, versión, notificación, outbox, auditoría.
- **Casos especiales:** repetir publicación devuelve versión ya publicada.

## POST `/api/v1/quotes/{quoteId}/versions/{versionId}/accept`

- **Descripción:** acepta una versión concreta.
- **Auth:** cliente de la organización con `quote:accept`.
- **Path:** `quoteId: uuid`, `versionId: uuid`; **Body:** `termsAccepted: true`, `acceptanceNote?: string 0..2000`.
- **Headers:** `Idempotency-Key` requerido.
- **Respuesta:** `200` quote aceptada y referencia a `orderId` si ya fue creada; ejemplo `{ "quoteId": "uuid", "version": 2, "status": "accepted", "orderId": null }`.
- **Error:** `403`, `404`, `409 QUOTE_VERSION_NOT_ACCEPTABLE`, `422 TERMS_NOT_ACCEPTED`.
- **Validaciones:** versión publicada, no expirada, pertenece a quote propia y términos explícitos.
- **Reglas:** el cliente no puede modificar ítems; registrar actor, IP/correlation ID y timestamp.
- **Dependencias:** quote, versión, organización, auditoría.
- **Casos especiales:** repetir la misma aceptación devuelve el resultado; aceptar otra versión después requiere política explícita.

## POST `/api/v1/quotes/{quoteId}/reject`

- **Descripción:** rechaza una cotización o versión.
- **Auth:** cliente dueño o team/admin con capability correspondiente.
- **Path:** `quoteId: uuid`; **Body:** `reason: string` 1–2000.
- **Respuesta:** `200` quote en `rejected`.
- **Error:** `403`, `404`, `409 QUOTE_NOT_REJECTABLE`, `422 REASON_REQUIRED`.
- **Validaciones:** estado permitido y motivo.
- **Reglas:** registrar actor; nunca borrar versiones.
- **Dependencias:** quote, auditoría, notificación.
- **Casos especiales:** rechazo repetido es idempotente si conserva mismo motivo o devuelve conflicto claro.

## POST `/api/v1/quotes/{quoteId}/cancel`

- **Descripción:** cancela una cotización no aceptada.
- **Auth:** team/admin; cliente solo si la policy lo permite antes de revisión.
- **Path:** `quoteId: uuid`; **Body:** `reason: string 1–2000`.
- **Respuesta:** `200` quote cancelada.
- **Error:** `403`, `404`, `409 QUOTE_NOT_CANCELLABLE`.
- **Validaciones:** estado actual y motivo.
- **Reglas:** no cancela una orden activa ni borra historial; esos son casos de orden/proyecto separados.
- **Dependencias:** quote, auditoría, outbox.
- **Casos especiales:** operación repetida devuelve estado actual.

---

# 11. Módulo Orders y Payments

## GET `/api/v1/orders`

- **Descripción:** lista órdenes visibles al actor.
- **Auth:** cliente `own_org`; team/admin `order:read_all`.
- **Query:** `status`, `organizationId` solo interno, `page`, `pageSize`.
- **Respuesta:** `200` órdenes resumidas con estado de activación y total autorizado.
- **Error:** `401`, `403`, `400 INVALID_FILTER`.
- **Validaciones:** scope y filtros.
- **Reglas:** cliente no ve datos completos de tarjeta/proveedor.
- **Dependencias:** órdenes, organizaciones, pagos resumidos.
- **Casos especiales:** listas vacías son válidas.

## GET `/api/v1/orders/{orderId}`

- **Descripción:** detalle de orden y sus ítems.
- **Auth:** cliente de organización; team/admin.
- **Path:** `orderId: uuid`.
- **Respuesta:** `200` order, quoteVersion, items, estado y proyectos asociados según permiso.
- **Error:** `403`, `404 ORDER_NOT_FOUND`.
- **Validaciones:** ownership y UUID.
- **Reglas:** snapshots son de solo lectura.
- **Dependencias:** order, quote version, order items, proyectos.
- **Casos especiales:** ocultar orden de otro tenant con `404`.

## POST `/api/v1/orders`

- **Descripción:** crea una orden desde una cotización aceptada.
- **Auth:** team/admin con `order:create`.
- **Body:** `quoteId: uuid`, `quoteVersionId: uuid`.
- **Headers:** `Idempotency-Key` requerido.
- **Respuesta:** `201` orden en `pending_activation`.
- **Error:** `403`, `404`, `409 ORDER_ALREADY_EXISTS`, `422 QUOTE_NOT_ACCEPTED`.
- **Validaciones:** versión exacta aceptada, quote vigente y snapshots calculados desde backend.
- **Reglas:** copiar ítems, cantidades, moneda, alcance y precios; no recalcular desde catálogo actual.
- **Dependencias:** quote, versión, order, order items, auditoría.
- **Casos especiales:** repetir con misma idempotency key devuelve la orden; otra versión produce conflicto.

## POST `/api/v1/orders/{orderId}/activate`

- **Descripción:** confirma y activa una orden, creando los proyectos.
- **Auth:** solo `admin` con `activate_projects`.
- **Path:** `orderId: uuid`; **Body:** `reason: string` 1–2000, `expectedVersion: integer`, `paymentPolicyOverride?: string` solo si una policy futura lo permite.
- **Headers:** `Idempotency-Key` requerido.
- **Respuesta:** `200` orden activa con `{ "projects": [{ "id": "uuid", "service": "landing-page" }] }`.
- **Error:** `403 ACTIVATION_FORBIDDEN`, `404`, `409 ORDER_ALREADY_ACTIVE|ACTIVATION_CONFLICT`, `422 ACTIVATION_PRECONDITION_FAILED`.
- **Validaciones:** sesión, capability, quote aceptada, versión, payment policy si aplica, cantidades, workflow y formularios publicados.
- **Reglas:** en una transacción: bloquear orden, crear un proyecto por ítem/unidad, fijar workflow, provisionar formularios/hitos, registrar evento/auditoría y outbox. No crear nada desde frontend ni mediante webhook.
- **Dependencias:** order, items, catálogo, workflows, plantillas, proyectos, formularios, hitos, auditoría, outbox.
- **Casos especiales:** reintento devuelve proyectos existentes; concurrencia usa lock/constraint; cualquier fallo hace rollback completo.

No existe `POST /projects` público. La única creación ordinaria de proyectos ocurre mediante esta operación.

## POST `/api/v1/orders/{orderId}/cancel`

- **Descripción:** cancela una orden no activa o aplica reversión autorizada.
- **Auth:** team/admin según policy; admin para órdenes activas o con pagos.
- **Path:** `orderId: uuid`; **Body:** `reason: string 1–2000`.
- **Respuesta:** `200` orden cancelada o en revisión.
- **Error:** `403`, `404`, `409 ORDER_NOT_CANCELLABLE`, `422 REASON_REQUIRED`.
- **Validaciones:** estado, pagos, proyectos y capability.
- **Reglas:** no borrar proyectos ni pagos; una reversión debe generar auditoría y workflow específico.
- **Dependencias:** order, payments, projects, audit.
- **Casos especiales:** reembolso/chargeback futuro puede requerir revisión manual.

## GET `/api/v1/orders/{orderId}/payments`

- **Descripción:** consulta resumen de pagos de una orden.
- **Auth:** cliente de organización con datos limitados; team/admin completo.
- **Path:** `orderId: uuid`.
- **Respuesta:** `200` intentos con proveedor, estado, importe, moneda y timestamps; nunca tarjeta.
- **Error:** `403`, `404`.
- **Validaciones:** ownership.
- **Reglas:** ocultar referencias sensibles según rol.
- **Dependencias:** order, payments, RLS.
- **Casos especiales:** si pagos aún no existen devuelve lista vacía.

## POST `/api/v1/orders/{orderId}/payment-attempts`

- **Descripción:** crea un intento de pago futuro.
- **Auth:** team/admin o sistema según integración; `payment:create`.
- **Path:** `orderId: uuid`; **Body:** `provider: string allowlist`, `returnPath?: string` interno, `amountExpected?: decimal` solo informativo y nunca fuente de verdad.
- **Headers:** `Idempotency-Key` requerido.
- **Respuesta:** `201` intento y URL hospedada del proveedor si aplica.
- **Error:** `403`, `404`, `409 PAYMENT_ATTEMPT_EXISTS`, `422 PAYMENT_CONFIGURATION_INVALID`, `502 PROVIDER_UNAVAILABLE`.
- **Validaciones:** importe/moneda calculados desde order, provider allowlist, timeout y return path interno.
- **Reglas:** no guardar tarjeta ni aceptar precio desde frontend; usar `PaymentProvider`.
- **Dependencias:** order, payment, proveedor, secrets server-side.
- **Casos especiales:** proveedor caído no cambia orden; reintento con misma key es seguro.

## POST `/api/v1/webhooks/payments/{provider}`

- **Descripción:** recibe webhook de proveedor de pagos.
- **Auth:** no sesión; firma del proveedor obligatoria.
- **Path:** `provider: string allowlist`; **Headers:** firma, timestamp y event ID según proveedor; **Body:** cuerpo crudo.
- **Respuesta:** `200`/`202` `{ "received": true }` incluso para evento duplicado válido.
- **Error:** `400 WEBHOOK_INVALID`, `401 WEBHOOK_SIGNATURE_INVALID`, `409 WEBHOOK_REPLAY`, `503 WEBHOOK_RETRYABLE`.
- **Validaciones:** leer cuerpo crudo, verificar firma/timestamp/event ID antes de parsear, tamaño máximo, importe, moneda y referencia.
- **Reglas:** persistir `WebhookEvent` con unique `(provider, externalEventId)`; actualizar pago y elegibilidad de orden; nunca activar proyectos directamente.
- **Dependencias:** payments, orders, webhook events, auditoría, outbox.
- **Casos especiales:** duplicado válido responde exitosamente sin repetir mutaciones; evento fuera de orden queda pendiente.

## POST `/api/v1/payment-events/{eventId}/reconcile`

- **Descripción:** resuelve manualmente un evento de pago pendiente.
- **Auth:** admin con `payments:reconcile`.
- **Path:** `eventId: uuid`; **Body:** `decision: accept|reject|retry`, `reason: string 1–2000`.
- **Respuesta:** `200` evento y pago/orden actualizados.
- **Error:** `403`, `404`, `409 EVENT_ALREADY_RESOLVED`, `422 DECISION_INVALID`.
- **Validaciones:** evento existente, firma previamente validada o revisión documentada.
- **Reglas:** no editar directamente base; auditar actor y decisión; no saltar `ActivateOrder`.
- **Dependencias:** webhook event, payment, order, audit.
- **Casos especiales:** una resolución repetida no debe duplicar cambios.

---

# 12. Módulo Projects

## GET `/api/v1/projects`

- **Descripción:** lista proyectos autorizados.
- **Auth:** cliente `project:read_own`; team/admin `project:read_all`.
- **Query:** `status`, `serviceId`, `organizationId` solo interno, `q` solo interno, `page`, `pageSize`, `sort`.
- **Respuesta:** `200` lista de `ProjectSummary`.
- **Error:** `401`, `403`, `400 INVALID_FILTER`.
- **Validaciones:** filtros allowlisted y scope.
- **Reglas:** cliente solo ve proyectos de sus organizaciones; no se acepta organization ID para ampliar acceso.
- **Dependencias:** projects, service catalog, organization members, RLS.
- **Casos especiales:** un cliente sin activaciones recibe lista vacía.

## GET `/api/v1/projects/{projectId}`

- **Descripción:** detalle de proyecto.
- **Auth:** cliente autorizado; team/admin.
- **Path:** `projectId: uuid`.
- **Respuesta:** `200` proyecto, servicio, estado visible, fechas, formularios pendientes, progreso y próximos pasos.
- **Error:** `401`, `403`, `404 PROJECT_NOT_FOUND`.
- **Validaciones:** UUID y ownership por organización.
- **Reglas:** cliente no recibe notas internas, secrets, storage keys ni campos administrativos no visibles.
- **Dependencias:** project, catalog, workflow, forms, milestones, RLS.
- **Casos especiales:** no permitir enumeración por UUID.

## POST `/api/v1/projects/{projectId}/transitions`

- **Descripción:** cambia el estado del proyecto según workflow.
- **Auth:** team/admin con `project:transition`; cliente no puede usarlo.
- **Path:** `projectId: uuid`; **Body:** `toStatus: string`, `reason?: string 0–2000`, `expectedVersion: integer`.
- **Respuesta:** `200` proyecto actualizado y evento creado.
- **Error:** `403`, `404`, `409 PROJECT_VERSION_CONFLICT`, `422 PROJECT_TRANSITION_NOT_ALLOWED`.
- **Validaciones:** estado perteneciente al workflow fijado, capability, motivo requerido y versión.
- **Reglas:** guardar estado anterior/nuevo, actor, timestamp y correlation ID en `ProjectEvent`; notificar vía outbox.
- **Dependencias:** project, workflow, events, milestones, audit, outbox.
- **Casos especiales:** transición repetida al mismo estado no duplica evento salvo policy explícita.

## GET `/api/v1/projects/{projectId}/events`

- **Descripción:** timeline visible del proyecto.
- **Auth:** cliente ve eventos públicos de su proyecto; team/admin ve alcance autorizado.
- **Path:** `projectId: uuid`; **Query:** `visibility?: public|internal`, `page`, `pageSize`.
- **Respuesta:** `200` eventos ordenados por fecha descendente.
- **Error:** `403`, `404`.
- **Validaciones:** cliente no puede solicitar `internal`.
- **Reglas:** eventos append-only; filtrar notas internas.
- **Dependencias:** project events, project, RLS.
- **Casos especiales:** paginación estable por timestamp + UUID.

## GET `/api/v1/projects/{projectId}/milestones`

- **Descripción:** lista hitos del proyecto.
- **Auth:** cliente autorizado para hitos visibles; team/admin completo.
- **Path:** `projectId: uuid`; **Query:** `status`, `page`, `pageSize`.
- **Respuesta:** `200` hitos con estado, orden y fechas visibles.
- **Error:** `403`, `404`.
- **Validaciones:** scope y filtros.
- **Reglas:** cliente no cambia hitos internos.
- **Dependencias:** project, milestones, workflow.
- **Casos especiales:** hitos archivados se conservan.

## PATCH `/api/v1/projects/{projectId}/milestones/{milestoneId}`

- **Descripción:** actualiza hito operativo.
- **Auth:** team/admin con `milestone:manage`.
- **Path:** `projectId: uuid`, `milestoneId: uuid`; **Body:** `status`, `dueAt?: datetime`, `notes?: string`, `expectedVersion`.
- **Respuesta:** `200` hito actualizado.
- **Error:** `403`, `404`, `409 MILESTONE_VERSION_CONFLICT`, `422 MILESTONE_INVALID`.
- **Validaciones:** hito pertenece al proyecto, estado permitido y fechas coherentes.
- **Reglas:** cambios importantes generan project event y auditoría.
- **Dependencias:** project, milestone, audit, outbox.
- **Casos especiales:** no borrar hitos usados como evidencia; archivar en su lugar.

---

# 13. Módulo Forms y Responses

No se exponen rutas globales `/forms` o `/responses` para datos de clientes. La ruta canónica es anidada bajo `/projects/{projectId}/forms/{formId}` para imponer ownership.

## GET `/api/v1/projects/{projectId}/forms`

- **Descripción:** lista formularios provisionados del proyecto.
- **Auth:** cliente del proyecto; team/admin.
- **Path:** `projectId: uuid`; **Query:** `status`, `required`, `page`, `pageSize`.
- **Respuesta:** `200` lista de `FormSummary`.
- **Error:** `403`, `404`.
- **Validaciones:** pertenencia del proyecto, filtros y estado visible.
- **Reglas:** formularios se crean en activación, no desde este endpoint.
- **Dependencias:** project, project forms, form versions, RLS.
- **Casos especiales:** proyecto sin formularios devuelve lista vacía.

## GET `/api/v1/projects/{projectId}/forms/{formId}`

- **Descripción:** devuelve definición y estado del formulario autorizado.
- **Auth:** cliente del proyecto mientras esté disponible; team/admin.
- **Path:** `projectId: uuid`, `formId: uuid`.
- **Respuesta:** `200` definición versionada, estado, respuestas actuales permitidas y reglas de UI necesarias.
- **Error:** `403`, `404 FORM_NOT_FOUND`, `409 FORM_LOCKED` solo si se intenta editar.
- **Validaciones:** form pertenece al proyecto y versión publicada/fijada.
- **Reglas:** el cliente solo recibe su proyecto; sanitizar definición y no ejecutar scripts.
- **Dependencias:** project form, form version, response revisions.
- **Casos especiales:** versión antigua se conserva para leer respuestas históricas.

## GET `/api/v1/projects/{projectId}/forms/{formId}/revisions`

- **Descripción:** lista revisiones de respuestas.
- **Auth:** cliente solo sus respuestas; team/admin autorizado.
- **Path:** `projectId: uuid`, `formId: uuid`; **Query:** `page`, `pageSize`.
- **Respuesta:** `200` revisiones con número, estado, actor permitido y timestamp; respuestas completas según rol.
- **Error:** `403`, `404`.
- **Validaciones:** pertenencia y paginación.
- **Reglas:** revisiones append-only; no borrar ni editar históricas.
- **Dependencias:** project form, response revisions, profile, RLS.
- **Casos especiales:** ocultar respuestas sensibles al rol que no corresponda.

## PUT `/api/v1/projects/{projectId}/forms/{formId}/response`

- **Descripción:** guarda una revisión de borrador.
- **Auth:** cliente del proyecto con formulario abierto; team/admin solo en representación autorizada.
- **Path:** `projectId: uuid`, `formId: uuid`; **Body:** `answers: object`, `expectedRevision: integer`.
- **Headers:** `Idempotency-Key` recomendado/obligatorio para autosave con reintentos.
- **Respuesta:** `200` nueva revisión `{ "revision": 3, "status": "in_progress" }`.
- **Error:** `403`, `404`, `409 RESPONSE_REVISION_CONFLICT`, `422 ANSWERS_INVALID`, `423 FORM_LOCKED`.
- **Validaciones:** schema de `FormVersion`, tamaño total, tipos, campos desconocidos y límites por campo.
- **Reglas:** crear nueva revisión; no sobrescribir historia; verificar organización y estado abierto.
- **Dependencias:** project, form version, response revisions, audit opcional.
- **Casos especiales:** autosave repetido con misma key devuelve la revisión existente.

## POST `/api/v1/projects/{projectId}/forms/{formId}/submit`

- **Descripción:** envía el formulario para revisión.
- **Auth:** cliente del proyecto con `form:submit`.
- **Path:** `projectId: uuid`, `formId: uuid`; **Body:** `revision: integer`, `submissionNote?: string 0–2000`.
- **Headers:** `Idempotency-Key` requerido.
- **Respuesta:** `200` formulario en `submitted`.
- **Error:** `403`, `404`, `409 FORM_NOT_SUBMITTABLE`, `422 FORM_REQUIRED_FIELDS_MISSING`, `423 FORM_LOCKED`.
- **Validaciones:** revisión existente, schema completo, campos requeridos, archivos requeridos y estado abierto.
- **Reglas:** fijar revisión enviada, registrar evento y notificar al equipo mediante outbox.
- **Dependencias:** project form, response revision, files, project event, notification.
- **Casos especiales:** repetición devuelve el envío existente; no duplica notificación.

## POST `/api/v1/projects/{projectId}/forms/{formId}/request-changes`

- **Descripción:** solicita correcciones al cliente.
- **Auth:** team/admin con `form:request_changes`.
- **Path:** `projectId: uuid`, `formId: uuid`; **Body:** `reason: string` 1–4000, `requiredFields?: string[]`.
- **Respuesta:** `200` formulario en `changes_requested`.
- **Error:** `403`, `404`, `409 FORM_NOT_REVIEWABLE`, `422 REASON_REQUIRED`.
- **Validaciones:** estado submitted/reviewable y campos pertenecientes al schema.
- **Reglas:** registrar actor, motivo, evento y notificación; reabrir solo según workflow.
- **Dependencias:** form, project, workflow, events, notifications.
- **Casos especiales:** petición repetida con misma versión es idempotente.

## POST `/api/v1/projects/{projectId}/forms/{formId}/lock`

- **Descripción:** bloquea un formulario cerrado o validado.
- **Auth:** team/admin con `form:lock`.
- **Path:** `projectId: uuid`, `formId: uuid`; **Body:** `reason: string 1–2000`.
- **Respuesta:** `200` formulario en `locked`.
- **Error:** `403`, `404`, `409 FORM_NOT_LOCKABLE`, `422 REASON_REQUIRED`.
- **Validaciones:** transición permitida y motivo.
- **Reglas:** impedir futuras ediciones; conservar respuestas y archivos.
- **Dependencias:** form, project, events, audit.
- **Casos especiales:** desbloqueo no es endpoint genérico; requiere capability y caso de uso futuro explícito.

---

# 14. Módulo Files

Los archivos binarios no pasan necesariamente por el servidor Astro. La API entrega una intención de carga y luego valida la finalización. El storage debe ser privado.

## GET `/api/v1/projects/{projectId}/files`

- **Descripción:** lista metadata de archivos autorizados.
- **Auth:** cliente del proyecto; team/admin.
- **Path:** `projectId: uuid`; **Query:** `status`, `purpose`, `page`, `pageSize`.
- **Respuesta:** `200` archivos sin `storageKey` interno ni URLs permanentes.
- **Error:** `403`, `404`.
- **Validaciones:** ownership y filtros.
- **Reglas:** descargar requiere endpoint temporal separado.
- **Dependencias:** project, files, storage policy, RLS.
- **Casos especiales:** archivos eliminados lógicamente pueden mostrarse solo a team/admin.

## POST `/api/v1/projects/{projectId}/files/upload-intents`

- **Descripción:** crea una intención de carga.
- **Auth:** cliente del proyecto; team/admin.
- **Path:** `projectId: uuid`; **Body:** `filename: string` 1–255, `mimeType: string allowlist`, `sizeBytes: integer >0`, `sha256?: string hex`, `purpose: string`.
- **Headers:** `Idempotency-Key` requerido.
- **Respuesta:** `201` `{ "fileId": "uuid", "uploadUrl": "temporary-url", "expiresAt": "datetime" }`.
- **Error:** `403`, `404`, `409 UPLOAD_ALREADY_EXISTS`, `413 FILE_TOO_LARGE`, `415 MIME_NOT_ALLOWED`, `422 FILENAME_INVALID`.
- **Validaciones:** MIME real esperado, extensión allowlist, tamaño, nombre sanitizado, cuota, estado del formulario/proyecto.
- **Reglas:** generar storage key server-side; nunca usar ruta recibida; no ejecutar HTML subido.
- **Dependencias:** project, file metadata, `FileStorage`, RLS.
- **Casos especiales:** URL expirada requiere nueva intención; no sustituye archivo revisado sin policy.

## POST `/api/v1/projects/{projectId}/files/{fileId}/complete`

- **Descripción:** confirma que la carga terminó.
- **Auth:** actor que creó la intención o team/admin autorizado.
- **Path:** `projectId: uuid`, `fileId: uuid`; **Body:** `uploadedBytes: integer`, `sha256: string hex`.
- **Respuesta:** `200` archivo en `available`.
- **Error:** `403`, `404`, `409 UPLOAD_NOT_PENDING`, `422 CHECKSUM_MISMATCH`.
- **Validaciones:** tamaño, checksum, existencia en storage, MIME real y ownership.
- **Reglas:** marcar metadata solo después de verificar el objeto; registrar evento si es evidencia.
- **Dependencias:** files, storage, project, audit.
- **Casos especiales:** repetir devuelve estado actual; objeto incompleto se marca para limpieza segura.

## GET `/api/v1/projects/{projectId}/files/{fileId}/download-url`

- **Descripción:** genera URL temporal de descarga.
- **Auth:** cliente con acceso al proyecto; team/admin.
- **Path:** `projectId: uuid`, `fileId: uuid`; **Query:** `disposition?: inline|attachment` allowlist.
- **Respuesta:** `200` `{ "url": "temporary-url", "expiresAt": "datetime" }`.
- **Error:** `403`, `404`, `410 FILE_UNAVAILABLE`.
- **Validaciones:** ownership, estado y expiración corta.
- **Reglas:** autorizar antes de pedir URL al storage; nunca revelar storage key.
- **Dependencias:** files, project, `FileStorage`.
- **Casos especiales:** URL expirada no se renueva automáticamente en frontend sin nueva autorización.

## DELETE `/api/v1/projects/{projectId}/files/{fileId}`

- **Descripción:** retira lógicamente un archivo editable.
- **Auth:** cliente dueño mientras sea editable; team/admin con capability.
- **Path:** `projectId: uuid`, `fileId: uuid`; **Body:** `reason?: string`.
- **Respuesta:** `204`.
- **Error:** `403`, `404`, `409 FILE_NOT_DELETABLE`.
- **Validaciones:** archivo pertenece al proyecto y no está revisado/bloqueado.
- **Reglas:** preferir soft delete; no borrar evidencia sin política de retención y auditoría.
- **Dependencias:** file, project, storage cleanup, audit.
- **Casos especiales:** limpieza física se ejecuta en job reintentable, no en la request.

---

# 15. Módulo Messages

## GET `/api/v1/projects/{projectId}/messages`

- **Descripción:** lista mensajes de un proyecto.
- **Auth:** cliente del proyecto; team/admin.
- **Path:** `projectId: uuid`; **Query:** `page`, `pageSize`, `before?: datetime`.
- **Respuesta:** `200` mensajes según visibilidad.
- **Error:** `403`, `404`.
- **Validaciones:** paginación estable y scope.
- **Reglas:** cliente no recibe mensajes internos; contenido se escapa al renderizar.
- **Dependencias:** project, messages, profiles, RLS.
- **Casos especiales:** no cargar HTML ejecutable ni permitir XSS almacenado.

## POST `/api/v1/projects/{projectId}/messages`

- **Descripción:** crea mensaje ligado al proyecto.
- **Auth:** cliente del proyecto; team/admin.
- **Path:** `projectId: uuid`; **Body:** `body: string` 1–10000, `visibility?: public|internal` solo team/admin, `clientRequestId?: string`.
- **Headers:** `Idempotency-Key` recomendado.
- **Respuesta:** `201` mensaje creado.
- **Error:** `403`, `404`, `413 MESSAGE_TOO_LARGE`, `422 MESSAGE_INVALID`, `429`.
- **Validaciones:** longitud, normalización, límites de frecuencia y visibilidad permitida.
- **Reglas:** guardar texto como texto, nunca HTML confiable por defecto; notificar mediante outbox.
- **Dependencias:** project, organization, profile, messages, notifications.
- **Casos especiales:** reintento con key no duplica mensaje; moderación futura detrás de puerto.

---

# 16. Módulo Notifications

## GET `/api/v1/notifications`

- **Descripción:** lista notificaciones del usuario actual.
- **Auth:** requerida.
- **Query:** `unread?: boolean`, `type?: string`, `page`, `pageSize`.
- **Respuesta:** `200` notificaciones propias con `id`, `type`, `title`, `readAt`, `createdAt` y referencia segura.
- **Error:** `401`, `400 INVALID_FILTER`.
- **Validaciones:** filtros allowlisted.
- **Reglas:** solo `own_user`; no incluir secrets ni datos de otro tenant.
- **Dependencias:** notifications, profile, RLS.
- **Casos especiales:** notificación archivada no desaparece de auditoría interna.

## POST `/api/v1/notifications/{notificationId}/read`

- **Descripción:** marca una notificación como leída.
- **Auth:** usuario propietario.
- **Path:** `notificationId: uuid`.
- **Respuesta:** `200` notificación actualizada.
- **Error:** `401`, `404 NOTIFICATION_NOT_FOUND`.
- **Validaciones:** ownership.
- **Reglas:** operación idempotente.
- **Dependencias:** notification, profile, RLS.
- **Casos especiales:** marcar repetidamente no cambia historial relevante.

## POST `/api/v1/notifications/read-all`

- **Descripción:** marca como leídas las notificaciones elegibles del usuario.
- **Auth:** requerida.
- **Body:** opcional `{ "before": "datetime" }`.
- **Respuesta:** `200` `{ "updatedCount": 4 }`.
- **Error:** `401`, `422 DATE_INVALID`.
- **Validaciones:** fecha válida y scope propio.
- **Reglas:** no modifica notificaciones de otros usuarios; puede ser idempotente.
- **Dependencias:** notifications, profile, RLS.
- **Casos especiales:** lista vacía devuelve `updatedCount: 0`.

---

# 17. Módulo Dashboard

El dashboard es una vista de lectura, no una fuente de verdad ni un módulo que muta entidades directamente.

## GET `/api/v1/dashboard/client`

- **Descripción:** resumen del portal del cliente.
- **Auth:** cliente con sesión válida.
- **Query:** `organizationId?: uuid` solo si tiene varias membresías propias.
- **Respuesta:** `200` `{ "quotes": [], "projects": [], "pendingForms": [], "notifications": [], "nextActions": [] }`.
- **Error:** `401`, `403 ORGANIZATION_NOT_ACCESSIBLE`.
- **Validaciones:** organización pertenece al actor; límites de agregación.
- **Reglas:** no calcular permisos desde datos del dashboard; cada lectura consulta casos/repositorios autorizados.
- **Dependencias:** quotes, projects, forms, notifications, organization members.
- **Casos especiales:** cliente sin proyectos obtiene estado vacío explicativo.

## GET `/api/v1/dashboard/internal`

- **Descripción:** resumen operativo para panel interno.
- **Auth:** team/admin con `dashboard:read`.
- **Query:** `organizationId?: uuid`, `status?: string`, `serviceId?: uuid`, `from?: datetime`, `to?: datetime`.
- **Respuesta:** `200` métricas y colas: cotizaciones pendientes, proyectos por estado, formularios pendientes, archivos recientes y pagos en revisión.
- **Error:** `403`, `400 INVALID_FILTER`.
- **Validaciones:** filtros allowlisted y límites temporales.
- **Reglas:** no incluye secrets ni credenciales; cifras se derivan de fuentes autorizadas.
- **Dependencias:** quote, order, project, forms, files, payments, RLS.
- **Casos especiales:** consultas pesadas deben usar read models/cache privado sin sustituir PostgreSQL como fuente de verdad.

---

# 18. Módulo Audit

## GET `/api/v1/audit-events`

- **Descripción:** consulta auditoría operativa.
- **Auth:** team/admin con `audit:read`; cliente solo recibe actividad filtrada mediante dashboard/proyecto.
- **Query:** `actorId?: uuid`, `resourceType?: string`, `resourceId?: uuid`, `action?: string`, `from?: datetime`, `to?: datetime`, `page`, `pageSize`.
- **Respuesta:** `200` eventos con actor autorizado, recurso, acción, resultado, timestamp y request ID; metadata minimizada.
- **Error:** `403`, `400 INVALID_FILTER`.
- **Validaciones:** filtros allowlisted, límites de fecha y paginación.
- **Reglas:** eventos append-only; nunca devolver secrets, tokens, passwords o payloads completos de pago.
- **Dependencias:** audit events, profiles, resources, RLS.
- **Casos especiales:** exportaciones masivas requieren capability y rate limit adicional.

---

# 19. Matriz de cobertura

| Caso de uso documentado | Endpoint canónico |
|---|---|
| Registro/login/sesión | `/auth/*` |
| Perfil propio | `/me` |
| Organizaciones y membresías | `/organizations/*`, `/invitations/*` |
| Autoridad e invitaciones internas | `/staff/invitations` |
| Catálogo de servicios | `/services/*` |
| Solicitud y negociación | `/quotes/*` |
| Orden | `/orders/*` |
| Activación | `POST /orders/{orderId}/activate` |
| Proyecto | `/projects/*` |
| Formularios | `/projects/{projectId}/forms/*` |
| Respuestas | `/projects/{projectId}/forms/{formId}/response` |
| Archivos | `/projects/{projectId}/files/*` |
| Mensajes | `/projects/{projectId}/messages` |
| Pagos futuros | `/orders/{orderId}/payment-attempts`, `/webhooks/payments/*` |
| Notificaciones | `/notifications/*` |
| Dashboard | `/dashboard/*` |
| Auditoría | `/audit-events` |

No existen rutas duplicadas para `service_instances`, `responses`, creación directa de proyectos o CRUD genérico de estados.

# 20. Reglas de evolución

- Cambios incompatibles requieren `/api/v2` o una estrategia de versionado documentada.
- Agregar campos opcionales no rompe `v1`; eliminar o cambiar semántica sí requiere migración.
- Cada endpoint nuevo debe mapearse a un caso de uso y capability existente.
- No crear endpoints por tabla automáticamente.
- Los módulos nuevos deben respetar la misma envoltura de respuesta, errores, paginación, auditoría e idempotencia.
- Los contratos deben probarse contra cliente A, cliente B, team, admin, sesión ausente, reintentos y estados inválidos.
- Antes de implementar se debe aprobar este documento, seleccionar runtime/proveedores y generar un plan por fases.
