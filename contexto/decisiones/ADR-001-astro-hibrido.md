# ADR-001: Mantener Astro con renderizado híbrido

**Estado:** aceptado
**Fecha:** 2026-07-27

## Contexto

La aplicación actual es una landing estática construida con Astro. El nuevo sistema requiere autenticación, datos personalizados, portal de clientes y panel interno.

## Decisión

Mantener Astro como frontend principal y utilizar renderizado híbrido:

- Landing pública prerenderizada.
- Rutas autenticadas renderizadas bajo demanda.
- Layout independiente para el cliente.
- Layout independiente para el equipo.
- Islands únicamente para interacciones que necesiten hidratación en el navegador.
- React opcional dentro de Islands complejas, no como frontend separado inicial.

## Motivos

- Se conserva la inversión existente en diseño, componentes, GSAP y SEO.
- La landing mantiene buen rendimiento.
- Se evita duplicar sistemas de estilos y despliegues.
- Astro puede generar páginas personalizadas mediante un adaptador server-side.
- El portal puede crecer sin convertir la landing completa en una SPA.

## Consecuencias

- Será necesario añadir un adaptador de servidor y gestionar cookies de sesión.
- Las rutas privadas deben distinguirse claramente de las públicas.
- Los componentes con estado complejo pueden requerir React o una implementación client-side dedicada.
- La lógica de negocio no debe vivir en los componentes Astro.

## Alternativa descartada

Crear inicialmente un proyecto React independiente para el dashboard. Se descarta por el costo adicional de autenticación, CORS, despliegues, estilos y mantenimiento para el alcance actual.

## Revisión futura

Reconsiderar la separación del portal si se convierte en un producto SaaS independiente, si requiere ciclos de despliegue separados o si la complejidad del estado cliente supera las ventajas de mantenerlo en Astro.
