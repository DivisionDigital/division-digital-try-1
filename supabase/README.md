# Base de datos Supabase

La carpeta contiene la fuente de verdad del modelo PostgreSQL 17 de División Digital.

## Entorno de desarrollo

- Proyecto: `division-digital-dev`
- Ref: `drvvtxbvgpygvcvqqofd`
- Región: `sa-east-1`
- CLI del proyecto: `supabase@2.110.0`

La referencia del proyecto no es un secreto. Contraseñas, access tokens, service-role keys y URLs con credenciales no se guardan en Git.

## Estado verificado

- 18 migraciones locales y remotas alineadas.
- 28 tablas públicas; 28 con RLS y políticas.
- 34 políticas públicas y 2 políticas de `storage.objects`.
- 62/62 aserciones pgTAP aprobadas.
- Seed idempotente: 1 servicio, 1 workflow, 2 plantillas, 2 versiones y 3 hitos.
- Bucket privado `project-files`, 25 MiB, PDF/JPEG/PNG/WebP.
- Security Advisor sin hallazgos; Performance Advisor solo informa índices todavía sin uso.

## Estructura

```text
supabase/
├── config.toml
├── migrations/
├── seed.sql
└── tests/database/
```

Las migraciones son imperativas e incrementales. No se modifican migraciones ya aplicadas; cualquier corrección genera una nueva.

## Comandos

```powershell
pnpm exec supabase --version
pnpm exec supabase migration new nombre
pnpm exec supabase migration list
```

Con Docker disponible:

```powershell
pnpm exec supabase start
pnpm exec supabase db reset
pnpm exec supabase test db
```

Antes de desplegar, comprobar que el proyecto vinculado es el entorno esperado. Producción recibe las mismas migraciones, pero no el seed de desarrollo.

## Flujo de cambios

1. Crear una migración nueva; no editar una migración ya aplicada.
2. Añadir constraints, índices y cambios de RLS/grants en el mismo conjunto versionado.
3. Ejecutar reset y pgTAP en local cuando Docker esté disponible; mientras no lo esté, validar únicamente contra el entorno remoto de desarrollo.
4. Ejecutar el seed dos veces y comprobar idempotencia.
5. Revisar Security y Performance Advisors.
6. Comparar el historial local/remoto antes de promover.
7. Aplicar exactamente las mismas migraciones a staging y producción; no ejecutar el seed de desarrollo.

## Reglas

- No aplicar DDL manual no versionado.
- No añadir usuarios, PII, pagos ni secretos al seed.
- Toda tabla pública nueva necesita RLS, grants explícitos, índices y pruebas.
- Los roles Data API no reciben privilegios predeterminados: toda exposición futura debe ser una allowlist probada.
- Los datos privados se leen y modifican mediante `/api/v1`; la única lectura directa del navegador es la proyección pública del catálogo.
- Las transiciones del dominio pertenecen a futuros casos de uso backend, no a triggers.
- Storage requiere una fila `files` pendiente, no expirada y creada por servidor antes de subir. El objeto pendiente solo es visible temporalmente a su creador.
- Los valores de `config.toml` son el contrato local. Los ajustes administrados por entorno —Auth, SMTP, Turnstile, backups y red— deben verificarse también en el Dashboard antes de una exposición pública.

La documentación detallada está en `contexto/datos/modelo-fisico-supabase.md` y `contexto/seguridad/rls-supabase.md`.
