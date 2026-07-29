# ADR-007 — Frontera Data API y runtime SSR

**Estado:** aceptada
**Fecha:** 2026-07-29

## Contexto

El portal manejará datos comerciales, operativos y personales. Exponer tablas privadas al navegador, incluso con RLS, amplía innecesariamente la superficie de ataque y acopla la UI al modelo físico. El login y las rutas privadas también requieren cookies server-side y secretos inaccesibles desde bundles públicos.

## Decisión

- Astro funciona en modo `server` con el adapter de Cloudflare; `/` permanece prerenderizada.
- El navegador solo consulta directamente seis columnas públicas de servicios publicados.
- Todos los datos privados y comandos de dominio pasan por `/api/v1`.
- Auth y Storage usan sus APIs específicas, limitadas por sesión y políticas.
- Existen clientes separados para navegador, SSR por petición y servidor privilegiado.
- La secret key vive únicamente en `src/server`/runtime y nunca usa prefijo `PUBLIC_`.
- RLS continúa activa en las 28 tablas como defensa adicional.

## Consecuencias

La futura API debe autenticar, autorizar y validar cada operación, devolver DTOs y registrar auditoría. No se podrán construir pantallas privadas consultando tablas desde `supabase-js` en el navegador. A cambio se reduce IDOR/BOLA, filtración accidental de columnas y acoplamiento al proveedor, y se facilita una migración futura.

## Verificación

La matriz exacta de grants, default ACL, RLS, helpers y Storage está cubierta por pgTAP. Security Advisor no reporta hallazgos y una prueba HTTP real confirmó las políticas del bucket privado.
