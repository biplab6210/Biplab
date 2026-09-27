import 'server-only';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '@/types/database';

/**
 * SERVICE-ROLE Supabase client. Bypasses Row Level Security entirely.
 *
 * Hard rules:
 * 1. Import this ONLY inside app/api/** route handlers (or other code
 *    that never ships to the browser). The `server-only` import above
 *    makes Next.js fail the build if a client component ever imports it.
 * 2. Every route handler that uses this client MUST perform its own
 *    authorization check first (see lib/auth/require-admin.ts) —
 *    this client will happily read/write anything, admin or not.
 * 3. Never log the service role key or return it in a response body.
 */
let cachedClient: SupabaseClient<Database> | null = null;

export function createAdminSupabaseClient(): SupabaseClient<Database> {
  if (cachedClient) return cachedClient;

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !serviceKey) {
    throw new Error(
      'Missing NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY environment variables.'
    );
  }

  cachedClient = createClient<Database>(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  return cachedClient;
}
