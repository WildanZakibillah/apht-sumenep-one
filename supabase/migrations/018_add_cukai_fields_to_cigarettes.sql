-- ============================================================
-- APHT Sumenep One — Migration 018: Add Cukai Fields to Cigarettes
-- ============================================================

-- Add excise columns to the cigarettes table
ALTER TABLE public.cigarettes
  ADD COLUMN IF NOT EXISTS kode_personalisasi TEXT,
  ADD COLUMN IF NOT EXISTS seri TEXT,
  ADD COLUMN IF NOT EXISTS warna TEXT;
