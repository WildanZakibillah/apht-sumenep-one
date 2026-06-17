-- Migration 013: Extend brands table with description and status

-- 1. Add description and status columns to brands table
ALTER TABLE brands
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'inactive'));

-- 2. Populate some mock data for existing brands
UPDATE brands SET
  description = 'Rokok kretek tangan berkualitas premium',
  status = 'active'
WHERE name = 'DEN HAAG';

UPDATE brands SET
  description = 'Rokok kretek tangan rasa mantap',
  status = 'active'
WHERE name = 'Karaoke Merah';

UPDATE brands SET
  description = 'Rokok kretek tangan dengan filter isi 12 batang',
  status = 'active'
WHERE name = 'Karaoke Biru 12';
