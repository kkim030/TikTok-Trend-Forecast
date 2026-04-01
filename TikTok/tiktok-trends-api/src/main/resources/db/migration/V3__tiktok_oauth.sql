-- ─────────────────────────────────────────────────────────────
-- V3: TikTok OAuth — store OAuth tokens on users table
-- ─────────────────────────────────────────────────────────────

ALTER TABLE users
    ADD COLUMN tiktok_open_id        VARCHAR(100) UNIQUE,
    ADD COLUMN display_name          VARCHAR(255),
    ADD COLUMN avatar_url            TEXT,
    ADD COLUMN tiktok_access_token   TEXT,
    ADD COLUMN tiktok_refresh_token  TEXT,
    ADD COLUMN token_expires_at      TIMESTAMP,
    ALTER COLUMN password_hash       DROP NOT NULL,
    ALTER COLUMN email               DROP NOT NULL;

CREATE INDEX idx_users_tiktok_open_id ON users(tiktok_open_id);
