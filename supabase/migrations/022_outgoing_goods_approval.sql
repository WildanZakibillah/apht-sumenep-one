-- ============================================================
-- APHT Sumenep One — Migration 022: Outgoing Goods Approval and Remove Notifications
-- ============================================================

-- 1. Ensure status column in outgoing_goods table
ALTER TABLE public.outgoing_goods
  ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'pending'
  CHECK (status IN ('pending', 'approved', 'rejected'));

-- 3. Rewrite update_stock_on_outgoing trigger function to only modify stock when approved
CREATE OR REPLACE FUNCTION public.update_stock_on_outgoing()
RETURNS TRIGGER AS $$
DECLARE
  v_sticks_per_pack INT;
  v_packs_deducted INT;
  v_old_packs_deducted INT;
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Only deduct stock if status is approved
    IF NEW.status = 'approved' THEN
      SELECT COALESCE(sticks_per_pack, 12) INTO v_sticks_per_pack
      FROM public.cigarettes
      WHERE id = NEW.product_id;

      v_packs_deducted := NEW.volume / v_sticks_per_pack;
      
      UPDATE public.cigarettes
      SET stock = stock - v_packs_deducted
      WHERE id = NEW.product_id;
    END IF;

  ELSIF TG_OP = 'DELETE' THEN
    -- Only revert stock if status was approved
    IF OLD.status = 'approved' THEN
      SELECT COALESCE(sticks_per_pack, 12) INTO v_sticks_per_pack
      FROM public.cigarettes
      WHERE id = OLD.product_id;

      v_packs_deducted := OLD.volume / v_sticks_per_pack;
      
      UPDATE public.cigarettes
      SET stock = stock + v_packs_deducted
      WHERE id = OLD.product_id;
    END IF;

  ELSIF TG_OP = 'UPDATE' THEN
    -- Case 1: Status changed from not approved to approved
    IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
      SELECT COALESCE(sticks_per_pack, 12) INTO v_sticks_per_pack
      FROM public.cigarettes
      WHERE id = NEW.product_id;
      v_packs_deducted := NEW.volume / v_sticks_per_pack;

      UPDATE public.cigarettes
      SET stock = stock - v_packs_deducted
      WHERE id = NEW.product_id;

    -- Case 2: Status changed from approved to not approved (revert)
    ELSIF OLD.status = 'approved' AND NEW.status != 'approved' THEN
      SELECT COALESCE(sticks_per_pack, 12) INTO v_sticks_per_pack
      FROM public.cigarettes
      WHERE id = OLD.product_id;
      v_old_packs_deducted := OLD.volume / v_sticks_per_pack;

      UPDATE public.cigarettes
      SET stock = stock + v_old_packs_deducted
      WHERE id = OLD.product_id;

    -- Case 3: Status remains approved, check if fields changed
    ELSIF NEW.status = 'approved' AND OLD.status = 'approved' THEN
      -- Get sticks_per_pack for new product
      SELECT COALESCE(sticks_per_pack, 12) INTO v_sticks_per_pack
      FROM public.cigarettes
      WHERE id = NEW.product_id;
      v_packs_deducted := NEW.volume / v_sticks_per_pack;

      -- Get sticks_per_pack for old product
      SELECT COALESCE(sticks_per_pack, 12) INTO v_sticks_per_pack
      FROM public.cigarettes
      WHERE id = OLD.product_id;
      v_old_packs_deducted := OLD.volume / v_sticks_per_pack;

      IF NEW.product_id = OLD.product_id THEN
        UPDATE public.cigarettes
        SET stock = stock + v_old_packs_deducted - v_packs_deducted
        WHERE id = NEW.product_id;
      ELSE
        -- Revert old product stock
        UPDATE public.cigarettes
        SET stock = stock + v_old_packs_deducted
        WHERE id = OLD.product_id;
        
        -- Deduct new product stock
        UPDATE public.cigarettes
        SET stock = stock - v_packs_deducted
        WHERE id = NEW.product_id;
      END IF;
    END IF;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
