# Seguridad de sesiones

- No guardar tokens o refresh tokens en `localStorage` o `sessionStorage`.
- Usar HTTPS y cookies `Secure`; elegir `SameSite` según el flujo y probar navegación desde correo.
- Evitar caché de respuestas que escriban `Set-Cookie` o contengan contenido personalizado.
- Inicializar clientes y datos de usuario dentro del request.
- Consultar al proveedor para confirmar una sesión revocada; validar solo un JWT local no siempre confirma el estado actual.
- Probar expiración, revocación, refresh rotation, múltiples pestañas, logout y replay de callback.
- Forzar reautenticación o MFA para cambiar roles, exportar datos, confirmar pagos o acceder a funciones administrativas.

## Riesgos específicos

Un XSS puede robar una sesión si los tokens son accesibles a JavaScript. Un CDN mal configurado puede entregar la respuesta de un usuario a otro. Un `returnTo` externo puede convertirse en open redirect. Una cookie sin protección adecuada puede permitir CSRF.

## Referencias

- [OWASP Session Management](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)
- [OWASP Authentication](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
