-- Cache Claude's video analysis per user (24hr TTL)
CREATE TABLE video_analysis_cache (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    analysis_json TEXT NOT NULL,
    analyzed_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    expires_at    TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX idx_video_analysis_user ON video_analysis_cache(user_id);
