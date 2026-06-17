-- ============================================================
-- APHT Sumenep One — Migration 015: Stock Management Triggers
-- ============================================================

-- Function to update stock when a production entry is created, updated, or deleted
CREATE OR REPLACE FUNCTION public.update_stock_on_production()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.cigarettes
    SET stock = stock + NEW.jumlah_kemasan
    WHERE id = NEW.product_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.cigarettes
    SET stock = stock - OLD.jumlah_kemasan
    WHERE id = OLD.product_id;
  ELSIF TG_OP = 'UPDATE' THEN
    UPDATE public.cigarettes
    SET stock = stock - OLD.jumlah_kemasan + NEW.jumlah_kemasan
    WHERE id = NEW.product_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for productions stock updates
DROP TRIGGER IF EXISTS on_production_stock_update ON public.productions;
CREATE TRIGGER on_production_stock_update
  AFTER INSERT OR UPDATE OR DELETE ON public.productions
  FOR EACH ROW EXECUTE FUNCTION public.update_stock_on_production();

-- Function to update stock when an outgoing goods transaction is created, updated, or deleted
CREATE OR REPLACE FUNCTION public.update_stock_on_outgoing()
RETURNS TRIGGER AS $$
DECLARE
  v_sticks_per_pack INT;
  v_packs_deducted INT;
  v_old_packs_deducted INT;
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Get sticks_per_pack for the product
    SELECT COALESCE(sticks_per_pack, 12) INTO v_sticks_per_pack
    FROM public.cigarettes
    WHERE id = NEW.product_id;

    v_packs_deducted := NEW.volume / v_sticks_per_pack;
    
    UPDATE public.cigarettes
    SET stock = stock - v_packs_deducted
    WHERE id = NEW.product_id;
    
  ELSIF TG_OP = 'DELETE' THEN
    -- Get sticks_per_pack for the product
    SELECT COALESCE(sticks_per_pack, 12) INTO v_sticks_per_pack
    FROM public.cigarettes
    WHERE id = OLD.product_id;

    v_packs_deducted := OLD.volume / v_sticks_per_pack;
    
    UPDATE public.cigarettes
    SET stock = stock + v_packs_deducted
    WHERE id = OLD.product_id;
    
  ELSIF TG_OP = 'UPDATE' THEN
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
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for outgoing goods stock updates
DROP TRIGGER IF EXISTS on_outgoing_stock_update ON public.outgoing_goods;
CREATE TRIGGER on_outgoing_stock_update
  AFTER INSERT OR UPDATE OR DELETE ON public.outgoing_goods
  FOR EACH ROW EXECUTE FUNCTION public.update_stock_on_outgoing();
