-- ============================================================
-- APHT Sumenep One — Initial Database Schema
-- Migration 001: Core Tables
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. FACTORIES (Pabrik)
-- ============================================================
CREATE TABLE IF NOT EXISTS factories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  golongan TEXT NOT NULL,
  address TEXT,
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'inactive')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE factories IS 'Registered tobacco factories under APHT Sumenep jurisdiction';

-- ============================================================
-- 2. WAREHOUSES (Gudang)
-- ============================================================
CREATE TABLE IF NOT EXISTS warehouses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT,
  factory_id UUID REFERENCES factories(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE warehouses IS 'Physical warehouse locations linked to factories';

-- ============================================================
-- 3. PROFILES (extends auth.users)
-- ============================================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  role TEXT NOT NULL DEFAULT 'staf_lapangan'
    CHECK (role IN ('super_admin', 'admin_pabrik', 'staf_lapangan', 'direktur')),
  factory_id UUID REFERENCES factories(id) ON DELETE SET NULL,
  warehouse_id UUID REFERENCES warehouses(id) ON DELETE SET NULL,
  avatar_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE profiles IS 'Extended user profiles with role and factory assignment';

-- ============================================================
-- 4. REGIONS (Wilayah Distribusi)
-- ============================================================
CREATE TABLE IF NOT EXISTS regions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE regions IS 'Distribution regions / marketing territories';

-- ============================================================
-- 5. PRODUCT TYPES (Jenis Produk: SKT, SKM, SPM)
-- ============================================================
CREATE TABLE IF NOT EXISTS product_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('SKT', 'SKM', 'SPM')),
  isi_per_pak INT NOT NULL DEFAULT 12,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE product_types IS 'Master data for tobacco product categories';

-- ============================================================
-- 6. BRANDS (Merek)
-- ============================================================
CREATE TABLE IF NOT EXISTS brands (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  product_type_id UUID REFERENCES product_types(id) ON DELETE SET NULL,
  factory_id UUID REFERENCES factories(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE brands IS 'Tobacco product brands tied to factory and product type';

-- ============================================================
-- 7. HJE RATES (Harga Jual Eceran)
-- ============================================================
CREATE TABLE IF NOT EXISTS hje_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_type_id UUID REFERENCES product_types(id) ON DELETE CASCADE,
  golongan TEXT NOT NULL,
  tarif NUMERIC(12,2) NOT NULL,
  effective_date DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE hje_rates IS 'Government-regulated retail prices per product type and golongan';

-- ============================================================
-- 8. PRODUCTS (Produk detail)
-- ============================================================
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  brand_id UUID REFERENCES brands(id) ON DELETE CASCADE NOT NULL,
  product_type_id UUID REFERENCES product_types(id) ON DELETE CASCADE NOT NULL,
  hje NUMERIC(12,2) NOT NULL,
  isi INT NOT NULL DEFAULT 12,
  satuan TEXT NOT NULL DEFAULT 'btg',
  bahan_kemasan TEXT,
  factory_id UUID REFERENCES factories(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE products IS 'Specific product SKU with packaging and pricing details';

-- ============================================================
-- 9. PRODUCTIONS (Catatan Produksi)
-- ============================================================
CREATE TABLE IF NOT EXISTS productions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doc_number TEXT NOT NULL,
  doc_date DATE NOT NULL,
  product_id UUID REFERENCES products(id) ON DELETE RESTRICT NOT NULL,
  factory_id UUID REFERENCES factories(id) ON DELETE CASCADE NOT NULL,
  jenis TEXT NOT NULL CHECK (jenis IN ('SKT', 'SKM', 'SPM')),
  merek TEXT NOT NULL,
  hje NUMERIC(12,2) NOT NULL,
  bahan_kemasan TEXT,
  isi INT NOT NULL,
  satuan TEXT NOT NULL DEFAULT 'btg',
  jumlah_kemasan INT NOT NULL,
  jumlah_isi INT NOT NULL,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE productions IS 'Daily production records entered via mobile app';

-- ============================================================
-- 10. CUKAI ALLOCATIONS (Alokasi Pita Cukai)
-- ============================================================
CREATE TABLE IF NOT EXISTS cukai_allocations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  factory_id UUID REFERENCES factories(id) ON DELETE CASCADE NOT NULL,
  quota INT NOT NULL,
  used INT NOT NULL DEFAULT 0,
  damaged INT NOT NULL DEFAULT 0,
  remaining INT GENERATED ALWAYS AS (quota - used - damaged) STORED,
  period TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE cukai_allocations IS 'Excise stamp quota allocations per factory per period';

-- ============================================================
-- 11. CUKAI USAGE LOG (Log Pemakaian Pita Cukai)
-- ============================================================
CREATE TABLE IF NOT EXISTS cukai_usage_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  allocation_id UUID REFERENCES cukai_allocations(id) ON DELETE CASCADE NOT NULL,
  factory_id UUID REFERENCES factories(id) ON DELETE CASCADE NOT NULL,
  usage_date DATE NOT NULL,
  used_amount INT NOT NULL DEFAULT 0,
  added_amount INT NOT NULL DEFAULT 0,
  notes TEXT,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE cukai_usage_log IS 'Individual excise stamp usage/addition entries';

-- ============================================================
-- 12. CUKAI REQUESTS (Pengajuan Pita Cukai)
-- ============================================================
CREATE TABLE IF NOT EXISTS cukai_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doc_number TEXT,
  request_date DATE NOT NULL,
  factory_id UUID REFERENCES factories(id) ON DELETE CASCADE NOT NULL,
  jenis_pengajuan TEXT NOT NULL
    CHECK (jenis_pengajuan IN ('AWAL', 'TAMBAHAN', 'PELENGKAP')),
  lokasi_penyediaan TEXT NOT NULL DEFAULT 'KPPBC',
  jenis_hasil_tembakau TEXT NOT NULL,
  kode_personalisasi TEXT,
  seri TEXT,
  warna TEXT,
  tarif_cukai NUMERIC(12,2),
  hje NUMERIC(12,2),
  isi_per_bks INT,
  jumlah_lembar INT,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE cukai_requests IS 'Excise stamp order requests submitted by factory admins';

-- ============================================================
-- 13. DISTRIBUTORS (Distributor / Pelanggan)
-- ============================================================
CREATE TABLE IF NOT EXISTS distributors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  region_id UUID REFERENCES regions(id) ON DELETE SET NULL,
  contact_info TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE distributors IS 'Distribution partners and customers';

-- ============================================================
-- 14. OUTGOING GOODS (Barang Keluar)
-- ============================================================
CREATE TABLE IF NOT EXISTS outgoing_goods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_date DATE NOT NULL,
  customer_name TEXT NOT NULL,
  region_id UUID REFERENCES regions(id) ON DELETE SET NULL,
  product_id UUID REFERENCES products(id) ON DELETE RESTRICT NOT NULL,
  factory_id UUID REFERENCES factories(id) ON DELETE CASCADE NOT NULL,
  volume INT NOT NULL,
  total_value NUMERIC(15,2) NOT NULL,
  payment_method TEXT NOT NULL DEFAULT 'tunai'
    CHECK (payment_method IN ('tunai', 'kredit')),
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE outgoing_goods IS 'Outgoing shipment records with payment tracking';

-- ============================================================
-- 15. REPORTS (Laporan Bulanan)
-- ============================================================
CREATE TABLE IF NOT EXISTS reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  factory_id UUID REFERENCES factories(id) ON DELETE CASCADE NOT NULL,
  period TEXT NOT NULL,
  date_sent TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'verified', 'rejected')),
  status_label TEXT,
  ttd_direktur BOOLEAN NOT NULL DEFAULT false,
  validasi_apht BOOLEAN NOT NULL DEFAULT false,
  verified_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  verified_at TIMESTAMPTZ,
  rejection_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE reports IS 'Monthly factory reports with multi-step verification workflow';

-- ============================================================
-- 16. NOTIFICATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'info'
    CHECK (type IN ('info', 'warning', 'success', 'error')),
  icon TEXT,
  is_read BOOLEAN NOT NULL DEFAULT false,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE notifications IS 'In-app notification feed for users';

-- ============================================================
-- 17. ARCHIVES (Arsip Digital)
-- ============================================================
CREATE TABLE IF NOT EXISTS archives (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id UUID REFERENCES reports(id) ON DELETE SET NULL,
  factory_id UUID REFERENCES factories(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  period TEXT NOT NULL,
  verified_date DATE,
  file_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE archives IS 'Verified and archived reports available for download';

-- ============================================================
-- INDEXES for common query patterns
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_profiles_factory ON profiles(factory_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_productions_factory ON productions(factory_id);
CREATE INDEX IF NOT EXISTS idx_productions_date ON productions(doc_date);
CREATE INDEX IF NOT EXISTS idx_cukai_allocations_factory ON cukai_allocations(factory_id);
CREATE INDEX IF NOT EXISTS idx_cukai_usage_factory ON cukai_usage_log(factory_id);
CREATE INDEX IF NOT EXISTS idx_outgoing_factory ON outgoing_goods(factory_id);
CREATE INDEX IF NOT EXISTS idx_outgoing_date ON outgoing_goods(transaction_date);
CREATE INDEX IF NOT EXISTS idx_reports_factory ON reports(factory_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_archives_factory ON archives(factory_id);

-- ============================================================
-- updated_at auto-trigger function
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all tables with that column
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN
    SELECT table_name FROM information_schema.columns
    WHERE column_name = 'updated_at'
      AND table_schema = 'public'
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS set_updated_at ON %I', t);
    EXECUTE format(
      'CREATE TRIGGER set_updated_at BEFORE UPDATE ON %I
       FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()',
      t
    );
  END LOOP;
END;
$$;

-- ============================================================
-- 18. STORAGE BUCKETS (Avatars)
-- ============================================================

-- Create avatars bucket if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Drop existing policies if any to avoid errors on re-run
DROP POLICY IF EXISTS "Avatar Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Avatar Auth Upload" ON storage.objects;
DROP POLICY IF EXISTS "Avatar Auth Update" ON storage.objects;
DROP POLICY IF EXISTS "Avatar Auth Delete" ON storage.objects;

-- Allow public read access
CREATE POLICY "Avatar Public Access" ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Allow authenticated users to upload avatars
CREATE POLICY "Avatar Auth Upload" ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');

-- Allow authenticated users to update avatars
CREATE POLICY "Avatar Auth Update" ON storage.objects FOR UPDATE
USING (bucket_id = 'avatars' AND auth.role() = 'authenticated');

-- Allow authenticated users to delete avatars
CREATE POLICY "Avatar Auth Delete" ON storage.objects FOR DELETE
USING (bucket_id = 'avatars' AND auth.role() = 'authenticated');
