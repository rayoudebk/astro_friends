-- ═══════════════════════════════════════════════════════════════════════════
-- ASTRO FRIENDS - SUPABASE SCHEMA
-- Run this in your Supabase SQL Editor (Database → SQL Editor)
-- GDPR Compliant: NO PII stored - only derived astrology data
-- ═══════════════════════════════════════════════════════════════════════════

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE: user_astro_profile
-- Stores derived natal chart data (no PII)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_astro_profile (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contact_id UUID NOT NULL UNIQUE,  -- Links to local Contact.id
    sun_sign TEXT NOT NULL,           -- e.g., "aries"
    moon_sign TEXT,                   -- e.g., "libra"
    rising_sign TEXT,                 -- e.g., "leo"
    element TEXT NOT NULL,            -- fire/earth/air/water
    modality TEXT NOT NULL,           -- cardinal/fixed/mutable
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_astro_profile_contact ON user_astro_profile(contact_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE: weekly_sky
-- Global weekly celestial context (moon phase, transits)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS weekly_sky (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    week_start DATE NOT NULL UNIQUE,  -- Monday of the week
    moon_phase TEXT NOT NULL,         -- e.g., "Waxing Gibbous"
    moon_sign TEXT,                   -- e.g., "scorpio"
    transits TEXT[],                  -- Array of transit descriptions
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_weekly_sky_week ON weekly_sky(week_start);

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE: oracle_content
-- AI-generated weekly readings per contact
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS oracle_content (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contact_id UUID NOT NULL,
    week_start DATE NOT NULL,
    weekly_reading TEXT NOT NULL,
    love_advice TEXT,
    career_advice TEXT,
    lucky_number INTEGER,
    lucky_color TEXT,
    mood TEXT,
    compatibility_sign TEXT,          -- Best match this week
    celestial_insight TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- One entry per contact per week
    UNIQUE(contact_id, week_start)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_oracle_contact ON oracle_content(contact_id);
CREATE INDEX IF NOT EXISTS idx_oracle_week ON oracle_content(week_start);

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE: compatibility_cache
-- AI-generated compatibility between two contacts
-- Now supports 3-layer model: Overall (static) + This Week (dynamic)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS compatibility_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contact_a UUID NOT NULL,
    contact_b UUID NOT NULL,
    
    -- Layer 1: Overall (static)
    base_score INTEGER NOT NULL,      -- From AstrologyAPI zodiac_compatibility
    synastry_highlights TEXT[],       -- Key aspects
    ai_output TEXT,                   -- Gemini-generated summary
    
    -- Layer 2: This Week (dynamic, AI-generated)
    this_week_score INTEGER,          -- Weekly adjusted score
    love_compatibility TEXT,          -- High/Medium/Low
    communication_compatibility TEXT, -- High/Medium/Low
    weekly_vibe TEXT,                 -- One word describing weekly energy
    weekly_reading TEXT,              -- AI-generated weekly reading
    growth_advice TEXT,               -- Weekly tip
    celestial_influence TEXT,         -- How current transits affect them
    
    week_start DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- One entry per pair
    UNIQUE(contact_a, contact_b)
);

-- Index
CREATE INDEX IF NOT EXISTS idx_compat_contacts ON compatibility_cache(contact_a, contact_b);

-- ─────────────────────────────────────────────────────────────────────────────
-- ROW LEVEL SECURITY (RLS)
-- Enable for production - currently open for development
-- ─────────────────────────────────────────────────────────────────────────────

-- Enable RLS on all tables
ALTER TABLE user_astro_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_sky ENABLE ROW LEVEL SECURITY;
ALTER TABLE oracle_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE compatibility_cache ENABLE ROW LEVEL SECURITY;

-- Allow anonymous access for development (adjust for production)
CREATE POLICY "Allow all for anon" ON user_astro_profile FOR ALL USING (true);
CREATE POLICY "Allow all for anon" ON weekly_sky FOR ALL USING (true);
CREATE POLICY "Allow all for anon" ON oracle_content FOR ALL USING (true);
CREATE POLICY "Allow all for anon" ON compatibility_cache FOR ALL USING (true);

-- ─────────────────────────────────────────────────────────────────────────────
-- HELPER FUNCTIONS
-- ─────────────────────────────────────────────────────────────────────────────

-- Function to get the start of the current week (Monday)
CREATE OR REPLACE FUNCTION get_week_start(d DATE DEFAULT CURRENT_DATE)
RETURNS DATE AS $$
BEGIN
    RETURN d - EXTRACT(DOW FROM d)::INTEGER + 1;
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════════
-- DONE! Your Supabase tables are ready.
-- ═══════════════════════════════════════════════════════════════════════════

