# Ciclo de cotización, pago y activación

## Separación de conceptos

`quote` representa una propuesta con alcance, precio y vigencia. `order` representa lo aceptado y debe conservar un snapshot. `payment` representa intentos y confirmaciones del proveedor. `service_instance` representa el proyecto habilitado y su ciclo operativo. No reemplazar todos estos conceptos con una sola columna `paid`.

## Idempotencia

Persistir el ID del evento del proveedor con una restricción única. Antes de activar, comprobar también que la orden no esté activa y que el pago confirmado corresponda a importe, moneda y referencia. Un segundo intento debe devolver el resultado existente, no duplicar servicio, notificación o acceso.

## Reconciliación

Los webhooks pueden repetirse, llegar tarde o fuera de orden. Mantener payload mínimo necesario, estado de procesamiento, error, número de intentos y timestamp. Crear una vista/cola para eventos pendientes y una acción administrativa auditada para resolverlos; nunca editar directamente la base en producción sin trazabilidad.

## Activación

La transacción debe cambiar el pago y la elegibilidad de la orden solo cuando las precondiciones se cumplan. La creación de proyectos ocurre en `ActivateOrder`, con autorización administrativa e idempotencia propia. El envío de correo/WhatsApp y otras llamadas externas ocurren después mediante outbox o tarea reintentable. La fecha de caducidad se calcula desde la política contratada y se conserva para auditoría.

## Casos negativos

Probar firma inválida, evento repetido, referencia desconocida, importe diferente, moneda diferente, pago parcial, reembolso, chargeback, orden cancelada, evento fuera de orden y timeout. Definir si cada caso se rechaza, se pone en revisión o genera reversión.

## Referencias

- [AWS prescriptive guidance: transactional outbox](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html)
- [AWS Lambda idempotency considerations](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [ADR de activación del proyecto](../../../contexto/decisiones/ADR-003-activacion-pago.md)
