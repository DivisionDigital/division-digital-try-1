# Matriz de permisos de División Digital

**Estado:** aprobada; controles de base de datos implementados
**Fecha:** 2026-07-28
**Última actualización:** 2026-07-28

## 1. Objetivo

Definir qué puede hacer cada actor sobre cada recurso. La autorización se aplica en tres capas:

1. Frontend: solo experiencia de usuario.
2. API/casos de uso: sesión, pertenencia, rol, estado y acción.
3. PostgreSQL/RLS: aislamiento de filas y defensa en profundidad.

Ocultar un botón o una ruta nunca es un control de seguridad.

## 2. Actores

### `anonymous`

Puede consultar la landing y el catálogo público. No puede consultar datos privados ni crear cotizaciones asociadas a una organización autenticada.

### `client`

Usuario autenticado asociado a una organización. Puede editar su perfil permitido, consultar sus cotizaciones y aceptar una versión propia, además de consultar y operar los proyectos de su organización según el estado de cada formulario.

Puede registrarse antes de contratar. No obtiene proyectos, archivos ni formularios hasta que exista una activación administrativa.

Su rol de organización solo puede ser `owner` o `member`.

### `team`

Usuario interno operativo. Gestiona clientes, cotizaciones, versiones, órdenes, proyectos, formularios, archivos, mensajes, estados y auditoría según las reglas del panel. No puede activar una orden en el MVP ni leer secretos o ejecutar SQL arbitrario.

Su autoridad se resuelve exclusivamente desde `staff_members`, no desde una organización cliente.

### `admin`

Usuario interno con la capacidad adicional `activate_projects`. Puede ejecutar `ActivateOrder`, confirmar activaciones y realizar las operaciones de `team`. La activación siempre deja actor, fecha, motivo y auditoría.

### `system`

Webhooks, jobs y outbox server-side. Puede ejecutar únicamente casos de uso explícitos con credenciales limitadas. Un webhook de pago futuro confirma evidencia del pago, pero no activa proyectos por sí solo.

## 3. Alcances de datos

| Alcance | Significado |
|---|---|
| `public` | Landing y catálogo publicado |
| `own_user` | Usuario autenticado actual |
| `own_org` | Organización a la que pertenece el cliente |
| `all_business` | Datos de negocio permitidos al panel interno |
| `system_only` | Procesos server-side e integraciones |
| `none` | Sin acceso |

## 4. Matriz principal

Abreviaturas: **C** crear, **R** consultar, **U** actualizar, **D** anular/archivar, **A** acción sensible.

| Recurso | Cliente | Equipo | Admin | Sistema |
|---|---|---|---|---|
| Landing y catálogo publicado | R | R | R | — |
| Registro y sesión propia | C/R/U | C/R/U | C/R/U | — |
| Perfil propio | R/U limitado | R/U | R/U | C/U |
| Perfiles de otros usuarios | — | R/U | R/U | C/U |
| Organización propia | R/U limitado | C/R/U/D | C/R/U/D | C/U |
| Membresías y roles | — | C/R/U/D operativo | C/R/U/D operativo | C/U |
| Solicitud de cotización | C/R/U limitada | R/U | R/U | C/U |
| Versiones de cotización propias | R/A aceptar | C/R/U/D | C/R/U/D | C/U |
| Órdenes | R propias | C/R/U/D | C/R/U/D/A | C/U |
| Pagos y estado | R resumen | C/R/U/D | C/R/U/D | C/R/U |
| Webhooks y eventos externos | — | R limitado | R limitado | C/R/U |
| Activación de órdenes/proyectos | — | — | A | — |
| Catálogo y configuración de servicios | R publicado | C/R/U/D | C/R/U/D | C/U |
| Workflows y plantillas de formularios | R asignadas | C/R/U/D | C/R/U/D | C/U |
| Proyectos propios | R | R/U operativo limitado | R/U operativo | C/U |
| Estado interno del proyecto | — | R/U operativo | R/U | C/U |
| Formularios del proyecto | C/R/U mientras abiertos | R/U/D | R/U/D | C/U |
| Respuestas de otros clientes | — | R/U/D autorizado | R/U/D autorizado | C/U |
| Archivos del proyecto propio | C/R/U/D limitado | C/R/U/D autorizado | C/R/U/D autorizado | C/U/D |
| Mensajes del proyecto propio | C/R/U limitado | R/U/D | R/U/D | C/U |
| Auditoría propia visible | R limitada | R | R | C |
| Auditoría global | — | R limitada | R | C |
| Configuración de integraciones | — | R limitada | R/U limitada | C/U |

`team` y `admin` comparten la operación diaria, pero solo `admin` posee `activate_projects`. Ningún rol de UI obtiene acceso a secretos, service keys, SQL, políticas RLS o credenciales de proveedores.

## 5. Reglas del cliente

- Puede crear una cotización para uno o varios servicios y cantidades.
- Puede aceptar únicamente una versión publicada para su organización.
- No puede modificar una cotización después de aceptarla.
- Puede consultar sus proyectos y sus formularios, archivos y mensajes asociados.
- Puede guardar revisiones mientras un formulario esté abierto.
- No puede cambiar organización, rol, precio, estado de pago, workflow, estado interno, responsable, vencimiento ni hitos del equipo.
- No puede activar proyectos por endpoint, query string, página de retorno o estado de navegador.
- No puede acceder a otra organización aunque conozca un UUID válido.

## 6. Reglas de activación

`ActivateOrder` debe resolver el actor desde la sesión y comprobar:

1. Capacidad `activate_projects` del administrador.
2. Orden y organización reales desde la base de datos.
3. Cotización aceptada y versión no reemplazada.
4. Precondiciones comerciales vigentes, incluido pago si la política futura lo exige.
5. Idempotencia por ítem y unidad.

La operación crea proyectos, formularios, hitos, evento inicial y outbox en una transacción. No realiza llamadas HTTP externas dentro de la transacción.

## 7. Reglas de API y RLS

Cada endpoint privado debe resolver:

```text
actor = sesión verificada
membership = membresía real en organization_members
staff = autoridad global real en staff_members
scope = own_user, own_org o all_business
resource = registro obtenido desde backend
permission = acción permitida por esta matriz
```

No se acepta como autorización `role`, `organization_id`, `user_id`, `project_id`, precio, pago o estado enviados por el cliente.

Todas las tablas expuestas deben tener RLS y grants revisados. Las políticas de cliente deben comprobar pertenencia mediante `organization_members`; para `UPDATE` deben proteger tanto `USING` como `WITH CHECK`. No usar `user_metadata` ni políticas privadas `USING (true)`.

Las invitaciones de organización solo conceden `owner|member`. Las invitaciones `team|admin` pertenecen al flujo interno separado y solo un administrador puede gestionarlas.

## 8. Pruebas obligatorias

### Cliente A y Cliente B

- Pueden registrar y consultar sus propias cotizaciones.
- Solo pueden aceptar versiones de su organización.
- Pueden ver únicamente sus proyectos y formularios.
- No pueden leer, editar, descargar ni inferir datos del otro cliente.
- No pueden activar proyectos ni cambiar precio, rol, organización o estado interno.

### Equipo y Admin

- `team` puede operar el panel, pero un intento de activación responde `403`.
- `admin` puede activar una orden válida y la operación queda auditada.
- Una segunda activación no duplica proyectos, formularios, hitos ni notificaciones.
- Ninguno puede ejecutar SQL arbitrario o leer secretos desde la UI.

### Casos negativos

- Sesión ausente, expirada o revocada.
- Cotización de otra organización.
- Versión reemplazada o ya aceptada.
- Cliente intentando activar por endpoint o query string.
- Equipo intentando activar sin capability.
- Cantidad cero, negativa o manipulada.
- Misma orden activada dos veces.
- UUID de proyecto o archivo de otra organización.
- Formulario cerrado, versión incorrecta o respuesta inválida.
