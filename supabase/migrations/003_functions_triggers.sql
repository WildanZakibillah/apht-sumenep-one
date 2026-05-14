-- ============================================================
-- APHT Sumenep One — Functions & Triggers
-- Migration 003
-- ============================================================

-- ============================================================
-- 1. Auto-create profile on new auth.users signup
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'staf_lapangan')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 2. Update cukai_allocations when usage log is inserted
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_cukai_on_usage()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE cukai_allocations
  SET
    used = used + NEW.used_amount,
    damaged = damaged  -- damaged is updated separately
  WHERE id = NEW.allocation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_cukai_usage_insert
  AFTER INSERT ON cukai_usage_log
  FOR EACH ROW EXECUTE FUNCTION public.update_cukai_on_usage();

-- ============================================================
-- 3. Auto-create notification when cukai reaches critical level
-- ============================================================
CREATE OR REPLACE FUNCTION public.check_cukai_threshold()
RETURNS TRIGGER AS $$
DECLARE
  threshold_pct NUMERIC := 0.10;
  remaining_pct NUMERIC;
  factory_name TEXT;
  admin_id UUID;
BEGIN
  remaining_pct := (NEW.quota - NEW.used - NEW.damaged)::NUMERIC / NULLIF(NEW.quota, 0);

  IF remaining_pct IS NOT NULL AND remaining_pct <= threshold_pct THEN
    SELECT name INTO factory_name FROM factories WHERE id = NEW.factory_id;

    -- Notify all super_admins
    INSERT INTO notifications (user_id, title, message, type, icon, metadata)
    SELECT
      p.id,
      'Peringatan Sisa Cukai',
      format('Sisa Pita Cukai di %s tersisa %s%% (%s lembar). Segera lakukan pengajuan.',
        factory_name,
        ROUND(remaining_pct * 100, 1),
        (NEW.quota - NEW.used - NEW.damaged)
      ),
      'warning',
      'warning_amber_rounded',
      jsonb_build_object(
        'factory_id', NEW.factory_id,
        'allocation_id', NEW.id,
        'remaining_pct', ROUND(remaining_pct * 100, 1)
      )
    FROM profiles p
    WHERE p.role = 'super_admin' OR p.factory_id = NEW.factory_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_cukai_allocation_update
  AFTER UPDATE ON cukai_allocations
  FOR EACH ROW EXECUTE FUNCTION public.check_cukai_threshold();

-- ============================================================
-- 4. Auto-create notification when new report is submitted
-- ============================================================
CREATE OR REPLACE FUNCTION public.notify_new_report()
RETURNS TRIGGER AS $$
DECLARE
  factory_name TEXT;
BEGIN
  SELECT name INTO factory_name FROM factories WHERE id = NEW.factory_id;

  INSERT INTO notifications (user_id, title, message, type, icon, metadata)
  SELECT
    p.id,
    'Laporan Baru Diterima',
    format('Laporan dari %s untuk periode %s telah diterima dan menunggu verifikasi.',
      factory_name, NEW.period
    ),
    'info',
    'description_outlined',
    jsonb_build_object('report_id', NEW.id, 'factory_id', NEW.factory_id)
  FROM profiles p
  WHERE p.role = 'super_admin';

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_report_created
  AFTER INSERT ON reports
  FOR EACH ROW EXECUTE FUNCTION public.notify_new_report();

-- ============================================================
-- 5. Dashboard stats aggregate view
-- ============================================================
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

-- ============================================================
-- 6. Enable Realtime on key tables
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE productions;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE cukai_allocations;
ALTER PUBLICATION supabase_realtime ADD TABLE reports;
ALTER PUBLICATION supabase_realtime ADD TABLE outgoing_goods;
