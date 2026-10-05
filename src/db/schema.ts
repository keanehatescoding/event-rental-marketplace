import { relations, sql } from "drizzle-orm";
import {
  boolean,
  date,
  index,
  integer,
  pgEnum,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from "drizzle-orm/pg-core";

export const bookingStatusEnum = pgEnum("booking_status", [
  "requested",
  "quote_sent",
  "confirmed",
  "fulfilled",
  "returned",
  "cancelled",
]);
export const itemKindEnum = pgEnum("item_kind", [
  "chair",
  "table",
  "tent",
  "linen",
  "cutlery",
  "decor",
  "sound",
  "lighting",
  "generator",
  "gown",
  "suit",
  "other",
]);
export const payoutStatusEnum = pgEnum("payout_status", ["pending", "paid", "failed"]);

const timestamps = {
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .notNull()
    .defaultNow()
    .$onUpdate(() => new Date()),
};

export const users = pgTable(
  "users",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    email: text("email").notNull(),
    name: text("name").notNull(),
    phone: text("phone"),
    passwordHash: text("password_hash").notNull(),
    emailVerifiedAt: timestamp("email_verified_at", { withTimezone: true }),
    ...timestamps,
  },
  (t) => [uniqueIndex("users_email_lower_idx").on(sql`lower(${t.email})`)],
);

export const sessions = pgTable(
  "sessions",
  {
    id: text("id").primaryKey(),
    userId: uuid("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [index("sessions_user_idx").on(t.userId)],
);

export const vendors = pgTable(
  "vendors",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    ownerId: uuid("owner_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    name: text("name").notNull(),
    slug: text("slug").notNull(),
    town: text("town").notNull(),
    phone: text("phone").notNull(),
    deliveryRadiusKm: integer("delivery_radius_km").notNull().default(20),
    kraPin: text("kra_pin"),
    ratingAverage: integer("rating_average_bps").notNull().default(0),
    published: boolean("published").notNull().default(false),
    ...timestamps,
  },
  (t) => [uniqueIndex("vendors_slug_idx").on(t.slug)],
);

export const items = pgTable(
  "items",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    vendorId: uuid("vendor_id")
      .notNull()
      .references(() => vendors.id, { onDelete: "cascade" }),
    kind: itemKindEnum("kind").notNull(),
    name: text("name").notNull(),
    description: text("description").notNull().default(""),
    // Rentals are priced per day in KES. Multi-day blocks are the per-day rate × days unless overridden.
    pricePerDayKes: integer("price_per_day_kes").notNull(),
    // Refundable deposit charged alongside the day rate.
    depositKes: integer("deposit_kes").notNull().default(0),
    quantity: integer("quantity").notNull(),
    photoUrls: text("photo_urls").array().notNull().default(sql`'{}'::text[]`),
    published: boolean("published").notNull().default(true),
    ...timestamps,
  },
  (t) => [index("items_vendor_idx").on(t.vendorId), index("items_kind_idx").on(t.kind, t.published)],
);

/** A specific event the renter is buying for. One event can have one or many bookings across vendors. */
export const events = pgTable(
  "events",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    renterId: uuid("renter_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    name: text("name").notNull(),
    kind: text("kind").notNull(),
    venueAddress: text("venue_address").notNull(),
    startsAt: timestamp("starts_at", { withTimezone: true }).notNull(),
    endsAt: timestamp("ends_at", { withTimezone: true }).notNull(),
    guestCount: integer("guest_count"),
    ...timestamps,
  },
  (t) => [index("events_renter_idx").on(t.renterId, t.startsAt)],
);

export const bookings = pgTable(
  "bookings",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    eventId: uuid("event_id")
      .notNull()
      .references(() => events.id, { onDelete: "cascade" }),
    vendorId: uuid("vendor_id")
      .notNull()
      .references(() => vendors.id, { onDelete: "restrict" }),
    status: bookingStatusEnum("status").notNull().default("requested"),
    startsOn: date("starts_on", { mode: "string" }).notNull(),
    endsOn: date("ends_on", { mode: "string" }).notNull(),
    subtotalKes: integer("subtotal_kes").notNull(),
    deliveryKes: integer("delivery_kes").notNull().default(0),
    depositKes: integer("deposit_kes").notNull().default(0),
    totalKes: integer("total_kes").notNull(),
    specialRequests: text("special_requests").notNull().default(""),
    cancelledAt: timestamp("cancelled_at", { withTimezone: true }),
    ...timestamps,
  },
  (t) => [
    index("bookings_vendor_dates_idx").on(t.vendorId, t.startsOn, t.endsOn),
    index("bookings_event_idx").on(t.eventId),
  ],
);

export const bookingItems = pgTable(
  "booking_items",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    bookingId: uuid("booking_id")
      .notNull()
      .references(() => bookings.id, { onDelete: "cascade" }),
    itemId: uuid("item_id")
      .notNull()
      .references(() => items.id, { onDelete: "restrict" }),
    quantity: integer("quantity").notNull(),
    pricePerDayKes: integer("price_per_day_kes").notNull(),
    days: integer("days").notNull(),
    subtotalKes: integer("subtotal_kes").notNull(),
  },
  (t) => [uniqueIndex("booking_items_booking_item_idx").on(t.bookingId, t.itemId)],
);

/** Pre- and post-event checks: did everything leave? did everything come back? */
export const inspections = pgTable(
  "inspections",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    bookingId: uuid("booking_id")
      .notNull()
      .references(() => bookings.id, { onDelete: "cascade" }),
    kind: text("kind").notNull(),
    performedAt: timestamp("performed_at", { withTimezone: true }).notNull(),
    conductedBy: text("conducted_by").notNull(),
    photoUrls: text("photo_urls").array().notNull().default(sql`'{}'::text[]`),
    missingItems: text("missing_items").array().notNull().default(sql`'{}'::text[]`),
    damageNotes: text("damage_notes").notNull().default(""),
    withholdKes: integer("withhold_kes").notNull().default(0),
  },
  (t) => [index("inspections_booking_idx").on(t.bookingId)],
);

export const payouts = pgTable(
  "payouts",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    bookingId: uuid("booking_id")
      .notNull()
      .references(() => bookings.id, { onDelete: "restrict" }),
    vendorId: uuid("vendor_id")
      .notNull()
      .references(() => vendors.id, { onDelete: "restrict" }),
    status: payoutStatusEnum("status").notNull().default("pending"),
    amountKes: integer("amount_kes").notNull(),
    feeKes: integer("fee_kes").notNull().default(0),
    channel: text("channel").notNull().default("mpesa"),
    externalRef: text("external_ref"),
    paidAt: timestamp("paid_at", { withTimezone: true }),
    ...timestamps,
  },
  (t) => [index("payouts_vendor_idx").on(t.vendorId, t.createdAt)],
);

export const bookingRelations = relations(bookings, ({ one, many }) => ({
  event: one(events, { fields: [bookings.eventId], references: [events.id] }),
  vendor: one(vendors, { fields: [bookings.vendorId], references: [vendors.id] }),
  items: many(bookingItems),
  inspections: many(inspections),
  payouts: many(payouts),
}));

export type Vendor = typeof vendors.$inferSelect;
export type Item = typeof items.$inferSelect;
export type Event = typeof events.$inferSelect;
export type Booking = typeof bookings.$inferSelect;
export type Payout = typeof payouts.$inferSelect;
