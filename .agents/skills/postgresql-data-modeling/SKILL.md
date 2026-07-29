---
name: postgresql-data-modeling
description: Usa esta skill al diseñar, migrar, consultar, optimizar o asegurar PostgreSQL para el portal de Division Digital, incluyendo tablas, relaciones, restricciones, índices, transacciones, RLS, Supabase, pooling, backups y pruebas de datos.
---

# Modelado y operación de PostgreSQL

## Objetivo

Crear un modelo relacional consistente, auditable y preparado para crecer. PostgreSQL debe proteger la integridad en la base de datos; la aplicación agrega reglas de negocio, pero no reemplaza `NOT NULL`, claves, restricciones, índices ni políticas de acceso.

Para decidir el paradigma y los límites del modelo, consultar primero la skill [relational-data-modeling](../relational-data-modeling/SKILL.md). Esta skill se enfoca en la implementación y operación concreta de PostgreSQL; la skill especializada cubre la comparación de modelos, el uso controlado de JSONB, multi-tenancy y la evolución conceptual.

## Flujo para cambios de datos

1. Leer el contexto del proyecto y convertir el requisito en entidades, relaciones, estados, invariantes y consultas principales.
2. Elegir tipos explícitos: `uuid` para identificadores públicos, `timestamptz` para fechas, `numeric` para dinero, `text` para contenido y enums/checks para estados controlados. Definir zona horaria y precisión monetaria.
3. Diseñar tablas normalizadas. Usar claves foráneas, `UNIQUE`, `NOT NULL`, `CHECK` y reglas de borrado explícitas. No guardar listas separadas por comas ni duplicar estados sin una razón documentada.
4. Identificar las consultas reales antes de crear índices. Indexar claves foráneas y filtros frecuentes; preferir índices compuestos o parciales solo cuando el patrón de consulta lo justifique. Evitar indexar todo.
5. Crear cambios con migraciones versionadas. Si se usa Supabase CLI, descubrir primero los comandos con `supabase --help`; crear migraciones con `supabase migration new <nombre>` y no inventar nombres de archivo.
6. Para cambios Supabase, consultar la documentación vigente y el changelog antes de implementar. Aplicar RLS a toda tabla expuesta y verificar permisos de Data API por separado de RLS.
7. Probar migraciones en una base local o entorno efímero, revisar datos existentes y planificar compatibilidad hacia atrás para cambios destructivos.
8. Ejecutar revisión de seguridad/advisors cuando corresponda, usar `EXPLAIN (ANALYZE, BUFFERS)` para consultas críticas y documentar el resultado.

## Modelo inicial sugerido

Separar identidad del negocio: `profiles`, `organizations` o `clients`, `services`, `service_instances`, `forms`, `form_submissions`, `quotes`, `orders`, `payments`, `service_events`, `files`, `notifications` y `audit_events`. El nombre final depende del alcance; no crear tablas por intuición sin confirmar el flujo.

Para División Digital, el modelo recomendado es una base/schema compartidos con `organization_id` y RLS. El núcleo comercial y operativo permanece normalizado; `jsonb` queda reservado para definiciones y respuestas de formularios versionadas, además de metadata que no justifique una columna. El estado actual se complementa con historial append-only y los archivos se almacenan fuera de PostgreSQL, conservando en la base sus metadatos y permisos.

Una compra debe conservar su historial: cotización, orden, pago y activación son conceptos relacionados pero no equivalentes. Los cambios de progreso deben ser eventos o estados auditables, no solo una columna sobrescrita sin historial.

## RLS y Supabase

- Activar RLS en tablas del esquema expuesto.
- Usar `TO authenticated` junto con una condición de pertenencia; `TO authenticated` por sí solo no evita IDOR/BOLA.
- Para `UPDATE`, definir tanto `USING` como `WITH CHECK` para impedir que un usuario reasigne la fila a otra identidad.
- Usar `(select auth.uid())` en las políticas y evitar `auth.role()`.
- Nunca usar `user_metadata` para autorización: el usuario puede modificarlo. Usar una relación de membresía controlada o `app_metadata` con el modelo adecuado.
- Recordar que `UPDATE` necesita una política de `SELECT` para encontrar la fila.
- Las vistas pueden omitir RLS; en PostgreSQL 15+ evaluar `security_invoker = true`, o mantenerlas en un esquema no expuesto y revocar permisos.
- No exponer `service_role` o claves secretas al navegador.
- Revisar políticas de Storage si el proyecto permite archivos; un `upsert` requiere permisos de inserción, lectura y actualización.

## Concurrencia y operación

- Encerrar cambios relacionados —por ejemplo, pago y activación— en una transacción con invariantes verificables.
- Usar restricciones únicas para deduplicar referencias externas y claves de idempotencia.
- Mantener transacciones cortas; no hacer llamadas HTTP dentro de una transacción abierta.
- Usar pooling apropiado para runtimes serverless y evitar crear conexiones por solicitud sin límite.
- Definir backup, restauración probada, retención y migraciones antes de producción.

## Referencias

- [Skill de selección y arquitectura del modelo](../relational-data-modeling/SKILL.md)
- [Patrones de PostgreSQL](references/postgresql-patterns.md)
- [RLS y Supabase](references/supabase-rls.md)
- [Arquitectura del proyecto](../../../contexto/arquitectura.md)
- [Modelo relacional del proyecto](../../../contexto/datos/modelo-relacional.md)
- [Modelo MVP y diccionario inicial](../../../contexto/datos/modelo-mvp.md)
- [Roadmap](../../../contexto/roadmap.md)
