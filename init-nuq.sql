CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE SCHEMA IF NOT EXISTS nuq;

-- Job status enum
DO $$ BEGIN
    CREATE TYPE nuq.job_status AS ENUM ('queued', 'active', 'completed', 'failed', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Main crawl group table
CREATE TABLE IF NOT EXISTS nuq.group_crawl (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT,
    owner_id TEXT,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW(),
    finished_at TIMESTAMP DEFAULT NULL,
    expires_at TIMESTAMP DEFAULT NULL,
    ttl INTEGER DEFAULT NULL,
    options JSONB DEFAULT NULL,
    scrape_options JSONB DEFAULT NULL,
    internal_options JSONB DEFAULT NULL,
    total_count INTEGER DEFAULT 0,
    completed_count INTEGER DEFAULT 0,
    credits_used INTEGER DEFAULT 0
);

-- Queue item table
CREATE TABLE IF NOT EXISTS nuq.queue_item (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id uuid REFERENCES nuq.group_crawl(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    status nuq.job_status DEFAULT 'queued',
    priority INTEGER DEFAULT 0,
    data JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    finished_at TIMESTAMP DEFAULT NULL,
    listen_channel_id TEXT,
    returnvalue JSONB,
    failedreason TEXT,
    lock uuid,
    locked_at TIMESTAMP DEFAULT NULL,
    owner_id TEXT
);

-- Queue scrape table
CREATE TABLE IF NOT EXISTS nuq.queue_scrape (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id uuid REFERENCES nuq.group_crawl(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    status nuq.job_status DEFAULT 'queued',
    priority INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    times_out_at TIMESTAMP DEFAULT NULL,
    owner_id TEXT,
    data JSONB,
    finished_at TIMESTAMP DEFAULT NULL,
    returnvalue JSONB,
    failedreason TEXT,
    lock uuid,
    locked_at TIMESTAMP DEFAULT NULL,
    listen_channel_id TEXT
);

-- Backlog table
CREATE TABLE IF NOT EXISTS nuq.queue_scrape_backlog (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id uuid REFERENCES nuq.group_crawl(id) ON DELETE CASCADE,
    owner_id TEXT,
    url TEXT NOT NULL,
    status nuq.job_status DEFAULT 'queued',
    priority INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    data JSONB
);

-- Concurrency tracking
CREATE TABLE IF NOT EXISTS nuq.queue_scrape_group_concurrency (
    group_id uuid PRIMARY KEY REFERENCES nuq.group_crawl(id) ON DELETE CASCADE,
    current_concurrency INTEGER DEFAULT 0
);

-- Finished crawl results table (required by nuq-prefetch-worker)
CREATE TABLE IF NOT EXISTS nuq.queue_crawl_finished (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id uuid REFERENCES nuq.group_crawl(id) ON DELETE CASCADE,
    url TEXT,
    status nuq.job_status DEFAULT 'queued',
    priority INTEGER DEFAULT 0,
    data JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    finished_at TIMESTAMP DEFAULT NULL,
    listen_channel_id TEXT,
    returnvalue JSONB,
    failedreason TEXT,
    lock uuid,
    locked_at TIMESTAMP DEFAULT NULL,
    owner_id TEXT
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_queue_item_status ON nuq.queue_item(status);
CREATE INDEX IF NOT EXISTS idx_queue_item_priority ON nuq.queue_item(priority ASC, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_queue_scrape_status ON nuq.queue_scrape(status);
CREATE INDEX IF NOT EXISTS idx_queue_scrape_priority ON nuq.queue_scrape(priority ASC, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_queue_scrape_backlog_status ON nuq.queue_scrape_backlog(status);
CREATE INDEX IF NOT EXISTS idx_queue_crawl_finished_group ON nuq.queue_crawl_finished(group_id);
CREATE INDEX IF NOT EXISTS idx_queue_crawl_finished_status ON nuq.queue_crawl_finished(status);
CREATE INDEX IF NOT EXISTS idx_queue_crawl_finished_priority ON nuq.queue_crawl_finished(priority ASC, created_at ASC);
