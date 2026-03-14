ALTER TABLE portal_access_links
    ADD COLUMN short_code TEXT;

UPDATE portal_access_links
SET short_code = substr(token_hash, 1, 16)
WHERE short_code IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_portal_access_links_short_code
    ON portal_access_links(short_code);
