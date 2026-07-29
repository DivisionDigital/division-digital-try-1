# Casos de abuso para pruebas

Probar como mínimo:

- Cliente A intenta leer o editar servicios, formularios y archivos de cliente B.
- Cliente intenta cambiar su `organization_id`, `user_id`, rol o estado de servicio.
- Usuario sin sesión llama directamente a endpoints privados.
- Usuario autenticado sin rol interno llama al panel del equipo.
- Login, recuperación o formulario se someten a repetición rápida y payloads grandes.
- Callback usa un código inválido, repetido o un `returnTo` externo.
- XSS almacenado en nombre, mensaje, formulario o nombre de archivo.
- Archivo con extensión permitida pero MIME real incorrecto, doble extensión, path traversal o tamaño excesivo.
- Webhook con firma inválida, evento duplicado, importe incorrecto o referencia inexistente.
- CDN/cache devuelve contenido o cookies de otro usuario.

Cada prueba debe registrar resultado esperado, respuesta real, evidencia y corrección si falla.
