---
name: astro-islands-portal-patterns
description: Usa esta skill al aplicar Islands de Astro a la landing, login, portal de clientes y panel interno de Division Digital, incluyendo GSAP, formularios, upload, filtros, progreso, React puntual y Server Islands.
---

# Patrón de Islands para División Digital

## Regla general

Usar un mismo proyecto Astro y una misma identidad visual con tres áreas técnicas: landing pública, portal cliente y panel de equipo. Compartir estilos y layouts no significa compartir automáticamente permisos, datos o estado.

## Mapa recomendado

| Área | Base | Islands recomendadas |
|---|---|---|
| Landing | `.astro` estático | menú, carrusel, chat, filtros y widgets locales |
| Login | Astro server-side | mejora visual del formulario; autenticación en servidor |
| `/app` | Astro server-side | tabs, formularios, autosave, upload, progreso |
| `/equipo` | Astro server-side | tablas, filtros, edición, gráficas y módulos React complejos |
| Widget personalizado | Server Island | avatar o contador independiente y autorizado |

## Implementación por módulo

1. Crear el HTML inicial en Astro y una versión usable sin JavaScript cuando el caso lo permita.
2. Definir el contrato de datos y permisos en el servidor antes de crear la island.
3. Hidratar solo la interacción: no pasar toda la respuesta de la API si el componente necesita un subconjunto.
4. Hacer que el cliente invoque acciones/API propias; no exponer claves administrativas ni llamar proveedores directamente desde la island.
5. Manejar loading, error, empty state, retry y permisos vencidos.
6. Probar que un usuario puede llamar la API directamente y que el backend aun así rechaza recursos no autorizados.

## Casos concretos

- Carrusel de servicios: mantener GSAP/TypeScript local si la interacción es visual; no migrar a React sin necesidad de estado complejo.
- Login: HTML/Astro Actions o endpoint server-side; una island solo mejora feedback y evita doble envío.
- Formularios de servicio: Astro server-side con island para autosave, validación progresiva o pasos complejos.
- Archivos: island para progreso y selección; servidor valida tipo, tamaño, pertenencia y almacenamiento privado.
- Progreso: renderizar estado inicial en servidor; island para filtros, timeline o actualización autorizada.
- Equipo: comenzar con Astro y extraer a React únicamente tablas, editores o flujos que necesiten mucha interacción.

## Seguridad y caché

- Una island no autentica ni autoriza.
- No cachear contenido personalizado o cookies de otros usuarios.
- Mantener páginas privadas bajo renderizado on-demand y respuestas apropiadamente privadas.
- Usar `server:defer` solo con props serializables, mínimas y no sensibles.
- Validar siempre en API, caso de uso y PostgreSQL/RLS.

## Estructura sugerida

```text
src/
├── components/landing/
├── components/portal/
├── components/team/
├── layouts/PublicLayout.astro
├── layouts/AppLayout.astro
├── layouts/TeamLayout.astro
├── islands/
└── server/
```

## Referencias

- [Matriz de módulos](references/portal-island-map.md)
- [Reglas de integración](references/integration-rules.md)
- [Arquitectura](../../../contexto/arquitectura.md)
- [Roadmap](../../../contexto/roadmap.md)
