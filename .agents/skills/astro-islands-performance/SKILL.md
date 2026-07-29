---
name: astro-islands-performance
description: Usa esta skill al optimizar Islands Astro, hidratación, JavaScript, bundles, estado compartido, carga diferida, accesibilidad, CLS, errores de red y medición de rendimiento de la landing o el portal.
---

# Rendimiento y estado de Islands

## Flujo de optimización

1. Medir antes de cambiar: HTML inicial, JavaScript transferido, tiempo de hidratación, LCP, INP, CLS, errores y comportamiento en móvil.
2. Auditar cada componente: ¿necesita JavaScript?, ¿cuándo debe estar listo?, ¿puede usar HTML progresivo?, ¿puede cargarse al entrar al viewport?
3. Reducir el alcance de la island. Preferir una interacción local sobre un dashboard global con todo el estado.
4. Elegir `client:idle` o `client:visible` cuando la interacción no sea crítica. Usar `rootMargin` y un fallback estable para evitar saltos.
5. Revisar dependencias y tamaño de cada framework. No incluir React para un toggle que puede resolverse con un script pequeño.
6. Mantener datos iniciales server-rendered y solicitar únicamente cambios o datos necesarios desde el cliente.
7. Compartir estado entre Islands solo cuando exista una necesidad real; usar Nano Stores o eventos tipados y mantener el store pequeño.
8. Repetir pruebas después de cada cambio importante y documentar la razón de la directiva elegida.

## Buenas prácticas

- Reservar dimensiones para imágenes, skeletons y componentes diferidos.
- Mantener fallbacks accesibles, con texto y estados de error reales.
- No hacer polling agresivo desde cada island.
- Cancelar requests al desmontar o cambiar de filtro.
- Evitar listeners globales duplicados y limpiar recursos en navegación/transiciones.
- No duplicar el mismo runtime de framework por pequeñas islas sin justificación.
- Cargar librerías pesadas bajo demanda y separar módulos por responsabilidad.
- Usar HTML semántico y controles de teclado antes de añadir JavaScript.
- No almacenar datos sensibles o permisos en stores del navegador.

## Estado entre Islands

La comunicación no debe depender de context providers de una sola island. Elegir entre:

- Props para datos estáticos iniciales.
- URL para filtros compartibles y navegables.
- Formularios/API para datos persistentes.
- Eventos personalizados para comunicación puntual.
- Nano Stores para estado pequeño realmente compartido.

El estado del navegador no reemplaza PostgreSQL ni la autorización del servidor.

## Validación

Usar Dev Toolbar, Lighthouse/Pa11y y pruebas reales de móvil. Comparar el bundle antes/después, revisar Network/Performance y probar una conexión lenta. La Dev Toolbar de Astro puede inspeccionar Islands y ejecutar auditorías rápidas, pero no sustituye herramientas dedicadas ni revisión humana.

## Referencias

- [Checklist de rendimiento](references/performance-checklist.md)
- [Estado compartido](references/shared-state.md)
- [Astro directives](https://docs.astro.build/en/reference/directives-reference/)
- [Compartir estado entre Islands](https://docs.astro.build/en/recipes/sharing-state-islands/)
