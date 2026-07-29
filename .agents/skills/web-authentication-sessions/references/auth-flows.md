# Flujos de autenticación del portal

## Registro inicial del cliente

1. El cliente envía el registro mediante una acción server-side.
2. El proveedor verifica el correo y completa el callback desde una URL allowlisted.
3. El backend crea o valida `profile`, `organization` y la membresía inicial `client` de forma controlada.
4. El servidor redirige a `/app`; la API vuelve a validar la pertenencia.
5. El cliente puede consultar su perfil y cotizaciones, aunque todavía no tenga proyectos.

## Invitaciones adicionales

Las invitaciones se usan para miembros adicionales de una organización y para personal interno. Una invitación nunca concede acceso a un proyecto sin una membresía válida.

No usar el navegador, la URL de retorno del pago ni una query string para conceder acceso a proyectos o cambiar membresías.

## Inicio de sesión

El formulario puede ser una página Astro o una island. La acción real debe ejecutarse server-side, validar el input y escribir la sesión en el mecanismo de cookies configurado. El navegador no debe recibir secretos administrativos.

## Callback y return URL

- Allowlist exacta de URLs por entorno.
- Intercambiar códigos una sola vez mediante PKCE.
- No aceptar URLs absolutas proporcionadas por el usuario.
- Permitir solo paths internos como `/app` o `/equipo`.
- Invalidar o limpiar parámetros sensibles después del callback.

## Recuperación

Usar enlaces temporales y de un solo uso gestionados por el proveedor. Mostrar respuestas equivalentes para correos existentes y no existentes. Aplicar rate limiting y no registrar tokens.

## Proveedores y runtime

Para Astro SSR, consultar la guía vigente de `@supabase/ssr`. Para Workers o APIs que reciben `Authorization: Bearer`, consultar el paquete server-side vigente. No mezclar un cliente browser con uno server-side ni compartir estado entre requests.

## Referencias

- [Supabase Auth con Astro](https://supabase.com/docs/guides/auth/quickstarts/astrojs)
- [Supabase server-side advanced guide](https://supabase.com/docs/guides/auth/server-side/advanced-guide)
- [Supabase package selection](https://supabase.com/docs/guides/auth/choosing-a-server-package)
