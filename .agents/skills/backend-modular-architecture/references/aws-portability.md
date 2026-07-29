# Portabilidad de proveedores hacia AWS

La portabilidad no significa que todos los proveedores sean intercambiables sin trabajo. Significa que las reglas del negocio no dependen de ellos y que cada integración tiene un contrato pequeño, probado y reemplazable.

| Necesidad | Inicio | Posible destino AWS | Regla |
|---|---|---|---|
| PostgreSQL | Supabase Postgres | RDS/Aurora PostgreSQL | Mantener SQL/migraciones portables; no poner reglas de negocio en funciones propietarias sin necesidad. |
| Identidad | Supabase Auth | Cognito u otro IdP | El dominio recibe un `Actor` verificado, no un objeto SDK. |
| Archivos | Supabase Storage/R2 | S3 | Usar `FileStorage` y URLs temporales; guardar metadatos, no binarios en PostgreSQL. |
| Backend HTTP | Astro server/Workers | Lambda, ECS o servicio Node | Mantener casos de uso sin depender del runtime. |
| Notificaciones | proveedor de correo/WhatsApp | SES, SNS, SQS o proveedor especializado | Usar `NotificationSender`, outbox y reintentos. |
| Pagos | gateway elegido | mismo gateway o adaptador AWS-side | Verificar firma, importe e idempotencia en el caso de uso. |

## Reglas

- No importar SDKs de AWS/Supabase dentro de entidades o casos de uso.
- Centralizar configuración y crear adaptadores en `infrastructure/`.
- Definir timeouts, retries, límites y manejo de errores por puerto.
- No asumir que una transacción de PostgreSQL incluye un envío de correo, archivo o mensaje externo.
- Mantener migraciones, contratos HTTP y eventos versionados en el repositorio.
- Preparar logs estructurados con correlation ID para poder cambiar el proveedor de observabilidad.
- Antes de extraer un módulo, medir volumen, latencia, fallos, frecuencia de despliegue y autonomía del equipo.

## Referencias

- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [Amazon RDS for PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [Amazon S3 presigned URLs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-presigned-url.html)
- [AWS Lambda best practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
