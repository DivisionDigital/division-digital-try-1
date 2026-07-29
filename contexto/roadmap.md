# Roadmap de desarrollo

**Estado:** hoja de ruta inicial
**Fecha:** 2026-07-27

El desarrollo se realizará por fases pequeñas y verificables. Cada fase deberá dejar el sistema en un estado ejecutable y documentado.

## Estado de avance al 2026-07-29

- Fase 0: decisiones de MVP, dominio, permisos y modelo aprobadas.
- Fase 1: landing migrada a runtime SSR, dependencias endurecidas y XSS prioritario corregido; quedan mejoras funcionales no relacionadas con datos.
- Fase 2: infraestructura PostgreSQL/Auth/Storage, migraciones, RLS, grants, seed, clientes Supabase y contratos documentales completados. La API y sus casos de uso todavía no están implementados.
- Fase 3: siguiente fase activa; registro, login, recuperación, sesiones, onboarding de organización y middleware.
- Fases 4–10: pendientes.

El estado detallado de la base está en `datos/modelo-fisico-supabase.md`. Este avance no convierte el entorno de desarrollo en producción.

## Fase 0 — Descubrimiento y definición del MVP

### Objetivo

Convertir el proceso comercial y operativo en reglas claras antes de construir pantallas.

### Entregables

- Catálogo inicial de servicios.
- Selección del primer servicio piloto.
- Roles y permisos.
- Estados de cotización, orden, proyecto y formulario.
- Campos y documentos requeridos.
- Reglas de fechas y vencimientos.
- Política de activación administrativa.
- Diseño de workflows y formularios configurables por servicio.
- Decisión sobre integración de pagos futura, sin bloquear el MVP.
- Criterios de aceptación del primer flujo.

### Por qué primero

Evita diseñar una base de datos o dashboard que no represente cómo trabaja realmente el equipo.

## Fase 1 — Estabilización de la landing

### Objetivo

Preparar la aplicación existente para crecer sin trasladar deuda técnica al portal.

### Entregables

- Actualización controlada de dependencias.
- Corrección de inserciones inseguras del chat.
- Validación y estados del formulario de contacto.
- Headers de seguridad y revisión de CSP.
- Mejoras de accesibilidad prioritarias.
- Scripts de `check`, build, lint y pruebas.
- Línea base de rendimiento.

### Validación

`pnpm exec astro check`, `pnpm run build` y pruebas funcionales de navegación y contacto.

## Fase 2 — Base del backend y contratos

### Objetivo

Crear la frontera entre Astro y la lógica de negocio.

### Entregables

- Estructura `src/server`.
- Módulos y puertos iniciales.
- Contratos API.
- Validaciones compartidas.
- Configuración de entornos.
- Manejo uniforme de errores.
- Migraciones iniciales.
- Health check seguro.

### Por qué ahora

El dashboard debe consumir casos de uso y contratos estables, no contener reglas de negocio dispersas.

## Fase 3 — Identidad y permisos

### Objetivo

Permitir acceso seguro al cliente y al equipo.

### Entregables

- Registro de clientes y creación segura de organización/membresía inicial.
- Login y recuperación.
- Sesión server-side.
- Perfil y organización.
- Membresías y roles.
- Middleware de protección.
- Primera matriz de autorización.

### Validación

Probar que un cliente no puede consultar ni modificar datos de otra organización.

## Fase 4 — Cotizaciones, órdenes y activación de proyectos

### Objetivo

Convertir una cotización aceptada y confirmada por un administrador en proyectos operables, uno por servicio y unidad contratada.

### Entregables

- Cotización personalizada.
- Versiones inmutables de cotización e ítems.
- Vigencia y fechas.
- Orden y snapshot de lo aceptado.
- Caso de uso `ActivateOrder` protegido para `admin`.
- Activación idempotente por ítem y unidad.
- Creación automática de proyectos, formularios, hitos, eventos y outbox.
- Pagos como módulo opcional preparado para integración futura.

### Por qué antes del dashboard completo

El dashboard debe mostrar servicios reales activados por un flujo real, no datos ficticios.

## Fase 5 — Primer servicio vertical

### Objetivo

Implementar un servicio completo de inicio a fin.

### Entregables

- Tarjeta del servicio en el dashboard.
- Proyecto independiente visible en `Mis Servicios`.
- Estado y progreso.
- Fechas relevantes.
- Formularios provisionados automáticamente desde el catálogo.
- Guardado de respuestas.
- Historial de revisiones de respuestas.
- Archivos privados.
- Hitos y actualizaciones.
- Vista del equipo para revisar la información.

### Criterio de finalización

Un cliente de prueba puede completar todo el proceso y el equipo puede operarlo sin intervenir directamente en la base de datos.

## Fase 6 — Panel del equipo

### Objetivo

Dar al equipo una herramienta operativa segura.

### Entregables

- Clientes y organizaciones.
- Cotizaciones.
- Versiones y aceptación de cotizaciones.
- Órdenes y activación administrativa.
- Proyectos activos.
- Formularios recibidos.
- Gestión de estados.
- Asignación de responsables.
- Solicitudes de información.
- Historial de actividad.

## Fase 7 — Generalización de módulos

### Objetivo

Reutilizar lo aprendido en el primer servicio para incorporar más servicios.

### Entregables

- Catálogo configurable.
- Configuración versionada de workflows.
- Plantillas de formularios versionadas.
- Hitos reutilizables.
- Reglas de documentos requeridos.
- Estados por tipo de servicio.
- Nuevos servicios piloto.

### Regla

No construir un editor genérico de formularios hasta haber implementado y probado varios formularios reales.

## Fase 8 — Notificaciones y automatizaciones

### Entregables

- Correos de invitación.
- Avisos de formularios pendientes.
- Avisos de cambio de estado.
- Recordatorios de vencimiento.
- Notificaciones de archivos y mensajes.
- Procesamiento asíncrono cuando sea necesario.

## Fase 9 — Calidad, seguridad y operación

### Entregables

- Pruebas unitarias del dominio.
- Pruebas de API.
- Pruebas end-to-end.
- Pruebas de aislamiento entre clientes.
- Rate limiting.
- Auditoría de permisos.
- Backups y restauración.
- Monitoreo de errores.
- Revisión de datos personales y retención.
- Procedimiento de despliegue y rollback.

## Fase 10 — Evolución hacia AWS

### Objetivo

Migrar o integrar servicios AWS solo cuando exista una necesidad concreta.

### Posibles sustituciones

```text
Supabase Auth       → Cognito
PostgreSQL          → RDS/Aurora PostgreSQL
Storage             → S3
Cloudflare Worker   → Lambda, ECS o Fargate
Colas               → SQS/EventBridge
Email               → SES
Secretos            → Secrets Manager
```

La migración debe ser incremental y validarse con exportación de datos, pruebas de compatibilidad y un entorno de staging.

## Alcance del primer MVP

Debe incluir:

- Registro y login de cliente.
- Un servicio real configurable.
- Dashboard del cliente.
- Uno o varios formularios por proyecto.
- Carga de archivos.
- Progreso y estados.
- Cotización, aceptación y confirmación administrativa.
- Activación idempotente de proyectos.
- Panel básico del equipo.

La integración de pagos automáticos queda preparada mediante puertos y tablas, pero no es un requisito para activar el primer flujo si el negocio opera con confirmación administrativa.

Debe quedar fuera inicialmente:

- Aplicación móvil.
- Microservicios.
- Constructor visual de formularios.
- Chat avanzado en tiempo real.
- Suscripciones complejas.
- IA.
- Reportes avanzados.

## Regla de documentación

Cada cambio deberá actualizar `contexto/bitacora.md`. Las decisiones que afecten la arquitectura deberán tener o actualizar un ADR en `contexto/decisiones/`.
