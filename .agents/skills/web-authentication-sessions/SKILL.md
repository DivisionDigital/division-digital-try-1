---
name: web-authentication-sessions
description: Usa esta skill al diseñar o implementar login, invitaciones, recuperación de cuenta, sesiones, cookies, PKCE, middleware, callbacks y protección de rutas para el portal Astro de Division Digital con Supabase Auth.
---

# Autenticación y sesiones web

## Objetivo

Construir autenticación server-side para una landing pública que evoluciona hacia `/app` para clientes y `/equipo` para personal interno. Los clientes pueden registrarse antes de tener servicios y consultar cotizaciones propias; la interfaz puede compartir el diseño de la landing, pero la sesión y la autorización deben resolverse en el servidor.

## Flujo de trabajo

1. Leer `contexto/arquitectura.md`, `contexto/roadmap.md` y la documentación vigente del proveedor antes de implementar. Verificar el changelog de Supabase y la versión instalada.
2. Definir actores, roles y método de acceso. Para este proyecto, habilitar registro de clientes con verificación de correo y creación controlada de organización/membresía inicial; las invitaciones quedan para miembros adicionales y personal interno.
3. Separar identidad de negocio: Supabase Auth administra `auth.users`; las tablas propias administran `profiles`, organizaciones, membresías, cotizaciones y proyectos.
4. Elegir el transporte según el runtime: usar cliente SSR/cookies para páginas Astro server-rendered; en runtimes de Workers, revisar el cliente server-side y el flujo de headers/cookies vigente. No copiar ejemplos de otro framework sin adaptarlos.
5. Usar PKCE para flujos server-side y callbacks con URLs allowlisted. Validar cualquier `returnTo` para impedir open redirects; aceptar únicamente rutas internas.
6. Inicializar el cliente de autenticación dentro del request. Leer la identidad en servidor y no tomar el rol o el usuario desde campos enviados por el navegador.
7. Proteger `/app`, `/equipo`, endpoints y acciones mediante middleware/casos de uso. Redirigir a login solo cuando no existe sesión; devolver 403 cuando existe sesión pero falta autorización.
8. Usar mensajes genéricos en login, registro y recuperación para no revelar si un correo existe. Aplicar rate limiting, verificación de email, expiración y reintentos controlados.
9. Al cerrar sesión, invalidar la sesión desde el proveedor y limpiar cookies. Probar sesión expirada, refresh fallido, doble pestaña, callback repetido y navegador sin cookies.
10. Documentar proveedor, flujo, decisiones y validaciones en `contexto/bitacora.md`; actualizar un ADR si cambia el runtime o la frontera de autenticación.

## Reglas de cookies y caché

- No guardar tokens, refresh tokens ni identificadores de sesión en `localStorage` o `sessionStorage`.
- Usar HTTPS y atributos `Secure` y `SameSite` adecuados al flujo.
- No cachear respuestas personalizadas que refresquen sesión o contengan `Set-Cookie`.
- No mantener clientes Supabase o datos de usuario en variables globales entre requests.
- Mantener la landing estática si se desea, pero marcar dashboard, login y callbacks como dinámicos/no-store.

## Reglas de producto

- El botón de login en la landing es navegación, no control de seguridad.
- Mostrar `Ingresar` siempre es válido; si el usuario ya tiene sesión, `/login` puede redirigirlo a `/app`.
- Clientes solo acceden a sus organizaciones, cotizaciones y proyectos activados; el equipo requiere membresía y rol interno.
- MFA y reautenticación deben priorizarse para administradores y acciones críticas.
- Nunca conceder acceso a un servicio por una query string, una página de retorno de pago o un estado calculado en el navegador.

## Validación mínima

Probar login válido e inválido, recuperación, invitación expirada, sesión revocada, callback manipulado, `returnTo` externo, rutas privadas sin sesión, cliente de otra organización y miembro sin rol suficiente.

## Referencias

- [Flujos y callbacks](references/auth-flows.md)
- [Seguridad de sesiones](references/session-security.md)
- [Arquitectura](../../../contexto/arquitectura.md)
- [Roadmap](../../../contexto/roadmap.md)
