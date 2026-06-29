-- ============================================================
-- APHT Sumenep One — Migration 027: Master Kategori Cukai
-- ============================================================

-- 1. Create Kategori Cukai Master Table
CREATE TABLE IF NOT EXISTS public.cukai_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  jenis_ht TEXT NOT NULL,
  isi_per_bungkus INT NOT NULL,
  golongan TEXT,
  hje NUMERIC(12,2) NOT NULL,
  tarif_cukai NUMERIC(12,2) NOT NULL,
  is_shared BOOLEAN NOT NULL DEFAULT true,
  keterangan TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.cukai_categories IS 'Master data for excise stamp categories and specifications';

-- Enable RLS
ALTER TABLE public.cukai_categories ENABLE ROW LEVEL SECURITY;

-- Select policy: All authenticated users can read categories
CREATE POLICY "cukai_categories_select" ON public.cukai_categories
  FOR SELECT TO authenticated USING (true);

-- Manage policy: Super admin only can write/edit/delete
CREATE POLICY "cukai_categories_manage_super_admin" ON public.cukai_categories
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'super_admin'
    )
  );

-- 2. Alter existing tables to add relations to Kategori Cukai
ALTER TABLE public.cigarettes
  ADD COLUMN IF NOT EXISTS cukai_category_id UUID REFERENCES public.cukai_categories(id) ON DELETE SET NULL;

ALTER TABLE public.cukai_allocations
  ADD COLUMN IF NOT EXISTS cukai_category_id UUID REFERENCES public.cukai_categories(id) ON DELETE SET NULL;

ALTER TABLE public.cukai_requests
  ADD COLUMN IF NOT EXISTS cukai_category_id UUID REFERENCES public.cukai_categories(id) ON DELETE SET NULL;

-- 3. Seed initial categories from existing product specifications
INSERT INTO public.cukai_categories (name, jenis_ht, isi_per_bungkus, golongan, hje, tarif_cukai, is_shared, keterangan)
SELECT DISTINCT 
  COALESCE(cig.cigarette_type, 'SKM') || ' ' || COALESCE(cig.sticks_per_pack, 12)::TEXT || ' HJE ' || COALESCE(cig.hje, 0)::TEXT,
  COALESCE(cig.cigarette_type, 'SKM'),
  COALESCE(cig.sticks_per_pack, 12),
  'II',
  COALESCE(cig.hje, 0),
  COALESCE(cig.excise_rate, 0),
  true,
  'Auto-generated from existing product specifications'
FROM public.cigarettes cig
ON CONFLICT DO NOTHING;

-- 4. Associate existing cigarettes with the auto-generated categories
UPDATE public.cigarettes cig
SET cukai_category_id = cat.id
FROM public.cukai_categories cat
WHERE cat.jenis_ht = COALESCE(cig.cigarette_type, 'SKM')
  AND cat.isi_per_bungkus = COALESCE(cig.sticks_per_pack, 12)
  AND cat.hje = COALESCE(cig.hje, 0)
  AND cat.tarif_cukai = COALESCE(cig.excise_rate, 0);

-- 5. Associate existing allocations and requests with Kategori Cukai based on product links
UPDATE public.cukai_allocations ca
SET cukai_category_id = cig.cukai_category_id
FROM public.cigarettes cig
WHERE ca.product_id = cig.id;

UPDATE public.cukai_requests cr
SET cukai_category_id = cig.cukai_category_id
FROM public.cigarettes cig
WHERE cr.product_id = cig.id;

-- 6. Redefine trigger function on_cukai_request_approved to work with cukai_category_id
CREATE OR REPLACE FUNCTION public.on_cukai_request_approved()
RETURNS TRIGGER AS $$
DECLARE
  alloc_id UUID;
  lembar_count INT;
  current_period VARCHAR(20);
BEGIN
  -- Only fire when status changes to 'approved'
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    lembar_count := COALESCE(NEW.jumlah_lembar, 0);
    
    -- Set quantity_remaining for the request itself (this represents the physical batch stock)
    UPDATE public.cukai_requests
    SET quantity_remaining = lembar_count
    WHERE id = NEW.id;
    
    IF lembar_count > 0 AND NEW.cukai_category_id IS NOT NULL THEN
      -- Determine current quarter period
      current_period := 'Q' || ((EXTRACT(MONTH FROM CURRENT_DATE)::INT - 1) / 3 + 1) || '-' || EXTRACT(YEAR FROM CURRENT_DATE)::INT;

      -- Find matching allocation in current period for this factory and category:
      SELECT ca.id INTO alloc_id
      FROM public.cukai_allocations ca
      WHERE ca.factory_id = NEW.factory_id
        AND ca.cukai_category_id = NEW.cukai_category_id
        AND ca.period = current_period
      ORDER BY ca.created_at DESC
      LIMIT 1;

      IF alloc_id IS NOT NULL THEN
        -- Add to the USED column (consumes the allocation)
        UPDATE public.cukai_allocations
        SET used = used + lembar_count
        WHERE id = alloc_id;
      ELSE
        -- Create a new allocation for this category if none exists
        INSERT INTO public.cukai_allocations (factory_id, cukai_category_id, quota, used, damaged, period)
        VALUES (
          NEW.factory_id,
          NEW.cukai_category_id,
          0,
          lembar_count,
          0,
          current_period
        );
      END IF;
    END IF;

  -- Revert if status is changed from approved back to pending/rejected
  ELSIF OLD.status = 'approved' AND NEW.status != 'approved' THEN
    lembar_count := COALESCE(OLD.jumlah_lembar, 0);

    UPDATE public.cukai_requests
    SET quantity_remaining = 0
    WHERE id = NEW.id;

    IF lembar_count > 0 AND OLD.cukai_category_id IS NOT NULL THEN
      current_period := 'Q' || ((EXTRACT(MONTH FROM OLD.request_date)::INT - 1) / 3 + 1) || '-' || EXTRACT(YEAR FROM OLD.request_date)::INT;

      SELECT ca.id INTO alloc_id
      FROM public.cukai_allocations ca
      WHERE ca.factory_id = OLD.factory_id
        AND ca.cukai_category_id = OLD.cukai_category_id
        AND ca.period = current_period
      ORDER BY ca.created_at DESC
      LIMIT 1;

      IF alloc_id IS NOT NULL THEN
        UPDATE public.cukai_allocations
        SET used = GREATEST(0, used - lembar_count)
        WHERE id = alloc_id;
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Redefine trigger function resolve_cukai_usage_allocation
CREATE OR REPLACE FUNCTION public.resolve_cukai_usage_allocation()
RETURNS TRIGGER AS $$
DECLARE
  matching_alloc_id UUID;
  prod_cat_id UUID;
  current_period VARCHAR(20);
BEGIN
  -- Determine current quarter period
  current_period := 'Q' || ((EXTRACT(MONTH FROM NEW.usage_date)::INT - 1) / 3 + 1) || '-' || EXTRACT(YEAR FROM NEW.usage_date)::INT;

  -- Get category of the product
  IF NEW.product_id IS NOT NULL THEN
    SELECT cukai_category_id INTO prod_cat_id
    FROM public.cigarettes
    WHERE id = NEW.product_id;
  END IF;

  -- 1. Try to find allocation matching the category
  IF prod_cat_id IS NOT NULL THEN
    SELECT ca.id INTO matching_alloc_id
    FROM public.cukai_allocations ca
    WHERE ca.factory_id = NEW.factory_id
      AND ca.cukai_category_id = prod_cat_id
      AND ca.period = current_period
    ORDER BY ca.created_at DESC
    LIMIT 1;
  END IF;

  -- 2. Fallback to any allocation for this factory in current period
  IF matching_alloc_id IS NULL THEN
    SELECT id INTO matching_alloc_id
    FROM public.cukai_allocations
    WHERE factory_id = NEW.factory_id
      AND period = current_period
    ORDER BY created_at DESC
    LIMIT 1;
  END IF;

  -- 3. Fallback to latest allocation
  IF matching_alloc_id IS NULL THEN
    SELECT id INTO matching_alloc_id
    FROM public.cukai_allocations
    WHERE factory_id = NEW.factory_id
    ORDER BY created_at DESC
    LIMIT 1;
  END IF;

  -- Assign resolved allocation_id
  IF matching_alloc_id IS NOT NULL THEN
    NEW.allocation_id := matching_alloc_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
