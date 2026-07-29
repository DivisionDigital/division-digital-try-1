---
name: backend-modular-architecture
description: Usa esta skill al diseñar o implementar el backend del portal de Division Digital: módulos de dominio, API propia, Astro híbrido, adaptadores de infraestructura, contratos, despliegue en Cloudflare y migración futura a AWS. Obliga a mantener el dominio independiente de proveedores y a documentar cada decisión.
---

# Arquitectura backend modular y portable

## Objetivo

Diseñar un monolito modular como primera etapa: una aplicación desplegable sencilla, con límites de dominio claros y puertos/adaptadores que permitan cambiar Supabase, Cloudflare o servicios externos por AWS sin reescribir la lógica de negocio.

## Flujo de trabajo

1. Leer `contexto/arquitectura.md`, `contexto/roadmap.md`, `contexto/bitacora.md` y los ADR relacionados antes de proponer cambios.
2. Identificar el caso de uso y su módulo: identidad, clientes, catálogo, cotizaciones, órdenes, pagos, servicios, formularios, archivos, solicitudes, notificaciones o administración.
3. Separar cuatro capas:
   - **Dominio:** entidades, estados, reglas e invariantes; no importa Astro, Supabase, AWS, HTTP ni SDKs.
   - **Aplicación:** casos de uso y puertos; coordina transacciones y permisos.
   - **Adaptadores:** handlers HTTP, validadores, serializadores, autenticación y webhooks.
   - **Infraestructura:** PostgreSQL/Supabase, almacenamiento, correo, WhatsApp, pagos, colas y observabilidad.
4. Definir primero el contrato de entrada y salida del caso de uso. Mantener DTOs versionables y no devolver filas crudas de la base de datos.
5. Implementar inicialmente dentro del proyecto Astro con rutas server/API y componentes interactivos como islands. Extraer a un servicio separado solo cuando haya una necesidad real de escala, despliegue o equipo.
6. Encapsular cada proveedor detrás de un puerto, por ejemplo `PaymentGateway`, `FileStorage`, `NotificationSender` y `UserIdentityProvider`.
7. Diseñar la configuración por entorno mediante variables y secretos; nunca acoplar lógica a un hostname, cuenta, región o clave de un proveedor.
8. Documentar el cambio en `contexto/bitacora.md` y, si modifica una decisión estructural, crear o actualizar un ADR.

## Reglas de arquitectura

- Preferir monolito modular antes que microservicios para el MVP; los límites internos permiten extraer módulos después.
- Usar PostgreSQL como fuente de verdad transaccional. El almacenamiento de archivos, cachés y notificaciones no sustituye la base de datos.
- Mantener la activación de servicios como un caso de uso explícito y transaccional; una página de éxito del navegador nunca confirma un pago.
- Mantener los paneles de cliente y equipo como interfaces del mismo backend y aplicar autorización en servidor, no solo ocultando rutas en Astro.
- Usar eventos internos o una tabla de eventos/outbox cuando un cambio necesite notificaciones, auditoría o reintentos.
- Diseñar endpoints idempotentes para webhooks, formularios repetidos y reintentos de red.
- Evitar acceso directo generalizado a la base de datos desde componentes UI; centralizar permisos y reglas en casos de uso.

## Portabilidad hacia AWS

Conservar el dominio y los puertos. Los adaptadores iniciales pueden usar Supabase/Postgres, Cloudflare Workers, R2 y un proveedor de pagos; los futuros adaptadores pueden usar RDS/Aurora PostgreSQL, Lambda o ECS, S3, SES/SNS/SQS y Cognito. El detalle de la correspondencia está en [references/aws-portability.md](references/aws-portability.md).

## Validación antes de entregar

- Confirmar que el módulo tiene límites, caso de uso, autorización y manejo de errores definidos.
- Verificar que ningún secreto llega al cliente ni queda en el repositorio.
- Probar el caso de uso y sus adaptadores con datos representativos; probar también reintentos y estados inválidos.
- Ejecutar las comprobaciones disponibles del proyecto y documentar qué se ejecutó y qué quedó pendiente.
- Revisar que la documentación describe el cambio real y sus riesgos.

## Referencias del proyecto

- [Arquitectura actual](../../../contexto/arquitectura.md)
- [Roadmap](../../../contexto/roadmap.md)
- [Bitácora](../../../contexto/bitacora.md)
- [Portabilidad AWS](references/aws-portability.md)
