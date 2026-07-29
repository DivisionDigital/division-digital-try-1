# Directivas y Server Islands

## Client directives

- `client:load`: prioridad alta; elementos visibles e inmediatamente interactivos.
- `client:idle`: prioridad media; espera a que termine la carga inicial.
- `client:visible`: prioridad baja; usa IntersectionObserver y puede usar `rootMargin`.
- `client:media`: hidrata cuando una media query coincide.
- `client:only="react"`: omite HTML server-rendered; usar solo para componentes browser-only y proporcionar fallback.

Las directivas `client:*` solo se aplican al componente de framework importado directamente desde un `.astro`. Un componente de framework sin directiva se renderiza como HTML sin JavaScript de cliente.

## Server Islands

`server:defer` retrasa un componente Astro server-rendered y solicita su contenido en una ruta especial. Requiere adapter. Los props deben ser serializables y mínimos; las Server Islands no reemplazan middleware, autorización o API.

La implementación usa props cifradas y puede usar GET o POST según el tamaño. Revisar límites, caché, cookies y despliegues rolling. Si varias versiones del frontend/backend conviven, configurar una clave estable mediante el mecanismo documentado por Astro.

## On-demand rendering

La landing puede permanecer prerenderizada, mientras login, portal, panel, endpoints y widgets personalizados usan renderizado bajo demanda. El adapter debe corresponder al runtime real, por ejemplo Cloudflare o Node.

## Referencias

- [Directives reference](https://docs.astro.build/en/reference/directives-reference/)
- [Server islands](https://docs.astro.build/en/guides/server-islands/)
- [On-demand rendering](https://docs.astro.build/en/guides/on-demand-rendering/)
