-- Migration 016: Drop factory code column
-- Remove the 'code' column since factories are now identified solely by NPPBKC or name/ID.

ALTER TABLE factories DROP COLUMN IF EXISTS code;
