# Estado compartido entre Islands

## Decidir dónde vive el estado

| Estado | Ubicación |
|---|---|
| Texto o props iniciales | Astro server-rendered |
| Filtro compartible | URL/query params |
| Formulario persistente | API + PostgreSQL |
| Toggle entre dos componentes | Evento o store pequeño |
| Sesión y permisos | Servidor/proveedor de identidad |
| Progreso del servicio | Backend y eventos; UI solo representa |

Astro recomienda Nano Stores para estado compartido entre frameworks/islands. Usarlo solo para estado de interfaz pequeño; no colocar secretos, permisos, pagos ni datos sensibles en un store del navegador.

## Reglas

- Tipar eventos y acciones del store.
- Evitar un store global que convierta la aplicación en una SPA accidental.
- Resetear estado al cambiar de organización o sesión.
- Manejar hydration mismatch y estado inicial con valores serializables.
- Preferir URL para filtros que deban ser navegables, compartibles o recuperables.

## Referencias

- [Share state between islands](https://docs.astro.build/en/recipes/sharing-state-islands/)
- [Share state between Astro components](https://docs.astro.build/en/recipes/sharing-state/)
