-- =============================================================================
-- FIX: Activate/Create Speed Arena for Speed Match game
-- Run this in your Supabase SQL Editor
-- =============================================================================

-- First, check if a speed arena already exists and activate it
UPDATE arenas
SET is_active = TRUE,
    name = 'Speed Match',
    slug = 'speed-match',
    description = 'Match the symbol pattern as fast as you can',
    supports_dual = TRUE,
    time_limit_sec = 60
WHERE domain_id = (SELECT id FROM domains WHERE key = 'speed')
  AND slug = 'tap-flash';

-- If no speed arena exists at all, create one
INSERT INTO arenas (domain_id, name, slug, description, is_active, supports_dual, time_limit_sec)
SELECT d.id, 'Speed Match', 'speed-match', 'Match the symbol pattern as fast as you can', TRUE, TRUE, 60
FROM domains d
WHERE d.key = 'speed'
  AND NOT EXISTS (
    SELECT 1 FROM arenas a WHERE a.domain_id = d.id AND a.is_active = TRUE
  )
ON CONFLICT (slug) DO UPDATE SET is_active = TRUE;

-- Verify the arena is now active
SELECT a.id, a.name, a.slug, a.is_active, d.key as domain_key
FROM arenas a
JOIN domains d ON d.id = a.domain_id
WHERE d.key = 'speed';
