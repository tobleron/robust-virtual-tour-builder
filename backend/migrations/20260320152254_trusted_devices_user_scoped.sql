CREATE TABLE trusted_devices_next (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    device_token_hash TEXT NOT NULL,
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
    UNIQUE (user_id, device_token_hash),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

INSERT INTO trusted_devices_next (
    id, user_id, device_token_hash, user_agent, user_agent_family, last_ip, last_country, last_region,
    last_lat, last_lon, last_timezone, last_language, first_seen_at, last_seen_at, trust_expires_at, revoked_at
)
SELECT
    id, user_id, device_token_hash, user_agent, user_agent_family, last_ip, last_country, last_region,
    last_lat, last_lon, last_timezone, last_language, first_seen_at, last_seen_at, trust_expires_at, revoked_at
FROM trusted_devices;

DROP TABLE trusted_devices;

ALTER TABLE trusted_devices_next RENAME TO trusted_devices;

CREATE INDEX idx_trusted_devices_user ON trusted_devices(user_id);
CREATE INDEX idx_trusted_devices_active ON trusted_devices(user_id, trust_expires_at, revoked_at);
