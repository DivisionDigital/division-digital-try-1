---
name: relational-data-modeling
description: Usa esta skill al elegir, diseñar o revisar modelos de datos para Division Digital: modelo relacional multi-tenant, normalización, JSONB controlado, formularios dinámicos, historial, archivos, índices y migraciones en PostgreSQL.
---

# Modelado relacional del portal

## Objetivo

Diseñar un modelo de datos que preserve la integridad del negocio, aísle correctamente a cada cliente y permita evolucionar el portal sin acoplar el dominio a un proveedor. La decisión por defecto es PostgreSQL relacional multi-tenant con JSONB acotado para estructuras realmente variables.

## Cuándo usarla

Usar esta skill al:

- convertir requisitos del portal en entidades, relaciones y restricciones;
- decidir entre modelo relacional, documental, EAV, event sourcing u otra alternativa;
- diseñar formularios dinámicos, cotizaciones, órdenes, pagos, servicios contratados o progreso;
- definir aislamiento por organización y el alcance de RLS;
- revisar índices, migraciones, retención, archivos o auditoría;
- preparar una evolución compatible con Supabase, Cloudflare y una futura migración a AWS.

## Decisión por defecto

Adoptar un modelo relacional normalizado pragmáticamente:

- PostgreSQL como fuente de verdad para identidad de negocio, organizaciones, cotizaciones, órdenes, pagos, servicios y auditoría.
- `organization_id` en cada recurso de negocio que pertenezca a un cliente y políticas RLS basadas en membresías.
- JSONB solo para respuestas de formularios, definiciones versionadas y metadata flexible; no para ocultar entidades consultables.
- Estado actual para lectura rápida más historial append-only para cambios importantes.
- Metadata de archivos en PostgreSQL y bytes en object storage privado.
- Catálogos separados de instancias contratadas, y snapshots comerciales en cotizaciones/órdenes para conservar lo acordado.

Documentar cualquier excepción con una ADR antes de implementarla.

## Flujo obligatorio

1. Leer [`contexto/datos/modelo-relacional.md`](../../../contexto/datos/modelo-relacional.md), [`contexto/datos/modelo-mvp.md`](../../../contexto/datos/modelo-mvp.md) y la [matriz de permisos](../../../contexto/seguridad/matriz-permisos.md).
2. Escribir el flujo de negocio, actores, consultas principales, invariantes y retención antes de crear tablas.
3. Dibujar el modelo conceptual y separar identidad, organización, catálogo, contratación, operación, archivos y auditoría.
4. Normalizar las entidades con relaciones y restricciones explícitas. Desnormalizar solo si se documenta la consulta que lo exige y la estrategia de sincronización.
5. Definir el tenant scope: organización, membresía, ownership, roles y columnas que nunca puede cambiar el cliente.
6. Elegir JSONB únicamente cuando la forma sea variable, versionable o poco apta para filtros relacionales. Añadir validación de aplicación y, cuando aplique, índices GIN o expresiones.
7. Diseñar índices desde consultas reales del dashboard; no indexar todas las columnas ni particionar antes de medir.
8. Crear una migración versionada con estrategia expand-and-contract, probarla con datos representativos y revisar RLS, constraints y planes de consulta.
9. Registrar el cambio en la documentación de datos, una ADR si modifica la arquitectura y `contexto/bitacora.md`.

## Reglas que no se deben romper

- No usar una tabla JSON gigante como modelo principal.
- No usar EAV para formularios dinámicos; usar plantillas versionadas y JSONB controlado.
- No crear una base de datos o schema por cliente en el MVP sin una exigencia de aislamiento/compliance documentada.
- No implementar event sourcing completo para todo el dominio; usar historial de eventos donde aporte auditoría o timeline.
- No guardar secretos, credenciales ni archivos binarios grandes en PostgreSQL.
- No confiar solo en el frontend para ownership: la API/caso de uso y RLS deben imponerlo.
- No sobrescribir la información comercial histórica de una cotización, orden o pago confirmado.
- Usar `uuid`, `timestamptz`, `numeric` para dinero y restricciones `NOT NULL`, `UNIQUE`, `CHECK` y foreign keys apropiadas.
- Mantener las migraciones reproducibles y compatibles con despliegues graduales.

## Referencias de trabajo

- [Selección de modelo](references/model-selection.md)
- [Patrones híbridos para PostgreSQL](references/hybrid-postgres-patterns.md)
- [Skill de PostgreSQL](../postgresql-data-modeling/SKILL.md)
- [Arquitectura modular](../../../contexto/arquitectura.md)
- [ADR-004: modelo relacional multi-tenant](../../../contexto/decisiones/ADR-004-modelo-relacional-multitenant.md)
