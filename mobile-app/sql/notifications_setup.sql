-- ============================================================
-- TABEL NOTIFICATIONS
-- ============================================================

-- Buat tabel notifications (jika belum ada)
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT,
  type TEXT DEFAULT 'info', -- info, success, warning, error
  icon TEXT DEFAULT 'notifications_outlined',
  is_read BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Index untuk query cepat
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON public.notifications(user_id, is_read) WHERE is_read = false;

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Policy: user hanya bisa lihat notifikasi miliknya
CREATE POLICY "Users can view own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: user bisa update (mark as read) notifikasi miliknya
CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: user bisa hapus notifikasi miliknya
CREATE POLICY "Users can delete own notifications"
  ON public.notifications FOR DELETE
  USING (auth.uid() = user_id);

-- Policy: service role bisa insert (untuk trigger/function)
CREATE POLICY "Service can insert notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (true);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;


-- ============================================================
-- FUNCTION: Kirim notifikasi saat pengajuan cukai disetujui
-- ============================================================

CREATE OR REPLACE FUNCTION public.notify_cukai_request_approved()
RETURNS TRIGGER AS $$
BEGIN
  -- Hanya trigger saat status berubah menjadi 'approved'
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    INSERT INTO public.notifications (user_id, title, message, type, icon, metadata)
    VALUES (
      NEW.created_by,
      'Pengajuan Cukai Disetujui',
      'Pengajuan cukai ' || COALESCE(NEW.jenis_pengajuan, '') || ' untuk ' || COALESCE(NEW.jenis_hasil_tembakau, '') || ' telah disetujui.',
      'success',
      'check_circle_outline_rounded',
      jsonb_build_object(
        'request_id', NEW.id,
        'doc_number', COALESCE(NEW.doc_number, '-'),
        'jenis_pengajuan', COALESCE(NEW.jenis_pengajuan, '-'),
        'jumlah_lembar', COALESCE(NEW.jumlah_lembar::text, '0')
      )
    );
  END IF;

  -- Notifikasi saat ditolak
  IF NEW.status = 'rejected' AND (OLD.status IS NULL OR OLD.status != 'rejected') THEN
    INSERT INTO public.notifications (user_id, title, message, type, icon, metadata)
    VALUES (
      NEW.created_by,
      'Pengajuan Cukai Ditolak',
      'Pengajuan cukai ' || COALESCE(NEW.jenis_pengajuan, '') || ' untuk ' || COALESCE(NEW.jenis_hasil_tembakau, '') || ' ditolak. Silakan periksa kembali.',
      'error',
      'warning_amber_rounded',
      jsonb_build_object(
        'request_id', NEW.id,
        'doc_number', COALESCE(NEW.doc_number, '-'),
        'alasan', COALESCE(NEW.rejection_reason, '-')
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pada tabel cukai_requests
DROP TRIGGER IF EXISTS trg_cukai_request_status_change ON public.cukai_requests;
CREATE TRIGGER trg_cukai_request_status_change
  AFTER UPDATE OF status ON public.cukai_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_cukai_request_approved();


-- ============================================================
-- DATA DUMMY NOTIFIKASI
-- Ganti 'YOUR_USER_ID_HERE' dengan UUID user yang valid
-- ============================================================

-- Contoh: INSERT dengan user_id yang sesuai
-- Jalankan query ini setelah mengganti YOUR_USER_ID_HERE

/*
INSERT INTO public.notifications (user_id, title, message, type, icon, is_read, metadata, created_at) VALUES
(
  'YOUR_USER_ID_HERE',
  'Pengajuan Cukai Disetujui',
  'Pengajuan cukai CK-1 untuk SKM telah disetujui. Silakan cek alokasi pita cukai Anda.',
  'success',
  'check_circle_outline_rounded',
  false,
  '{"request_id": "dummy-1", "doc_number": "CK1-2025-001", "jenis_pengajuan": "CK-1", "jumlah_lembar": "5000"}',
  now() - interval '10 minutes'
),
(
  'YOUR_USER_ID_HERE',
  'Produksi Berhasil Dicatat',
  'Data produksi merek GUDANG BARU sebanyak 12.000 batang berhasil dicatat ke sistem.',
  'info',
  'inventory_2_outlined',
  false,
  '{"merek": "GUDANG BARU", "jumlah": "12000"}',
  now() - interval '2 hours'
),
(
  'YOUR_USER_ID_HERE',
  'Pengajuan Cukai Ditolak',
  'Pengajuan cukai CK-1 untuk SPM ditolak. Alasan: Dokumen pendukung tidak lengkap.',
  'error',
  'warning_amber_rounded',
  false,
  '{"request_id": "dummy-2", "doc_number": "CK1-2025-002", "alasan": "Dokumen pendukung tidak lengkap"}',
  now() - interval '1 day'
),
(
  'YOUR_USER_ID_HERE',
  'Stok Cukai Menipis',
  'Sisa pita cukai Anda tinggal 500 lembar. Segera ajukan permohonan pita cukai baru.',
  'warning',
  'warning_amber_rounded',
  true,
  '{"sisa": "500"}',
  now() - interval '2 days'
),
(
  'YOUR_USER_ID_HERE',
  'Barang Keluar Tercatat',
  'Pengiriman 5.000 batang ke Toko Jaya Abadi berhasil dicatat.',
  'info',
  'local_shipping_outlined',
  true,
  '{"customer": "Toko Jaya Abadi", "volume": "5000"}',
  now() - interval '3 days'
);
*/

-- ============================================================
-- QUERY CEPAT: Insert dummy dengan user pertama di profiles
-- (Gunakan ini jika ingin langsung test)
-- ============================================================

DO $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Ambil user pertama dari profiles
  SELECT id INTO v_user_id FROM public.profiles LIMIT 1;
  
  IF v_user_id IS NULL THEN
    RAISE NOTICE 'Tidak ada user di tabel profiles. Skip dummy data.';
    RETURN;
  END IF;

  INSERT INTO public.notifications (user_id, title, message, type, icon, is_read, metadata, created_at) VALUES
  (
    v_user_id,
    'Pengajuan Cukai Disetujui',
    'Pengajuan cukai CK-1 untuk SKM telah disetujui. Silakan cek alokasi pita cukai Anda.',
    'success',
    'check_circle_outline_rounded',
    false,
    '{"request_id": "dummy-1", "doc_number": "CK1-2025-001", "jenis_pengajuan": "CK-1", "jumlah_lembar": "5000"}'::jsonb,
    now() - interval '10 minutes'
  ),
  (
    v_user_id,
    'Produksi Berhasil Dicatat',
    'Data produksi merek GUDANG BARU sebanyak 12.000 batang berhasil dicatat ke sistem.',
    'info',
    'inventory_2_outlined',
    false,
    '{"merek": "GUDANG BARU", "jumlah": "12000"}'::jsonb,
    now() - interval '2 hours'
  ),
  (
    v_user_id,
    'Pengajuan Cukai Ditolak',
    'Pengajuan cukai CK-1 untuk SPM ditolak. Alasan: Dokumen pendukung tidak lengkap.',
    'error',
    'warning_amber_rounded',
    false,
    '{"request_id": "dummy-2", "doc_number": "CK1-2025-002", "alasan": "Dokumen pendukung tidak lengkap"}'::jsonb,
    now() - interval '1 day'
  ),
  (
    v_user_id,
    'Stok Cukai Menipis',
    'Sisa pita cukai Anda tinggal 500 lembar. Segera ajukan permohonan pita cukai baru.',
    'warning',
    'warning_amber_rounded',
    true,
    '{"sisa": "500"}'::jsonb,
    now() - interval '2 days'
  ),
  (
    v_user_id,
    'Barang Keluar Tercatat',
    'Pengiriman 5.000 batang ke Toko Jaya Abadi berhasil dicatat.',
    'info',
    'local_shipping_outlined',
    true,
    '{"customer": "Toko Jaya Abadi", "volume": "5000"}'::jsonb,
    now() - interval '3 days'
  );

  RAISE NOTICE 'Dummy notifications inserted for user: %', v_user_id;
END $$;
