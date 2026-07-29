# Checklist de seguridad backend

## Identidad y acceso

- [ ] Cada caso de uso identifica actor, recurso, acción y tenant.
- [ ] Sesión/token se valida en servidor; cookies tienen `HttpOnly`, `Secure` y `SameSite` apropiados.
- [ ] Autorización por recurso evita IDOR/BOLA y escalamiento de rol.
- [ ] Acciones privilegiadas requieren una ruta server-side y auditoría.

## Entradas y salidas

- [ ] Body, query, params, headers y archivos se validan con esquema y límites.
- [ ] SQL usa parámetros; contenido de usuario se escapa al renderizar.
- [ ] No se usa `innerHTML` con texto no confiable.
- [ ] Errores no revelan secretos, PII ni detalles internos.

## Secretos e integraciones

- [ ] Secretos solo en el entorno/secret manager; `.env` real fuera de Git.
- [ ] No se registran tokens, passwords, firmas, documentos ni números de tarjeta.
- [ ] Webhooks verifican cuerpo crudo, firma, timestamp, evento e idempotencia.
- [ ] Integraciones tienen timeout, retry limitado, backoff y circuito/manual review.

## Datos y archivos

- [ ] RLS y grants se prueban por cada rol.
- [ ] PII está minimizada, clasificada, retenida y eliminable conforme al contexto legal.
- [ ] Uploads validan tamaño, MIME real, extensión, nombre, ruta y autorización.
- [ ] Descargas usan permisos y URLs temporales; nunca se confía en un nombre de archivo del usuario.

## Operación

- [ ] Rate limiting para login, formularios, webhooks y acciones administrativas.
- [ ] Logs estructurados con correlation ID y sin datos sensibles.
- [ ] Alertas para fallos de webhook, accesos denegados y errores anómalos.
- [ ] Dependencias y lockfile revisados; backups y restauración probados.
- [ ] Se documentaron pruebas negativas y riesgos pendientes.

## Referencias

- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)
- [Ley 1581 de 2012, Colombia](https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=49981)
- [Supabase product security](https://supabase.com/docs/guides/security/product-security)
