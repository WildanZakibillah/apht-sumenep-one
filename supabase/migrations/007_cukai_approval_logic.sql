-- ============================================================
-- Migration 007: Auto-increase cukai quota when request is approved
-- ============================================================

-- Logika bisnis:
-- 1. Pengajuan cukai = pembelian pita cukai baru (pengeluaran uang)
-- 2. Saat pengajuan APPROVED → stok cukai (quota) bertambah
-- 3. Catat pemakaian = pakai pita untuk produksi → stok berkurang (used naik)
-- 4. Sisa cukai = quota - used - damaged
-- 5. Pengeluaran cukai = sum(tarif_cukai * jumlah_lembar) dari pengajuan approved

-- ============================================================
-- Trigger: When cukai_request is approved, add to allocation quota
-- ============================================================
CREATE OR REPLACE FUNCTION public.on_cukai_request_approved()
RETURNS TRIGGER AS $$
DECLARE
  alloc_id UUID;
  lembar_count INT;
BEGIN
  -- Only fire when status changes to 'approved'
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    lembar_count := COALESCE(NEW.jumlah_lembar, 0);
    
    IF lembar_count > 0 THEN
      -- Find the latest allocation for this factory
      SELECT id INTO alloc_id
      FROM cukai_allocations
      WHERE factory_id = NEW.factory_id
      ORDER BY created_at DESC
      LIMIT 1;

      IF alloc_id IS NOT NULL THEN
        -- Add the approved quantity to the quota
        UPDATE cukai_allocations
        SET quota = quota + lembar_count
        WHERE id = alloc_id;
      ELSE
        -- Create a new allocation if none exists
        INSERT INTO cukai_allocations (factory_id, quota, used, damaged, period)
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

-- Drop existing trigger if any to avoid conflict
DROP TRIGGER IF EXISTS on_cukai_request_approved ON cukai_requests;

CREATE TRIGGER on_cukai_request_approved
  AFTER UPDATE ON cukai_requests
  FOR EACH ROW EXECUTE FUNCTION public.on_cukai_request_approved();
