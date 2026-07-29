# ADR-006: autoridad interna global separada de organizaciones

**Estado:** aceptada e implementada
**Fecha:** 2026-07-28

## Contexto

`organization_members` representa la pertenencia de una persona a una organización cliente. Usar esa misma tabla para roles `team` o `admin` mezclaría autoridad global con tenancy, permitiría que una invitación de cliente escalara privilegios y haría ambiguo el alcance de RLS.

El MVP admite organizaciones multiusuario y necesita personal interno con dos roles: `team` para operación y `admin` para operación más `activate_projects`.

## Decisión

- `organization_members.role` solo admite `owner|member`.
- `staff_members.role` solo admite `team|admin`.
- Ambas tablas referencian `auth.users`, pero su significado y ciclo de vida son independientes.
- Las invitaciones se separan en `organization_invitations` y `staff_invitations`.
- La API de invitaciones de organización nunca acepta roles globales.
- Las invitaciones internas se administrarán en `/api/v1/staff/invitations`.
- Los helpers RLS resuelven membresía y staff desde sus tablas respectivas; nunca desde `user_metadata`.
- Solo `admin` posee la capability de backend `activate_projects`.

## Consecuencias

### Positivas

- Una organización cliente no puede conceder autoridad interna.
- Las políticas RLS expresan con claridad tenant y alcance global.
- Revocar una membresía cliente no revoca accidentalmente al personal, ni viceversa.
- La auditoría puede distinguir administración de tenant y autoridad interna.

### Costos

- Existen dos flujos de invitación y aceptación.
- Un usuario podría ser a la vez miembro cliente y staff; la API debe resolver cada capacidad explícitamente.
- Los casos de uso administrativos deben consultar `staff_members` y no inferir roles desde la organización.

## Controles

- `staff_members` no tiene escrituras directas para `authenticated`.
- `staff_invitations` solo es visible a `admin` por RLS.
- Las constraints impiden roles fuera de sus dominios.
- Las pruebas pgTAP demuestran que `team` no satisface `is_admin()` y `admin` sí.

## Contrato afectado

- `POST /api/v1/organizations/{organizationId}/invitations`: `role` solo `owner|member`.
- `POST /api/v1/staff/invitations`: `role` solo `team|admin`, autorizado para `admin`.
- La sesión devuelve membresías de organización y autoridad staff como conjuntos separados.
