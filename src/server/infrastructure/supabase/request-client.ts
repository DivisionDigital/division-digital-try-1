import { createServerClient, parseCookieHeader } from '@supabase/ssr';
import {
  PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  PUBLIC_SUPABASE_URL,
} from 'astro:env/client';
import type { AstroCookies } from 'astro';

type RequestClientContext = {
  request: Request;
  cookies: AstroCookies;
};

/**
 * Request-scoped Auth client. It carries only the end user's session and must
 * never be replaced with the privileged server client.
 */
export function createSupabaseRequestClient({
  request,
  cookies,
}: RequestClientContext) {
  return createServerClient(
    PUBLIC_SUPABASE_URL,
    PUBLIC_SUPABASE_PUBLISHABLE_KEY,
    {
      cookies: {
        getAll() {
          return parseCookieHeader(request.headers.get('Cookie') ?? '');
        },
        setAll(cookiesToSet) {
          for (const { name, value, options } of cookiesToSet) {
            cookies.set(name, value, {
              ...options,
              httpOnly: true,
              sameSite: 'lax',
              secure: import.meta.env.PROD,
              path: '/',
            });
          }
        },
      },
    },
  );
}
