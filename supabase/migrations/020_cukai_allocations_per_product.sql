-- ============================================================
-- APHT Sumenep One — Migration 020: Excise Allocations Per Product/Specification
-- ============================================================

-- 1. Add product_id to cukai_allocations
ALTER TABLE public.cukai_allocations
  ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES public.cigarettes(id) ON DELETE SET NULL;

-- 2. Update on_cukai_request_approved function to handle per-product/specification allocations
CREATE OR REPLACE FUNCTION public.on_cukai_request_approved()
RETURNS TRIGGER AS $$
DECLARE
  alloc_id UUID;
  lembar_count INT;
  req_type VARCHAR(50);
  req_isi INT;
  req_hje NUMERIC;
  current_period VARCHAR(20);
BEGIN
  -- Only fire when status changes to 'approved'
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    lembar_count := COALESCE(NEW.jumlah_lembar, 0);
    
    -- Set quantity_remaining for the request itself
    UPDATE public.cukai_requests
    SET quantity_remaining = lembar_count
    WHERE id = NEW.id;
    
    IF lembar_count > 0 THEN
      -- Get specifications of the product associated with this request
      SELECT cigarette_type, sticks_per_pack, hje
      INTO req_type, req_isi, req_hje
      FROM public.cigarettes
      WHERE id = NEW.product_id;

      -- Determine current quarter period
      current_period := 'Q' || ((EXTRACT(MONTH FROM CURRENT_DATE)::INT - 1) / 3 + 1) || '-' || EXTRACT(YEAR FROM CURRENT_DATE)::INT;

      -- Find matching allocation in current period for this factory:
      -- Either matches the product_id directly, OR matches its specifications (cigarette_type, sticks_per_pack, hje)
      SELECT ca.id INTO alloc_id
      FROM public.cukai_allocations ca
      LEFT JOIN public.cigarettes cig ON ca.product_id = cig.id
      WHERE ca.factory_id = NEW.factory_id
        AND ca.period = current_period
        AND (
          ca.product_id = NEW.product_id
          OR (
            cig.cigarette_type = req_type
            AND cig.sticks_per_pack = req_isi
            AND cig.hje = req_hje
          )
        )
      ORDER BY ca.created_at DESC
      LIMIT 1;

      IF alloc_id IS NOT NULL THEN
        -- Add the approved quantity to the quota of the matching allocation
        UPDATE public.cukai_allocations
        SET quota = quota + lembar_count
        WHERE id = alloc_id;
      ELSE
        -- Create a new allocation for this product/specification if none exists
        INSERT INTO public.cukai_allocations (factory_id, product_id, quota, used, damaged, period)
        VALUES (
          NEW.factory_id,
          NEW.product_id,
          lembar_count,
          0,
          0,
          current_period
        );
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
