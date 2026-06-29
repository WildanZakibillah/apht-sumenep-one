-- =============================================
-- FIX: Pastikan trigger produksi aktif dan terpasang
-- Jalankan di Supabase SQL Editor
-- =============================================

-- 1. Pastikan kolom unaffixed_stock ada
ALTER TABLE public.cigarettes
ADD COLUMN IF NOT EXISTS unaffixed_stock INT NOT NULL DEFAULT 0;

-- 2. Recreate function update_stock_on_production (produksi -> unaffixed_stock)
CREATE OR REPLACE FUNCTION public.update_stock_on_production()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.cigarettes
    SET unaffixed_stock = unaffixed_stock + NEW.jumlah_kemasan
    WHERE id = NEW.product_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.cigarettes
    SET unaffixed_stock = unaffixed_stock - OLD.jumlah_kemasan
    WHERE id = OLD.product_id;
  ELSIF TG_OP = 'UPDATE' THEN
    UPDATE public.cigarettes
    SET unaffixed_stock = unaffixed_stock - OLD.jumlah_kemasan + NEW.jumlah_kemasan
    WHERE id = NEW.product_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. PENTING: Pasang ulang trigger (DROP dulu lalu CREATE baru)
DROP TRIGGER IF EXISTS on_production_stock_update ON public.productions;
CREATE TRIGGER on_production_stock_update
  AFTER INSERT OR UPDATE OR DELETE ON public.productions
  FOR EACH ROW EXECUTE FUNCTION public.update_stock_on_production();

-- 4. Recreate function update_stok_on_cukai_usage (pelekatan cukai: unaffixed -> stock)
CREATE OR REPLACE FUNCTION public.update_stok_on_cukai_usage()
RETURNS TRIGGER AS $$
DECLARE
  v_unaffixed_stock INT;
BEGIN
  IF TG_OP = 'INSERT' THEN
    SELECT unaffixed_stock INTO v_unaffixed_stock
    FROM public.cigarettes
    WHERE id = NEW.product_id;

    IF v_unaffixed_stock IS NULL OR v_unaffixed_stock < NEW.used_amount THEN
      RAISE EXCEPTION 'Safety check failed: Stok rokok belum dilekati (% kemasan) tidak mencukupi untuk pemakaian pita cukai (% lembar).',
        COALESCE(v_unaffixed_stock, 0), NEW.used_amount;
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

  ELSIF TG_OP = 'DELETE' THEN
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

  ELSIF TG_OP = 'UPDATE' THEN
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

    SELECT unaffixed_stock INTO v_unaffixed_stock
    FROM public.cigarettes
    WHERE id = NEW.product_id;

    IF v_unaffixed_stock IS NULL OR v_unaffixed_stock < NEW.used_amount THEN
      RAISE EXCEPTION 'Safety check failed: Stok rokok belum dilekati (% kemasan) tidak mencukupi untuk pemakaian pita cukai (% lembar).',
        COALESCE(v_unaffixed_stock, 0), NEW.used_amount;
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
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Pasang ulang trigger cukai usage
DROP TRIGGER IF EXISTS on_cukai_usage_stock_update ON public.cukai_usage_log;
CREATE TRIGGER on_cukai_usage_stock_update
  AFTER INSERT OR UPDATE OR DELETE ON public.cukai_usage_log
  FOR EACH ROW EXECUTE FUNCTION public.update_stok_on_cukai_usage();

-- 6. Hitung ulang unaffixed_stock berdasarkan produksi yang sudah ada
-- (Karena sebelumnya trigger lama menambah ke stock, kita pindahkan)
UPDATE public.cigarettes c
SET unaffixed_stock = COALESCE((
  SELECT SUM(p.jumlah_kemasan)
  FROM public.productions p
  WHERE p.product_id = c.id
), 0),
stock = 0;
