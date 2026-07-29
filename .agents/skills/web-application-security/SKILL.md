---
name: web-application-security
description: Usa esta skill al revisar o implementar seguridad web general en Astro y su backend: XSS, CSRF, headers, CORS, validación, SQL injection, uploads, secretos, rate limiting, errores, auditoría y pruebas OWASP.
---

# Seguridad de aplicaciones web

## Objetivo

Aplicar seguridad desde el diseño a la landing, portal cliente, panel interno y API. Usar defensa en profundidad: navegador, servidor, base de datos, integraciones, dependencias y operación.

## Flujo de revisión

1. Inventariar rutas, actores, datos personales, documentos, pagos, integraciones y acciones de alto impacto. Crear un modelo de amenazas breve antes de implementar.
2. Definir autenticación, autorización por recurso, límites de organización y auditoría. No considerar una ruta oculta o una island como control de acceso.
3. Validar en servidor body, query, params, headers y archivos con esquemas estrictos, allowlists y límites de tamaño. Rechazar campos desconocidos cuando sea seguro hacerlo.
4. Usar consultas parametrizadas y codificación de salida por contexto. Escapar HTML y URL; no insertar texto del usuario con `innerHTML` sin sanitización controlada.
5. Proteger acciones basadas en cookies contra CSRF con SameSite apropiado, token CSRF y/o validación de Origin según el flujo. Restringir CORS a orígenes conocidos.
6. Configurar HTTPS, HSTS, CSP, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy` y protección contra framing. Evitar `unsafe-inline` amplio; adaptar CSP a Astro y GSAP mediante nonces/hashes cuando sea viable.
7. Proteger login, recuperación, formularios, uploads, webhooks y operaciones administrativas con rate limiting, timeouts, backoff y límites de payload.
8. Guardar secretos únicamente en variables protegidas o secret manager. No registrar tokens, contraseñas, firmas, documentos o datos completos de pago.
9. Para archivos, permitir solo formatos necesarios, validar MIME real, renombrar, limitar tamaño, almacenar fuera del webroot, mantenerlos privados y usar URLs temporales.
10. Entregar cambios sensibles solo después de pruebas positivas y negativas, revisión de dependencias, logs sin PII innecesaria y documentación en la bitácora.

## Reglas operativas

- Responder con errores genéricos en login y recuperación para evitar enumeración.
- Devolver 401 sin sesión y 403 con sesión pero sin permiso.
- Usar correlation ID en logs y no incluir secretos.
- Auditar cambios de roles, pagos, estados, archivos y acceso administrativo.
- Aplicar backups, restauración probada, gestión de incidentes y revisión periódica de dependencias.
- Tratar los webhooks como entradas no confiables: verificar firma sobre el cuerpo crudo e idempotencia.

## Estándar de referencia

Usar OWASP ASVS como checklist de requisitos y pruebas. Para decisiones de contraseñas, sesiones y uploads consultar los documentos enlazados en las referencias de esta skill.

## Referencias

- [Checklist de revisión](references/web-security-checklist.md)
- [Pruebas de abuso](references/abuse-cases.md)
- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)
- [OWASP Cheat Sheets](https://cheatsheetseries.owasp.org/)
