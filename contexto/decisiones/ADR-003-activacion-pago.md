# ADR-003: Activación administrativa y pagos desacoplados

**Estado:** aceptado
**Fecha:** 2026-07-28

## Contexto

División Digital no funciona como un e-commerce de precios fijos. El cliente se registra, solicita una cotización para uno o varios servicios, negocia el alcance y acepta una versión de la propuesta. La prestación empieza cuando un administrador confirma la cotización aceptada.

Los pagos automáticos todavía no forman parte del flujo mínimo, pero deben poder integrarse sin rediseñar órdenes, proyectos, formularios ni workflows.

## Decisión

Separar cuatro conceptos:

1. `quote`: solicitud y negociación.
2. `order`: snapshot de la versión aceptada y acuerdo que puede activarse.
3. `payment`: intento o confirmación de un proveedor, opcional en la primera versión.
4. `service_instance`/`Project`: proyecto independiente creado por cada ítem y unidad contratada.

La activación se ejecutará mediante el caso de uso `ActivateOrder`, autorizado únicamente para `admin`. Este caso de uso crea todos los proyectos y provisiona sus formularios de forma transaccional e idempotente.

Un proveedor de pagos futuro podrá confirmar pagos y cambiar la elegibilidad de la orden mediante un webhook verificado. No podrá activar proyectos directamente: la autorización de activación seguirá siendo una capability explícita y auditable. Si el negocio decide automatizarla posteriormente, se modificará esa policy sin cambiar el modelo de proyectos ni formularios.

## Flujo principal

```text
Registro
  -> solicitud de cotización
  -> revisión/modificación interna
  -> versión publicada
  -> aceptación del cliente
  -> confirmación del administrador
  -> orden activa
  -> un proyecto por servicio y unidad
  -> formularios y workflow provisionados
```

## Flujo futuro de pago

```text
Orden aceptada
  -> intento de pago
  -> webhook firmado
  -> evento idempotente
  -> pago confirmado / orden elegible
  -> ActivateOrder autorizado
```

La página de retorno del proveedor solo informa al usuario. Nunca confirma un pago ni concede acceso.

## Reglas

- El cliente puede registrarse antes de tener servicios.
- El cliente no puede activar, cancelar, cambiar precio o cambiar estado interno de un proyecto.
- Solo `admin` puede confirmar la activación en el MVP.
- Cada `order_item` y unidad contratada crea exactamente un proyecto independiente.
- La orden y sus ítems conservan snapshots inmutables.
- La activación usa una restricción única o clave idempotente por ítem/unidad.
- El webhook futuro verifica cuerpo crudo, firma, timestamp, referencia, importe, moneda e idempotencia.
- Un webhook repetido devuelve el resultado existente y no duplica proyectos, formularios ni notificaciones.
- Los efectos externos se publican mediante outbox después de confirmar la transacción.
- La confirmación manual de un pago, cuando aplique, registra administrador, fecha, motivo y auditoría.

## Motivos

- Respeta el proceso comercial real de cotización personalizada.
- Permite que un cliente tenga varias cotizaciones antes de contratar.
- Evita mezclar evidencia de pago con el inicio operativo del proyecto.
- Permite activar varios servicios en una sola operación sin perder independencia de ciclo de vida.
- Deja preparado el puerto de pagos para integración futura sin acoplar el dominio.

## Consecuencias

- Se necesitan versiones inmutables de cotización y snapshots de orden.
- La activación debe crear proyectos, formularios, hitos, eventos y outbox en una transacción.
- El panel debe diferenciar capacidad `internal` de capacidad `activate_projects`.
- Los pagos y webhooks pueden implementarse después como módulo/adaptador.
- Deben probarse doble activación, versiones reemplazadas, pagos repetidos y accesos no autorizados.
