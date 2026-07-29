# Division Digital

Landing estatica construida con Astro para presentar los servicios de Division Digital: soluciones e-commerce, inteligencia artificial, chat multiagente, automatizacion comercial y experiencias digitales de alto impacto.

El proyecto esta organizado como una pagina unica con secciones modulares, animaciones GSAP, fondo interactivo en canvas, modulo comercial de servicios, mockup de portafolio, formulario de cotizacion y widget flotante de chat.

## Stack principal

- Astro 7.1.6 en modo `server`
- Adapter Cloudflare 14.1.7 para Workers
- TypeScript con configuracion strict de Astro
- GSAP 3 para animaciones
- GSAP ScrollTrigger para animaciones al hacer scroll
- GSAP Flip para la galeria dinamica de servicios
- CSS modular dentro de componentes Astro
- CSS global con tokens de diseno
- pnpm como gestor de paquetes
- Cloudflare Workers para SSR; la landing `/` continúa prerenderizada
- Supabase PostgreSQL 17, Auth y Storage como infraestructura de datos del portal
- Supabase CLI `2.110.0` fijada como dependencia de desarrollo

## Requisitos

- Node.js `>=22.12.0`
- pnpm

## Instalacion

```powershell
pnpm install
```

## Comandos disponibles

```powershell
pnpm dev
```

Inicia el servidor de desarrollo de Astro.

```powershell
pnpm build
```

Genera el bundle SSR para Cloudflare en `dist/`; la landing `/` continúa prerenderizada.

```powershell
pnpm preview
```

Sirve localmente el build de produccion.

```powershell
pnpm run check
```

Valida tipos y diagnosticos de archivos Astro.

```powershell
pnpm exec supabase --version
```

Ejecuta la CLI versionada del proyecto. `supabase db reset` y `supabase test db` requieren Docker.

## Estructura del proyecto

```text
/
|-- public/
|   |-- logo174.png
|   |-- marcas/
|   `-- Servicios/
|-- src/
|   |-- components/
|   |-- layouts/
|   |-- pages/
|   `-- styles/
|-- docs/
|   `-- deploy-cloudflare-workers.md
|-- supabase/
|   |-- migrations/
|   |-- tests/database/
|   |-- config.toml
|   `-- seed.sql
|-- astro.config.mjs
|-- package.json
|-- tsconfig.json
`-- wrangler.jsonc
```

## Contexto y seguimiento

La carpeta `contexto/` conserva el diagnóstico técnico y la bitácora de cambios del proyecto:

- `contexto/informe-analisis-inicial.md`: análisis de arquitectura, funcionamiento, rendimiento, seguridad y preparación para servicios.
- `contexto/bitacora.md`: registro de cambios, decisiones y validaciones futuras.
- `contexto/datos/modelo-fisico-supabase.md`: diccionario de tablas, ERD, estados, migraciones y validaciones del modelo implementado.
- `contexto/seguridad/rls-supabase.md`: RLS, grants y politicas del bucket privado.
- `supabase/README.md`: operación de migraciones, validación y promoción por entornos.

## Infraestructura de datos

El entorno remoto de desarrollo es `division-digital-dev` (`drvvtxbvgpygvcvqqofd`) en `sa-east-1`. Las migraciones imperativas de `supabase/migrations/` son la unica fuente de verdad del esquema.

La implementacion incluye 28 tablas publicas con RLS, autoridad cliente e interna separadas, snapshots comerciales, formularios y workflows versionados, auditoria/outbox y el bucket privado `project-files`. Las 18 migraciones remotas están alineadas. Las 62 aserciones pgTAP están aprobadas y Security Advisor no presenta hallazgos. El seed idempotente publica el servicio piloto Landing Page; no contiene usuarios, datos personales, pagos ni secretos.

El Data API solo expone al navegador seis columnas seguras del catálogo publicado. Perfiles, organizaciones, cotizaciones, proyectos, invitaciones, auditoría, webhooks y outbox se consumirán exclusivamente mediante la futura `/api/v1`. Ya existen clientes Supabase separados para navegador, SSR por petición y servidor privilegiado; no hay endpoints ni pantallas de login todavía. El detalle verificable y el flujo de promoción están en `contexto/datos/modelo-fisico-supabase.md`.

Copiar `.env.example` a un archivo local ignorado por Git y definir:

```text
PUBLIC_SUPABASE_URL
PUBLIC_SUPABASE_PUBLISHABLE_KEY
SUPABASE_SECRET_KEY
```

La secret key solo puede existir en el runtime server y nunca debe usar el prefijo `PUBLIC_`.

## Pagina principal

La ruta principal se define en `src/pages/index.astro`. Desde ahi se ensamblan las secciones del sitio:

- `InteractiveBackground`: fondo global interactivo con particulas en canvas.
- `Navbar`: navegacion fija con efecto glassmorphism y menu movil.
- `Hero`: bloque principal con CTA, metricas y animaciones de entrada.
- `Services`: carrusel interactivo de servicios con imagenes, controles y accesos directos a cotizacion.
- `Showcase`: mockup visual de e-commerce y carrusel de marcas.
- `Process`: timeline animado del proceso de trabajo.
- `ChatFeature`: demostracion visual del chat multiagente.
- `About`: seccion de mision, vision, valores e indicadores de confianza.
- `Contact`: formulario visual de contacto e informacion comercial.
- `Footer`: enlaces, datos de contacto y redes.
- `ChatWidget`: widget flotante de chat, actualmente solo interfaz.

## Sistema visual

El sistema base esta en `src/styles/global.css` e incluye:

- Reset CSS.
- Variables globales de color, espaciado, sombras, radios y z-index.
- Tema oscuro con acento fucsia.
- Utilidades de layout como `.container` y `.section`.
- Componentes compartidos como `.btn`, `.card`, `.section-label` y `.text-gradient`.
- Clases auxiliares de animacion: `.reveal`, `.reveal-left`, `.reveal-right` y `.reveal-scale`.

El layout global esta en `src/layouts/Layout.astro` y centraliza:

- Metadatos SEO basicos.
- Open Graph y Twitter Card.
- Carga de Google Fonts.
- Import del CSS global.
- Configuracion global de GSAP.
- IntersectionObserver para revelar elementos al entrar en viewport.

## Animaciones e interaccion

El proyecto usa animaciones en varias capas:

- Canvas interactivo de particulas en `InteractiveBackground.astro`.
- Animaciones de entrada en el hero con GSAP.
- Menu movil animado en `Navbar.astro`.
- Carrusel de servicios con transiciones GSAP, avance automatico y microinteracciones CSS.
- Timeline ciclico del proceso en `Process.astro`.
- Burbujas animadas en `ChatFeature.astro`.
- Apertura, cierre y mensajes simulados en `ChatWidget.astro`.

Varias secciones respetan `prefers-reduced-motion` para reducir o desactivar animaciones cuando el usuario lo solicita desde el sistema.

## Assets

Los assets publicos estan en `public/`.

- `public/logo174.png`: logo principal y favicon usado por el layout.
- `public/marcas/`: logos de marcas mostradas en el carrusel.
- `public/Servicios/`: imagenes usadas por la galeria de servicios.

Las imagenes de servicios son visualmente importantes para el sitio. Antes de produccion conviene revisar peso, dimensiones y formatos para optimizar carga.

## Formulario y chat

El formulario de `Contact.astro` esta preparado como interfaz de contacto. Cualquier envio real debe conectarse a un endpoint, proveedor de formularios o Worker que valide y procese los datos fuera del cliente.

El widget `ChatWidget.astro` contiene la experiencia de interfaz del chat. Cualquier integracion con IA, CRM, WhatsApp, correo o servicios externos debe realizarse desde backend o Cloudflare Worker para no exponer credenciales en el navegador.

Para llevar estas piezas a produccion se puede integrar:

- Un endpoint en Astro o Cloudflare Worker.
- Un proveedor de formularios.
- Un CRM.
- WhatsApp Business.
- Un backend de chat multiagente.

Buenas practicas para estas integraciones:

- No guardar tokens, API keys ni secrets en archivos versionados.
- Usar variables de entorno o secrets del proveedor de despliegue.
- Validar y sanitizar todos los datos recibidos desde formularios o chat.
- Evitar insertar texto del usuario como HTML sin sanitizacion previa.

## Deploy en Cloudflare Workers

Astro usa el adapter oficial de Cloudflare en modo `server`. La landing se compila como HTML prerenderizado y las futuras rutas privadas podrán ejecutarse bajo demanda en Workers.

Flujo base:

```powershell
pnpm build
pnpm exec wrangler deploy
```

Hay una guia mas completa en `docs/deploy-cloudflare-workers.md`.

## Notas de mantenimiento

- `dist/`, `.astro/` y `node_modules/` estan ignorados por Git; `.agents/skills/` contiene reglas técnicas del proyecto y debe conservarse junto con la documentación.
- Antes de publicar, validar con `pnpm run check`, `pnpm run build` y `pnpm run audit:prod`.
- Turnstile es obligatorio antes de exponer registro/login públicamente; solo puede permanecer desactivado en localhost.
- Si el chat acepta texto libre del usuario en produccion, sanitizar la salida antes de insertarla en el DOM.

## Estado actual

La landing compila prerenderizada dentro de un runtime Astro SSR para Cloudflare. La infraestructura de datos remota, RLS, grants, Storage, seed, Advisors y pruebas están validados para desarrollo. El siguiente incremento es implementar login y `/api/v1`; antes de exponerlos públicamente se deben verificar en el entorno Auth, SMTP, URLs permitidas, Turnstile, rate limiting y secretos.
