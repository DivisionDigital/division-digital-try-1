# Bitácora de cambios

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
