# Bitácora de cambios

## 2026-07-29 — Cierre documental de la infraestructura de datos

- **Objetivo:** consolidar el desarrollo completo del modelo Supabase/PostgreSQL antes de iniciar autenticación, sin registrar información administrativa ajena al contrato técnico.
- **Archivos afectados:** README principal, README de Supabase, modelo físico, RLS/Storage, roadmap, flujo backend, convenciones, índice de contexto, skill de autorización PostgreSQL/RLS y esta bitácora.
- **Cambios realizados:** se documentaron las tres etapas de migraciones, la frontera exacta de Data API, funciones privadas, políticas, seed, Storage, promoción por entornos, responsabilidades pendientes del backend y estado de avance hacia login.
- **Validaciones:** historial local/remoto de 18 migraciones; 28/28 tablas con RLS; 34 políticas públicas + 2 de Storage; cero grants de tabla para navegador; 12 grants de columna del catálogo; 62/62 pgTAP; seed 1 servicio/1 workflow/2 formularios/3 hitos; Security Advisor limpio; `astro check` sin diagnósticos y auditoría de producción sin vulnerabilidades conocidas.
- **Skills:** solo se actualizó `postgresql-authorization-rls` porque era necesario fijar la decisión vigente de no exponer datos privados mediante Data API. Las demás skills revisadas continúan alineadas.
- **Pendientes:** implementar login y `/api/v1`; verificar por entorno configuración Auth, SMTP, Turnstile, URLs, secretos, backups y red antes de exposición pública.

## 2026-07-29 — Endurecimiento previo al login

- **Objetivo:** dejar el modelo remoto y el runtime preparados para implementar login y `/api/v1` sin exponer datos privados.
- **Archivos afectados:** tres migraciones nuevas, suites pgTAP, configuración Supabase, clientes Supabase, Astro/Cloudflare, dependencias, componentes de landing, README, arquitectura, seguridad, modelo físico, contrato API y ADR-007.
- **Cambios realizados:** allowlist de seis columnas públicas del catálogo; grants y default ACL revocados; `service_role` mínimo; owner defensivo; inmutabilidad completa de versiones, órdenes, proyectos, formularios, pagos, webhooks, outbox y archivos; Storage pendiente/no expirado; Astro SSR con landing prerenderizada; clientes browser/SSR/server separados; variables tipadas; XSS del chat corregido y enlaces externos endurecidos.
- **Validaciones:** 18 migraciones remotas alineadas; seed idempotente 1/1/2 tras dos ejecuciones; 62/62 pgTAP; prueba HTTP Auth/Storage aprobada y fixtures eliminados; `astro check` y build sin diagnósticos; preview servido por `workerd` con HTTP 200; auditoría de producción sin vulnerabilidades conocidas; Security Advisor limpio. Performance Advisor solo informa índices sin uso en una base sin carga.
- **Pendientes no bloqueantes para código local:** aplicar en el panel remoto las reglas Auth de contraseña de 12 caracteres, complejidad y reautenticación; email confirmado y rotación ya están activas. Turnstile deberá habilitarse antes de exposición pública.

## 2026-07-28 — Implementación del modelo Supabase/PostgreSQL

- **Objetivo:** materializar la infraestructura de datos aprobada para el portal sin desarrollar endpoints ni lógica backend.
- **Archivos afectados:** `supabase/config.toml`, `supabase/migrations/`, `supabase/seed.sql`, `supabase/tests/database/`, `package.json`, `pnpm-lock.yaml`, documentación de arquitectura, datos, seguridad, API, ADR-006 y esta bitácora.
- **Cambios realizados:** se creó `division-digital-dev` (`drvvtxbvgpygvcvqqofd`) en São Paulo sobre PostgreSQL 17; se fijó Supabase CLI `2.110.0`; se implementaron 28 tablas, constraints, snapshots, 15 migraciones, Auth, helpers privados, RLS, grants explícitos, bucket privado `project-files`, seed idempotente de Landing Page y pruebas pgTAP.
- **Decisiones:** organizaciones multiusuario; membresías cliente `owner|member`; autoridad global separada en `staff_members` con `team|admin`; solo `admin` tendrá `activate_projects`; COP predeterminada; workflows y formularios versionados; sin triggers de dominio, cron, proveedor de pagos ni purga física.
- **Validaciones:** migraciones remotas aplicadas una por una; historial local/remoto alineado; seed ejecutado dos veces; 27 pruebas pgTAP aprobadas, incluidas rutas de Storage; 28/28 tablas públicas con RLS; aislamiento cliente A/B y diferencia team/admin comprobados; Security Advisor limpio; Performance Advisor sin FKs no indexadas; plan del dashboard usa el índice de organización/estado.
- **Riesgos o pendientes:** los avisos informativos de índices sin uso requieren carga representativa antes de decidir; pgTAP queda instalado solo en desarrollo; faltan política legal de retención, SLO/RPO/RTO, pipeline de promoción y los futuros casos de uso de API, pagos, webhooks y outbox.

## 2026-07-24 — Análisis inicial

- Se inspeccionó la estructura, configuración, componentes, estilos, assets y documentación existentes.
- Se ejecutó `pnpm exec astro check`: 0 errores, 0 advertencias y 0 avisos.
- Se ejecutó `pnpm run build`: compilación estática exitosa.
- Se creó el informe técnico inicial en `informe-analisis-inicial.md`.
- No se modificó la lógica de la aplicación.

## 2026-07-24 — Animaciones independientes de Windows

- **Objetivo:** mantener las animaciones visuales de la landing activas aunque el sistema operativo comunique la preferencia `prefers-reduced-motion`.
- **Archivos afectados:** `InteractiveBackground.astro`, `Hero.astro`, `Services.astro`, `Showcase.astro` y `ChatWidget.astro`.
- **Cambios realizados:** se retiraron las consultas CSS y JavaScript a `prefers-reduced-motion`; se conservaron las pausas por pestaña oculta, sección fuera de viewport y breakpoints responsive.
- **Validaciones:** `pnpm exec astro check` y `pnpm run build` ejecutados correctamente; no quedan referencias a `prefers-reduced-motion`, `motionQuery` ni `onMotionChange` dentro de `src/`.
- **Riesgos o pendientes:** esta decisión prioriza una experiencia animada uniforme sobre la preferencia de reducción de movimiento del sistema.

## 2026-07-24 — Carrusel comercial de servicios

- **Objetivo:** reemplazar el collage visual de servicios por una presentación comercial llamativa, interactiva y con rutas directas de cotización.
- **Archivos afectados:** `Services.astro`, `Contact.astro`, `Footer.astro` y `README.md`.
- **Cambios realizados:** se creó un carrusel de siete servicios con tres tarjetas visibles en escritorio, dos en tablet y una en móvil. Incluye imágenes optimizadas, controles, contador, avance automático con GSAP, microinteracciones y una banda de cotización protagonista. Cada CTA conserva la selección de servicio antes de llevar al formulario.
- **Validaciones:** comprobación visual local del carrusel y del avance automático. `pnpm exec astro check` y `pnpm run build` terminan correctamente.
- **Riesgos o pendientes:** siete imágenes de `src/assets/Servicios/` vuelven a formar parte del build para reforzar el diseño visual; las demás imágenes originales siguen sin importarse.

## Plantilla para próximos cambios

### YYYY-MM-DD — Título

- **Objetivo:**
- **Archivos afectados:**
- **Cambios realizados:**
- **Validaciones:**
- **Riesgos o pendientes:**

## 2026-07-28 — Corrección del flujo de proyectos por servicio

- **Objetivo:** alinear la arquitectura con el proceso real: registro previo del cliente, cotización multi-servicio, confirmación administrativa y creación automática de proyectos independientes.
- **Archivos afectados:** `contexto/arquitectura.md`, `contexto/datos/modelo-relacional.md`, `contexto/datos/modelo-mvp.md`, `contexto/roadmap.md`, `contexto/seguridad/matriz-permisos.md`, `contexto/decisiones/ADR-003-activacion-pago.md`, `contexto/decisiones/ADR-004-modelo-relacional-multitenant.md`, `contexto/decisiones/ADR-005-proyectos-por-servicio-y-formularios-configurables.md`, `contexto/README.md` y las instrucciones de autenticación locales.
- **Decisiones:** el cliente puede registrarse sin servicios; una cotización tiene versiones inmutables; `ActivateOrder` crea un proyecto por ítem/unidad; los formularios se provisionan desde el catálogo y quedan ligados al proyecto; solo `admin` activa en el MVP; los pagos futuros quedan desacoplados y solo podrán marcar elegibilidad mediante webhooks verificados.
- **Validaciones:** revisión documental de entidades, cardinalidades, ownership, idempotencia, RLS, permisos, workflows y compatibilidad con el backend modular portable.
- **Riesgos o pendientes:** confirmar proveedor de autenticación/pagos, servicio piloto, configuración real de formularios/workflows, política de pago previa a activación y requisitos legales de registro y tratamiento de datos.

## 2026-07-28 — Documentación canónica del diseño de dominio

- **Objetivo:** convertir el análisis aprobado en documentación permanente para que futuras implementaciones no dependan del contexto de una conversación.
- **Archivos afectados:** `contexto/backend-flow.md`, `contexto/domain-model.md`, `contexto/use-cases.md`, `contexto/conventions.md`, `docs/api-design.md`, `contexto/README.md`, `contexto/arquitectura.md` y este archivo.
- **Decisiones documentadas:** flujo completo desde registro hasta operación de proyectos; entidades y relaciones; `ActivateOrder`; estados y transiciones; permisos; convenciones de capas, datos, seguridad, API e idempotencia.
- **Validaciones:** revisión de consistencia contra arquitectura, modelo MVP, matriz de permisos, ADRs y skills locales. No se implementaron endpoints, migraciones ni módulos funcionales.
- **Riesgos o pendientes:** el diseño de API es conceptual; deberá convertirse en contratos ejecutables solo después de aprobar el plan de implementación y seleccionar proveedores/runtime.

## 2026-07-28 — Diseño completo de la API backend

- **Objetivo:** documentar el contrato de API antes de implementar cualquier endpoint.
- **Archivo afectado:** `docs/api-design.md`, además de su referencia en `contexto/README.md`.
- **Decisiones:** usar `/api/v1`, una ruta canónica `/projects` para el agregado `Project`, formularios y respuestas anidados al proyecto, activación únicamente mediante `POST /orders/{orderId}/activate`, respuestas/error envelopes consistentes, comandos explícitos, RLS, idempotencia y webhooks separados.
- **Validaciones:** cobertura de casos de uso, revisión de duplicados de rutas, permisos por rol, dependencias entre entidades, estados, concurrencia y seguridad contra IDOR/BOLA.
- **Riesgos o pendientes:** el contrato requiere aprobación antes de generar el plan de implementación; quedan por confirmar runtime, proveedor de identidad, proveedor de pagos y detalles finales de DTOs.

## 2026-07-24 — Corrección de colores hover en servicios

- Se normalizaron los colores de acento del carrusel a componentes RGB separados por espacios.
- Esto hace válida la sintaxis `rgb(var(--service-rgb) / transparencia)` usada en bordes, sombras y gradientes, restaurando los colores de cada tarjeta al pasar el cursor.
## 2026-07-24 — Jerarquía visual del círculo decorativo

- Se definieron capas explícitas dentro de cada tarjeta de servicio.
- El círculo de acento quedó detrás del degradado y de la información para funcionar como fondo y no superponerse al contenido.
## 2026-07-24 — Círculo decorativo detrás de la imagen

- Se colocó el círculo de acento en la capa base de la zona visual de cada tarjeta.
- La imagen se renderiza sobre él, de modo que el círculo no se percibe superpuesto; su color solo se integra de forma sutil mediante la opacidad existente de la imagen.
## 2026-07-24 — Hover contenido en tarjetas de servicios

- Se reemplazó la sombra exterior del hover por un realce interno de borde y color.
- La tarjeta conserva su tamaño y no invade visualmente el espacio de las tarjetas contiguas.
## 2026-07-24 — Etiquetas de alcance y espacio seguro del carrusel

- Se añadió espacio inferior interno a la ventana del carrusel para evitar el recorte visual de las tarjetas.
- El detalle en párrafo antes del CTA se reemplazó por tres etiquetas concretas por servicio, con un indicador de color que refuerza la identidad visual de cada tarjeta.
## 2026-07-24 — Legibilidad de etiquetas de servicio

- Se mantuvo el diseño de etiquetas, aumentando su tamaño, contraste y el grosor tipográfico.
- Se sustituyó la tipografía monoespaciada por Space Grotesk para una lectura más clara en pantallas pequeñas y grandes.

## 2026-07-27 — Base documental de arquitectura y roadmap

- **Objetivo:** establecer el contexto técnico y la ruta de desarrollo antes de comenzar la implementación del portal de clientes y el panel interno.
- **Archivos afectados:** `contexto/README.md`, `contexto/arquitectura.md`, `contexto/roadmap.md`, `contexto/decisiones/ADR-001-astro-hibrido.md`, `contexto/decisiones/ADR-002-backend-portable.md`, `contexto/decisiones/ADR-003-activacion-pago.md` y este archivo.
- **Cambios realizados:** se documentó la arquitectura objetivo basada en Astro híbrido, backend modular con puertos y adaptadores, API propia, activación de servicios mediante pagos verificados y una futura migración posible hacia AWS. Se definieron las fases del proyecto y el alcance del primer MVP.
- **Validaciones:** revisión de consistencia documental con el estado actual del repositorio y las decisiones acordadas durante la orientación del proyecto.
- **Riesgos o pendientes:** todavía deben confirmarse el primer servicio piloto, el proveedor de pagos, el proveedor inicial de autenticación/datos y los requisitos legales de tratamiento de información.

## 2026-07-28 — Skills locales de backend

- **Objetivo:** convertir la investigación técnica de backend en conocimiento reutilizable durante la implementación del portal.
- **Archivos afectados:** `.agents/skills/backend-modular-architecture/`, `.agents/skills/postgresql-data-modeling/`, `.agents/skills/backend-security/`, `.agents/skills/payment-webhook-workflows/`, `.gitignore`, `contexto/README.md` y este archivo.
- **Cambios realizados:** se crearon cuatro skills con instrucciones accionables y referencias sobre arquitectura modular portable a AWS, modelado y operación de PostgreSQL/Supabase, seguridad backend y ciclo de cotización-pago-webhook-activación. Cada skill incluye metadatos `agents/openai.yaml` para invocación desde el proyecto.
- **Validaciones:** se ejecutó la inicialización oficial de cada skill y una revisión estructural de sus frontmatter, metadatos y referencias. El `quick_validate.py` oficial no pudo ejecutarse porque los runtimes Python disponibles no incluyen `PyYAML`.
- **Riesgos o pendientes:** las reglas de proveedores de pagos, Supabase y AWS deberán verificarse contra su documentación vigente cuando se implemente cada integración concreta; todavía no se instalaron dependencias ni se modificó el backend de la aplicación.

## 2026-07-28 — Skills de seguridad, autenticación y autorización

- **Objetivo:** convertir la investigación de seguridad del portal, login, sesiones y PostgreSQL en procedimientos reutilizables durante el desarrollo.
- **Archivos afectados:** `.agents/skills/web-authentication-sessions/`, `.agents/skills/postgresql-authorization-rls/`, `.agents/skills/web-application-security/`, `.agents/skills/backend-security/SKILL.md`, `.gitignore`, `contexto/README.md` y este archivo.
- **Cambios realizados:** se crearon skills para autenticación server-side en Astro/Supabase, cookies, PKCE, callbacks, middleware, roles y sesiones; autorización por organizaciones con PostgreSQL/RLS; y seguridad web integral con OWASP, XSS, CSRF, headers, validación, uploads, secretos, rate limiting y casos de abuso. La skill general de backend ahora enlaza las especializadas.
- **Validaciones:** se ejecutó `init_skill.py` para las tres skills nuevas y se revisaron manualmente frontmatter, prompts, referencias, enlaces relativos y separación de responsabilidades. El validador oficial sigue pendiente por la ausencia de `PyYAML` en los runtimes Python disponibles.
- **Riesgos o pendientes:** las decisiones finales de proveedor, runtime Astro/Cloudflare, método de login y configuración Supabase deberán validarse con documentación vigente al implementar; no se modificó código funcional de la aplicación.

## 2026-07-28 — Skills de Astro Islands

- **Objetivo:** convertir la investigación sobre Islands de Astro en guías reutilizables para la landing, el portal de clientes y el panel interno.
- **Archivos afectados:** `.agents/skills/astro-islands-architecture/`, `.agents/skills/astro-islands-performance/`, `.agents/skills/astro-islands-portal-patterns/`, `.gitignore`, `contexto/README.md` y este archivo.
- **Cambios realizados:** se crearon skills para seleccionar directivas `client:*`, usar Server Islands y renderizado on-demand, optimizar hidratación/JavaScript/estado compartido y aplicar Islands a la arquitectura concreta de División Digital. Se añadieron referencias a la documentación oficial de Astro.
- **Validaciones:** se ejecutó `init_skill.py` para las tres skills nuevas y se revisaron manualmente frontmatter, metadatos, referencias, enlaces relativos, ausencia de plantillas TODO y separación entre cliente/servidor.
- **Riesgos o pendientes:** la directiva final de cada componente deberá verificarse con mediciones de rendimiento y el runtime/adapter elegido; no se modificó código funcional de la aplicación.

## 2026-07-28 — Matriz inicial de permisos

- **Objetivo:** definir el alcance de acceso del cliente y del panel interno antes de implementar autenticación, API y políticas RLS.
- **Archivos afectados:** `contexto/seguridad/matriz-permisos.md`, `contexto/README.md`, `contexto/arquitectura.md` y este archivo.
- **Decisiones:** el cliente solo puede consultar y modificar su propia información permitida, organización, servicios, formularios, archivos y comunicaciones. Equipo y Admin comparten todos los permisos de negocio del panel interno durante el MVP. Se recomienda resolverlos mediante una capacidad común `internal`, dejando la diferenciación de Admin para una necesidad futura.
- **Controles definidos:** autorización en frontend solo como UX; validación obligatoria en API/casos de uso; RLS por organización; el cliente no puede cambiar rol, organización, estado de pago o estado interno; procesos de sistema y secretos permanecen server-side.
- **Validaciones:** revisión de consistencia con la arquitectura, roadmap y skills de autenticación/RLS; se documentaron pruebas positivas, negativas y casos de aislamiento entre clientes.
- **Pendientes:** confirmar si una cuenta cliente representará siempre a una persona o si desde el MVP una organización podrá tener múltiples miembros.

## 2026-07-28 — Skills y documentación del modelo relacional

- **Objetivo:** convertir la investigación de modelos de datos en conocimiento reutilizable y establecer la decisión de datos para el portal antes de crear migraciones.
- **Archivos afectados:** `.agents/skills/relational-data-modeling/`, `.agents/skills/postgresql-data-modeling/SKILL.md`, `.gitignore`, `contexto/datos/modelo-relacional.md`, `contexto/datos/modelo-mvp.md`, `contexto/decisiones/ADR-004-modelo-relacional-multitenant.md`, `contexto/README.md`, `contexto/arquitectura.md` y este archivo.
- **Decisiones:** PostgreSQL relacional multi-tenant como fuente de verdad; base/schema compartidos en el MVP con `organization_id`, membresías y RLS; normalización pragmática; JSONB solo para formularios versionados y metadata controlada; estado actual más historial append-only; archivos en object storage privado con metadata en PostgreSQL; sin EAV, base por cliente, particionamiento ni event sourcing global prematuros.
- **Cambios realizados:** se creó la skill especializada con referencias de selección de modelo y patrones híbridos; la skill de PostgreSQL ahora enlaza esa decisión; se documentó el modelo conceptual, el inventario lógico MVP, las relaciones, invariantes, índices candidatos, migraciones y una ADR formal.
- **Validaciones:** revisión manual de frontmatter, prompt, referencias, enlaces relativos, consistencia entre arquitectura, permisos y modelo, y comprobación posterior de diff/estructura. El validador oficial de skills sigue condicionado por la ausencia de `PyYAML` en los runtimes Python disponibles.
- **Riesgos o pendientes:** confirmar organización multi-miembro, servicio piloto, formularios reales, estados, proveedores, moneda, requisitos legales, volumen y retención antes de generar la primera migración SQL.
