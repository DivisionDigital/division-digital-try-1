# Patrones de PostgreSQL para el portal

## Jerarquía recomendada

Usar `profiles` para datos mínimos asociados a identidad y tablas de negocio separadas para clientes, membresías, cotizaciones, órdenes, pagos, instancias de servicio, formularios, entregables, archivos, notificaciones y auditoría. Esto permite cambiar el proveedor de identidad sin mezclar credenciales con el modelo comercial.

## Convenciones

- Identificadores internos y públicos: `uuid` generado en servidor.
- Fechas: `timestamptz` en UTC; conservar `created_at` y `updated_at`.
- Dinero: `numeric(12,2)` más `currency`; nunca `float`.
- Estados: `text` con `CHECK` o enum cuando el conjunto sea estable; documentar transiciones.
- Borrado: preferir estados (`cancelled`, `archived`) para historial financiero; usar `ON DELETE` explícito.
- Auditoría: registrar actor, acción, recurso, timestamp, correlation ID y datos mínimos necesarios.

## Integridad

Cada relación debe tener una clave foránea. Usar `UNIQUE` para referencias externas y combinaciones que no pueden repetirse. Usar `CHECK` para importes no negativos, rangos de fechas y estados válidos. Las reglas críticas deben ser imposibles de violar incluso si falla la API.

## Índices y consultas

Partir de consultas del dashboard: servicios por cliente y estado, formularios pendientes, eventos recientes, pagos por referencia y solicitudes abiertas. Revisar `EXPLAIN (ANALYZE, BUFFERS)` antes de optimizar. Usar índices parciales para colas activas cuando exista evidencia; evitar índices redundantes que encarezcan escrituras.

## Transacciones

Bloquear o usar restricciones únicas para carreras de activación. Mantener la transacción corta y no hacer HTTP dentro de ella. Para efectos externos, confirmar el cambio interno y publicar un outbox/evento que pueda reintentarse.

## Migraciones

Preferir expand-and-contract: agregar estructura compatible, desplegar código que soporte ambos formatos, migrar datos, eliminar lo antiguo en una migración posterior. Probar rollback operativo aunque no toda migración sea reversible automáticamente.

## Referencias

- [CREATE TABLE](https://www.postgresql.org/docs/current/sql-createtable.html)
- [Constraints](https://www.postgresql.org/docs/current/ddl-constraints.html)
- [Indexes](https://www.postgresql.org/docs/current/indexes.html)
- [Transactions](https://www.postgresql.org/docs/current/tutorial-transactions.html)
- [Supabase database migrations](https://supabase.com/docs/guides/deployment/database-migrations)
