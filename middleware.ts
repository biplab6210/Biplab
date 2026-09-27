import { createServerClient, type CookieOptions } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

/**
 * Runs on every request (see matcher below).
 * 1. Refreshes the Supabase auth session cookie so server components
 *    always see an up-to-date session.
 * 2. Blocks unauthenticated access to /admin/** (except /admin/login)
 *    at the edge, before any admin page or data ever renders.
 * Admin-role verification (is this user actually in admin_users?)
 * happens again in lib/auth/require-admin.ts inside each page/route —
 * middleware only checks "is there a valid session at all".
 */
export async function middleware(request: NextRequest) {
  const response = NextResponse.next({ request: { headers: request.headers } });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return request.cookies.get(name)?.value;
        },
        set(name: string, value: string, options: CookieOptions) {
          response.cookies.set({ name, value, ...options });
        },
        remove(name: string, options: CookieOptions) {
          response.cookies.set({ name, value: '', ...options });
        },
      },
    }
  );

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const path = request.nextUrl.pathname;
  const isAdminPath = path.startsWith('/admin') && path !== '/admin/login';

  if (isAdminPath && !user) {
    const loginUrl = new URL('/admin/login', request.url);
    loginUrl.searchParams.set('redirectTo', path);
    return NextResponse.redirect(loginUrl);
  }

  return response;
}

export const config = {
  matcher: [
    '/admin/:path*',
    // add other paths here if they need session refresh too
  ],
};
