# Multi-vendor event & wedding rental marketplace

- **Concept:** A marketplace for renting event items — decor, furniture, lighting, tableware, and attire — from multiple small vendors in one place, rather than each couple or planner sourcing everything separately.
- **Origin:** Rent the Runway and the broader wedding/event-rental marketplace category (well established on platforms like WeddingWire) in the US.
- **Kenya landscape:** One small Nairobi player, Happy Wishy, already rents and sells wedding gowns specifically — so this is not a fully empty category. The broader, multi-category event-rental marketplace (decor, furniture, and several vendor types together, not just bridal wear) appears less developed.
- **Opportunity:** Kenya's wedding and event culture is large and highly visual (a natural fit for Instagram-first discovery), but the whitespace here is narrower than the other ideas on this list given the existing player.
- **Target customers:** Wedding planners, engaged couples, and corporate event planners in urban centers.
- **Revenue model:** Rental fee per item/set plus a damage deposit, or a vendor-side commission/listing fee.
- **Difficulty:** Medium — logistics-heavy (delivery, pickup, damage/loss risk on physical inventory).
- **Scalability:** Medium — travels to other East African capitals with similar wedding cultures.
- **Risks:** Real inventory and logistics costs; competing for attention with an existing (if small) local player; margins can be thin once damage/loss is accounted for.
- **MVP:** Start with one category that avoids directly competing with Happy Wishy's gowns — e.g., decor and furniture — with a small curated inventory in Nairobi, discovered and booked Instagram-first.

---

## Stack & dev

Scaffolded as a Next.js 16 + Drizzle (Postgres) app, matching the stack used in `odpc-compliance-saas`. The schema in `src/db/schema.ts` is the current source of truth for the data model; UI, auth and payment integrations are not yet wired up.

```
npm install
# point .env at a Postgres instance, see .env.example
npm run db:generate   # drizzle-kit: emit SQL migrations from the schema
npm run db:migrate    # apply migrations in ./drizzle
npm run dev           # Next.js dev server on :3000
```

What is here:
- `src/db/schema.ts` — Drizzle Postgres schema specific to this domain
- `src/db/index.ts` — pooled `pg` + Drizzle client
- `src/app/layout.tsx`, `src/app/page.tsx`, `src/app/globals.css` — minimal Next.js app scaffold
- `scripts/migrate.ts`, `scripts/seed.ts` — Drizzle migration and seed entry points
- `drizzle.config.ts`, `next.config.ts`, `tsconfig.json`, `eslint.config.mjs`, `postcss.config.mjs`
- `.gitignore`, `.env.example`

What is still a stub:
- Auth (sessions, password reset, email verify) — copy and adapt the `lib/session.ts`, `lib/password.ts`, `lib/email-verification.ts` set from `odpc-compliance-saas`.
- Payments (M-Pesa Daraja / Paystack / card) — stack-specific, add per project.
- `scripts/seed.ts` seed data — the script runs but does not insert sample records yet.
