# Deploy en Cloudflare Workers

Guia para publicar este proyecto Astro en Cloudflare Workers.

El estado actual del proyecto es **Astro estatico**: `astro.config.mjs` no usa adapter y Astro genera archivos en `dist/`. Para este caso no hace falta `@astrojs/cloudflare`; basta con desplegar `dist/` como assets estaticos de Workers.

## Requisitos

- Cuenta de Cloudflare.
- Node `>=22.12.0`, como indica `package.json`.
- Dependencias instaladas con pnpm.
- Wrangler disponible. Puede ejecutarse bajo demanda con `pnpm dlx wrangler@latest` o instalarse como dev dependency.

Comandos base:

```powershell
pnpm install
pnpm astro build
pnpm dlx wrangler@latest login
```

## Configuracion recomendada para este proyecto

Crear `wrangler.jsonc` en la raiz:

```jsonc
{
  "$schema": "node_modules/wrangler/config-schema.json",
  "name": "division-digital",
  "compatibility_date": "2026-04-15",
  "assets": {
    "directory": "./dist",
    "not_found_handling": "404-page"
  }
}
```

Notas:

- `assets.directory` apunta a `./dist`, que es la salida del build de Astro.
- No se define `main` porque este proyecto es estatico y no necesita Worker SSR.
- `not_found_handling: "404-page"` permite servir una pagina `404.html` si existe. Si aun no hay `src/pages/404.astro`, se puede quitar esta linea.
- Cambiar `name` si Cloudflare ya tiene un Worker con ese nombre.

## Deploy manual

```powershell
pnpm astro build
pnpm dlx wrangler@latest deploy
```

Al terminar, Cloudflare entregara una URL tipo:

```text
https://division-digital.<tu-subdominio>.workers.dev
```

## Preview local con Wrangler

Para probar el resultado de Workers antes de publicar:

```powershell
pnpm astro build
pnpm dlx wrangler@latest dev
```

Esto levanta el Worker local usando la configuracion de `wrangler.jsonc`.

## Scripts opcionales

Si se quiere dejar el flujo mas comodo, primero instalar Wrangler:

```powershell
pnpm add -D wrangler
```

Luego agregar estos scripts a `package.json`:

```json
{
  "scripts": {
    "cf:preview": "astro build && wrangler dev",
    "cf:deploy": "astro build && wrangler deploy"
  }
}
```

Despues:

```powershell
pnpm cf:preview
pnpm cf:deploy
```

## Dominio personalizado

Desde Cloudflare Dashboard:

1. Entrar a **Workers & Pages**.
2. Abrir el Worker `division-digital`.
3. Ir a **Settings** -> **Domains & Routes**.
4. Agregar el dominio o subdominio, por ejemplo:

```text
divisiondigital.com
www.divisiondigital.com
```

Si el dominio ya esta en Cloudflare DNS, la vinculacion suele quedar lista desde el dashboard. Si esta fuera de Cloudflare, primero hay que mover o configurar DNS segun indique Cloudflare.

## Variables y secrets

Para una landing estatica normalmente no se necesitan variables. Si mas adelante se integra un backend, analytics privado, CRM o chat multiagente con claves sensibles:

- Variables no sensibles pueden ir en `wrangler.jsonc` dentro de `vars`.
- Secrets no deben escribirse en el repo. Usar Wrangler:

```powershell
pnpm dlx wrangler@latest secret put OPENAI_API_KEY
pnpm dlx wrangler@latest secret put CRM_API_KEY
```

Para desarrollo local, crear `.dev.vars` y no versionarlo:

```text
OPENAI_API_KEY=valor-local
CRM_API_KEY=valor-local
```

## Cuando usar `@astrojs/cloudflare`

No instalar el adapter solo para publicar la landing estatica.

Usarlo si el sitio pasa a necesitar:

- SSR u on-demand rendering.
- Endpoints Astro en `src/pages/api/*`.
- Acceso directo a bindings de Cloudflare como KV, D1, R2, Durable Objects, Workers AI o secrets desde el runtime.
- Logica server-side para el chat multiagente.

En ese caso:

```powershell
pnpm astro add cloudflare
pnpm astro build
pnpm dlx wrangler@latest deploy
```

La configuracion cambia porque Astro genera un Worker en `dist/_worker.js/index.js`. Un `wrangler.jsonc` para SSR se parece a esto:

```jsonc
{
  "$schema": "node_modules/wrangler/config-schema.json",
  "name": "division-digital",
  "main": "./dist/_worker.js/index.js",
  "compatibility_date": "2026-04-15",
  "compatibility_flags": ["nodejs_compat"],
  "assets": {
    "binding": "ASSETS",
    "directory": "./dist"
  },
  "observability": {
    "enabled": true
  }
}
```

## CI/CD sugerido

En cualquier pipeline:

```powershell
pnpm install --frozen-lockfile
pnpm astro build
pnpm dlx wrangler@latest deploy
```

Variables necesarias en CI:

- `CLOUDFLARE_ACCOUNT_ID`
- `CLOUDFLARE_API_TOKEN`

El API token debe tener permisos para desplegar Workers en la cuenta/proyecto correspondiente.

## Checklist antes de publicar

- `pnpm astro build` termina sin errores.
- `dist/` existe y contiene `index.html`.
- `wrangler.jsonc` tiene el `name` correcto.
- No hay secrets en `wrangler.jsonc`, `.env`, README ni commits.
- El dominio final esta decidido.
- Si hay pagina 404, existe `src/pages/404.astro`; si no, quitar `not_found_handling`.

## Fuentes oficiales

- Cloudflare Workers: guia de Astro: https://developers.cloudflare.com/workers/framework-guides/web-apps/astro/
- Cloudflare Workers: configuracion automatica de proyectos existentes: https://developers.cloudflare.com/workers/framework-guides/automatic-configuration/
- Astro: adapter de Cloudflare y runtime: https://docs.astro.build/en/guides/integrations-guide/cloudflare/
