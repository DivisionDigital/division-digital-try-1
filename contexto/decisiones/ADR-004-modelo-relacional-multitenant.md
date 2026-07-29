# ADR-004: modelo relacional multi-tenant para el portal

**Estado:** aceptada e implementada
**Fecha:** 2026-07-28
**Decisores:** equipo de desarrollo de División Digital

## Contexto

El proyecto evolucionará una landing Astro hacia un portal en el que clientes se registran, solicitan cotizaciones, consultan proyectos contratados, completan formularios, suben archivos y observan el progreso. El equipo administra cotizaciones, activaciones, solicitudes, estados, archivos y comunicaciones; los pagos automáticos serán una integración posterior.

El sistema necesita relaciones consistentes, transacciones para confirmar una activación administrativa y provisionar proyectos, aislamiento entre clientes, formularios variables, auditoría y una ruta de migración futura hacia AWS. Los pagos automáticos serán una integración desacoplada.

## Decisión

Adoptar PostgreSQL como fuente de verdad con un modelo relacional multi-tenant, una base/schema compartidos en el MVP y `organization_id` más membresías para resolver ownership y RLS.

El modelo se normalizará pragmáticamente. JSONB se reservará para definiciones/respuestas de formularios versionadas y metadata flexible. El estado actual se guardará junto con historial append-only para cambios importantes. Los archivos se conservarán en object storage privado y PostgreSQL guardará su metadata y permisos.

Se separarán el catálogo de servicios y las instancias/proyectos contratados, y se conservarán snapshots de valores comerciales en versiones de cotización y órdenes para mantener la historia aunque cambie el catálogo. Cada ítem y unidad contratada generará un proyecto independiente, con formularios y workflow provisionados desde configuración versionada.

## Alternativas consideradas

### Base documental como modelo principal

Se descarta como núcleo porque complica la integridad entre cotizaciones, órdenes, pagos, servicios y membresías, además de hacer menos explícitos los reportes y el aislamiento.

### EAV para formularios

Se descarta porque debilita tipos, constraints, consultas, validación y reportes. Las plantillas versionadas con JSONB ofrecen flexibilidad dentro de una envoltura relacional.

### Base o schema por cliente

Se descarta para el MVP por el coste de provisión, migraciones, backups, pooling y reportes. Se reconsiderará ante requisitos de compliance, aislamiento dedicado o volumen que lo justifique.

### Event sourcing completo

Se descarta como estrategia global inicial por la complejidad de replay, consistencia y lecturas. Se conservarán eventos de dominio, progreso y auditoría donde aporten trazabilidad.

## Consecuencias positivas

- Integridad referencial y transacciones nativas.
- RLS y ownership expresables de forma verificable.
- Reportes y panel interno más sencillos.
- Formularios flexibles sin convertir el dominio en EAV.
- Portabilidad hacia RDS/Aurora PostgreSQL.
- Evolución gradual mediante migraciones versionadas.

## Consecuencias y riesgos

- Las políticas RLS deben probarse con varios clientes; un error de ownership puede causar exposición de datos.
- El diseño requiere migraciones y contratos más explícitos que una tabla documental.
- JSONB puede crecer sin control si no se validan tamaño, versión y campos extraídos.
- Se necesitará object storage y políticas de archivos separadas.
- La estrategia de índices debe basarse en consultas reales y mediciones.

## Acciones derivadas

- Crear el diccionario lógico del MVP en [`../datos/modelo-mvp.md`](../datos/modelo-mvp.md).
- Aplicar el diseño de proyectos por servicio y formularios configurables de [ADR-005](./ADR-005-proyectos-por-servicio-y-formularios-configurables.md).
- Evolucionar únicamente mediante nuevas migraciones; la implementación inicial quedó fijada en `supabase/migrations/` con Landing Page como servicio piloto.
- Mantener las pruebas de aislamiento cliente A/cliente B como requisito de cada cambio RLS.
- Revisar la decisión cuando existan datos de volumen, retención, compliance y consultas de producción.

## Referencias

- [Modelo relacional del portal](../datos/modelo-relacional.md)
- [Matriz de permisos](../seguridad/matriz-permisos.md)
- [ADR-002: backend modular y portable](./ADR-002-backend-portable.md)
- [PostgreSQL: constraints](https://www.postgresql.org/docs/current/ddl-constraints.html)
- [PostgreSQL: JSON types](https://www.postgresql.org/docs/current/datatype-json.html)
- [Supabase: Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
