---
name: astro-islands-architecture
description: Usa esta skill al diseñar o revisar Islands de Astro, directivas client:*, componentes de framework, scripts de cliente, Server Islands, renderizado estático/on-demand y límites entre HTML, navegador y servidor en Division Digital.
---

# Arquitectura de Islands en Astro

## Objetivo

Mantener Astro server-first: renderizar HTML y CSS por defecto y añadir JavaScript solo a regiones que realmente necesitan interacción. Tratar cada island como una unidad pequeña, independiente y con una estrategia de carga explícita.

## Flujo de decisión

1. Leer el contexto del proyecto y clasificar el componente: contenido estático, interacción local, widget complejo, datos personalizados o acción server-side.
2. Resolver primero con HTML/CSS/`.astro`. Si necesita comportamiento en navegador, preferir un `<script>` de Astro/TypeScript local antes de añadir React u otro framework.
3. Si se necesita un framework, importar el componente directamente desde `.astro` y elegir una sola directiva `client:*` según prioridad.
4. Usar `client:load` solo para interacción crítica visible; `client:idle` para interacción secundaria; `client:visible` para elementos debajo del viewport; `client:media` para variantes responsive.
5. Usar `client:only` únicamente cuando el componente no pueda renderizarse server-side. Proporcionar fallback y revisar accesibilidad, SEO y layout shift.
6. Usar `server:defer` solo para una región personalizada independiente. Requiere adapter y no sustituye la autorización de una página o API.
7. Mantener los límites de servidor y navegador claros: los secretos, permisos y reglas de negocio permanecen server-side.
8. Documentar la razón de cada island importante y verificar bundle, HTML inicial, hidratación y comportamiento sin JavaScript cuando corresponda.

## Directivas

| Directiva | Regla de uso |
|---|---|
| `client:load` | UI crítica e inmediatamente visible |
| `client:idle` | UI no crítica después de la carga inicial |
| `client:visible` | UI debajo del viewport o pesada |
| `client:media` | UI necesaria solo con una media query |
| `client:only` | Último recurso para componentes browser-only |
| `server:defer` | Contenido personalizado diferido en servidor |

## Reglas estructurales

- No convertir toda la página en una única island.
- No usar una island como límite de autorización.
- No pasar secretos ni objetos de usuario innecesarios a componentes de cliente.
- No colocar lógica de negocio crítica en el navegador.
- No mezclar varios frameworks sin una razón de mantenimiento clara.
- Crear layouts separados para landing pública, portal cliente y panel de equipo.
- Mantener la página autenticada bajo renderizado on-demand; la landing puede permanecer prerenderizada.

## Validación

Probar carga inicial, navegación con JavaScript deshabilitado cuando sea posible, hidratación tardía, errores de red, dispositivos lentos, accesibilidad de fallback y autorización server-side. Consultar [references/directives-and-server-islands.md](references/directives-and-server-islands.md) para detalles.

## Referencias

- [Directivas y Server Islands](references/directives-and-server-islands.md)
- [Arquitectura del proyecto](../../../contexto/arquitectura.md)
- [Astro directives](https://docs.astro.build/en/reference/directives-reference/)
- [Astro on-demand rendering](https://docs.astro.build/en/guides/on-demand-rendering/)
