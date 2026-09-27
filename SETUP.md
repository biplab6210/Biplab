# Setup — Part 1 (Foundation)

## What's in this part
- Full Postgres schema with Row Level Security (`supabase/schema.sql`)
- Next.js + Tailwind project scaffold
- Supabase client helpers (browser, server, service-role)
- Admin-route protection middleware
- Server-side coupon validation logic (the security-critical part of
  requirement #6 — discount math never trusts the browser)

There's no UI yet — that starts in Part 2. This part is the foundation
everything else will be built on.

## 1. Create a Supabase project
1. Go to https://supabase.com → New Project.
2. Note your **Project URL** and **anon public key** and **service_role
   key** (Project Settings → API).

## 2. Run the schema
1. Open the Supabase SQL Editor.
2. Paste the entire contents of `supabase/schema.sql` and run it.
3. Create two Storage buckets (Storage → New bucket): `media` (public)
   and `payment-proofs` (public read is fine since screenshots aren't
   sensitive login data, but you can make it private + signed URLs
   later if you prefer).

## 3. Configure environment variables
```bash
cp .env.example .env.local
```
Fill in `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, and
`SUPABASE_SERVICE_ROLE_KEY` from step 1.

## 4. Install dependencies
```bash
npm install
```
(This step needs network access, which isn't available in the
environment that generated this code — run it on your own machine.)

## 5. Create your first admin account
Part 6 will add a `scripts/create-admin.mjs` CLI for this. For now, if
you want to test auth early: create a user in Supabase Auth → Users →
Add User, then insert a matching row:
```sql
insert into admin_users (id, full_name, role)
values ('paste-the-auth-user-uuid-here', 'Your Name', 'superadmin');
```

## Security notes already baked in
- `SUPABASE_SERVICE_ROLE_KEY` is only ever read in files marked
  `server-only` (`lib/supabase/admin.ts`) — Next.js will fail the build
  if a client component tries to import it.
- Every table has RLS enabled. The public can only read *published*
  services/packages/portfolio and *insert* (never read/update/delete)
  orders, payments, messages, and customers.
- Coupons have **no public read policy at all** — codes are validated
  through a server route using the service-role client, so they can't
  be listed or brute-forced by reading the table directly.
- Coupon discount math runs entirely server-side
  (`lib/pricing/coupons.ts`) and re-validates on every order — the
  frontend's displayed price is never trusted for the actual charge.
