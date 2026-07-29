# Checklist de rendimiento de Islands

- [ ] La página funciona con el mínimo JavaScript posible.
- [ ] Cada island tiene una razón documentada para existir.
- [ ] La directiva coincide con la prioridad real del componente.
- [ ] No se usa `client:load` en contenido debajo del viewport.
- [ ] `client:only` tiene fallback accesible y está justificado.
- [ ] Se midieron JS transferido, hidratación, LCP, INP y CLS.
- [ ] Imágenes y skeletons reservan dimensiones.
- [ ] No hay listeners globales duplicados.
- [ ] Requests se cancelan o controlan al cambiar de vista.
- [ ] El bundle y el runtime de frameworks están revisados.
- [ ] Se probaron móvil, red lenta, CPU lenta y JavaScript deshabilitado.
- [ ] La Dev Toolbar, Lighthouse o herramienta equivalente se usó como evidencia.
