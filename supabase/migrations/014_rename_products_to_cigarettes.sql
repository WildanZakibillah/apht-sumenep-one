-- ============================================================
-- APHT Sumenep One — Migration 014: Rename products to cigarettes
-- ============================================================

-- Rename products table to cigarettes if it exists
ALTER TABLE IF EXISTS public.products RENAME TO cigarettes;

-- Rename column isi to sticks_per_pack if it exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'cigarettes' 
      AND column_name = 'isi'
  ) THEN
    ALTER TABLE public.cigarettes RENAME COLUMN isi TO sticks_per_pack;
  END IF;
END $$;

-- Add new spec columns if they don't exist
ALTER TABLE public.cigarettes 
  ADD COLUMN IF NOT EXISTS product_name TEXT,
  ADD COLUMN IF NOT EXISTS product_code TEXT,
  ADD COLUMN IF NOT EXISTS cigarette_type TEXT CHECK (cigarette_type IN ('SKT', 'SKM', 'SPM')),
  ADD COLUMN IF NOT EXISTS variant TEXT,
  ADD COLUMN IF NOT EXISTS packs_per_slop INT DEFAULT 10,
  ADD COLUMN IF NOT EXISTS slops_per_carton INT DEFAULT 20,
  ADD COLUMN IF NOT EXISTS excise_rate NUMERIC(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS stock INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS product_image TEXT,
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive'));

-- Pre-fill product_name and cigarette_type for existing records (where they are null)
UPDATE public.cigarettes c
SET 
  product_name = b.name,
  cigarette_type = pt.category
FROM public.brands b
JOIN public.product_types pt ON b.product_type_id = pt.id
WHERE c.brand_id = b.id AND (c.product_name IS NULL OR c.cigarette_type IS NULL);

-- Make product_name NOT NULL for future entries
ALTER TABLE public.cigarettes ALTER COLUMN product_name SET NOT NULL;

-- Enable RLS on cigarettes (should be enabled already by rename, but let's be explicit)
ALTER TABLE public.cigarettes ENABLE ROW LEVEL SECURITY;

-- Drop old policies on cigarettes
DROP POLICY IF EXISTS "Authenticated users can view products" ON public.cigarettes;
DROP POLICY IF EXISTS "Factory users can manage own products" ON public.cigarettes;
DROP POLICY IF EXISTS "products_select" ON public.cigarettes;
DROP POLICY IF EXISTS "products_insert" ON public.cigarettes;
DROP POLICY IF EXISTS "products_update" ON public.cigarettes;
DROP POLICY IF EXISTS "products_delete" ON public.cigarettes;

-- Create clean policies for cigarettes
CREATE POLICY "Authenticated users can view cigarettes"
  ON public.cigarettes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Factory users can manage own cigarettes"
  ON public.cigarettes FOR ALL
  USING (
    factory_id = public.user_factory_id()
    OR public.is_super_admin()
  );
