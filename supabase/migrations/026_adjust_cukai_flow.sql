-- ============================================================
-- APHT Sumenep One — Migration 026: Adjust Cukai Flow (Plafond vs Physical Stock Batches)
-- ============================================================

-- 1. Redefine on_cukai_request_approved function
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
    
    -- Set quantity_remaining for the request itself (this represents the physical batch stock)
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
        -- Add to the USED column instead of the quota column! (consumes the allocation)
        UPDATE public.cukai_allocations
        SET used = used + lembar_count
        WHERE id = alloc_id;
      ELSE
        -- Fallback to general factory allocation (product_id is null) in current period
        SELECT id INTO alloc_id
        FROM public.cukai_allocations
        WHERE factory_id = NEW.factory_id
          AND period = current_period
          AND product_id IS NULL
        ORDER BY created_at DESC
        LIMIT 1;

        IF alloc_id IS NOT NULL THEN
          UPDATE public.cukai_allocations
          SET used = used + lembar_count
          WHERE id = alloc_id;
        ELSE
          -- Create a new allocation with quota = 0 and used = lembar_count if none exists
          INSERT INTO public.cukai_allocations (factory_id, product_id, quota, used, damaged, period)
          VALUES (
            NEW.factory_id,
            NEW.product_id,
            0,
            lembar_count,
            0,
            current_period
          );
        END IF;
      END IF;
    END IF;

  -- Revert if status is changed from approved back to pending/rejected
  ELSIF OLD.status = 'approved' AND NEW.status != 'approved' THEN
    lembar_count := COALESCE(OLD.jumlah_lembar, 0);

    UPDATE public.cukai_requests
    SET quantity_remaining = 0
    WHERE id = NEW.id;

    IF lembar_count > 0 THEN
      SELECT cigarette_type, sticks_per_pack, hje
      INTO req_type, req_isi, req_hje
      FROM public.cigarettes
      WHERE id = OLD.product_id;

      current_period := 'Q' || ((EXTRACT(MONTH FROM OLD.request_date)::INT - 1) / 3 + 1) || '-' || EXTRACT(YEAR FROM OLD.request_date)::INT;

      SELECT ca.id INTO alloc_id
      FROM public.cukai_allocations ca
      LEFT JOIN public.cigarettes cig ON ca.product_id = cig.id
      WHERE ca.factory_id = OLD.factory_id
        AND ca.period = current_period
        AND (
          ca.product_id = OLD.product_id
          OR (
            cig.cigarette_type = req_type
            AND cig.sticks_per_pack = req_isi
            AND cig.hje = req_hje
          )
        )
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


-- 2. Redefine update_cukai_on_usage function (stop updating 'used' column since it's already consumed when requested/approved)
CREATE OR REPLACE FUNCTION public.update_cukai_on_usage()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.cukai_allocations
    SET
      damaged = damaged + NEW.damaged_amount
    WHERE id = NEW.allocation_id;

  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.cukai_allocations
    SET
      damaged = GREATEST(0, damaged - OLD.damaged_amount)
    WHERE id = OLD.allocation_id;

  ELSIF TG_OP = 'UPDATE' THEN
    UPDATE public.cukai_allocations
    SET
      damaged = GREATEST(0, damaged - OLD.damaged_amount + NEW.damaged_amount)
    WHERE id = NEW.allocation_id;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
