---
name: postgresql-authorization-rls
description: Usa esta skill al diseñar o revisar autorización, roles de base de datos, organizaciones, membresías, permisos por recurso, Row Level Security, vistas y funciones PostgreSQL/Supabase para Division Digital.
---

# Autorización PostgreSQL y RLS

## Objetivo

Aplicar mínimo privilegio y aislamiento por organización en el portal. PostgreSQL debe actuar como segunda barrera: la API valida reglas de negocio y RLS evita que un error de consulta exponga filas de otra organización.

## Flujo de trabajo

1. Definir una matriz actor–recurso–acción–organización antes de escribir una política. Incluir cliente, miembro del equipo, administrador, webhook y tareas internas.
2. Separar roles de PostgreSQL de usuarios del portal. Los roles DB controlan conexiones y privilegios técnicos; no crear un rol DB por cliente.
3. Modelar `profiles`, `organizations`, `organization_members` y relaciones de recursos como `organization_id`, `client_id` o membresía explícita. No confiar en IDs enviados por el cliente.
4. Aplicar restricciones relacionales: claves foráneas, `NOT NULL`, `UNIQUE`, `CHECK` y reglas de borrado. La autorización no debe depender solamente de TypeScript.
5. Habilitar RLS en cada tabla expuesta. Revisar grants/Data API por separado: RLS controla filas, pero no concede el privilegio de acceso al objeto.
6. Escribir políticas con `TO authenticated` más una condición de pertenencia. Usar `(select auth.uid())` y evitar `auth.role()`.
7. Para `UPDATE`, definir `USING` y `WITH CHECK`; para leer una fila antes de actualizarla, asegurar también la política `SELECT` correspondiente.
8. Mantener roles y permisos en tablas controladas por servidor o membresías. No usar `user_metadata` como fuente de autorización porque es editable por el usuario.
9. Revisar vistas, funciones y Storage. Las vistas pueden bypassar RLS; las funciones `SECURITY DEFINER` pueden ampliar privilegios; Storage tiene sus propias políticas.
10. Probar como `anon`, cliente A, cliente B, miembro del equipo y administrador. Probar lectura, inserción, actualización, eliminación y reasignación entre organizaciones.

## Principios de implementación

- Denegar por defecto y agregar solo las operaciones necesarias.
- Mantener autorización en la API aunque el cliente use un token válido.
- No usar `service_role` o secret keys desde navegador; en servidor, limitar su uso a adaptadores privilegiados con autorización explícita y auditoría.
- Usar transacciones y restricciones únicas para evitar carreras en activación, pagos y asignaciones.
- Mantener consultas parametrizadas y seleccionar únicamente columnas necesarias.
- No crear una política `USING (true)` para datos privados.
- Versionar toda política y cambio de esquema mediante migraciones.

## Frontera vigente de División Digital

- `anon` y `authenticated` no tienen grants de tabla sobre datos privados.
- La única lectura directa desde navegador es `SELECT` sobre `id`, `slug`, `name`, `description`, `version` y `published_at` del catálogo publicado.
- Perfiles, organizaciones, membresías, cotizaciones, órdenes, proyectos, formularios, archivos, mensajes, pagos, webhooks, auditoría y outbox pasan por `/api/v1`.
- RLS se conserva en las 28 tablas como defensa en profundidad, aunque el navegador no tenga grant directo.
- Los helpers privilegiados viven en `app_private`, fijan `search_path`, usan referencias calificadas y no conceden `EXECUTE` a `PUBLIC`.
- No ampliar esta frontera por conveniencia. Cualquier excepción requiere ADR, migración aditiva, grant mínimo, política RLS, índice del predicado y pruebas positivas/negativas.

## Validación mínima

Cada tabla nueva debe tener: propietario o relación de tenant definida, RLS habilitado, políticas documentadas, pruebas negativas entre clientes, revisión de vistas/funciones y verificación de grants. Ejecutar advisors disponibles y documentar resultados.

## Referencias

- [Patrones de RLS](references/rls-patterns.md)
- [Roles y privilegios](references/database-privileges.md)
- [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [PostgreSQL Row Security](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
