# ADR-002: Backend modular y portable hacia AWS

**Estado:** aceptado
**Fecha:** 2026-07-27

## Contexto

El producto necesita autenticación, clientes, servicios, formularios, archivos, pagos y operaciones internas. Existe una posibilidad futura de usar AWS.

## Decisión

Construir un monolito modular con separación hexagonal:

```text
Dominio → Aplicación → Puertos → Adaptadores
```

El frontend consumirá una API propia. Los adaptadores encapsularán los proveedores de identidad, base de datos, archivos, pagos, notificaciones y colas.

## Motivos

- Reduce el acoplamiento a Supabase y Cloudflare.
- Permite migrar proveedores sin reescribir casos de uso.
- Mantiene una operación sencilla durante el MVP.
- Evita la complejidad prematura de microservicios.
- Permite extraer módulos posteriormente si la escala lo justifica.

## Contratos principales

```text
AuthProvider
DatabaseRepository
FileStorage
PaymentProvider
NotificationProvider
JobQueue
```

## Consecuencias

- Hay más estructura inicial que en una aplicación CRUD directa.
- Las consultas y SDKs no deben repartirse por el frontend.
- Se deberán mantener migraciones y contratos API versionados.
- Algunas capacidades específicas de proveedores no estarán disponibles directamente en el dominio.

## Alternativa descartada

Conectar cada componente directamente al SDK de Supabase o Cloudflare. Se descarta porque dificultaría una futura migración a Cognito, RDS, S3 o Lambda.
