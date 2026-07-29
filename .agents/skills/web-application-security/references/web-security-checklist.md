# Checklist de seguridad web

## Identidad y acceso

- [ ] Todas las rutas privadas requieren sesión en servidor.
- [ ] Cada operación comprueba pertenencia al recurso y rol.
- [ ] Respuestas de login/recuperación no permiten enumerar cuentas.
- [ ] MFA y reautenticación cubren administradores y acciones críticas.

## Input, output y navegador

- [ ] Validar body, query, params, headers y archivos en servidor.
- [ ] SQL parametrizado y salida codificada por contexto.
- [ ] No usar `innerHTML` con contenido no confiable.
- [ ] CSRF, CORS y `Origin` revisados según el transporte de sesión.
- [ ] CSP, HSTS, `nosniff`, Referrer-Policy y framing revisados.

## Archivos e integraciones

- [ ] Allowlists de formatos y tamaños.
- [ ] MIME real validado, nombre generado y almacenamiento privado.
- [ ] URLs temporales y permisos por organización.
- [ ] Webhooks verifican firma sobre cuerpo crudo e idempotencia.
- [ ] Timeouts, retries y límites de payload configurados.

## Operación

- [ ] Rate limiting en login, recuperación, formularios, uploads y administración.
- [ ] Secretos fuera de Git y del frontend.
- [ ] Logs con correlation ID y sin PII innecesaria.
- [ ] Backups y restauración probados.
- [ ] Dependencias y lockfile auditados.
- [ ] Evidencia de pruebas negativas y riesgos pendientes.
