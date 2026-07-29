# Casos de uso del dominio

**Estado:** catálogo conceptual; no son endpoints implementados
**Fecha:** 2026-07-28

Los casos de uso son la frontera entre la interfaz y el dominio. Reciben comandos o consultas validados, resuelven el actor desde la sesión y devuelven DTOs versionables. No devuelven filas crudas ni dependen de SDKs de proveedores.

## 1. Identidad

| Caso de uso | Actor | Resultado |
|---|---|---|
| `RegisterClient` | Público | Cuenta, perfil, organización y membresía inicial |
| `VerifyClientEmail` | Cliente | Identidad verificada |
| `Login` | Público | Sesión server-side |
| `RecoverAccount` | Público | Flujo temporal de recuperación |
| `UpdateOwnProfile` | Cliente | Campos de perfil permitidos actualizados |

## 2. Cotizaciones

| Caso de uso | Actor | Resultado |
|---|---|---|
| `CreateQuoteRequest` | Cliente | Cotización pendiente de revisión |
| `ReviewQuote` | Team/Admin | Solicitud cargada para operación interna |
| `EditQuoteDraft` | Team/Admin | Alcance, servicios y precio modificados |
| `PublishQuoteVersion` | Team/Admin | Versión inmutable visible al cliente |
| `AcceptQuoteVersion` | Cliente | Versión propia aceptada |
| `RejectQuote` | Cliente/Team/Admin según estado | Cotización rechazada con motivo |
| `ExpireQuote` | Sistema/Team | Cotización vencida sin alterar historia |

El cliente acepta una versión exacta, nunca un precio o servicio enviado manualmente desde el navegador.

## 3. Órdenes y activación

| Caso de uso | Actor | Resultado |
|---|---|---|
| `CreateOrderFromAcceptedQuote` | Team/Admin | Orden con snapshot comercial |
| `ConfirmOrder` | Admin | Orden elegible para activación |
| `ActivateOrder` | Admin | Proyectos y recursos derivados creados |
| `CancelOrder` | Team/Admin según policy | Orden cancelada con auditoría |

### `ActivateOrder`

Precondiciones:

- sesión válida;
- capability `activate_projects`;
- organización y orden obtenidas desde backend;
- cotización aceptada;
- versión aceptada vigente;
- política comercial cumplida;
- orden no activada previamente.

Efectos transaccionales:

- crea un proyecto por ítem/unidad;
- fija snapshots y versiones de catálogo;
- provisiona formularios y workflow;
- crea hitos y evento inicial;
- registra auditoría;
- publica outbox después de confirmar la transacción.

## 4. Proyectos

| Caso de uso | Actor | Resultado |
|---|---|---|
| `ListOwnProjects` | Cliente | Proyectos de su organización |
| `GetProject` | Cliente/Team/Admin | Proyecto autorizado |
| `TransitionProject` | Team/Admin | Estado válido y evento histórico |
| `UpdateProjectDates` | Team/Admin | Fechas auditadas |
| `ArchiveProject` | Team/Admin | Proyecto archivado sin borrar historia |
| `AddProjectMessage` | Cliente/Team/Admin | Mensaje ligado al proyecto |

## 5. Formularios y archivos

| Caso de uso | Actor | Resultado |
|---|---|---|
| `ProvisionProjectForms` | Sistema | Formularios creados desde catálogo |
| `SaveProjectFormDraft` | Cliente | Nueva revisión de respuestas |
| `SubmitProjectForm` | Cliente | Formulario enviado tras validación |
| `RequestFormChanges` | Team/Admin | Formulario reabre una transición permitida |
| `LockProjectForm` | Team/Admin | Formulario deja de ser editable |
| `CreateUploadIntent` | Cliente/Team/Admin | Intento de carga autorizado |
| `FinalizeUpload` | Cliente/Team/Admin | Metadata validada y archivo asociado |
| `CreateDownloadUrl` | Cliente/Team/Admin | URL temporal tras comprobar ownership |

## 6. Pagos futuros

| Caso de uso | Actor | Resultado |
|---|---|---|
| `CreatePaymentAttempt` | Team/Admin/Sistema | Intento ligado a orden |
| `ProcessPaymentWebhook` | Sistema | Evento verificado e idempotente |
| `ReconcilePaymentEvent` | Admin | Evento pendiente resuelto con auditoría |

`ProcessPaymentWebhook` no llama a `ActivateOrder` automáticamente en el MVP.

## 7. Reglas comunes

- Resolver actor, organización y permisos en servidor.
- Validar estado actual antes de cualquier transición.
- Usar transacciones solo para cambios internos relacionados.
- Ejecutar llamadas externas mediante puertos y fuera de transacciones abiertas.
- Registrar correlation ID y auditoría en acciones sensibles.
- Hacer idempotentes webhooks, activación, uploads finalizados y reintentos.
