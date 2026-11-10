#!/usr/bin/env tsx
/**
 * Database seeding script
 * Run with: npm run db:seed
 */

import { db } from "../src/db";

async function main() {
  console.log("Seeding database...");
  // Add seed data here as needed
  console.log("Seeding complete");
  process.exit(0);
}

main().catch((err) => {
  console.error("Seeding failed:", err);
  process.exit(1);
});
