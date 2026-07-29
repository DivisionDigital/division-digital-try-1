import { createClient } from '@supabase/supabase-js';
import { SUPABASE_SECRET_KEY } from 'astro:env/server';
import { PUBLIC_SUPABASE_URL } from 'astro:env/client';

/**
 * Server-only infrastructure adapter. Every caller must authenticate and
 * authorize the actor before using this client because secret keys bypass RLS.
 */
export function createPrivilegedSupabaseClient() {
  return createClient(PUBLIC_SUPABASE_URL, SUPABASE_SECRET_KEY, {
    auth: {
      autoRefreshToken: false,
      detectSessionInUrl: false,
      persistSession: false,
    },
  });
}
