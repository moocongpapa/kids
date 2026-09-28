-- Separate Render Postgres database. No child profiles or usage records here.
CREATE TABLE IF NOT EXISTS content_blocks (
  content_id TEXT PRIMARY KEY,
  reason TEXT NOT NULL,
  disabled_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS content_blocks_disabled_at_idx
  ON content_blocks (disabled_at DESC);
