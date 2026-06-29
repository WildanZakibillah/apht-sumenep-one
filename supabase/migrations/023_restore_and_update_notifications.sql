-- ============================================================
-- APHT Sumenep One — Migration 023: Restore Notifications Table and Set Up Mobile Notification Triggers
-- ============================================================

-- 1. Restore public.notifications table if it was dropped
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'info' CHECK (type IN ('info', 'warning', 'success', 'error')),
  icon TEXT,
  is_read BOOLEAN NOT NULL DEFAULT false,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS and insert policies for notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own notifications" ON public.notifications;
CREATE POLICY "Users can read own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own notifications" ON public.notifications;
CREATE POLICY "Users can delete own notifications"
  ON public.notifications FOR DELETE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can insert notifications" ON public.notifications;
CREATE POLICY "System can insert notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (true);

-- 2. Trigger for Cukai Request status change notifications
CREATE OR REPLACE FUNCTION public.notify_cukai_request_status_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Only notify when status has changed and is approved or rejected
  IF NEW.status != OLD.status AND NEW.status IN ('approved', 'rejected') THEN
    INSERT INTO public.notifications (user_id, title, message, type, icon, metadata)
    VALUES (
      NEW.created_by,
      CASE WHEN NEW.status = 'approved' THEN 'Pengajuan Cukai Disetujui' ELSE 'Pengajuan Cukai Ditolak' END,
      CASE WHEN NEW.status = 'approved' 
        THEN format('Pengajuan pita cukai sebesar %s lembar telah disetujui.', NEW.jumlah_lembar)
        ELSE format('Pengajuan pita cukai sebesar %s lembar telah ditolak.', NEW.jumlah_lembar)
      END,
      CASE WHEN NEW.status = 'approved' THEN 'success' ELSE 'error' END,
      CASE WHEN NEW.status = 'approved' THEN 'check_circle' ELSE 'cancel' END,
      jsonb_build_object('request_id', NEW.id, 'status', NEW.status)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_cukai_request_status_change ON public.cukai_requests;
CREATE TRIGGER on_cukai_request_status_change
  AFTER UPDATE ON public.cukai_requests
  FOR EACH ROW EXECUTE FUNCTION public.notify_cukai_request_status_change();

-- 3. Trigger for Outgoing Goods status change notifications
CREATE OR REPLACE FUNCTION public.notify_outgoing_goods_status_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Only notify when status has changed and is approved or rejected
  IF NEW.status != OLD.status AND NEW.status IN ('approved', 'rejected') THEN
    INSERT INTO public.notifications (user_id, title, message, type, icon, metadata)
    VALUES (
      NEW.created_by,
      CASE WHEN NEW.status = 'approved' THEN 'Pengajuan Barang Keluar Disetujui' ELSE 'Pengajuan Barang Keluar Ditolak' END,
      CASE WHEN NEW.status = 'approved' 
        THEN format('Pengajuan pengeluaran barang untuk customer %s telah disetujui.', NEW.customer_name)
        ELSE format('Pengajuan pengeluaran barang untuk customer %s telah ditolak.', NEW.customer_name)
      END,
      CASE WHEN NEW.status = 'approved' THEN 'success' ELSE 'error' END,
      CASE WHEN NEW.status = 'approved' THEN 'check_circle' ELSE 'cancel' END,
      jsonb_build_object('outgoing_id', NEW.id, 'status', NEW.status)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_outgoing_goods_status_change ON public.outgoing_goods;
CREATE TRIGGER on_outgoing_goods_status_change
  AFTER UPDATE ON public.outgoing_goods
  FOR EACH ROW EXECUTE FUNCTION public.notify_outgoing_goods_status_change();
