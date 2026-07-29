create schema if not exists app_private;

comment on schema app_private is
  'Funciones internas de autorización e integridad; no debe exponerse mediante Data API.';

revoke all on schema app_private from public;
revoke create on schema public from public;
