---
name: backend-security
description: Usa esta skill al implementar o revisar autenticación, sesiones, autorización, RLS, validación de entradas, secretos, uploads, webhooks, rate limiting, privacidad, auditoría y observabilidad del backend de Division Digital.
---

# Seguridad backend

## Objetivo

Aplicar defensa en profundidad al portal: identidad verificada, autorización por recurso y acción, validación en servidor, mínimo privilegio, secretos protegidos, trazabilidad y recuperación ante fallos. La seguridad debe existir aunque el usuario llame la API sin usar la UI.

## Flujo de revisión

1. Definir el actor, recurso, acción y límite de tenant para cada endpoint o caso de uso. Considerar cliente, miembro del equipo, administrador, webhook y tarea interna.
2. Dibujar el flujo de datos: navegador, Astro/server, API, base de datos, Storage, pagos y notificaciones. Clasificar PII, credenciales, documentos y datos financieros.
3. Autenticar en servidor y comprobar autorización por recurso. No confiar en IDs, roles, estados o precios enviados por el cliente.
4. Validar body, query, params, archivos y headers con esquemas estrictos; rechazar campos desconocidos cuando sea posible, limitar tamaños y normalizar antes de procesar.
5. Proteger secretos con variables de entorno/secret manager. Publicar únicamente claves diseñadas para clientes; nunca registrar tokens, contraseñas, firmas, documentos ni datos de pago completos.
6. Proteger endpoints sensibles con rate limiting, expiración, reautenticación cuando corresponda y controles CSRF/CORS según el modelo de cookies.
7. Diseñar errores seguros: mensajes útiles para el cliente, detalles técnicos solo en logs protegidos y respuestas consistentes que no filtren si existe una cuenta.
8. Registrar auditoría de acciones administrativas, cambios de estado, acceso a archivos y eventos de pago con actor, recurso, timestamp, request/correlation ID y resultado.
9. Probar abuso: IDOR entre clientes, escalamiento de rol, replay de webhook, doble envío, carga maliciosa, payload grande, SQL injection, XSS almacenado y fuga de secretos.
10. Documentar amenazas, controles y pendientes en la bitácora; no marcar un control como completo sin una prueba o evidencia.

## Reglas críticas

- Autorización en backend y RLS, nunca solo en middleware visual o rutas ocultas.
- No usar `user_metadata` para permisos en Supabase; usar relación de membresía controlada o `app_metadata` con tokens refrescados correctamente.
- No exponer `service_role`, claves privadas, credenciales de AWS ni tokens de pago.
- Escapar contenido generado por usuarios; no usar `innerHTML` con datos no confiables sin sanitización estricta.
- Para archivos, validar extensión y MIME real, tamaño, nombre, permisos, ruta por usuario y descarga mediante URL temporal; no servir subidas como HTML ejecutable.
- Para SQL, usar parámetros o el cliente seguro; no concatenar entrada de usuario.
- Verificar firmas de webhooks sobre el cuerpo crudo y aplicar idempotencia antes de mutar estado.
- Minimizar PII y retenerla solo el tiempo necesario. Alinear consentimiento, política, derechos del titular y eliminación con la normativa colombiana aplicable.

## Criterio de entrega

Un cambio sensible se entrega solo con validación de autenticación, autorización positiva y negativa, entradas inválidas, repetición, logs sin secretos y revisión de dependencias. Consultar [references/security-checklist.md](references/security-checklist.md) como lista de salida.

## Referencias del proyecto

- [Autenticación y sesiones](../web-authentication-sessions/SKILL.md)
- [Autorización PostgreSQL y RLS](../postgresql-authorization-rls/SKILL.md)
- [Seguridad web](../web-application-security/SKILL.md)
- [Checklist de seguridad](references/security-checklist.md)
- [Arquitectura](../../../contexto/arquitectura.md)
- [ADR de activación de pago](../../../contexto/decisiones/ADR-003-activacion-pago.md)
- [Bitácora](../../../contexto/bitacora.md)
