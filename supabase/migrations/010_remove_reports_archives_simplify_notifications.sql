-- ============================================================
-- Migration 010: Remove reports & archives tables, simplify notifications
-- ============================================================
-- Tujuan:
--  1) Hapus fitur Laporan Masuk dan Arsip Digital sepenuhnya
--  2) Notifikasi HANYA dibuat saat ada pengajuan cukai masuk (INSERT cukai_requests)
--     - Hapus trigger notif untuk: report created, production created, cukai status change
--     - Hapus trigger notif cukai threshold (warning sisa cukai)
--  3) Bersihkan notifikasi lama yang tidak relevan

-- ------------------------------------------------------------
-- 1. Drop notification triggers / functions yang tidak dipakai lagi
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS on_cukai_request_status_change ON cukai_requests;
DROP FUNCTION IF EXISTS public.notify_cukai_request_status() CASCADE;

DROP TRIGGER IF EXISTS on_production_created ON productions;
DROP FUNCTION IF EXISTS public.notify_production_created() CASCADE;

DROP TRIGGER IF EXISTS on_cukai_allocation_update ON cukai_allocations;
DROP FUNCTION IF EXISTS public.check_cukai_threshold() CASCADE;

DROP TRIGGER IF EXISTS on_report_created ON reports;
DROP FUNCTION IF EXISTS public.notify_new_report() CASCADE;

-- Update notify_cukai_request_created supaya menarget super_admin (admin dashboard)
DROP TRIGGER IF EXISTS on_cukai_request_created ON cukai_requests;
DROP FUNCTION IF EXISTS public.notify_cukai_request_created() CASCADE;

CREATE OR REPLACE FUNCTION public.notify_cukai_request_created()
RETURNS TRIGGER AS $$
DECLARE
  factory_name TEXT;
BEGIN
  SELECT name INTO factory_name FROM factories WHERE id = NEW.factory_id;

  -- Notify all super_admins so they see the request in dashboard
  INSERT INTO notifications (user_id, title, message, type, icon, metadata)
  SELECT
    p.id,
    'Pengajuan Cukai Baru',
    format('%s mengajukan %s lembar pita cukai (%s).',
      COALESCE(factory_name, '-'),
      COALESCE(NEW.jumlah_lembar, 0),
      NEW.jenis_pengajuan
    ),
    'info',
    'request_page',
    jsonb_build_object(
      'request_id', NEW.id,
      'factory_id', NEW.factory_id,
      'doc_number', NEW.doc_number,
      'jenis', NEW.jenis_pengajuan
    )
  FROM profiles p
  WHERE p.role = 'super_admin';

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_cukai_request_created
  AFTER INSERT ON cukai_requests
  FOR EACH ROW EXECUTE FUNCTION public.notify_cukai_request_created();

-- ------------------------------------------------------------
-- 2. Drop tables Reports & Archives
-- ------------------------------------------------------------
-- Lepas dari realtime publication dulu (kalau ada)
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime DROP TABLE reports;
  EXCEPTION WHEN OTHERS THEN NULL;
  END;
END $$;

DROP TABLE IF EXISTS archives CASCADE;
DROP TABLE IF EXISTS reports CASCADE;

-- ------------------------------------------------------------
-- 3. Bersihkan notifikasi lama yang merujuk ke fitur yang dihapus
-- ------------------------------------------------------------
DELETE FROM notifications
WHERE title IN (
  'Laporan Baru Diterima',
  'Laporan Masuk',
  'Laporan Diverifikasi',
  'Produksi Dicatat',
  'Produksi Tercatat',
  'Peringatan Sisa Cukai',
  'Cukai Kritis',
  'Pengajuan Cukai Disetujui',
  'Pengajuan Cukai Ditolak',
  'Pengajuan Ditolak',
  'Status Pengajuan Berubah',
  'Pengajuan Cukai Terkirim'
);

-- ------------------------------------------------------------
-- 4. Update dashboard_stats view (hilangkan referensi reports)
-- ------------------------------------------------------------
DROP VIEW IF EXISTS dashboard_stats;
CREATE OR REPLACE VIEW dashboard_stats AS
SELECT
  (SELECT COUNT(*) FROM factories WHERE status = 'active') AS total_active_factories,
  (SELECT COUNT(*) FROM factories) AS total_factories,
  (SELECT COALESCE(SUM(jumlah_isi), 0) FROM productions
    WHERE doc_date >= date_trunc('month', CURRENT_DATE)) AS production_this_month,
  (SELECT COALESCE(SUM(remaining), 0) FROM cukai_allocations) AS total_remaining_cukai,
  (SELECT COALESCE(SUM(volume), 0) FROM outgoing_goods
    WHERE transaction_date >= date_trunc('month', CURRENT_DATE)) AS outgoing_this_month,
  (SELECT COALESCE(SUM(total_value), 0) FROM outgoing_goods
    WHERE transaction_date >= date_trunc('month', CURRENT_DATE)) AS revenue_this_month;
