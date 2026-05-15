-- ============================================================
-- Migration 006: Fix cukai allocation creation & add notification triggers
-- ============================================================

-- Allow admin_pabrik to insert cukai_allocations for their own factory
CREATE POLICY "Factory admin can create allocations"
  ON cukai_allocations FOR INSERT
  WITH CHECK (
    factory_id = public.user_factory_id()
    AND public.user_role() IN ('admin_pabrik', 'super_admin')
  );

-- Allow admin_pabrik to update cukai_allocations for their own factory
CREATE POLICY "Factory admin can update own allocations"
  ON cukai_allocations FOR UPDATE
  USING (
    factory_id = public.user_factory_id()
    OR public.is_super_admin()
  );

-- ============================================================
-- Trigger: Notify user when cukai_request status changes
-- ============================================================
CREATE OR REPLACE FUNCTION public.notify_cukai_request_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Only fire when status actually changes
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO notifications (user_id, title, message, type, icon, metadata)
    VALUES (
      NEW.created_by,
      CASE NEW.status
        WHEN 'approved' THEN 'Pengajuan Cukai Disetujui'
        WHEN 'rejected' THEN 'Pengajuan Cukai Ditolak'
        ELSE 'Status Pengajuan Berubah'
      END,
      CASE NEW.status
        WHEN 'approved' THEN format('Pengajuan cukai %s telah disetujui.', COALESCE(NEW.doc_number, '-'))
        WHEN 'rejected' THEN format('Pengajuan cukai %s ditolak.', COALESCE(NEW.doc_number, '-'))
        ELSE format('Status pengajuan %s berubah menjadi %s.', COALESCE(NEW.doc_number, '-'), NEW.status)
      END,
      CASE NEW.status
        WHEN 'approved' THEN 'success'
        WHEN 'rejected' THEN 'error'
        ELSE 'info'
      END,
      CASE NEW.status
        WHEN 'approved' THEN 'check_circle_outline_rounded'
        WHEN 'rejected' THEN 'warning_amber_rounded'
        ELSE 'description_outlined'
      END,
      jsonb_build_object('request_id', NEW.id, 'status', NEW.status, 'doc_number', NEW.doc_number)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_cukai_request_status_change
  AFTER UPDATE ON cukai_requests
  FOR EACH ROW EXECUTE FUNCTION public.notify_cukai_request_status();

-- ============================================================
-- Trigger: Notify user when cukai_request is created (confirmation)
-- ============================================================
CREATE OR REPLACE FUNCTION public.notify_cukai_request_created()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO notifications (user_id, title, message, type, icon, metadata)
  VALUES (
    NEW.created_by,
    'Pengajuan Cukai Terkirim',
    format('Pengajuan cukai %s (%s) berhasil dikirim dan menunggu persetujuan.', COALESCE(NEW.doc_number, '-'), NEW.jenis_pengajuan),
    'info',
    'description_outlined',
    jsonb_build_object('request_id', NEW.id, 'doc_number', NEW.doc_number, 'jenis', NEW.jenis_pengajuan)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_cukai_request_created
  AFTER INSERT ON cukai_requests
  FOR EACH ROW EXECUTE FUNCTION public.notify_cukai_request_created();

-- ============================================================
-- Trigger: Notify on production entry
-- ============================================================
CREATE OR REPLACE FUNCTION public.notify_production_created()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO notifications (user_id, title, message, type, icon, metadata)
  VALUES (
    NEW.created_by,
    'Produksi Dicatat',
    format('Data produksi %s (%s) sebanyak %s kemasan berhasil dicatat.', NEW.merek, NEW.jenis, NEW.jumlah_kemasan),
    'success',
    'inventory_2_outlined',
    jsonb_build_object('production_id', NEW.id, 'doc_number', NEW.doc_number)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_production_created
  AFTER INSERT ON productions
  FOR EACH ROW EXECUTE FUNCTION public.notify_production_created();
