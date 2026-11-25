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

Requires **Node.js 20.19.0 on the 20.x line or 22.9.0 on the 22.x line**: the `db:migrate` and `db:seed` scripts pass `--env-file-if-exists` to `tsx`, and Node.js only supports that flag from those versions.

```
npm install
# point .env at a Postgres instance, see .env.example
npm run db:generate   # drizzle-kit: emit SQL migrations from the schema
npm run db:migrate    # apply migrations in ./drizzle
npm run db:seed       # insert demo vendors, items, an event and a booking
npm run dev           # Next.js dev server on :3000
```

What is here:
- `src/db/schema.ts` — Drizzle Postgres schema specific to this domain
- `src/db/index.ts` — pooled `pg` + Drizzle client
- `src/app/layout.tsx`, `src/app/page.tsx`, `src/app/globals.css` — minimal Next.js app scaffold
- `scripts/migrate.ts`, `scripts/seed.ts` — Drizzle migration and seed entry points; the seed is idempotent and inserts two vendors, their items, a renter event and a confirmed booking
- `drizzle.config.ts`, `next.config.ts`, `tsconfig.json`, `eslint.config.mjs`, `postcss.config.mjs`
- `.gitignore`, `.env.example`

What is still a stub:
- Auth (sessions, password reset, email verify) — copy and adapt the `lib/session.ts`, `lib/password.ts`, `lib/email-verification.ts` set from `odpc-compliance-saas`.
- Payments (M-Pesa Daraja / Paystack / card) — stack-specific, add per project.

## Deploying

Railway deploys this service from `master`. `.railway/railway.ts` is the source
of truth for the environment: apply it with `railway config apply`. It builds
with Railpack, runs `npm run db:migrate` before each deploy, and checks
`/api/health` (which queries Postgres, not just the app process) before
routing traffic to the new version.

Set secrets on Railway itself, never in the repository:

```
railway variables --service event-rental-marketplace --set APP_URL=https://<your-public-host>
```

`DATABASE_URL` is injected from the Postgres service declared in `railway.ts`.

To run the same shape locally: `docker compose up -d db`, then put
`DATABASE_URL=postgres://app:app@localhost:5432/app` in `.env`, run
`npm run db:migrate` and `npm run dev`. `docker compose down` keeps the data
volume; add `-v` to remove it.

For a self-hosted container deployment, `docker build -t event-rental-marketplace .` produces a
production image that applies migrations and then starts the app. Its
`HEALTHCHECK` uses the same `/api/health` endpoint.
