# Project Structure (Full Plan)

This is Part 1 of a multi-part build. Files marked **(done)** exist in this
delivery; everything else is planned for the next parts so you can see the
whole shape of the app up front.

```
service-biz-app/
├── package.json                        (done)
├── tsconfig.json                        (done)
├── next.config.js                       (done)
├── tailwind.config.ts                   (done)
├── postcss.config.js                    (done)
├── middleware.ts                        (done) — protects /admin/*
├── .env.example                         (done)
├── types/
│   └── database.ts                      (done)
├── lib/
│   ├── supabase/
│   │   ├── client.ts                    (done) — browser client
│   │   ├── server.ts                    (done) — server/RLS-scoped client
│   │   └── admin.ts                     (done) — service-role client
│   ├── auth/
│   │   └── require-admin.ts             (done) — API route guard
│   ├── pricing/
│   │   └── coupons.ts                   (done) — server-side coupon math
│   └── validation/
│       └── schemas.ts                   (next) — zod schemas for every form
├── supabase/
│   └── schema.sql                       (done) — full DB schema + RLS
├── app/
│   ├── layout.tsx                       (next)
│   ├── page.tsx                         (next) — Home
│   ├── globals.css                      (next)
│   ├── services/
│   │   ├── page.tsx                     (next) — Services listing
│   │   └── [slug]/page.tsx              (next) — Service detail + order CTA
│   ├── pricing/page.tsx                 (next)
│   ├── portfolio/page.tsx               (next)
│   ├── about/page.tsx                   (next)
│   ├── contact/page.tsx                 (next)
│   ├── order/[serviceSlug]/page.tsx     (next) — order form + coupon + payment
│   ├── api/
│   │   ├── coupons/validate/route.ts    (next)
│   │   ├── orders/route.ts              (next)
│   │   ├── payments/route.ts            (next)
│   │   ├── messages/route.ts            (next)
│   │   └── admin/
│   │       ├── services/route.ts        (next) — CRUD
│   │       ├── services/[id]/route.ts   (next)
│   │       ├── packages/route.ts        (next)
│   │       ├── coupons/route.ts         (next)
│   │       ├── portfolio/route.ts       (next)
│   │       ├── orders/route.ts          (next)
│   │       ├── orders/[id]/route.ts     (next) — status updates
│   │       ├── messages/route.ts        (next)
│   │       ├── settings/route.ts        (next)
│   │       ├── social-links/route.ts    (next)
│   │       └── media/route.ts           (next) — upload handler
│   └── admin/
│       ├── login/page.tsx               (next)
│       ├── layout.tsx                   (next) — sidebar shell
│       ├── page.tsx                     (next) — Dashboard w/ charts
│       ├── services/page.tsx            (next)
│       ├── pricing/page.tsx             (next)
│       ├── coupons/page.tsx             (next)
│       ├── portfolio/page.tsx           (next)
│       ├── orders/page.tsx              (next)
│       ├── customers/page.tsx           (next)
│       ├── messages/page.tsx            (next)
│       ├── payments/page.tsx            (next)
│       ├── social-media/page.tsx        (next)
│       ├── settings/page.tsx            (next)
│       ├── seo/page.tsx                 (next)
│       ├── media/page.tsx               (next)
│       └── profile/page.tsx             (next)
├── components/
│   ├── site/  (Navbar, Footer, Hero, ServiceCard, PricingCard, ...) (next)
│   └── admin/ (Sidebar, DataTable, StatCard, FormField, ...)        (next)
├── scripts/
│   └── create-admin.mjs                 (next) — first-admin bootstrap CLI
├── SETUP.md                              (done)
└── DEPLOYMENT.md                         (next)
```

## Why this order

The schema, security layer (RLS + `requireAdmin`), and coupon math came
first because every other feature (orders, admin CRUD, the storefront)
reads or writes through them. Getting these right first means the UI
work in the next parts has a real, secure backend to sit on — not a
mockup wired up to fake data.

## Next parts

- **Part 2:** Auth (admin login/logout), admin panel shell + dashboard,
  and the first full CRUD module (Services) end-to-end as the template
  the rest follow.
- **Part 3:** Pricing packages, coupons admin, portfolio admin, media
  upload handling.
- **Part 4:** Public website (home, services, pricing, portfolio,
  about, contact) reading live from the database.
- **Part 5:** Order flow (service → package → coupon → submit),
  payment/QR section, orders + payments admin views, dashboard charts.
- **Part 6:** Website settings/SEO admin, social links, admin profile,
  `create-admin.mjs`, deployment guide + custom domain steps, security
  checklist.

Say "continue" (or name a specific part) and I'll keep building.
