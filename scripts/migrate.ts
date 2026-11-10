#!/usr/bin/env tsx
/**
 * Database migration script for Drizzle ORM
 * Run with: npm run db:migrate
 */

import { drizzle } from "drizzle-orm/node-postgres";
import { migrate } from "drizzle-orm/node-postgres/migrator";
import { Pool } from "pg";

async function main() {
  if (!process.env.DATABASE_URL) {
    console.error("Error: DATABASE_URL environment variable is required");
    process.exit(1);
  }
  const pool = new Pool({ connectionString: process.env.DATABASE_URL, connectionTimeoutMillis: 5000 });
  const db = drizzle({ client: pool });

  console.log("Running migrations...");
  await migrate(db, { migrationsFolder: "./drizzle" });
  console.log("Migrations complete");
  process.exit(0);
}

main().catch((err) => {
  console.error("Migration failed:", err);
  process.exit(1);
});
