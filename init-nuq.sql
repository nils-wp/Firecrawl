CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE SCHEMA IF NOT EXISTS nuq;

CREATE TABLE IF NOT EXISTS nuq.group_crawl (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT, owner_id TEXT, status TEXT DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW(),
    finished_at TIMESTAMP DEFAULT NULL,
    expires_at TIMESTAMP DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS nuq.queue_item (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id uuid REFERENCES nuq.group_crawl(id) ON DELETE CASCADE,
    url TEXT NOT NULL, status TEXT DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS nuq.queue_scrape (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id uuid REFERENCES nuq.group_crawl(id) ON DELETE CASCADE,
    url TEXT NOT NULL, status TEXT DEFAULT 'pending',
    priority INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    times_out_at TIMESTAMP DEFAULT NULL,
    owner_id TEXT, data JSONB,
    finished_at TIMESTAMP DEFAULT NULL,
    returnvalue JSONB, failedreason TEXT,
    lock uuid, locked_at TIMESTAMP DEFAULT NULL,
    listen_channel_id TEXT
);

CREATE TABLE IF NOT EXISTS nuq.queue_scrape_backlog (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id uuid REFERENCES nuq.group_crawl(id) ON DELETE CASCADE,
    owner_id TEXT, url TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    priority INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    data JSONB
);

CREATE TABLE IF NOT EXISTS nuq.queue_scrape_group_concurrency (
    group_id uuid PRIMARY KEY REFERENCES nuq.group_crawl(id) ON DELETE CASCADE,
    current_concurrency INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_queue_scrape_status ON nuq.queue_scrape(status);
CREATE INDEX IF NOT EXISTS idx_queue_scrape_priority ON nuq.queue_scrape(priority ASC, created_at ASC);
