# Mapa de Islands del portal

## Landing

Mantener Hero, copy, tarjetas, SEO y footer en `.astro`. Usar script local o una island pequeña para menú, carrusel, chat y filtros. Hidratar abajo del viewport con `client:visible` cuando sea posible.

## Login

Renderizar formulario y estados iniciales server-side. La island puede gestionar loading, errores visuales y doble envío; la sesión, cookies, PKCE, callbacks y rate limiting viven en el servidor.

## Portal cliente

- `ServiceCard`: HTML inicial, sin framework si no hay interacción.
- `ServiceFilters`: island pequeña; filtros en URL si deben compartirse.
- `FormWizard`: React/otro framework solo si los pasos y validaciones justifican estado complejo.
- `FileUploader`: island para progreso; API y Storage validan permisos.
- `ProgressTimeline`: HTML inicial; island solo para filtros o actualizaciones autorizadas.

## Panel equipo

Comenzar con Astro server-side y extraer módulos de alta interacción. Priorizar componentes React para editores complejos, tablas con edición y drag-and-drop; no envolver toda la aplicación sin evidencia.
