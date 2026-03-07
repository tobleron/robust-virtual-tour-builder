-- Auth identity hardening: username, verification, reset tokens.

ALTER TABLE users ADD COLUMN username TEXT;
ALTER TABLE users ADD COLUMN status TEXT NOT NULL DEFAULT 'pending_verification';
ALTER TABLE users ADD COLUMN email_verified_at DATETIME;

-- Backfill existing users with deterministic unique username slug candidates.
UPDATE users
SET username = lower(replace(substr(email, 1, instr(email, '@') - 1), ' ', '-')) || '-' || substr(id, 1, 6)
WHERE username IS NULL OR trim(username) = '';

-- Existing legacy accounts are considered active/verified.
UPDATE users
SET status = 'active',
    email_verified_at = COALESCE(email_verified_at, created_at)
WHERE email_verified_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username_unique ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);

CREATE TABLE IF NOT EXISTS email_verification_tokens (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at DATETIME NOT NULL,
    consumed_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_email_verification_tokens_user ON email_verification_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_email_verification_tokens_expiry ON email_verification_tokens(expires_at);

CREATE TABLE IF NOT EXISTS password_reset_tokens (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at DATETIME NOT NULL,
    consumed_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_user ON password_reset_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_expiry ON password_reset_tokens(expires_at);
