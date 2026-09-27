import 'server-only';
import { createServerSupabaseClient } from '@/lib/supabase/server';

export class UnauthorizedError extends Error {
  status = 401;
}
export class ForbiddenError extends Error {
  status = 403;
}

/**
 * Verifies the current request's session belongs to a logged-in user
 * AND that user has a row in admin_users. Throws otherwise. Every
 * admin API route handler should call this first, before touching
 * the service-role client.
 */
export async function requireAdmin() {
  const supabase = createServerSupabaseClient();

  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser();

  if (authError || !user) {
    throw new UnauthorizedError('Not signed in.');
  }

  const { data: adminRow, error: adminError } = await supabase
    .from('admin_users')
    .select('id, role, full_name')
    .eq('id', user.id)
    .single();

  if (adminError || !adminRow) {
    throw new ForbiddenError('Signed in but not an authorized admin.');
  }

  return { user, admin: adminRow };
}
