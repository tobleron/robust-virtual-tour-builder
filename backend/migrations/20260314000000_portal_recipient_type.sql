ALTER TABLE portal_customers
ADD COLUMN recipient_type TEXT NOT NULL DEFAULT 'property_owner';

UPDATE portal_customers
SET recipient_type = 'property_owner'
WHERE recipient_type IS NULL OR TRIM(recipient_type) = '';
