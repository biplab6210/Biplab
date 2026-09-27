-- =====================================================================
-- Service Business Website — Database Schema (PostgreSQL / Supabase)
-- =====================================================================
-- Run this in the Supabase SQL Editor (or `supabase db push` with the CLI)
-- on a fresh project. Safe to re-run: uses IF NOT EXISTS / CREATE OR REPLACE
-- where practical, but for a truly clean re-run drop the schema first.
-- =====================================================================

create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- ENUM TYPES
-- ---------------------------------------------------------------------
do $$ begin
  create type service_status as enum ('published', 'draft', 'hidden');
exception when duplicate_object then null; end $$;

do $$ begin
  create type order_status as enum ('new', 'pending', 'in_progress', 'completed', 'cancelled');
exception when duplicate_object then null; end $$;

do $$ begin
  create type coupon_discount_type as enum ('percentage', 'fixed');
exception when duplicate_object then null; end $$;

do $$ begin
  create type portfolio_category as enum ('websites', 'advertisements', 'videos', 'graphics', 'ai_projects', 'other');
exception when duplicate_object then null; end $$;

do $$ begin
  create type payment_status as enum ('submitted', 'verified', 'rejected');
exception when duplicate_object then null; end $$;

do $$ begin
  create type message_status as enum ('unread', 'read', 'archived');
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------
-- ADMIN USERS
-- Admin accounts are managed through Supabase Auth (auth.users).
-- This table stores the admin-specific profile/role data and links
-- 1:1 to an auth.users row. Never store plaintext passwords here.
-- ---------------------------------------------------------------------
create table if not exists admin_users (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null default 'admin' check (role in ('admin', 'superadmin')),
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- CUSTOMERS
-- Lightweight CRM record, upserted whenever an order or message comes in.
-- ---------------------------------------------------------------------
create table if not exists customers (
  id uuid primary key default uuid_generate_v4(),
  full_name text not null,
  phone text,
  whatsapp text,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_customers_email on customers (email);
create index if not exists idx_customers_phone on customers (phone);

-- ---------------------------------------------------------------------
-- SERVICES
-- ---------------------------------------------------------------------
create table if not exists services (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  slug text not null unique,
  description text,
  image_url text,
  icon text,
  category text,
  starting_price numeric(12,2) not null default 0,
  discount_percent numeric(5,2) not null default 0,
  features jsonb not null default '[]'::jsonb, -- array of strings
  status service_status not null default 'draft',
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_services_status on services (status);
create index if not exists idx_services_slug on services (slug);

-- ---------------------------------------------------------------------
-- PRICING PACKAGES
-- Each package belongs to a service (nullable = a standalone/global package).
-- ---------------------------------------------------------------------
create table if not exists pricing_packages (
  id uuid primary key default uuid_generate_v4(),
  service_id uuid references services(id) on delete cascade,
  package_name text not null,
  description text,
  features jsonb not null default '[]'::jsonb,
  original_price numeric(12,2) not null,
  discount_percent numeric(5,2) not null default 0,
  final_price numeric(12,2) generated always as (
    round(original_price * (1 - discount_percent / 100.0), 2)
  ) stored,
  status service_status not null default 'draft',
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_pricing_service on pricing_packages (service_id);

-- ---------------------------------------------------------------------
-- COUPONS
-- ---------------------------------------------------------------------
create table if not exists coupons (
  id uuid primary key default uuid_generate_v4(),
  code text not null unique,
  discount_type coupon_discount_type not null,
  discount_value numeric(12,2) not null,        -- percent (0-100) or fixed amount
  min_order_amount numeric(12,2) not null default 0,
  max_discount_amount numeric(12,2),            -- cap for percentage coupons
  usage_limit integer,                          -- null = unlimited
  usage_count integer not null default 0,
  start_date timestamptz,
  expiry_date timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_coupons_code on coupons (upper(code));

-- ---------------------------------------------------------------------
-- PORTFOLIO
-- ---------------------------------------------------------------------
create table if not exists portfolio (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  description text,
  image_url text,
  video_url text,
  project_url text,
  category portfolio_category not null default 'other',
  project_date date,
  status service_status not null default 'draft',
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_portfolio_category on portfolio (category);
create index if not exists idx_portfolio_status on portfolio (status);

-- ---------------------------------------------------------------------
-- ORDERS
-- Snapshot of pricing at time of order is stored directly on the row
-- (never recompute historical orders from live service/coupon data).
-- ---------------------------------------------------------------------
create table if not exists orders (
  id uuid primary key default uuid_generate_v4(),
  order_number text not null unique default (
    'ORD-' || to_char(now(), 'YYYYMMDD') || '-' || lpad(floor(random() * 100000)::text, 5, '0')
  ),
  customer_id uuid references customers(id) on delete set null,
  customer_name text not null,
  phone text not null,
  whatsapp text,
  email text,
  service_id uuid references services(id) on delete set null,
  service_name_snapshot text,
  package_id uuid references pricing_packages(id) on delete set null,
  package_name_snapshot text,
  coupon_id uuid references coupons(id) on delete set null,
  coupon_code_snapshot text,
  original_price numeric(12,2) not null default 0,
  discount_amount numeric(12,2) not null default 0,
  final_price numeric(12,2) not null default 0,
  message text,
  status order_status not null default 'new',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_orders_status on orders (status);
create index if not exists idx_orders_customer on orders (customer_id);
create index if not exists idx_orders_created on orders (created_at desc);

-- ---------------------------------------------------------------------
-- PAYMENTS
-- Customer-submitted proof of payment against an order. This is manual
-- verification (no live payment gateway) unless one is integrated later.
-- ---------------------------------------------------------------------
create table if not exists payments (
  id uuid primary key default uuid_generate_v4(),
  order_id uuid not null references orders(id) on delete cascade,
  amount numeric(12,2) not null,
  utr_number text,
  screenshot_url text,
  status payment_status not null default 'submitted',
  admin_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_payments_order on payments (order_id);
create index if not exists idx_payments_status on payments (status);

-- ---------------------------------------------------------------------
-- MESSAGES (contact form)
-- ---------------------------------------------------------------------
create table if not exists messages (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  phone text,
  email text,
  message text not null,
  status message_status not null default 'unread',
  created_at timestamptz not null default now()
);
create index if not exists idx_messages_status on messages (status);

-- ---------------------------------------------------------------------
-- SOCIAL LINKS
-- ---------------------------------------------------------------------
create table if not exists social_links (
  id uuid primary key default uuid_generate_v4(),
  platform text not null unique, -- 'facebook' | 'instagram' | 'youtube' | 'whatsapp'
  url text not null,
  is_active boolean not null default true,
  sort_order integer not null default 0
);

-- ---------------------------------------------------------------------
-- WEBSITE SETTINGS (singleton key/value store)
-- One row per setting key so admin can add new settings without a migration.
-- ---------------------------------------------------------------------
create table if not exists website_settings (
  key text primary key,
  value jsonb not null default '""'::jsonb,
  updated_at timestamptz not null default now()
);

-- Seed the default/expected settings keys so the admin form always has
-- something to render even before the admin edits them.
insert into website_settings (key, value) values
  ('website_name', '"My Digital Agency"'),
  ('logo_url', 'null'),
  ('favicon_url', 'null'),
  ('hero_title', '"Grow Your Business With Professional Digital Services"'),
  ('hero_subtitle', '"Websites, advertisements, social media marketing, AI content and creative digital solutions — all in one place."'),
  ('hero_image_url', 'null'),
  ('hero_cta_primary_label', '"View Services"'),
  ('hero_cta_secondary_label', '"Get Started"'),
  ('about_business_name', '"My Digital Agency"'),
  ('about_description', '""'),
  ('about_founder_name', '""'),
  ('about_founder_image_url', 'null'),
  ('about_experience', '""'),
  ('about_skills', '[]'),
  ('about_mission', '""'),
  ('about_vision', '""'),
  ('contact_phone', '""'),
  ('contact_whatsapp', '""'),
  ('contact_email', '""'),
  ('contact_address', '""'),
  ('payment_upi_id', '""'),
  ('payment_qr_url', 'null'),
  ('payment_instructions', '""'),
  ('footer_text', '"© 2026 All Rights Reserved."'),
  ('seo_title', '"My Digital Agency — Websites, Ads, AI & Marketing"'),
  ('seo_meta_description', '"Professional website design, advertising, and digital marketing services."')
on conflict (key) do nothing;

-- ---------------------------------------------------------------------
-- MEDIA LIBRARY
-- Metadata for anything uploaded to Supabase Storage. The actual file
-- bytes live in the `media` storage bucket; this table indexes them.
-- ---------------------------------------------------------------------
create table if not exists media (
  id uuid primary key default uuid_generate_v4(),
  file_name text not null,
  storage_path text not null,
  public_url text not null,
  mime_type text not null,
  size_bytes integer not null,
  purpose text, -- 'logo' | 'favicon' | 'hero' | 'service' | 'portfolio' | 'payment_qr' | 'profile' | 'general'
  uploaded_by uuid references admin_users(id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists idx_media_purpose on media (purpose);

-- ---------------------------------------------------------------------
-- NOTIFICATIONS (admin-facing, e.g. "New order received")
-- ---------------------------------------------------------------------
create table if not exists notifications (
  id uuid primary key default uuid_generate_v4(),
  type text not null,              -- 'order' | 'message' | 'payment'
  title text not null,
  body text,
  reference_id uuid,               -- id of the related order/message/payment
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_notifications_read on notifications (is_read);

-- ---------------------------------------------------------------------
-- updated_at auto-touch trigger
-- ---------------------------------------------------------------------
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

do $$
declare t text;
begin
  foreach t in array array['admin_users','customers','services','pricing_packages',
                            'coupons','portfolio','orders','payments'] loop
    execute format(
      'drop trigger if exists trg_set_updated_at on %I; 
       create trigger trg_set_updated_at before update on %I
       for each row execute function set_updated_at();', t, t);
  end loop;
end $$;

-- =====================================================================
-- ROW LEVEL SECURITY
-- Public (anon) role: read-only on published/active content, and
-- INSERT-only on orders/payments/messages/customers (never UPDATE/DELETE,
-- never SELECT other customers' data). Admins (authenticated + present
-- in admin_users) get full access via the service role in API routes —
-- the frontend never talks to these tables with elevated privileges.
-- =====================================================================

alter table admin_users enable row level security;
alter table customers enable row level security;
alter table services enable row level security;
alter table pricing_packages enable row level security;
alter table coupons enable row level security;
alter table portfolio enable row level security;
alter table orders enable row level security;
alter table payments enable row level security;
alter table messages enable row level security;
alter table social_links enable row level security;
alter table website_settings enable row level security;
alter table media enable row level security;
alter table notifications enable row level security;

-- Helper: is the current auth.uid() an admin?
create or replace function is_admin()
returns boolean as $$
  select exists (select 1 from admin_users where id = auth.uid());
$$ language sql stable security definer;

-- Public read access to "storefront" content
create policy "public read published services" on services
  for select using (status = 'published');
create policy "public read published packages" on pricing_packages
  for select using (status = 'published');
create policy "public read published portfolio" on portfolio
  for select using (status = 'published');
create policy "public read active social links" on social_links
  for select using (is_active = true);
create policy "public read website settings" on website_settings
  for select using (true);

-- Public insert-only for lead-generation tables (server-side API routes
-- additionally validate/sanitize before writing — RLS is a second layer)
create policy "public insert customers" on customers for insert with check (true);
create policy "public insert orders" on orders for insert with check (true);
create policy "public insert payments" on payments for insert with check (true);
create policy "public insert messages" on messages for insert with check (true);

-- Admin full access (all tables)
do $$
declare t text;
begin
  foreach t in array array['admin_users','customers','services','pricing_packages',
                            'coupons','portfolio','orders','payments','messages',
                            'social_links','website_settings','media','notifications'] loop
    execute format(
      'drop policy if exists "admin full access" on %I;
       create policy "admin full access" on %I for all using (is_admin()) with check (is_admin());',
       t, t);
  end loop;
end $$;

-- Coupons are never publicly SELECTable (validated only via a server-side
-- API route using the service role, so codes can't be enumerated).
-- No public select policy is created for `coupons` on purpose.

-- ---------------------------------------------------------------------
-- Atomic coupon usage increment (avoids read-then-write race conditions
-- when two customers redeem the last use of a limited coupon at once)
-- ---------------------------------------------------------------------
create or replace function increment_coupon_usage(coupon_id uuid)
returns void as $$
  update coupons set usage_count = usage_count + 1 where id = coupon_id;
$$ language sql security definer;

-- =====================================================================
-- End of schema
-- =====================================================================
