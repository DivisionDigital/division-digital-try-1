# Selección del modelo de datos

## Niveles de diseño

Antes de elegir una tecnología, separar tres niveles:

1. **Conceptual:** actores, conceptos del negocio y relaciones.
2. **Lógico:** tablas/documentos, claves, cardinalidades, estados y restricciones.
3. **Físico:** tipos PostgreSQL, índices, particiones, RLS, pooling, backups y despliegue.

Un modelo físico no debe decidirse antes de entender las consultas, las invariantes, el aislamiento entre clientes y la evolución esperada.

## Comparación breve

| Modelo | Fortalezas | Coste o riesgo | Encaje en División Digital |
| --- | --- | --- | --- |
| Relacional | Integridad referencial, transacciones, consultas y reportes | Requiere diseñar relaciones y migraciones | **Modelo principal recomendado** |
| Documental | Iteración rápida de documentos variables | Integridad entre documentos y joins más complejos | Útil solo para partes flexibles |
| Clave-valor | Latencia baja y caché | Poca semántica relacional | Complemento, no fuente de verdad |
| Grafo | Relaciones muy conectadas | Operación y consultas innecesarias para este dominio | No justificado en el MVP |
| Columnar | Analítica masiva | No es el sistema transaccional principal | Futuro almacén analítico |
| Series temporales | Métricas/eventos por tiempo | Modelo especializado | Solo observabilidad si hace falta |
| EAV | Campos arbitrarios | Tipado, constraints, consultas y reportes débiles | Evitar para formularios |
| Event sourcing | Reconstrucción completa del estado | Complejidad operativa y de lectura | Evitar como enfoque global inicial |

## Decisión para el proyecto

Usar PostgreSQL relacional multi-tenant con normalización pragmática. Incorporar JSONB solo en definiciones/respuestas de formularios y metadata controlada; mantener entidades comerciales y operativas como tablas tipadas.

La decisión se basa en que el portal necesita:

- relaciones claras entre cliente, organización, cotización, pago y servicio;
- transacciones para confirmar pagos y activar servicios;
- aislamiento verificable entre clientes;
- formularios que pueden variar sin convertir cada pregunta en una columna;
- historial de progreso y auditoría;
- consultas administrativas y reportes confiables;
- una ruta portable desde Supabase/PostgreSQL gestionado hacia RDS o Aurora PostgreSQL.

## Cuándo reconsiderar

Revisar esta decisión solo si aparecen datos y cargas que justifiquen una tecnología complementaria: analítica masiva, búsqueda especializada, relaciones de grafo reales, telemetría de alta frecuencia o requisitos de aislamiento por cliente. La excepción debe incluir volumen, consultas, coste operativo, seguridad y plan de integración.
