#!/usr/bin/env tsx
/**
 * Database seeding script
 * Run with: npm run db:seed
 */

import { db, schema } from "../src/db";

const SEED_OWNER_EMAIL = "seed.vendor.one@example.com";
const SEED_PASSWORD_HASH = "seed-account-not-usable-for-login";

function pickBy<T>(rows: T[], predicate: (row: T) => boolean, label: string): T {
  const row = rows.find(predicate);
  if (!row) {
    throw new Error(`Seed failed: no inserted row found for ${label}`);
  }
  return row;
}

function pickByEmail<T extends { email: string }>(rows: T[], email: string): T {
  return pickBy(
    rows,
    (row) => row.email.toLowerCase() === email.toLowerCase(),
    email,
  );
}

function pickByName<T extends { name: string }>(rows: T[], name: string): T {
  return pickBy(rows, (row) => row.name === name, name);
}

function pickBySlug<T extends { slug: string }>(rows: T[], slug: string): T {
  return pickBy(rows, (row) => row.slug === slug, slug);
}

function addDays(base: Date, days: number): Date {
  const next = new Date(base);
  next.setUTCDate(next.getUTCDate() + days);
  return next;
}

function isoDate(d: Date): string {
  return d.toISOString().slice(0, 10);
}

async function main() {
  if (!process.env.DATABASE_URL) {
    console.error("Error: DATABASE_URL environment variable is required");
    process.exit(1);
  }

  console.log("Seeding database...");

  const start = addDays(new Date(), 30);
  const endsAt = addDays(start, 2);

  let alreadySeeded = false;

  await db.transaction(async (tx) => {
    const insertedOwners = await tx
      .insert(schema.users)
      .values({
        email: SEED_OWNER_EMAIL,
        name: "Grace Mwangi",
        phone: "+254700000001",
        passwordHash: SEED_PASSWORD_HASH,
        emailVerifiedAt: new Date(),
      })
      .onConflictDoNothing()
      .returning({ id: schema.users.id, email: schema.users.email });

    if (insertedOwners.length === 0) {
      alreadySeeded = true;
      return;
    }

    const ownerOne = insertedOwners[0];

    const insertedUsers = await tx
      .insert(schema.users)
      .values([
        {
          email: "seed.vendor.two@example.com",
          name: "Peter Otieno",
          phone: "+254700000002",
          passwordHash: SEED_PASSWORD_HASH,
          emailVerifiedAt: new Date(),
        },
        {
          email: "seed.renter@example.com",
          name: "Achieng Ochieng",
          phone: "+254700000003",
          passwordHash: SEED_PASSWORD_HASH,
          emailVerifiedAt: new Date(),
        },
      ])
      .returning({ id: schema.users.id, email: schema.users.email });

    const ownerTwo = pickByEmail(insertedUsers, "seed.vendor.two@example.com");
    const renter = pickByEmail(insertedUsers, "seed.renter@example.com");

    const seededVendors = await tx
      .insert(schema.vendors)
      .values([
        {
          ownerId: ownerOne.id,
          name: "Karen Decor & Furniture Hire",
          slug: "karen-decor-furniture",
          town: "Nairobi",
          phone: "+254700000001",
          deliveryRadiusKm: 35,
          kraPin: "P051234567X",
          ratingAverage: 4600,
          published: true,
        },
        {
          ownerId: ownerTwo.id,
          name: "Westlands Sound & Lighting",
          slug: "westlands-sound-lighting",
          town: "Nairobi",
          phone: "+254700000002",
          deliveryRadiusKm: 25,
          ratingAverage: 4400,
          published: true,
        },
      ])
      .returning({ id: schema.vendors.id, slug: schema.vendors.slug });

    const decorVendor = pickBySlug(seededVendors, "karen-decor-furniture");
    const soundVendor = pickBySlug(seededVendors, "westlands-sound-lighting");

    const seededItems = await tx
      .insert(schema.items)
      .values([
        {
          vendorId: decorVendor.id,
          kind: "chair" as const,
          name: "Gold Chiavari Chair",
          description: "Gold resin Chiavari chair with ivory cushion.",
          pricePerDayKes: 350,
          depositKes: 200,
          quantity: 150,
          photoUrls: ["https://example.com/seed/chiavari-chair.jpg"],
        },
        {
          vendorId: decorVendor.id,
          kind: "table" as const,
          name: "Round Banquet Table (1.8m)",
          description: "Seats 10 guests; white linen included on request.",
          pricePerDayKes: 800,
          depositKes: 1000,
          quantity: 20,
          photoUrls: ["https://example.com/seed/round-table.jpg"],
        },
        {
          vendorId: decorVendor.id,
          kind: "tent" as const,
          name: "10m x 15m Marquee Tent",
          description: "Frame marquee with side walls and clear roof panels.",
          pricePerDayKes: 25000,
          depositKes: 20000,
          quantity: 2,
        },
        {
          vendorId: soundVendor.id,
          kind: "sound" as const,
          name: "PA System (8 speakers)",
          description: "Wireless mics, mixer and two monitors included.",
          pricePerDayKes: 12000,
          depositKes: 10000,
          quantity: 3,
        },
        {
          vendorId: soundVendor.id,
          kind: "lighting" as const,
          name: "LED Uplight Set (8 units)",
          description: "RGBWA uplights with DMX controller.",
          pricePerDayKes: 3000,
          depositKes: 2000,
          quantity: 6,
        },
        {
          vendorId: soundVendor.id,
          kind: "generator" as const,
          name: "30kVA Silent Generator",
          description: "Includes fuel for a single event day.",
          pricePerDayKes: 8000,
          depositKes: 5000,
          quantity: 2,
        },
      ])
      .returning({
        id: schema.items.id,
        pricePerDayKes: schema.items.pricePerDayKes,
        name: schema.items.name,
      });

    const [event] = await tx
      .insert(schema.events)
      .values({
        renterId: renter.id,
        name: "Achieng & Tunde Wedding",
        kind: "wedding",
        venueAddress: "Karen Country Club, Nairobi",
        startsAt: start,
        endsAt,
        guestCount: 120,
      })
      .returning({ id: schema.events.id });

    const chairs = pickByName(seededItems, "Gold Chiavari Chair");
    const tables = pickByName(seededItems, "Round Banquet Table (1.8m)");
    const days = 3;
    const chairQuantity = 100;
    const tableQuantity = 15;
    const subtotalKes =
      chairs.pricePerDayKes * chairQuantity * days +
      tables.pricePerDayKes * tableQuantity * days;
    const deliveryKes = 5000;
    const depositKes = 5000;

    const [booking] = await tx
      .insert(schema.bookings)
      .values({
        eventId: event.id,
        vendorId: decorVendor.id,
        status: "confirmed",
        startsOn: isoDate(start),
        endsOn: isoDate(endsAt),
        subtotalKes,
        deliveryKes,
        depositKes,
        totalKes: subtotalKes + deliveryKes + depositKes,
        specialRequests: "Deliver by 08:00 and collect the morning after.",
      })
      .returning({ id: schema.bookings.id });

    await tx.insert(schema.bookingItems).values([
      {
        bookingId: booking.id,
        itemId: chairs.id,
        quantity: chairQuantity,
        pricePerDayKes: chairs.pricePerDayKes,
        days,
        subtotalKes: chairs.pricePerDayKes * chairQuantity * days,
      },
      {
        bookingId: booking.id,
        itemId: tables.id,
        quantity: tableQuantity,
        pricePerDayKes: tables.pricePerDayKes,
        days,
        subtotalKes: tables.pricePerDayKes * tableQuantity * days,
      },
    ]);

    await tx.insert(schema.inspections).values({
      bookingId: booking.id,
      kind: "pre_event",
      performedAt: addDays(start, -1),
      conductedBy: "Grace Mwangi",
      damageNotes: "",
    });
  });

  if (alreadySeeded) {
    console.log("Seed data already present; nothing to do");
    process.exit(0);
  }

  console.log("Seeding complete");
  process.exit(0);
}

main().catch((err) => {
  console.error("Seeding failed:", err);
  process.exit(1);
});
