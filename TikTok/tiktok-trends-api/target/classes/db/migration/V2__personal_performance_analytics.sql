-- ─────────────────────────────────────────────────────────────
-- V2: Personal performance analytics
-- Tracks the authenticated user's own TikTok account KPIs
-- over time so we can compare against public trend benchmarks.
-- ─────────────────────────────────────────────────────────────

-- Weekly KPI snapshots for each user's own account
CREATE TABLE user_performance_snapshots (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id                 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Core counts (pulled from TikTok Research API for the user's account)
    total_views             BIGINT DEFAULT 0,
    total_likes             BIGINT DEFAULT 0,
    total_shares            BIGINT DEFAULT 0,
    total_comments          BIGINT DEFAULT 0,
    follower_count          BIGINT DEFAULT 0,
    video_count             INTEGER DEFAULT 0,

    -- Computed KPIs (calculated during ingestion)
    engagement_rate         FLOAT,   -- (likes + comments + shares) / views
    view_velocity           FLOAT,   -- % change in views vs previous snapshot
    follower_growth_rate    FLOAT,   -- % change in followers vs previous snapshot
    avg_watch_time_pct      FLOAT,   -- average watch time as % of video duration
    share_rate              FLOAT,   -- shares / views

    -- Period this snapshot covers
    period_start            TIMESTAMP NOT NULL,
    period_end              TIMESTAMP NOT NULL,
    recorded_at             TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Benchmark: aggregated KPI averages from public trends for the same period
-- Used to render the "your stats vs trend benchmark" comparison
CREATE TABLE trend_benchmarks (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    period_start        TIMESTAMP NOT NULL,
    period_end          TIMESTAMP NOT NULL,
    avg_engagement_rate FLOAT,
    avg_view_velocity   FLOAT,
    avg_share_rate      FLOAT,
    avg_follower_growth FLOAT,
    computed_at         TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (period_start, period_end)
);

-- KPI grades per snapshot (A/B/C/D/F vs benchmark)
-- Stored so frontend can render score card without recomputing
CREATE TABLE user_kpi_grades (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    snapshot_id             UUID NOT NULL REFERENCES user_performance_snapshots(id) ON DELETE CASCADE,
    benchmark_id            UUID NOT NULL REFERENCES trend_benchmarks(id),
    engagement_rate_grade   CHAR(1),   -- A/B/C/D/F
    view_velocity_grade     CHAR(1),
    follower_growth_grade   CHAR(1),
    watch_time_grade        CHAR(1),
    share_rate_grade        CHAR(1),
    overall_grade           CHAR(1),
    graded_at               TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_perf_snapshots_user_id      ON user_performance_snapshots(user_id);
CREATE INDEX idx_perf_snapshots_period_start ON user_performance_snapshots(period_start);
CREATE INDEX idx_benchmarks_period           ON trend_benchmarks(period_start, period_end);
CREATE INDEX idx_kpi_grades_snapshot         ON user_kpi_grades(snapshot_id);
