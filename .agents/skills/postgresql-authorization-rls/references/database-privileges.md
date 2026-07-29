# Roles y privilegios PostgreSQL

## Separar responsabilidades

- Rol de migraciones: puede cambiar esquema, solo para despliegues controlados.
- Rol de runtime: mínimo privilegio para consultas y operaciones necesarias.
- Rol administrativo: reservado para tareas operativas y nunca expuesto al navegador.
- Usuario del portal: identidad de Supabase Auth, no rol de conexión PostgreSQL.

No crear roles DB por cliente. `pg_hba.conf` regula quién puede conectarse al servidor; `GRANT` regula objetos; RLS regula filas. Son capas diferentes.

## Supabase

La publishable key puede usarse con RLS en clientes apropiados. Las secret/service role keys bypassan RLS y solo pueden vivir en servidor. Todo uso privilegiado debe tener una autorización previa, alcance mínimo, auditoría y pruebas.

## Migraciones

Versionar `CREATE TABLE`, `ALTER TABLE`, grants, RLS y funciones. Revisar cambios destructivos con expand-and-contract. Probar el esquema con una conexión equivalente al rol runtime, no solo con un usuario administrador.

## Referencias

- [PostgreSQL Role Attributes](https://www.postgresql.org/docs/current/role-attributes.html)
- [PostgreSQL Privileges](https://www.postgresql.org/docs/current/ddl-priv.html)
- [Supabase API keys](https://supabase.com/docs/guides/getting-started/api-keys)
