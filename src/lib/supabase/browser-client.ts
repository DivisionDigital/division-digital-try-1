import { createBrowserClient } from '@supabase/ssr';
import {
  PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  PUBLIC_SUPABASE_URL,
} from 'astro:env/client';

let browserClient: ReturnType<typeof createBrowserClient> | undefined;

/**
 * Browser client for Supabase Auth and authorized Storage operations only.
 * Private business data must be requested from the application's /api/v1 API.
 */
export function getSupabaseBrowserClient() {
  browserClient ??= createBrowserClient(
    PUBLIC_SUPABASE_URL,
    PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  );

  return browserClient;
}
