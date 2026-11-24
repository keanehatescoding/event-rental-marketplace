CREATE TYPE "public"."booking_status" AS ENUM('requested', 'quote_sent', 'confirmed', 'fulfilled', 'returned', 'cancelled');--> statement-breakpoint
CREATE TYPE "public"."item_kind" AS ENUM('chair', 'table', 'tent', 'linen', 'cutlery', 'decor', 'sound', 'lighting', 'generator', 'gown', 'suit', 'other');--> statement-breakpoint
CREATE TYPE "public"."payout_status" AS ENUM('pending', 'paid', 'failed');--> statement-breakpoint
CREATE TABLE "booking_items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"booking_id" uuid NOT NULL,
	"item_id" uuid NOT NULL,
	"quantity" integer NOT NULL,
	"price_per_day_kes" integer NOT NULL,
	"days" integer NOT NULL,
	"subtotal_kes" integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE "bookings" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"event_id" uuid NOT NULL,
	"vendor_id" uuid NOT NULL,
	"status" "booking_status" DEFAULT 'requested' NOT NULL,
	"starts_on" date NOT NULL,
	"ends_on" date NOT NULL,
	"subtotal_kes" integer NOT NULL,
	"delivery_kes" integer DEFAULT 0 NOT NULL,
	"deposit_kes" integer DEFAULT 0 NOT NULL,
	"total_kes" integer NOT NULL,
	"special_requests" text DEFAULT '' NOT NULL,
	"cancelled_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "events" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"renter_id" uuid NOT NULL,
	"name" text NOT NULL,
	"kind" text NOT NULL,
	"venue_address" text NOT NULL,
	"starts_at" timestamp with time zone NOT NULL,
	"ends_at" timestamp with time zone NOT NULL,
	"guest_count" integer,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "inspections" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"booking_id" uuid NOT NULL,
	"kind" text NOT NULL,
	"performed_at" timestamp with time zone NOT NULL,
	"conducted_by" text NOT NULL,
	"photo_urls" text[] DEFAULT '{}'::text[] NOT NULL,
	"missing_items" text[] DEFAULT '{}'::text[] NOT NULL,
	"damage_notes" text DEFAULT '' NOT NULL,
	"withhold_kes" integer DEFAULT 0 NOT NULL
);
--> statement-breakpoint
CREATE TABLE "items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"vendor_id" uuid NOT NULL,
	"kind" "item_kind" NOT NULL,
	"name" text NOT NULL,
	"description" text DEFAULT '' NOT NULL,
	"price_per_day_kes" integer NOT NULL,
	"deposit_kes" integer DEFAULT 0 NOT NULL,
	"quantity" integer NOT NULL,
	"photo_urls" text[] DEFAULT '{}'::text[] NOT NULL,
	"published" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "payouts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"booking_id" uuid NOT NULL,
	"vendor_id" uuid NOT NULL,
	"status" "payout_status" DEFAULT 'pending' NOT NULL,
	"amount_kes" integer NOT NULL,
	"fee_kes" integer DEFAULT 0 NOT NULL,
	"channel" text DEFAULT 'mpesa' NOT NULL,
	"external_ref" text,
	"paid_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "sessions" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" uuid NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"email" text NOT NULL,
	"name" text NOT NULL,
	"phone" text,
	"password_hash" text NOT NULL,
	"email_verified_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "vendors" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"owner_id" uuid NOT NULL,
	"name" text NOT NULL,
	"slug" text NOT NULL,
	"town" text NOT NULL,
	"phone" text NOT NULL,
	"delivery_radius_km" integer DEFAULT 20 NOT NULL,
	"kra_pin" text,
	"rating_average_bps" integer DEFAULT 0 NOT NULL,
	"published" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "booking_items" ADD CONSTRAINT "booking_items_booking_id_bookings_id_fk" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "booking_items" ADD CONSTRAINT "booking_items_item_id_items_id_fk" FOREIGN KEY ("item_id") REFERENCES "public"."items"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_event_id_events_id_fk" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_vendor_id_vendors_id_fk" FOREIGN KEY ("vendor_id") REFERENCES "public"."vendors"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "events" ADD CONSTRAINT "events_renter_id_users_id_fk" FOREIGN KEY ("renter_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inspections" ADD CONSTRAINT "inspections_booking_id_bookings_id_fk" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "items" ADD CONSTRAINT "items_vendor_id_vendors_id_fk" FOREIGN KEY ("vendor_id") REFERENCES "public"."vendors"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "payouts" ADD CONSTRAINT "payouts_booking_id_bookings_id_fk" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "payouts" ADD CONSTRAINT "payouts_vendor_id_vendors_id_fk" FOREIGN KEY ("vendor_id") REFERENCES "public"."vendors"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "vendors" ADD CONSTRAINT "vendors_owner_id_users_id_fk" FOREIGN KEY ("owner_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "booking_items_booking_item_idx" ON "booking_items" USING btree ("booking_id","item_id");--> statement-breakpoint
CREATE INDEX "bookings_vendor_dates_idx" ON "bookings" USING btree ("vendor_id","starts_on","ends_on");--> statement-breakpoint
CREATE INDEX "bookings_event_idx" ON "bookings" USING btree ("event_id");--> statement-breakpoint
CREATE INDEX "events_renter_idx" ON "events" USING btree ("renter_id","starts_at");--> statement-breakpoint
CREATE INDEX "inspections_booking_idx" ON "inspections" USING btree ("booking_id");--> statement-breakpoint
CREATE INDEX "items_vendor_idx" ON "items" USING btree ("vendor_id");--> statement-breakpoint
CREATE INDEX "items_kind_idx" ON "items" USING btree ("kind","published");--> statement-breakpoint
CREATE INDEX "payouts_vendor_idx" ON "payouts" USING btree ("vendor_id","created_at");--> statement-breakpoint
CREATE INDEX "sessions_user_idx" ON "sessions" USING btree ("user_id");--> statement-breakpoint
CREATE UNIQUE INDEX "users_email_lower_idx" ON "users" USING btree (lower("email"));--> statement-breakpoint
CREATE UNIQUE INDEX "vendors_slug_idx" ON "vendors" USING btree ("slug");