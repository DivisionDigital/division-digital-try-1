// @ts-check
import cloudflare from '@astrojs/cloudflare';
import { defineConfig, envField } from 'astro/config';

// https://astro.build/config
export default defineConfig({
  output: 'server',
  adapter: cloudflare({
    imageService: 'compile',
  }),
  security: {
    checkOrigin: true,
  },
  env: {
    schema: {
      PUBLIC_SUPABASE_URL: envField.string({
        context: 'client',
        access: 'public',
        url: true,
      }),
      PUBLIC_SUPABASE_PUBLISHABLE_KEY: envField.string({
        context: 'client',
        access: 'public',
        min: 20,
      }),
      SUPABASE_SECRET_KEY: envField.string({
        context: 'server',
        access: 'secret',
        min: 20,
      }),
    },
    validateSecrets: true,
  },
});
