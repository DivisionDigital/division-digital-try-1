# Lista de control para RLS en Supabase

RLS y los permisos de Data API son controles diferentes: primero verificar que el rol tenga acceso al objeto y después que la política limite las filas. Toda tabla expuesta debe tener RLS habilitado.

## Patrón de pertenencia

Una política de cliente debe comprobar la relación real con el recurso, por ejemplo mediante `client_id`, `owner_id` o una tabla de membresías. `TO authenticated` solamente identifica el rol; no autoriza el acceso a la fila.

Para `UPDATE`, combinar condición de fila actual y futura: `USING` evita editar una fila ajena y `WITH CHECK` evita moverla a otro propietario. Añadir política de `SELECT`, porque PostgreSQL necesita leer la fila para actualizarla.

## Evitar fugas

- No usar `user_metadata` para permisos.
- No exponer `service_role` al navegador.
- Tratar las vistas como potencialmente privilegiadas; preferir `security_invoker = true` en PostgreSQL compatible o mantenerlas fuera de esquemas expuestos.
- Revisar funciones `SECURITY DEFINER`: no agregarlas para ocultar un error de permisos; si son imprescindibles, usar esquema no expuesto, `search_path` controlado, validación de `auth.uid()` y grants mínimos.
- Revisar Storage: carpeta por usuario/cliente, MIME/tamaño, políticas de lectura y permisos de reemplazo.

## Validación mínima

Probar como `anon`, cliente A, cliente B y equipo autorizado. Intentar leer, editar, eliminar y reasignar recursos de otro cliente. Probar sesión expirada y token con claims antiguos. Ejecutar advisors o el mecanismo equivalente disponible y registrar los resultados.

## Referencias

- [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Supabase API security](https://supabase.com/docs/guides/api/securing-your-api)
- [Supabase product security](https://supabase.com/docs/guides/security/product-security)
