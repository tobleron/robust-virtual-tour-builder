-- Risk-based step-up authentication schema.

ALTER TABLE users ADD COLUMN force_step_up_reason TEXT;
ALTER TABLE users ADD COLUMN force_step_up_until DATETIME;

CREATE TABLE IF NOT EXISTS trusted_devices (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    device_token_hash TEXT NOT NULL UNIQUE,
    user_agent TEXT,
    user_agent_family TEXT,
    last_ip TEXT,
    last_country TEXT,
    last_region TEXT,
    last_lat REAL,
    last_lon REAL,
    last_timezone TEXT,
    last_language TEXT,
    first_seen_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_seen_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    trust_expires_at DATETIME NOT NULL,
    revoked_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_trusted_devices_user ON trusted_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_trusted_devices_active ON trusted_devices(user_id, trust_expires_at, revoked_at);

CREATE TABLE IF NOT EXISTS login_attempts (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT,
    email TEXT,
    ip_address TEXT,
    device_token_hash TEXT,
    success INTEGER NOT NULL DEFAULT 0,
    failure_reason TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_login_attempts_email_time ON login_attempts(email, created_at);
CREATE INDEX IF NOT EXISTS idx_login_attempts_ip_time ON login_attempts(ip_address, created_at);
CREATE INDEX IF NOT EXISTS idx_login_attempts_user_time ON login_attempts(user_id, created_at);

CREATE TABLE IF NOT EXISTS otp_challenges (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    challenge_type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    risk_score INTEGER NOT NULL DEFAULT 0,
    risk_reasons_json TEXT NOT NULL DEFAULT '[]',
    otp_hash TEXT NOT NULL,
    otp_expires_at DATETIME NOT NULL,
    attempts_used INTEGER NOT NULL DEFAULT 0,
    max_attempts INTEGER NOT NULL DEFAULT 5,
    resend_available_at DATETIME NOT NULL,
    resend_count INTEGER NOT NULL DEFAULT 0,
    ip_address TEXT,
    user_agent TEXT,
    device_token_hash TEXT,
    issued_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    verified_at DATETIME,
    consumed_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_otp_challenges_user_status ON otp_challenges(user_id, status, issued_at);
CREATE INDEX IF NOT EXISTS idx_otp_challenges_ip_time ON otp_challenges(ip_address, issued_at);

CREATE TABLE IF NOT EXISTS auth_events (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT,
    event_type TEXT NOT NULL,
    decision TEXT NOT NULL,
    risk_score INTEGER,
    reason TEXT,
    ip_address TEXT,
    user_agent TEXT,
    country TEXT,
    region TEXT,
    lat REAL,
    lon REAL,
    timezone TEXT,
    language TEXT,
    extra_json TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_auth_events_user_time ON auth_events(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_auth_events_type_time ON auth_events(event_type, created_at);
