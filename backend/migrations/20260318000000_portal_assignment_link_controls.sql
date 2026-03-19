ALTER TABLE portal_customer_tour_assignments
ADD COLUMN short_code TEXT;

ALTER TABLE portal_customer_tour_assignments
ADD COLUMN status TEXT NOT NULL DEFAULT 'active';

ALTER TABLE portal_customer_tour_assignments
ADD COLUMN expires_at_override DATETIME;

ALTER TABLE portal_customer_tour_assignments
ADD COLUMN revoked_at DATETIME;

ALTER TABLE portal_customer_tour_assignments
ADD COLUMN revoked_reason TEXT;

ALTER TABLE portal_customer_tour_assignments
ADD COLUMN last_opened_at DATETIME;

ALTER TABLE portal_customer_tour_assignments
ADD COLUMN open_count INTEGER NOT NULL DEFAULT 0;

ALTER TABLE portal_customer_tour_assignments
ADD COLUMN geo_country_code TEXT;

ALTER TABLE portal_customer_tour_assignments
ADD COLUMN geo_region TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_portal_customer_tour_assignments_short_code
    ON portal_customer_tour_assignments(short_code);

CREATE INDEX IF NOT EXISTS idx_portal_customer_tour_assignments_customer_tour
    ON portal_customer_tour_assignments(customer_id, tour_id);
