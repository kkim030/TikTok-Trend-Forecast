-- ─────────────────────────────────────────────────────────────
-- V1: Core schema
-- ─────────────────────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users (TikTok influencers)
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tiktok_handle   VARCHAR(100) NOT NULL UNIQUE,
    email           VARCHAR(255) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    niche           VARCHAR(100),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Public TikTok videos ingested from Research API
CREATE TABLE videos (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tiktok_video_id  VARCHAR(100) NOT NULL UNIQUE,
    author_handle    VARCHAR(100),
    title            TEXT,
    music_title      VARCHAR(255),
    music_artist     VARCHAR(255),
    hashtags         TEXT[],
    content_category VARCHAR(100),
    duration_seconds INTEGER,
    published_at     TIMESTAMP,
    ingested_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Snapshots of video performance metrics (taken each ingestion run)
CREATE TABLE video_metrics (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    video_id        UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    views           BIGINT DEFAULT 0,
    likes           BIGINT DEFAULT 0,
    shares          BIGINT DEFAULT 0,
    comments        BIGINT DEFAULT 0,
    engagement_rate FLOAT,    -- (likes + comments + shares) / views
    share_rate      FLOAT,    -- shares / views
    recorded_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Aggregated public trend signals
CREATE TABLE trends (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trend_type      VARCHAR(50) NOT NULL,  -- 'hashtag', 'music', 'content_category'
    keyword         VARCHAR(255) NOT NULL,
    velocity_score  FLOAT,    -- week-over-week growth rate
    engagement_avg  FLOAT,
    view_count_avg  BIGINT,
    detected_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMP,
    UNIQUE (trend_type, keyword)
);

-- AI-generated video recommendations per user
CREATE TABLE recommendations (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trend_id            UUID REFERENCES trends(id),
    concept_title       TEXT,
    concept_description TEXT,
    suggested_music     VARCHAR(255),
    suggested_hashtags  TEXT[],
    confidence_score    FLOAT,
    generated_at        TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_video_metrics_video_id     ON video_metrics(video_id);
CREATE INDEX idx_video_metrics_recorded_at  ON video_metrics(recorded_at);
CREATE INDEX idx_trends_type                ON trends(trend_type);
CREATE INDEX idx_trends_velocity            ON trends(velocity_score DESC);
CREATE INDEX idx_recommendations_user_id    ON recommendations(user_id);
