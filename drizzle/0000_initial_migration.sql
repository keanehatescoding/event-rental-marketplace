-- Initial migration for event-rental-marketplace
-- This file should be regenerated using: npm run db:generate

-- Create enums
CREATE TYPE booking_status AS ENUM ('requested', 'quote_sent', 'confirmed', 'fulfilled', 'returned', 'cancelled');
CREATE TYPE item_kind AS ENUM ('chair', 'table', 'tent', 'linen', 'cutlery', 'decor', 'sound', 'lighting', 'generator', 'gown', 'suit', 'other');
CREATE TYPE payout_status AS ENUM ('pending', 'paid', 'failed');

-- Create tables
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    name TEXT NOT NULL,
    phone TEXT,
    password_hash TEXT NOT NULL,
    email_verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX users_email_lower_idx ON users (lower(email));

CREATE TABLE sessions (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX sessions_user_idx ON sessions (user_id);

CREATE TABLE vendors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    town TEXT NOT NULL,
    phone TEXT NOT NULL,
    delivery_radius_km INTEGER NOT NULL DEFAULT 20,
    kra_pin TEXT,
    rating_average_bps INTEGER NOT NULL DEFAULT 0,
    published BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX vendors_slug_idx ON vendors (slug);

CREATE TABLE items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    kind item_kind NOT NULL,
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    price_per_day_kes INTEGER NOT NULL,
    deposit_kes INTEGER NOT NULL DEFAULT 0,
    quantity INTEGER NOT NULL,
    photo_urls TEXT[] NOT NULL DEFAULT '{}'::text[],
    published BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX items_vendor_idx ON items (vendor_id);
CREATE INDEX items_kind_idx ON items (kind, published);

CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    renter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    kind TEXT NOT NULL,
    venue_address TEXT NOT NULL,
    starts_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ends_at TIMESTAMP WITH TIME ZONE NOT NULL,
    guest_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX events_renter_idx ON events (renter_id, starts_at);

CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE RESTRICT,
    status booking_status NOT NULL DEFAULT 'requested',
    starts_on DATE NOT NULL,
    ends_on DATE NOT NULL,
    subtotal_kes INTEGER NOT NULL,
    delivery_kes INTEGER NOT NULL DEFAULT 0,
    deposit_kes INTEGER NOT NULL DEFAULT 0,
    total_kes INTEGER NOT NULL,
    special_requests TEXT NOT NULL DEFAULT '',
    cancelled_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX bookings_vendor_dates_idx ON bookings (vendor_id, starts_on, ends_on);
CREATE INDEX bookings_event_idx ON bookings (event_id);

CREATE TABLE booking_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES items(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL,
    price_per_day_kes INTEGER NOT NULL,
    days INTEGER NOT NULL,
    subtotal_kes INTEGER NOT NULL
);

CREATE UNIQUE INDEX booking_items_booking_item_idx ON booking_items (booking_id, item_id);

CREATE TABLE inspections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    kind TEXT NOT NULL,
    performed_at TIMESTAMP WITH TIME ZONE NOT NULL,
    conducted_by TEXT NOT NULL,
    photo_urls TEXT[] NOT NULL DEFAULT '{}'::text[],
    missing_items TEXT[] NOT NULL DEFAULT '{}'::text[],
    damage_notes TEXT NOT NULL DEFAULT '',
    withhold_kes INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX inspections_booking_idx ON inspections (booking_id);

CREATE TABLE payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE RESTRICT,
    vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE RESTRICT,
    status payout_status NOT NULL DEFAULT 'pending',
    amount_kes INTEGER NOT NULL,
    fee_kes INTEGER NOT NULL DEFAULT 0,
    channel TEXT NOT NULL DEFAULT 'mpesa',
    external_ref TEXT,
    paid_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX payouts_vendor_idx ON payouts (vendor_id, created_at);

-- Create update triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_vendors_updated_at BEFORE UPDATE ON vendors FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_items_updated_at BEFORE UPDATE ON items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
