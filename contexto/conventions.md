# Convenciones del proyecto

**Estado:** estándar de diseño para el backend futuro
**Fecha:** 2026-07-28

## 1. Arquitectura de código

- `domain/` contiene entidades, value objects, estados e invariantes puras.
- `application/` contiene casos de uso, políticas y coordinación transaccional.
- `ports/` contiene interfaces para identidad, base de datos, storage, pagos, notificaciones y jobs.
- `adapters/` contiene HTTP, Supabase, Cloudflare, storage y proveedores externos.
- `infrastructure/` contiene configuración, conexiones, migraciones y observabilidad.
- La lógica de dominio no importa Astro, Supabase, Cloudflare, AWS ni SDKs externos.

## 2. Nombres

- Entidades de dominio en PascalCase: `Project`, `QuoteVersion`.
- Casos de uso en verbo + objeto: `ActivateOrder`, `SubmitProjectForm`.
- Tablas en `snake_case` plural.
- Columnas en `snake_case`.
- Estados en `snake_case` y con transiciones documentadas.
- Identificadores públicos y de negocio como UUID generados en servidor.

## 3. Datos

- PostgreSQL es la fuente de verdad transaccional.
- Usar `timestamptz` en UTC.
- Usar `numeric` para dinero y guardar `currency`.
- Aplicar `NOT NULL`, foreign keys, `UNIQUE`, `CHECK` y `ON DELETE` explícitos.
- Mantener estado actual para lectura rápida e historial append-only para cambios relevantes.
- No borrar historia comercial, pagos confirmados, revisiones de respuestas o auditoría.
- Usar JSONB solo para estructuras variables, versionadas y validadas.
- Los archivos binarios viven en object storage privado; PostgreSQL conserva metadata y ownership.

## 4. Multi-tenancy y autorización

- Cada recurso de negocio debe tener `organization_id` o una ruta de ownership inequívoca.
- El actor se obtiene de la sesión verificada, no del body.
- No confiar en `role`, `user_id`, `organization_id`, `project_id`, precio o estado enviados por el cliente.
- API y RLS deben imponer la autorización.
- `UPDATE` debe proteger estado actual y futuro con `USING` y `WITH CHECK`.
- No usar `user_metadata` para permisos.
- No exponer `service_role`, secrets ni credenciales de proveedores.
- `anon` y `authenticated` no reciben grants sobre tablas privadas. La única proyección Data API del navegador son seis columnas del catálogo publicado.
- Los datos privados y comandos de dominio pasan por `/api/v1`; cualquier excepción requiere ADR, migración, RLS, grants mínimos y pruebas negativas.

## 5. API conceptual

- La API recibe comandos y consultas, no filas arbitrarias.
- Los DTOs deben ser versionables y mínimos.
- Errores esperados usan códigos consistentes: `401`, `403`, `404`, `409`, `422` y `429`.
- Las acciones repetibles aceptan idempotency keys cuando cambian estado.
- Los webhooks verifican cuerpo crudo, firma, timestamp y evento antes de mutar datos.
- No se hacen llamadas HTTP de proveedores dentro de una transacción PostgreSQL abierta.

## 6. Seguridad y privacidad

- Validar body, query, params, headers y archivos en servidor.
- Escapar contenido de usuario y evitar `innerHTML` con datos no confiables.
- Aplicar rate limiting a registro, login, cotizaciones, uploads, webhooks y acciones administrativas.
- Usar cookies `HttpOnly`, `Secure` y `SameSite` adecuadas.
- Registrar auditoría sin passwords, tokens, firmas, documentos completos ni datos de pago sensibles.
- Usar URLs temporales para descargar archivos.
- Minimizar PII y definir retención antes de producción.

## 7. Documentación y cambios

Cada cambio relevante debe actualizar:

1. Documento funcional o técnico afectado.
2. ADR si cambia una decisión estructural.
3. `contexto/bitacora.md` con objetivo, archivos, validaciones y riesgos.
4. Tests o evidencia de validación cuando el código exista.

La documentación es parte del producto. Si el código contradice estos documentos, el cambio no se considera terminado hasta actualizar ambos lados.
