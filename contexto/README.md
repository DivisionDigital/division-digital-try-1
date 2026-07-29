# Contexto del proyecto

Esta carpeta conserva el contexto técnico y funcional de División Digital para que los cambios futuros puedan hacerse con trazabilidad.

## Archivos

- `informe-analisis-inicial.md`: diagnóstico de la versión analizada el 24 de julio de 2026.
- `bitacora.md`: registro breve de cambios, decisiones, validaciones y pendientes.
- `arquitectura.md`: arquitectura objetivo del frontend, backend, datos, seguridad y portabilidad hacia AWS.
- `backend-flow.md`: flujo funcional completo, actores, reglas y fuentes de verdad del backend.
- `domain-model.md`: lenguaje ubicuo, entidades, relaciones y provisionamiento de proyectos.
- `use-cases.md`: catálogo conceptual de casos de uso y sus permisos/resultados.
- `conventions.md`: convenciones de arquitectura, datos, seguridad, API y documentación.
- `datos/modelo-relacional.md`: investigación y decisión del modelo relacional multi-tenant, JSONB controlado, historial y almacenamiento de archivos.
- `datos/modelo-mvp.md`: inventario lógico inicial de entidades, relaciones, invariantes, índices candidatos y secuencia de migraciones.
- `datos/modelo-fisico-supabase.md`: implementación PostgreSQL 17, diccionario de 28 tablas, ERD, estados, migraciones, validaciones y límites operativos.
- `roadmap.md`: fases de desarrollo, alcance del MVP y criterios de avance.
- `seguridad/matriz-permisos.md`: actores, alcances y permisos para el cliente, equipo, administrador y procesos internos.
- `seguridad/rls-supabase.md`: helpers privados, grants explícitos, políticas RLS y controles del bucket `project-files`.
- `../docs/api-design.md`: contrato técnico propuesto de la API, agrupado por módulos y sin endpoints implementados.
- `decisiones/`: decisiones arquitectónicas registradas como ADR, con contexto, motivos y consecuencias.
- `decisiones/ADR-005-proyectos-por-servicio-y-formularios-configurables.md`: regla de un proyecto por servicio/unidad y provisionamiento automático de formularios y workflows.
- `decisiones/ADR-006-autoridad-interna-separada.md`: separación entre membresías cliente `owner|member` y autoridad global `team|admin`.
- `decisiones/ADR-007-frontera-data-api-y-runtime-ssr.md`: datos privados mediante `/api/v1`, catálogo público acotado y clientes Supabase separados.
- `../supabase/`: configuración, migraciones imperativas, seed idempotente y pruebas pgTAP.
- `.agents/skills/`: skills locales para aplicar durante el desarrollo frontend y backend: arquitectura modular, modelado relacional, PostgreSQL, Astro Islands, seguridad web, autenticación, RLS y pagos/webhooks.

## Convención para próximos cambios

Cada modificación relevante debe registrar en `bitacora.md`:

1. Fecha y objetivo.
2. Archivos afectados.
3. Decisión técnica tomada.
4. Validaciones ejecutadas.
5. Pendientes o riesgos conocidos.

Los informes posteriores pueden mantener el mismo nombre con versión o fecha, por ejemplo `informe-analisis-2026-08.md`.

Las decisiones que cambien la arquitectura deben registrarse en `decisiones/` y relacionarse desde `arquitectura.md` y `bitacora.md`.

Para el estado implementado de la base, usar como documentos canónicos `datos/modelo-fisico-supabase.md`, `seguridad/rls-supabase.md`, `../supabase/README.md` y las migraciones. Los documentos conceptuales no sustituyen esos artefactos ejecutables.
