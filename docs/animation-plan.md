# Plan Para Optimizar Animaciones Sin Cambiar Su Apariencia

## Resumen

Optimizar el rendimiento de las animaciones de la landing manteniendo el diseno, tiempos, intencion visual y comportamiento actual. El enfoque es conservador: no redisenar animaciones, no eliminar efectos visibles y no cambiar textos ni contenido; solo evitar trabajo innecesario cuando no se ve, prevenir inicializaciones duplicadas y limpiar loops/listeners que puedan saturar moviles o equipos poco potentes.

## Cambios Clave

- Hacer idempotentes los scripts de animacion para evitar duplicados por `DOMContentLoaded` + `astro:page-load`.
- Anadir limpieza de recursos: timelines, ScrollTriggers, `requestAnimationFrame`, timers y event listeners.
- Pausar o reanudar animaciones segun visibilidad, sin cambiar keyframes ni duracion visible.
- Optimizar listeners frecuentes como scroll de navbar y resize del canvas.
- Respetar `prefers-reduced-motion` en animaciones decorativas infinitas sin afectar a usuarios que no lo soliciten.

## Implementacion

- Mantener cada optimizacion dentro de sus componentes actuales.
- Usar `IntersectionObserver` o `ScrollTrigger` para activar `animation-play-state` y timelines solo cuando la seccion relevante este visible.
- No modificar valores visuales principales: keyframes, textos, layout, colores, numero de pasos, orden de secciones, copy, tiempos perceptibles ni comportamiento de interaccion.
- En `Services`, controlar el ciclo GSAP Flip para pausar temporizadores/tweens al salir del viewport y reanudar al volver.
- En `InteractiveBackground`, conservar la cantidad actual de particulas y el look del canvas; solo impedir loops duplicados, pausar en pestana oculta y respetar movimiento reducido.
- En `Layout`, evitar observar/reanimar elementos `.reveal` ya procesados.

## Validacion

- Ejecutar `pnpm astro check`.
- Ejecutar `pnpm build`.
- Confirmar por revision de codigo que:
  - No se cambiaron textos ni estructura visual.
  - No se alteraron keyframes principales ni tiempos visibles.
  - No quedan timelines, timers, RAF loops o listeners duplicables en reinicializaciones.
  - Las animaciones infinitas decorativas quedan pausables fuera de pantalla o en pestana oculta.

## Supuestos

- Nivel elegido: conservador. Se prioriza preservar apariencia sobre reducir densidad visual.
- Archivo del plan: `docs/animation-plan.md`.
- Validacion requerida: `pnpm astro check` y `pnpm build`.
- No se deben tocar cambios existentes no relacionados.
- Cualquier optimizacion mas agresiva, como reducir particulas en movil, bajar FPS del canvas o desactivar animaciones decorativas por dispositivo, queda fuera de esta primera pasada.
