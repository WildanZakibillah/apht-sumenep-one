-- ============================================================
-- APHT Sumenep One — Migration 021: Resolve Allocation ID Automatically Before Usage Log Insert
-- ============================================================

-- Create function to resolve allocation ID matching product specifications or fallback to general allocation
CREATE OR REPLACE FUNCTION public.resolve_cukai_usage_allocation()
RETURNS TRIGGER AS $$
DECLARE
  matching_alloc_id UUID;
  req_type VARCHAR(50);
  req_isi INT;
  req_hje NUMERIC;
  current_period VARCHAR(20);
BEGIN
  -- Determine current quarter period
  current_period := 'Q' || ((EXTRACT(MONTH FROM NEW.usage_date)::INT - 1) / 3 + 1) || '-' || EXTRACT(YEAR FROM NEW.usage_date)::INT;

  -- 1. Try to find allocation matching product specifications
  IF NEW.product_id IS NOT NULL THEN
    SELECT cigarette_type, sticks_per_pack, hje
    INTO req_type, req_isi, req_hje
    FROM public.cigarettes
    WHERE id = NEW.product_id;

    SELECT ca.id INTO matching_alloc_id
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
  END IF;

  -- 2. Fallback to general factory allocation (where product_id IS NULL)
  IF matching_alloc_id IS NULL THEN
    SELECT id INTO matching_alloc_id
    FROM public.cukai_allocations
    WHERE factory_id = NEW.factory_id
      AND period = current_period
      AND product_id IS NULL
    ORDER BY created_at DESC
    LIMIT 1;
  END IF;

  -- 3. If still not found, fallback to latest allocation for this factory
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

-- Create trigger BEFORE INSERT OR UPDATE
DROP TRIGGER IF EXISTS on_cukai_usage_resolve_allocation ON public.cukai_usage_log;
CREATE TRIGGER on_cukai_usage_resolve_allocation
  BEFORE INSERT OR UPDATE ON public.cukai_usage_log
  FOR EACH ROW EXECUTE FUNCTION public.resolve_cukai_usage_allocation();
