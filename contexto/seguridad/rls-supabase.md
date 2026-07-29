# RLS, grants y Storage en Supabase

**Estado:** implementado y validado
**Fecha:** 2026-07-29
**Última validación remota:** 2026-07-29
**Fuente de verdad:** migraciones `create_rls_grants_and_storage_policies`, `harden_data_api_privileges` y `harden_project_files_upload_policies`

## 1. Fuentes de autoridad

- Identidad: `auth.users`.
- Membresía cliente: `organization_members` con rol `owner|member` y estado `active`.
- Autoridad interna global: `staff_members` con rol `team|admin` y estado `active`.
- `admin` es el único rol que poseerá la capability de backend `activate_projects`.

Los roles no se leen de `user_metadata`, cuerpos HTTP, headers ni parámetros enviados por el navegador.

## 2. Funciones privadas

El esquema `app_private` no se expone mediante Data API. Sus funciones privilegiadas son:

- `is_org_member(organization_id)`;
- `is_staff(allowed_roles[])`;
- `is_admin()`;
- `is_org_owner(organization_id)`;
- `can_upload_project_file(bucket, path)`;
- `can_read_project_file(bucket, path)`.

Estas seis funciones son `SECURITY DEFINER`, tienen `search_path` vacío y referencias calificadas. Se revocó `EXECUTE` a `PUBLIC`; únicamente los roles técnicos expresamente declarados pueden invocarlas.

`handle_new_auth_user()` es la séptima función `SECURITY DEFINER`: solo la ejecuta `supabase_auth_admin` desde el trigger de `auth.users`. Las otras 12 funciones de `app_private` son guards de triggers para `updated_at`, tenant, append-only e inmutabilidad y no usan `SECURITY DEFINER`.

No hay funciones `SECURITY DEFINER` ni vistas en el schema `public`. También se revocó `CREATE` público sobre ese schema.

## 3. Grants explícitos

Los grants y RLS son controles complementarios:

| Rol | Grants Data API |
|---|---|
| `anon` | `SELECT` solo sobre `id, slug, name, description, version, published_at` de `service_catalog`. |
| `authenticated` | La misma proyección pública del catálogo; ningún grant sobre tablas privadas. |
| `service_role` | `SELECT`/`INSERT` explícitos y `UPDATE` solo en tablas mutables; sin `DELETE`, `TRUNCATE`, `TRIGGER` ni `REFERENCES`. |

También se revocaron privilegios predeterminados del rol `postgres` para objetos futuros. Los casos de uso backend usarán el cliente privilegiado server-side y validarán capacidad, estado e invariantes. RLS permanece como defensa adicional y no sustituye esa autorización.

La comprobación remota registra cero grants de tabla para `anon/authenticated` y 12 grants de columna: seis columnas de catálogo multiplicadas por los dos roles. Conceder acceso a una tabla privada requerirá una decisión arquitectónica explícita, una migración, políticas e invariantes probadas.

## 4. Alcance de lectura

| Recurso | Cliente miembro | `team` | `admin` |
|---|---|---|---|
| Perfil | Propio | Operativo | Operativo |
| Organización y membresías | Organizaciones propias | Todas | Todas |
| Catálogo publicado | Sí | Sí, incluido interno | Sí, incluido interno |
| Cotizaciones, órdenes y proyectos | Tenant propio | Todas | Todas |
| Pagos y webhooks | No directo | Lectura | Lectura |
| Eventos/hitos/archivos/mensajes | Solo visibles al cliente y de su tenant | Todos | Todos |
| Invitaciones internas | No | No | Lectura |
| Auditoría | No directo | Lectura | Lectura |
| Outbox | No | No | Lectura |

Las políticas de cliente comprueban `organization_id`; las tablas sin tenant directo usan una relación hacia el agregado propietario.

## 5. Frontera de escritura

El navegador no escribe tablas de negocio por Data API. Perfil, organización, cotizaciones, mensajes, notificaciones y todas las transiciones se atenderán mediante `/api/v1`, con autenticación, autorización, validación e idempotencia. La política RLS de organizaciones exige además `owner` o staff autorizado, aunque el grant directo esté revocado.

## 6. Storage

El bucket `project-files` es privado, con límite de 25 MiB y MIME permitidos:

```text
application/pdf
image/jpeg
image/png
image/webp
```

Para cargar un objeto debe existir previamente una fila `files` con:

- misma pareja `storage_bucket`/`storage_path`;
- estado `pending_upload`;
- `created_by = auth.uid()`;
- organización accesible o autoridad interna;
- `upload_expires_at` futuro.

El creador puede leer temporalmente su objeto `pending_upload` no expirado, requisito de la respuesta de Storage. La lectura normal exige `available`; el cliente además necesita `visibility = client` y membresía activa. No hay políticas de `UPDATE` o `DELETE` en `storage.objects`, por lo que no se permite `upsert`.

## 7. Pruebas de seguridad

Las suites pgTAP suman 62 aserciones y validan:

- cliente A ve su tenant;
- cliente A no ve el tenant B;
- cliente B no ve recursos de A;
- cliente A solo ve su proyecto;
- cliente A puede cargar únicamente en una ruta pendiente respaldada por metadata;
- cliente B no puede leer objetos de Storage de cliente A;
- `team` obtiene alcance operativo;
- `team` no satisface `is_admin()`;
- `admin` sí satisface `is_admin()`.

Las pruebas usan usuarios `.example.test`, se ejecutan dentro de una transacción y terminan con `ROLLBACK`.

Además se ejecutó una prueba HTTP real con Auth y Storage: subida pendiente y lectura autorizada; rechazo de ruta ajena, expiración, MIME, 25 MiB excedidos, `upsert` y visibilidad interna; todos los fixtures se eliminaron al finalizar.

La base contiene 34 políticas públicas y 2 políticas de `storage.objects`. Las cuatro suites se reejecutaron tras la validación final y terminaron con `ROLLBACK`; no quedaron usuarios ni datos de prueba.

## 8. Reglas para cambios futuros

- Toda tabla pública nueva debe habilitar RLS en la misma migración.
- Toda política debe tener un índice para su predicado de ownership.
- Todo `UPDATE` debe revisar `USING` y `WITH CHECK`.
- Nunca usar `USING (true)` en datos privados.
- Una vista pública futura debe declarar `security_invoker`.
- Los cambios de grants deben probar ausencia y presencia de privilegios, no solo políticas.
- Service role, secretos y SQL arbitrario nunca llegan al navegador.
- La frontera vigente es datos privados solo mediante `/api/v1`; no restaurar escrituras Data API desde la UI por conveniencia.
- Toda función privilegiada nueva debe vivir fuera de schemas expuestos, fijar `search_path`, revocar `EXECUTE` a `PUBLIC` y recibir una prueba negativa.
