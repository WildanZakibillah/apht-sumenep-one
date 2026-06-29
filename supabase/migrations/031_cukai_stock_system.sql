-- Migration 031: Cukai Direct Stock and Carry-Over system

-- 1. Add new columns to cukai_allocations table
ALTER TABLE public.cukai_allocations
ADD COLUMN IF NOT EXISTS monthly_quota INT NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS carry_over INT NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS additions INT NOT NULL DEFAULT 0;

-- 2. Add current_stock generated column
ALTER TABLE public.cukai_allocations
ADD COLUMN IF NOT EXISTS current_stock INT GENERATED ALWAYS AS (quota - used - damaged) STORED;

-- 3. Create or replace monthly allocation builder helper function
CREATE OR REPLACE FUNCTION public.get_or_create_monthly_allocation(
  p_factory_id UUID,
  p_cukai_category_id UUID,
  p_date DATE
)
RETURNS UUID AS $$
DECLARE
  v_period TEXT;
  v_alloc_id UUID;
  v_prev_period TEXT;
  v_prev_stock INT := 0;
  v_monthly_quota INT := 50000; -- Default fallback quota
  v_prev_alloc_id UUID;
BEGIN
  -- Format target period as YYYY-MM
  v_period := to_char(p_date, 'YYYY-MM');

  -- Check if allocation already exists for this period
  SELECT id INTO v_alloc_id
  FROM public.cukai_allocations
  WHERE factory_id = p_factory_id
    AND cukai_category_id = p_cukai_category_id
    AND period = v_period;

  IF v_alloc_id IS NOT NULL THEN
    RETURN v_alloc_id;
  END IF;

  -- Find the previous month's allocation
  v_prev_period := to_char(p_date - INTERVAL '1 month', 'YYYY-MM');

  SELECT id, current_stock, monthly_quota INTO v_prev_alloc_id, v_prev_stock, v_monthly_quota
  FROM public.cukai_allocations
  WHERE factory_id = p_factory_id
    AND cukai_category_id = p_cukai_category_id
    AND period = v_prev_period
  ORDER BY created_at DESC
  LIMIT 1;

  -- Fallback to latest available allocation if no previous month's row exists
  IF v_prev_alloc_id IS NULL THEN
    SELECT monthly_quota INTO v_monthly_quota
    FROM public.cukai_allocations
    WHERE factory_id = p_factory_id
      AND cukai_category_id = p_cukai_category_id
    ORDER BY period DESC
    LIMIT 1;
  END IF;

  -- Default fallback if still null
  v_monthly_quota := COALESCE(v_monthly_quota, 50000);
  v_prev_stock := COALESCE(v_prev_stock, 0);

  -- Create a new monthly allocation
  INSERT INTO public.cukai_allocations (
    factory_id,
    cukai_category_id,
    period,
    monthly_quota,
    carry_over,
    quota,
    used,
    damaged,
    additions
  ) VALUES (
    p_factory_id,
    p_cukai_category_id,
    v_period,
    v_monthly_quota,
    v_prev_stock,
    v_monthly_quota + v_prev_stock,
    0,
    0,
    0
  )
  RETURNING id INTO v_alloc_id;

  RETURN v_alloc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Redefine trigger function resolve_cukai_usage_allocation
CREATE OR REPLACE FUNCTION public.resolve_cukai_usage_allocation()
RETURNS TRIGGER AS $$
DECLARE
  matching_alloc_id UUID;
  prod_cat_id UUID;
BEGIN
  -- Get category of the product
  IF NEW.product_id IS NOT NULL THEN
    SELECT cukai_category_id INTO prod_cat_id
    FROM public.cigarettes
    WHERE id = NEW.product_id;
  END IF;

  IF prod_cat_id IS NOT NULL THEN
    matching_alloc_id := public.get_or_create_monthly_allocation(
      NEW.factory_id,
      prod_cat_id,
      NEW.usage_date
    );
  END IF;

  -- Assign resolved allocation_id
  IF matching_alloc_id IS NOT NULL THEN
    NEW.allocation_id := matching_alloc_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Redefine trigger function on_cukai_request_approved
CREATE OR REPLACE FUNCTION public.on_cukai_request_approved()
RETURNS TRIGGER AS $$
DECLARE
  lembar_count INT;
  alloc_id UUID;
BEGIN
  -- Only fire when status changes to 'approved'
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    lembar_count := COALESCE(NEW.jumlah_lembar, 0);
    
    -- Set quantity_remaining for the request itself
    UPDATE public.cukai_requests
    SET quantity_remaining = lembar_count
    WHERE id = NEW.id;
    
    IF lembar_count > 0 AND NEW.cukai_category_id IS NOT NULL THEN
      -- Get or create monthly allocation matching request date
      alloc_id := public.get_or_create_monthly_allocation(
        NEW.factory_id,
        NEW.cukai_category_id,
        NEW.request_date
      );

      IF alloc_id IS NOT NULL THEN
        -- Add to additions and quota (which automatically increases current_stock)
        UPDATE public.cukai_allocations
        SET additions = additions + lembar_count,
            quota = quota + lembar_count
        WHERE id = alloc_id;
      END IF;
    END IF;

  -- Revert if status is changed from approved back to pending/rejected
  ELSIF OLD.status = 'approved' AND NEW.status != 'approved' THEN
    lembar_count := COALESCE(OLD.jumlah_lembar, 0);

    UPDATE public.cukai_requests
    SET quantity_remaining = 0
    WHERE id = NEW.id;

    IF lembar_count > 0 AND OLD.cukai_category_id IS NOT NULL THEN
      -- Find matching allocation
      SELECT id INTO alloc_id
      FROM public.cukai_allocations
      WHERE factory_id = OLD.factory_id
        AND cukai_category_id = OLD.cukai_category_id
        AND period = to_char(OLD.request_date, 'YYYY-MM');

      IF alloc_id IS NOT NULL THEN
        -- Deduct from additions and quota
        UPDATE public.cukai_allocations
        SET additions = GREATEST(0, additions - lembar_count),
            quota = GREATEST(0, quota - lembar_count)
        WHERE id = alloc_id;
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Re-create triggers for safety
DROP TRIGGER IF EXISTS on_cukai_request_approved ON public.cukai_requests;
CREATE TRIGGER on_cukai_request_approved
  AFTER UPDATE ON public.cukai_requests
  FOR EACH ROW EXECUTE FUNCTION public.on_cukai_request_approved();

DROP TRIGGER IF EXISTS on_cukai_usage_resolve_allocation ON public.cukai_usage_log;
CREATE TRIGGER on_cukai_usage_resolve_allocation
  BEFORE INSERT OR UPDATE ON public.cukai_usage_log
  FOR EACH ROW EXECUTE FUNCTION public.resolve_cukai_usage_allocation();

-- 7. Redefine update_stok_on_cukai_usage function to validate against current_stock
CREATE OR REPLACE FUNCTION public.update_stok_on_cukai_usage()
RETURNS TRIGGER AS $$
DECLARE
  v_unaffixed_stock INT;
  v_cukai_stock INT;
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Check if unaffixed stock is sufficient
    SELECT unaffixed_stock INTO v_unaffixed_stock
    FROM public.cigarettes
    WHERE id = NEW.product_id;

    IF v_unaffixed_stock IS NULL OR v_unaffixed_stock < NEW.used_amount THEN
      RAISE EXCEPTION 'Safety check failed: Stok rokok belum dilekati (% kemasan) tidak mencukupi untuk pemakaian pita cukai (% lembar).', 
        COALESCE(v_unaffixed_stock, 0), NEW.used_amount;
    END IF;

    -- Check if available stamp stock (current_stock) is sufficient
    SELECT current_stock INTO v_cukai_stock
    FROM public.cukai_allocations
    WHERE id = NEW.allocation_id;

    IF v_cukai_stock IS NULL OR v_cukai_stock < (NEW.used_amount + NEW.damaged_amount) THEN
      RAISE EXCEPTION 'Safety check failed: Stok pita cukai (% lembar) tidak mencukupi untuk pencatatan ini (% lembar).',
        COALESCE(v_cukai_stock, 0), (NEW.used_amount + NEW.damaged_amount);
    END IF;

    -- Deduct remaining excise stamp sheets (used + damaged) from request batch if applicable
    IF NEW.cukai_request_id IS NOT NULL THEN
      UPDATE public.cukai_requests
      SET quantity_remaining = GREATEST(0, quantity_remaining - (NEW.used_amount + NEW.damaged_amount))
      WHERE id = NEW.cukai_request_id;
    END IF;

    -- Add to finished stock and deduct from unaffixed stock
    IF NEW.product_id IS NOT NULL THEN
      UPDATE public.cigarettes
      SET unaffixed_stock = unaffixed_stock - NEW.used_amount,
          stock = stock + NEW.used_amount
      WHERE id = NEW.product_id;
    END IF;

    -- Update cukai_allocations used and damaged sheets
    IF NEW.allocation_id IS NOT NULL THEN
      UPDATE public.cukai_allocations
      SET used = used + NEW.used_amount,
          damaged = damaged + NEW.damaged_amount
      WHERE id = NEW.allocation_id;
    END IF;

  ELSIF TG_OP = 'DELETE' THEN
    -- Revert remaining excise stamp sheets on request batch if applicable
    IF OLD.cukai_request_id IS NOT NULL THEN
      UPDATE public.cukai_requests
      SET quantity_remaining = quantity_remaining + (OLD.used_amount + OLD.damaged_amount)
      WHERE id = OLD.cukai_request_id;
    END IF;

    -- Revert finished stock and unaffixed stock
    IF OLD.product_id IS NOT NULL THEN
      UPDATE public.cigarettes
      SET unaffixed_stock = unaffixed_stock + OLD.used_amount,
          stock = GREATEST(0, stock - OLD.used_amount)
      WHERE id = OLD.product_id;
    END IF;

    -- Revert from cukai_allocations
    IF OLD.allocation_id IS NOT NULL THEN
      UPDATE public.cukai_allocations
      SET used = GREATEST(0, used - OLD.used_amount),
          damaged = GREATEST(0, damaged - OLD.damaged_amount)
      WHERE id = OLD.allocation_id;
    END IF;

  ELSIF TG_OP = 'UPDATE' THEN
    -- Revert old usage
    IF OLD.cukai_request_id IS NOT NULL THEN
      UPDATE public.cukai_requests
      SET quantity_remaining = quantity_remaining + (OLD.used_amount + OLD.damaged_amount)
      WHERE id = OLD.cukai_request_id;
    END IF;
    IF OLD.product_id IS NOT NULL THEN
      UPDATE public.cigarettes
      SET unaffixed_stock = unaffixed_stock + OLD.used_amount,
          stock = GREATEST(0, stock - OLD.used_amount)
      WHERE id = OLD.product_id;
    END IF;
    IF OLD.allocation_id IS NOT NULL THEN
      UPDATE public.cukai_allocations
      SET used = GREATEST(0, used - OLD.used_amount),
          damaged = GREATEST(0, damaged - OLD.damaged_amount)
      WHERE id = OLD.allocation_id;
    END IF;

    -- Check if unaffixed stock is sufficient
    SELECT unaffixed_stock INTO v_unaffixed_stock
    FROM public.cigarettes
    WHERE id = NEW.product_id;

    IF v_unaffixed_stock IS NULL OR v_unaffixed_stock < NEW.used_amount THEN
      RAISE EXCEPTION 'Safety check failed: Stok rokok belum dilekati (% kemasan) tidak mencukupi untuk pemakaian pita cukai (% lembar).', 
        COALESCE(v_unaffixed_stock, 0), NEW.used_amount;
    END IF;

    -- Check if available stamp stock (current_stock) is sufficient
    SELECT current_stock INTO v_cukai_stock
    FROM public.cukai_allocations
    WHERE id = NEW.allocation_id;

    IF v_cukai_stock IS NULL OR v_cukai_stock < (NEW.used_amount + NEW.damaged_amount) THEN
      RAISE EXCEPTION 'Safety check failed: Stok pita cukai (% lembar) tidak mencukupi untuk pencatatan ini (% lembar).',
        COALESCE(v_cukai_stock, 0), (NEW.used_amount + NEW.damaged_amount);
    END IF;

    IF NEW.cukai_request_id IS NOT NULL THEN
      UPDATE public.cukai_requests
      SET quantity_remaining = GREATEST(0, quantity_remaining - (NEW.used_amount + NEW.damaged_amount))
      WHERE id = NEW.cukai_request_id;
    END IF;
    IF NEW.product_id IS NOT NULL THEN
      UPDATE public.cigarettes
      SET unaffixed_stock = unaffixed_stock - NEW.used_amount,
          stock = stock + NEW.used_amount
      WHERE id = NEW.product_id;
    END IF;
    IF NEW.allocation_id IS NOT NULL THEN
      UPDATE public.cukai_allocations
      SET used = used + NEW.used_amount,
          damaged = damaged + NEW.damaged_amount
      WHERE id = NEW.allocation_id;
    END IF;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Re-initialize existing allocations to monthly values
-- Update quota default parameters
UPDATE public.cukai_allocations
SET monthly_quota = quota,
    carry_over = 0,
    additions = 0
WHERE monthly_quota = 0;

-- 9. Clean up duplicate triggers on cukai_usage_log to prevent double execution
DROP TRIGGER IF EXISTS on_cukai_usage_stok_update ON public.cukai_usage_log;
DROP TRIGGER IF EXISTS on_cukai_usage_stock_update ON public.cukai_usage_log;
DROP TRIGGER IF EXISTS on_cukai_usage_allocation_update ON public.cukai_usage_log;

CREATE TRIGGER on_cukai_usage_stock_update
  AFTER INSERT OR UPDATE OR DELETE ON public.cukai_usage_log
  FOR EACH ROW EXECUTE FUNCTION public.update_stok_on_cukai_usage();

-- 10. Recalculate and repair stocks for all cigarettes (fixes any doubled stok values)
UPDATE public.cigarettes c
SET 
  unaffixed_stock = COALESCE((
    SELECT SUM(p.jumlah_kemasan)
    FROM public.productions p
    WHERE p.product_id = c.id
  ), 0) - COALESCE((
    SELECT SUM(u.used_amount)
    FROM public.cukai_usage_log u
    WHERE u.product_id = c.id
  ), 0),
  stock = COALESCE((
    SELECT SUM(u.used_amount)
    FROM public.cukai_usage_log u
    WHERE u.product_id = c.id
  ), 0) - COALESCE((
    SELECT SUM(o.volume / COALESCE(NULLIF(c.sticks_per_pack, 0), 12))
    FROM public.outgoing_goods o
    WHERE o.product_id = c.id AND o.status = 'approved'
  ), 0);

-- 11. Repair any incorrectly formatted HJE values (scale up values <= 100 by 1000)
UPDATE public.cigarettes SET hje = hje * 1000 WHERE hje <= 100;
UPDATE public.cukai_categories SET hje = hje * 1000 WHERE hje <= 100;
UPDATE public.productions SET hje = hje * 1000 WHERE hje <= 100;
UPDATE public.cukai_requests SET hje = hje * 1000 WHERE hje <= 100;

-- 12. Recalculate used and damaged fields for all allocations to match actual logs
UPDATE public.cukai_allocations ca
SET 
  used = COALESCE((
    SELECT SUM(u.used_amount)
    FROM public.cukai_usage_log u
    WHERE u.allocation_id = ca.id
  ), 0),
  damaged = COALESCE((
    SELECT SUM(u.damaged_amount)
    FROM public.cukai_usage_log u
    WHERE u.allocation_id = ca.id
  ), 0);



