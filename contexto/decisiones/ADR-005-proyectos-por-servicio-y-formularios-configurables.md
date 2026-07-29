# ADR-005: Un proyecto por servicio y formularios configurables

**Estado:** aceptado
**Fecha:** 2026-07-28
**Relacionado:** ADR-004, modelo MVP y matriz de permisos

## Contexto

Una cotización puede incluir varios servicios y un mismo cliente puede contratar el mismo servicio más de una vez. Cada contratación debe tener su propio estado, formularios, archivos, hitos, mensajes e historial. Los formularios cambian según el tipo de servicio y no deben crearse manualmente desde el panel.

## Decisión

- El catálogo (`service_catalog`) representa un tipo configurable de servicio.
- Una contratación concreta se representa como un proyecto (`Project`), persistido inicialmente en `service_instances`.
- Cada ítem y unidad de una orden genera un proyecto independiente.
- El catálogo define formularios, versiones, workflow, hitos y configuración aplicables.
- Al activar una orden, el sistema provisiona automáticamente `project_forms`, workflow e hitos para cada proyecto.
- Las respuestas se guardan en revisiones append-only asociadas al formulario del proyecto.
- Cada proyecto fija la versión de catálogo, workflow y formularios que recibió; publicar cambios solo afecta proyectos futuros.
- El dominio valida workflows y transiciones desde configuración versionada, sin condicionar la lógica principal a un servicio concreto.

## Invariantes

```text
order_item + unit_number -> exactamente un Project
Project -> exactamente un organization y un service_catalog
Project -> un workflow_version fijado
ProjectForm -> un Project y un form_version fijados
Respuesta -> solo puede pertenecer al ProjectForm de su Project
```

La creación debe ser idempotente. Una repetición de `ActivateOrder` devuelve los proyectos existentes y no duplica recursos derivados.

## Alternativas descartadas

- Una sola fila de servicio por cliente: no permite contratar dos veces el mismo servicio.
- Formularios globales por cliente: mezcla información de proyectos distintos y rompe el aislamiento de contexto.
- Código `if/else` por cada servicio: obliga a modificar la arquitectura al agregar servicios.
- Tabla JSON gigante por proyecto: debilita integridad, consultas, permisos e historial.
- Crear proyectos/formularios manualmente desde la UI: permite omisiones y estados parciales.

## Consecuencias

- El panel administra catálogo y configuración, pero la activación ejecuta un caso de uso transaccional.
- Se requieren versiones inmutables de workflows y formularios.
- El dashboard puede consultar proyectos, formularios pendientes e historial sin reconstruir eventos completos.
- La creación de un nuevo servicio debe limitarse a registrar configuración validada y plantillas, no a modificar el dominio.
- Se deben probar cantidades mayores que uno, servicios repetidos, cambios de catálogo y doble activación.
