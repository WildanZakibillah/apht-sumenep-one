-- ============================================================
-- APHT Sumenep One — Migration 017: Enhance Cukai Tracking Tables
-- ============================================================

-- 1. Add product_id and quantity_remaining columns to public.cukai_requests
ALTER TABLE public.cukai_requests
ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES public.cigarettes(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS quantity_remaining INT DEFAULT 0;

-- 2. Add product_id and cukai_request_id to public.cukai_usage_log
ALTER TABLE public.cukai_usage_log
ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES public.cigarettes(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS cukai_request_id UUID REFERENCES public.cukai_requests(id) ON DELETE SET NULL;

-- 3. Update existing approved requests to set quantity_remaining = jumlah_lembar
UPDATE public.cukai_requests
SET quantity_remaining = COALESCE(jumlah_lembar, 0)
WHERE status = 'approved' AND quantity_remaining IS NULL;

-- 4. Update cukai approval trigger to populate quantity_remaining on approval
CREATE OR REPLACE FUNCTION public.on_cukai_request_approved()
RETURNS TRIGGER AS $$
DECLARE
  alloc_id UUID;
  lembar_count INT;
BEGIN
  -- Only fire when status changes to 'approved'
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    lembar_count := COALESCE(NEW.jumlah_lembar, 0);
    
    -- Set quantity_remaining for the request itself
    UPDATE public.cukai_requests
    SET quantity_remaining = lembar_count
    WHERE id = NEW.id;
    
    IF lembar_count > 0 THEN
      -- Find the latest allocation for this factory
      SELECT id INTO alloc_id
      FROM public.cukai_allocations
      WHERE factory_id = NEW.factory_id
      ORDER BY created_at DESC
      LIMIT 1;

      IF alloc_id IS NOT NULL THEN
        -- Add the approved quantity to the quota
        UPDATE public.cukai_allocations
        SET quota = quota + lembar_count
        WHERE id = alloc_id;
      ELSE
        -- Create a new allocation if none exists
        INSERT INTO public.cukai_allocations (factory_id, quota, used, damaged, period)
        VALUES (
          NEW.factory_id,
          lembar_count,
          0,
          0,
          'Q' || ((EXTRACT(MONTH FROM CURRENT_DATE)::INT - 1) / 3 + 1) || '-' || EXTRACT(YEAR FROM CURRENT_DATE)::INT
        );
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Create trigger to update stok pita cukai and finished stock on pemakaian (usage insert/update/delete)
CREATE OR REPLACE FUNCTION public.update_stok_on_cukai_usage()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Deduct remaining excise stamp sheets
    IF NEW.cukai_request_id IS NOT NULL THEN
      UPDATE public.cukai_requests
      SET quantity_remaining = GREATEST(0, quantity_remaining - NEW.used_amount)
      WHERE id = NEW.cukai_request_id;
    END IF;

    -- Add to finished stock (in packs / bungkus)
    IF NEW.product_id IS NOT NULL THEN
      UPDATE public.cigarettes
      SET stock = stock + NEW.used_amount
      WHERE id = NEW.product_id;
    END IF;

  ELSIF TG_OP = 'DELETE' THEN
    -- Revert remaining excise stamp sheets
    IF OLD.cukai_request_id IS NOT NULL THEN
      UPDATE public.cukai_requests
      SET quantity_remaining = quantity_remaining + OLD.used_amount
      WHERE id = OLD.cukai_request_id;
    END IF;

    -- Revert finished stock
    IF OLD.product_id IS NOT NULL THEN
      UPDATE public.cigarettes
      SET stock = GREATEST(0, stock - OLD.used_amount)
      WHERE id = OLD.product_id;
    END IF;

  ELSIF TG_OP = 'UPDATE' THEN
    -- Revert old usage
    IF OLD.cukai_request_id IS NOT NULL THEN
      UPDATE public.cukai_requests
      SET quantity_remaining = quantity_remaining + OLD.used_amount
      WHERE id = OLD.cukai_request_id;
    END IF;
    IF OLD.product_id IS NOT NULL THEN
      UPDATE public.cigarettes
      SET stock = GREATEST(0, stock - OLD.used_amount)
      WHERE id = OLD.product_id;
    END IF;

    -- Apply new usage
    IF NEW.cukai_request_id IS NOT NULL THEN
      UPDATE public.cukai_requests
      SET quantity_remaining = GREATEST(0, quantity_remaining - NEW.used_amount)
      WHERE id = NEW.cukai_request_id;
    END IF;
    IF NEW.product_id IS NOT NULL THEN
      UPDATE public.cigarettes
      SET stock = stock + NEW.used_amount
      WHERE id = NEW.product_id;
    END IF;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Trigger for public.cukai_usage_log stock updates
DROP TRIGGER IF EXISTS on_cukai_usage_stok_update ON public.cukai_usage_log;
CREATE TRIGGER on_cukai_usage_stok_update
  AFTER INSERT OR UPDATE OR DELETE ON public.cukai_usage_log
  FOR EACH ROW EXECUTE FUNCTION public.update_stok_on_cukai_usage();

-- 7. Disable production stock trigger to prevent double counting since finished stock is now increased when applying excise stamps
DROP TRIGGER IF EXISTS on_production_stock_update ON public.productions;
