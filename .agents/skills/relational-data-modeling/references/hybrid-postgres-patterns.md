# Patrones híbridos para PostgreSQL

## Multi-tenancy compartido

Para el MVP, usar una base y schema compartidos. Cada recurso de negocio debe tener `organization_id` directo o una ruta de ownership inequívoca. Las políticas RLS deben resolver la membresía mediante una relación controlada, no mediante campos editables por el usuario.

Ventajas: menor coste, migraciones únicas, reportes globales sencillos y buena portabilidad. Riesgo principal: una política incorrecta puede producir IDOR/BOLA; por eso las pruebas deben intentar acceder con cliente A a recursos de cliente B.

## Núcleo relacional

Separar al menos:

- `profiles` y `organizations`/`organization_members` para identidad y pertenencia;
- `service_catalog` de `service_instances` para diferenciar oferta de contratación;
- `quotes`, `quote_items`, `payment_orders` y `payments` para el ciclo comercial;
- `form_templates`, `form_versions` y `form_submissions` para formularios;
- `service_events` o `service_updates` para timeline/progreso;
- `files` para metadata y referencia a almacenamiento privado;
- `audit_events` para acciones sensibles.

No mezclar credenciales con información comercial ni colocar todos los módulos en una única tabla polimórfica sin restricciones.

## JSONB para formularios

Una plantilla debe versionarse. La estructura puede vivir en `form_versions.definition` y las respuestas en `form_submissions.answers`, ambas con `jsonb`. El servidor valida que las respuestas correspondan a la versión publicada, tamaño máximo, tipos permitidos y estado de la submission.

No usar JSONB cuando se necesite consultar, ordenar, unir, autorizar o reportar con frecuencia sobre el campo. En esos casos, extraer una entidad/columna relacional. Si una consulta JSONB es frecuente, medir y considerar un índice GIN o una expresión indexada.

## Estado e historial

Guardar el estado actual en la entidad operativa para lecturas rápidas y un historial append-only para cambios relevantes. Cada evento debe identificar recurso, actor, estado anterior/nuevo, timestamp, correlación y metadata mínima. Esto da trazabilidad sin obligar a reconstruir todo el sistema mediante event sourcing.

## Archivos

PostgreSQL conserva `storage_key`, nombre original sanitizado, MIME validado, tamaño, checksum, relación con organización/servicio y timestamps. El contenido vive en object storage privado. Las descargas se entregan mediante URLs temporales y la autorización se revisa antes de emitirlas.

## Comercial y snapshots

Una cotización puede cambiar antes de ser aceptada; una orden y un pago confirmado deben conservar el importe, moneda y descripción acordados. Usar `quote_items` para la propuesta y un snapshot en la orden o sus líneas aceptadas para no depender de cambios posteriores del catálogo.

## Evolución

Aplicar expand-and-contract: agregar columnas/tablas compatibles, desplegar código que soporte el formato, migrar datos, activar el nuevo camino y eliminar lo anterior en una fase posterior. No renombrar ni eliminar columnas en el mismo despliegue que aún ejecuta código antiguo.

## Fuentes oficiales

- [PostgreSQL: constraints](https://www.postgresql.org/docs/current/ddl-constraints.html)
- [PostgreSQL: JSON types](https://www.postgresql.org/docs/current/datatype-json.html)
- [PostgreSQL: indexes](https://www.postgresql.org/docs/current/indexes.html)
- [PostgreSQL: transactions](https://www.postgresql.org/docs/current/tutorial-transactions.html)
- [Supabase: database migrations](https://supabase.com/docs/guides/deployment/database-migrations)
- [Supabase: Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
