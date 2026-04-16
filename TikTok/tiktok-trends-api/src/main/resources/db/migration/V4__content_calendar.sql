-- Content calendar for iOS app
CREATE TABLE calendar_entries (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recommendation_id UUID REFERENCES recommendations(id) ON DELETE SET NULL,
    title             VARCHAR(255) NOT NULL,
    notes             TEXT,
    scheduled_at      TIMESTAMP NOT NULL,
    status            VARCHAR(20) NOT NULL DEFAULT 'draft'
                          CHECK (status IN ('draft', 'scheduled', 'posted')),
    created_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_calendar_entries_user_id      ON calendar_entries(user_id);
CREATE INDEX idx_calendar_entries_scheduled_at ON calendar_entries(scheduled_at);
CREATE INDEX idx_calendar_entries_user_month   ON calendar_entries(user_id, scheduled_at);
