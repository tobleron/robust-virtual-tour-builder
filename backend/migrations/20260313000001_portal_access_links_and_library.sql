CREATE TABLE IF NOT EXISTS portal_settings (
    id INTEGER PRIMARY KEY NOT NULL CHECK (id = 1),
    renewal_heading TEXT NOT NULL DEFAULT 'Access expired',
    renewal_message TEXT NOT NULL DEFAULT 'Contact Robust Virtual Tour Builder to renew access.',
    contact_email TEXT,
    contact_phone TEXT,
    whatsapp_number TEXT,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT OR IGNORE INTO portal_settings (
    id,
    renewal_heading,
    renewal_message,
    contact_email,
    contact_phone,
    whatsapp_number,
    updated_at
) VALUES (
    1,
    'Access expired',
    'Contact Robust Virtual Tour Builder to renew access.',
    NULL,
    NULL,
    NULL,
    CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS portal_access_links (
    id TEXT PRIMARY KEY NOT NULL,
    customer_id TEXT NOT NULL,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at DATETIME NOT NULL,
    revoked_at DATETIME,
    last_opened_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES portal_customers(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_portal_access_links_customer ON portal_access_links(customer_id);
CREATE INDEX IF NOT EXISTS idx_portal_access_links_expiry ON portal_access_links(expires_at);

CREATE TABLE IF NOT EXISTS portal_library_tours (
    id TEXT PRIMARY KEY NOT NULL,
    title TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'published',
    storage_path TEXT NOT NULL,
    cover_path TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_portal_library_tours_status ON portal_library_tours(status);

CREATE TABLE IF NOT EXISTS portal_customer_tour_assignments (
    id TEXT PRIMARY KEY NOT NULL,
    customer_id TEXT NOT NULL,
    tour_id TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES portal_customers(id) ON DELETE CASCADE,
    FOREIGN KEY (tour_id) REFERENCES portal_library_tours(id) ON DELETE CASCADE,
    UNIQUE (customer_id, tour_id)
);

CREATE INDEX IF NOT EXISTS idx_portal_customer_tour_assignments_customer
    ON portal_customer_tour_assignments(customer_id);
CREATE INDEX IF NOT EXISTS idx_portal_customer_tour_assignments_tour
    ON portal_customer_tour_assignments(tour_id);
