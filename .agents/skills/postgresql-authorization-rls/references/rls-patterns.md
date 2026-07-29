# Patrones de autorización y RLS

## Pertenencia por organización

Para un recurso con `organization_id`, la política de lectura debe comprobar una membresía controlada:

```sql
create policy "members read organization services"
on public.service_instances
for select
to authenticated
using (
  exists (
    select 1
    from public.organization_members m
    where m.organization_id = service_instances.organization_id
      and m.user_id = (select auth.uid())
  )
);
```

Esto es específico de Supabase, donde `auth.uid()` se deriva de la identidad autenticada. En PostgreSQL sin Supabase se necesita un contexto de sesión confiable o autorización server-side equivalente.

## Actualizaciones

```sql
create policy "members update own submissions"
on public.form_submissions
for update
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));
```

El `USING` limita la fila original y `WITH CHECK` evita que el usuario cambie su propietario en el resultado.

## Diseño de políticas

- Separar `SELECT`, `INSERT`, `UPDATE` y `DELETE`.
- Usar políticas de equipo basadas en membresía y permisos, no en texto enviado por el cliente.
- Mantener los estados internos editables solo por el equipo.
- No usar `USING (true)` para información privada.
- Probar como `anon`, cliente A, cliente B y personal interno.

## Vistas y funciones

Revisar `security_invoker = true` en vistas compatibles con PostgreSQL 15+. Tratar `SECURITY DEFINER` como código privilegiado: esquema no expuesto, `search_path` controlado, validación de actor y grants mínimos.
