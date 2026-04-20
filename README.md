# Division Digital

Landing estatica construida con Astro para presentar los servicios de Division Digital: soluciones e-commerce, inteligencia artificial, chat multiagente, automatizacion comercial y experiencias digitales de alto impacto.

El proyecto esta organizado como una pagina unica con secciones modulares, animaciones GSAP, fondo interactivo en canvas, galeria de servicios tipo bento, mockup de portafolio, formulario visual de contacto y widget flotante de chat.

## Stack principal

- Astro 6
- TypeScript con configuracion strict de Astro
- GSAP 3 para animaciones
- GSAP ScrollTrigger para animaciones al hacer scroll
- GSAP Flip para la galeria dinamica de servicios
- CSS modular dentro de componentes Astro
- CSS global con tokens de diseno
- pnpm como gestor de paquetes
- Cloudflare Workers Assets para despliegue estatico

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

Genera el sitio estatico en `dist/`.

```powershell
pnpm preview
```

Sirve localmente el build de produccion.

```powershell
pnpm astro check
```

Valida tipos y diagnosticos de archivos Astro.

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
|-- astro.config.mjs
|-- package.json
|-- tsconfig.json
`-- wrangler.jsonc
```

## Pagina principal

La ruta principal se define en `src/pages/index.astro`. Desde ahi se ensamblan las secciones del sitio:

- `InteractiveBackground`: fondo global interactivo con particulas en canvas.
- `Navbar`: navegacion fija con efecto glassmorphism y menu movil.
- `Hero`: bloque principal con CTA, metricas y animaciones de entrada.
- `Services`: galeria bento de servicios con imagenes y animacion GSAP Flip.
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
- Galeria bento con `ScrollTrigger`, `Flip` y `gsap.matchMedia()` en `Services.astro`.
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

El proyecto esta configurado como sitio Astro estatico. `astro.config.mjs` no usa adapter SSR, por lo que el build genera archivos en `dist/`.

La configuracion de Cloudflare esta en `wrangler.jsonc` y usa `dist/` como directorio de assets.

Flujo base:

```powershell
pnpm build
pnpm dlx wrangler@latest deploy
```

Hay una guia mas completa en `docs/deploy-cloudflare-workers.md`.

## Notas de mantenimiento

- `dist/`, `.astro/`, `node_modules/` y `.agents/` estan ignorados por Git.
- Antes de publicar, validar con `pnpm astro check` y `pnpm build`.
- Si se agregan endpoints, SSR o bindings de Cloudflare, evaluar el uso de `@astrojs/cloudflare`.
- Si el chat acepta texto libre del usuario en produccion, sanitizar la salida antes de insertarla en el DOM.

## Estado actual

El sitio compila como una landing estatica modular con enfoque visual fuerte, animaciones GSAP y preparacion para despliegue estatico en Cloudflare Workers.
