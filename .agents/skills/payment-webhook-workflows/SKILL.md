---
name: payment-webhook-workflows
description: Usa esta skill al diseñar cotizaciones, órdenes, enlaces de pago, confirmación manual, webhooks, idempotencia, activación de servicios, vencimientos, reintentos y notificaciones del portal de Division Digital.
---

# Pagos, webhooks y activación de servicios

## Objetivo

Modelar un flujo donde el equipo cotiza, el cliente puede pagar por un medio externo y un administrador activa los proyectos de forma confiable. El webhook verificado y una operación idempotente son la fuente de evidencia del pago; la redirección del navegador solo informa al usuario.

## Flujo recomendado

1. Crear o localizar el cliente y una `quote` con servicio, alcance, moneda, importe, impuestos si aplica, vigencia y condiciones.
2. Convertir la cotización aceptada en una `order` con referencia interna y snapshot de lo vendido. No recalcular el histórico usando el catálogo actual.
3. Crear un intento de pago con proveedor, referencia externa, importe esperado, moneda, estado y una clave de idempotencia. Nunca aceptar importe o servicio únicamente desde el frontend.
4. Enviar al cliente un enlace o instrucciones generadas por el backend/proveedor. No guardar datos de tarjeta; usar tokenización o checkout hospedado.
5. Recibir el webhook en un endpoint público mínimo: leer el cuerpo crudo, verificar firma, validar timestamp/evento, localizar por referencia y guardar el evento recibido.
6. Aplicar idempotencia con una restricción única sobre proveedor + ID de evento, y también sobre la referencia de pago. Si el evento ya fue procesado, responder exitosamente sin repetir la activación.
7. En una transacción corta, comprobar importe, moneda, orden, estado permitido y no reembolso; marcar el pago confirmado y dejar la orden elegible según la política comercial. La activación de `service_instance` se ejecuta mediante `ActivateOrder`, no desde el webhook.
8. Registrar el cambio en historial/auditoría y producir notificaciones fuera de la transacción mediante outbox, cola o proceso reintentable.
9. Mantener estados explícitos y transiciones válidas. Los fallos de webhook deben quedar pendientes/reintentables y tener reconciliación manual desde el panel del equipo.
10. Calcular vencimiento desde una fecha de servicio definida, no desde la visita al dashboard. Mostrar al cliente estado, fechas, formularios pendientes, progreso y próximos pasos.

## Estados mínimos

Separar `quote_status`, `order_status`, `payment_status` y `service_status`. Un ejemplo es `draft -> sent -> accepted -> pending_admin_confirmation -> active -> in_progress -> delivered -> archived`; el pago, si aplica, mantiene su propio ciclo `pending -> confirmed -> refunded/chargeback`. Adaptar los nombres al negocio y documentar cada transición.

## Controles obligatorios

- Firmas verificadas sobre cuerpo crudo y secreto del proveedor protegido.
- Idempotencia de webhook y de creación de pago.
- Comparación server-side de importe, moneda y referencia.
- Prohibición de activar por query params, frontend, página de retorno o webhook sin capability de activación.
- Reintentos con backoff, dead-letter/manual review y observabilidad.
- Auditoría de quién creó, confirmó, reintentó, canceló o revirtió.
- Manejo explícito de pagos parciales, reembolsos, chargebacks y eventos fuera de orden, aunque se implementen después.

## Validación

Probar evento válido, firma inválida, evento repetido, evento fuera de orden, importe incorrecto, orden inexistente, timeout del proveedor y activación ya realizada. Documentar el proveedor elegido y sus requisitos vigentes antes de conectar producción.

## Referencias

- [Ciclo de pago](references/payment-lifecycle.md)
- [ADR de activación](../../../contexto/decisiones/ADR-003-activacion-pago.md)
- [Arquitectura](../../../contexto/arquitectura.md)
- [Roadmap](../../../contexto/roadmap.md)
