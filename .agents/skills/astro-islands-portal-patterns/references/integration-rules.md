# Reglas de integración

- Mantener layouts compartidos visualmente, pero separar rutas y autorización.
- El cliente llama API propia; no llamar proveedores ni usar secret keys desde islands.
- Enviar a la island solo datos necesarios y no sensibles.
- Manejar estados loading, empty, error, forbidden y sesión expirada.
- Mantener un contrato de eventos o props cuando dos islands se comuniquen.
- Registrar cambios de arquitectura y decisiones de hidratación en `contexto/bitacora.md`.
- Medir el impacto antes y después de añadir una dependencia o convertir un componente en island.
- Probar la interfaz sin JavaScript cuando el caso de uso lo permita.
