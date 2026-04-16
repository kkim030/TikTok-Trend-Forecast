-- Music preview URLs for iOS music playback feature
ALTER TABLE trends
    ADD COLUMN IF NOT EXISTS music_preview_url   TEXT,
    ADD COLUMN IF NOT EXISTS music_artist        VARCHAR(255),
    ADD COLUMN IF NOT EXISTS music_cover_art_url TEXT;
