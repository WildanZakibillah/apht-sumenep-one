-- ============================================================
-- APHT Sumenep One — Migration 019: Add Damaged Amount to Usage Log
-- ============================================================

-- 1. Add damaged_amount to cukai_usage_log
ALTER TABLE public.cukai_usage_log
  ADD COLUMN IF NOT EXISTS damaged_amount INT NOT NULL DEFAULT 0;

-- 2. Update update_stok_on_cukai_usage function to include damaged stamps
CREATE OR REPLACE FUNCTION public.update_stok_on_cukai_usage()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Deduct remaining excise stamp sheets (used + damaged)
    IF NEW.cukai_request_id IS NOT NULL THEN
      UPDATE public.cukai_requests
      SET quantity_remaining = GREATEST(0, quantity_remaining - (NEW.used_amount + NEW.damaged_amount))
      WHERE id = NEW.cukai_request_id;
    END IF;

    -- Add to finished stock (used_amount only)
    IF NEW.product_id IS NOT NULL THEN
      UPDATE public.cigarettes
      SET stock = stock + NEW.used_amount
      WHERE id = NEW.product_id;
    END IF;

  ELSIF TG_OP = 'DELETE' THEN
    -- Revert remaining excise stamp sheets
    IF OLD.cukai_request_id IS NOT NULL THEN
      UPDATE public.cukai_requests
      SET quantity_remaining = quantity_remaining + (OLD.used_amount + OLD.damaged_amount)
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
      SET quantity_remaining = quantity_remaining + (OLD.used_amount + OLD.damaged_amount)
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
      SET quantity_remaining = GREATEST(0, quantity_remaining - (NEW.used_amount + NEW.damaged_amount))
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

-- 3. Replace update_cukai_on_usage to support insert/update/delete for allocations
CREATE OR REPLACE FUNCTION public.update_cukai_on_usage()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.cukai_allocations
    SET
      used = used + NEW.used_amount,
      damaged = damaged + NEW.damaged_amount
    WHERE id = NEW.allocation_id;

  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.cukai_allocations
    SET
      used = GREATEST(0, used - OLD.used_amount),
      damaged = GREATEST(0, damaged - OLD.damaged_amount)
    WHERE id = OLD.allocation_id;

  ELSIF TG_OP = 'UPDATE' THEN
    UPDATE public.cukai_allocations
    SET
      used = GREATEST(0, used - OLD.used_amount + NEW.used_amount),
      damaged = GREATEST(0, damaged - OLD.damaged_amount + NEW.damaged_amount)
    WHERE id = NEW.allocation_id;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Re-create triggers for allocation updates
DROP TRIGGER IF EXISTS on_cukai_usage_insert ON public.cukai_usage_log;
DROP TRIGGER IF EXISTS on_cukai_usage_allocation_update ON public.cukai_usage_log;

CREATE TRIGGER on_cukai_usage_allocation_update
  AFTER INSERT OR UPDATE OR DELETE ON public.cukai_usage_log
  FOR EACH ROW EXECUTE FUNCTION public.update_cukai_on_usage();
