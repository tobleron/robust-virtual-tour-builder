ALTER TABLE portal_customer_tour_assignments
ADD COLUMN updated_at DATETIME;

UPDATE portal_customer_tour_assignments
SET updated_at = COALESCE(updated_at, created_at, CURRENT_TIMESTAMP);
