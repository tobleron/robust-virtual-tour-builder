CREATE TABLE IF NOT EXISTS portal_customers (
    id TEXT PRIMARY KEY NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    contact_name TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    renewal_message TEXT,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_portal_customers_slug ON portal_customers(slug);
CREATE INDEX IF NOT EXISTS idx_portal_customers_active ON portal_customers(is_active);

CREATE TABLE IF NOT EXISTS portal_users (
    id TEXT PRIMARY KEY NOT NULL,
    customer_id TEXT NOT NULL,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    billing_status TEXT NOT NULL DEFAULT 'active',
    expires_at DATETIME NOT NULL,
    is_active INTEGER NOT NULL DEFAULT 1,
    last_signed_in_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES portal_customers(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_portal_users_customer_unique ON portal_users(customer_id);
CREATE INDEX IF NOT EXISTS idx_portal_users_username ON portal_users(username);
CREATE INDEX IF NOT EXISTS idx_portal_users_expiry ON portal_users(expires_at);

CREATE TABLE IF NOT EXISTS portal_tours (
    id TEXT PRIMARY KEY NOT NULL,
    customer_id TEXT NOT NULL,
    title TEXT NOT NULL,
    slug TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'published',
    package_profile TEXT NOT NULL DEFAULT '2k',
    storage_path TEXT NOT NULL,
    entry_path TEXT NOT NULL DEFAULT 'tour_2k/index.html',
    cover_path TEXT,
    published_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES portal_customers(id) ON DELETE CASCADE,
    UNIQUE (customer_id, slug)
);

CREATE INDEX IF NOT EXISTS idx_portal_tours_customer ON portal_tours(customer_id);
CREATE INDEX IF NOT EXISTS idx_portal_tours_status ON portal_tours(status);

CREATE TABLE IF NOT EXISTS portal_audit_log (
    id TEXT PRIMARY KEY NOT NULL,
    actor_user_id TEXT,
    customer_id TEXT,
    event_type TEXT NOT NULL,
    details_json TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES portal_customers(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_portal_audit_customer ON portal_audit_log(customer_id);
CREATE INDEX IF NOT EXISTS idx_portal_audit_event_type ON portal_audit_log(event_type);
