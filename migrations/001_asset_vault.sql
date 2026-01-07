-- ASSET VAULT MIGRATION
-- Extends existing Supabase project: ylcepmvbjjnwmzvevxid
-- Run in Supabase SQL Editor: https://supabase.com/dashboard/project/ylcepmvbjjnwmzvevxid/sql

-- Asset Projects
CREATE TABLE IF NOT EXISTS asset_projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    style_guide JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Characters for asset generation (tiered system)
CREATE TABLE IF NOT EXISTS asset_characters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES asset_projects(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    tier TEXT CHECK (tier IN ('hero', 'supporting', 'chorus')) NOT NULL DEFAULT 'supporting',
    description TEXT,
    visual_traits JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reference images uploaded by user
CREATE TABLE IF NOT EXISTS reference_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID REFERENCES asset_characters(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    public_url TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Generated assets from FAL.ai
CREATE TABLE IF NOT EXISTS generated_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID REFERENCES asset_characters(id) ON DELETE CASCADE,
    reference_image_id UUID REFERENCES reference_images(id),
    prompt TEXT NOT NULL,
    fal_model TEXT NOT NULL,
    fal_seed INTEGER,
    storage_path TEXT,
    public_url TEXT,
    generation_params JSONB DEFAULT '{}',
    status TEXT CHECK (status IN ('pending', 'processing', 'completed', 'failed')) DEFAULT 'pending',
    qc_status TEXT CHECK (qc_status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    qc_notes TEXT,
    cost_estimate DECIMAL(10,6),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Generation jobs (queue for UI + API triggers)
CREATE TABLE IF NOT EXISTS generation_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_id TEXT,
    source TEXT NOT NULL DEFAULT 'ui',
    callback_url TEXT,
    callback_headers JSONB DEFAULT '{}',
    payload JSONB NOT NULL,
    status TEXT CHECK (status IN ('queued', 'processing', 'completed', 'failed')) DEFAULT 'queued',
    result JSONB,
    error TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

-- Backgrounds
CREATE TABLE IF NOT EXISTS asset_backgrounds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES asset_projects(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT,
    prompt TEXT NOT NULL,
    storage_path TEXT,
    public_url TEXT,
    status TEXT CHECK (status IN ('pending', 'processing', 'completed', 'failed')) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_asset_chars_project ON asset_characters(project_id);
CREATE INDEX IF NOT EXISTS idx_asset_chars_tier ON asset_characters(tier);
CREATE INDEX IF NOT EXISTS idx_gen_assets_character ON generated_assets(character_id);
CREATE INDEX IF NOT EXISTS idx_gen_assets_status ON generated_assets(status);
CREATE INDEX IF NOT EXISTS idx_gen_assets_qc ON generated_assets(qc_status);
CREATE INDEX IF NOT EXISTS idx_gen_jobs_status ON generation_jobs(status);
CREATE INDEX IF NOT EXISTS idx_gen_jobs_source ON generation_jobs(source);
CREATE INDEX IF NOT EXISTS idx_gen_jobs_external ON generation_jobs(external_id);
CREATE INDEX IF NOT EXISTS idx_backgrounds_project ON asset_backgrounds(project_id);