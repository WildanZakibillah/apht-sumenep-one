-- ============================================================
-- APHT Sumenep - Row Level Security (RLS) Policies
-- ============================================================
-- Jalankan SQL ini di Supabase SQL Editor (Dashboard > SQL Editor)
--
-- Roles:
--   super_admin  : Full access ke semua data
--   direktur     : Hanya bisa akses data pabriknya sendiri (factory_id di profiles)
--   service_role : Bypass RLS (digunakan untuk admin operations)
-- ============================================================

-- Helper function: get current user's role from profiles
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

-- Helper function: get current user's factory_id from profiles
CREATE OR REPLACE FUNCTION public.get_my_factory_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT factory_id FROM public.profiles WHERE id = auth.uid();
$$;

-- ============================================================
-- 1. PROFILES
-- ============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;

-- Semua authenticated user bisa melihat data profil 
-- (Mencegah infinite recursion dari get_my_role)
CREATE POLICY "profiles_select" ON public.profiles
  FOR SELECT USING (auth.role() = 'authenticated');

-- User hanya bisa update profil sendiri
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- ============================================================
-- 2. FACTORIES
-- ============================================================
ALTER TABLE public.factories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "factories_select" ON public.factories;
DROP POLICY IF EXISTS "factories_insert" ON public.factories;
DROP POLICY IF EXISTS "factories_update" ON public.factories;
DROP POLICY IF EXISTS "factories_delete" ON public.factories;

-- Super admin bisa lihat semua; direktur hanya pabriknya
CREATE POLICY "factories_select" ON public.factories
  FOR SELECT USING (
    get_my_role() = 'super_admin'
    OR id = get_my_factory_id()
  );

-- Hanya super admin yang bisa CRUD factories
CREATE POLICY "factories_insert" ON public.factories
  FOR INSERT WITH CHECK (get_my_role() = 'super_admin');

CREATE POLICY "factories_update" ON public.factories
  FOR UPDATE USING (get_my_role() = 'super_admin')
  WITH CHECK (get_my_role() = 'super_admin');

CREATE POLICY "factories_delete" ON public.factories
  FOR DELETE USING (get_my_role() = 'super_admin');

-- ============================================================
-- 3. PRODUCTIONS
-- ============================================================
ALTER TABLE public.productions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "productions_select" ON public.productions;
DROP POLICY IF EXISTS "productions_insert" ON public.productions;
DROP POLICY IF EXISTS "productions_update" ON public.productions;
DROP POLICY IF EXISTS "productions_delete" ON public.productions;

CREATE POLICY "productions_select" ON public.productions
  FOR SELECT USING (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

CREATE POLICY "productions_insert" ON public.productions
  FOR INSERT WITH CHECK (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

CREATE POLICY "productions_update" ON public.productions
  FOR UPDATE USING (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

CREATE POLICY "productions_delete" ON public.productions
  FOR DELETE USING (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

-- ============================================================
-- 4. CUKAI_ALLOCATIONS
-- ============================================================
ALTER TABLE public.cukai_allocations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cukai_allocations_select" ON public.cukai_allocations;
DROP POLICY IF EXISTS "cukai_allocations_insert" ON public.cukai_allocations;
DROP POLICY IF EXISTS "cukai_allocations_update" ON public.cukai_allocations;
DROP POLICY IF EXISTS "cukai_allocations_delete" ON public.cukai_allocations;

-- Semua yang berhak bisa lihat; direktur hanya pabriknya
CREATE POLICY "cukai_allocations_select" ON public.cukai_allocations
  FOR SELECT USING (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

-- Hanya super admin yang bisa mengelola alokasi cukai
CREATE POLICY "cukai_allocations_insert" ON public.cukai_allocations
  FOR INSERT WITH CHECK (get_my_role() = 'super_admin');

CREATE POLICY "cukai_allocations_update" ON public.cukai_allocations
  FOR UPDATE USING (get_my_role() = 'super_admin')
  WITH CHECK (get_my_role() = 'super_admin');

CREATE POLICY "cukai_allocations_delete" ON public.cukai_allocations
  FOR DELETE USING (get_my_role() = 'super_admin');

-- ============================================================
-- 5. CUKAI_REQUESTS
-- ============================================================
ALTER TABLE public.cukai_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cukai_requests_select" ON public.cukai_requests;
DROP POLICY IF EXISTS "cukai_requests_insert" ON public.cukai_requests;
DROP POLICY IF EXISTS "cukai_requests_update" ON public.cukai_requests;
DROP POLICY IF EXISTS "cukai_requests_delete" ON public.cukai_requests;

CREATE POLICY "cukai_requests_select" ON public.cukai_requests
  FOR SELECT USING (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

-- Direktur dan super admin bisa buat pengajuan
CREATE POLICY "cukai_requests_insert" ON public.cukai_requests
  FOR INSERT WITH CHECK (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

-- Hanya super admin yang bisa approve/reject (update)
CREATE POLICY "cukai_requests_update" ON public.cukai_requests
  FOR UPDATE USING (get_my_role() = 'super_admin')
  WITH CHECK (get_my_role() = 'super_admin');

CREATE POLICY "cukai_requests_delete" ON public.cukai_requests
  FOR DELETE USING (get_my_role() = 'super_admin');

-- ============================================================
-- 6. CUKAI_USAGE_LOG
-- ============================================================
ALTER TABLE public.cukai_usage_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cukai_usage_log_select" ON public.cukai_usage_log;
DROP POLICY IF EXISTS "cukai_usage_log_insert" ON public.cukai_usage_log;

CREATE POLICY "cukai_usage_log_select" ON public.cukai_usage_log
  FOR SELECT USING (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

CREATE POLICY "cukai_usage_log_insert" ON public.cukai_usage_log
  FOR INSERT WITH CHECK (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

-- ============================================================
-- 7. OUTGOING_GOODS
-- ============================================================
ALTER TABLE public.outgoing_goods ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "outgoing_goods_select" ON public.outgoing_goods;
DROP POLICY IF EXISTS "outgoing_goods_insert" ON public.outgoing_goods;
DROP POLICY IF EXISTS "outgoing_goods_update" ON public.outgoing_goods;
DROP POLICY IF EXISTS "outgoing_goods_delete" ON public.outgoing_goods;

CREATE POLICY "outgoing_goods_select" ON public.outgoing_goods
  FOR SELECT USING (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

CREATE POLICY "outgoing_goods_insert" ON public.outgoing_goods
  FOR INSERT WITH CHECK (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

CREATE POLICY "outgoing_goods_update" ON public.outgoing_goods
  FOR UPDATE USING (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

CREATE POLICY "outgoing_goods_delete" ON public.outgoing_goods
  FOR DELETE USING (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

-- ============================================================
-- 8. BRANDS
-- ============================================================
ALTER TABLE public.brands ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "brands_select" ON public.brands;
DROP POLICY IF EXISTS "brands_insert" ON public.brands;
DROP POLICY IF EXISTS "brands_update" ON public.brands;
DROP POLICY IF EXISTS "brands_delete" ON public.brands;

-- Semua bisa baca brands (data master)
CREATE POLICY "brands_select" ON public.brands
  FOR SELECT USING (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

CREATE POLICY "brands_insert" ON public.brands
  FOR INSERT WITH CHECK (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

CREATE POLICY "brands_update" ON public.brands
  FOR UPDATE USING (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

CREATE POLICY "brands_delete" ON public.brands
  FOR DELETE USING (get_my_role() = 'super_admin');

-- ============================================================
-- 9. PRODUCTS
-- ============================================================
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "products_select" ON public.products;
DROP POLICY IF EXISTS "products_insert" ON public.products;
DROP POLICY IF EXISTS "products_update" ON public.products;
DROP POLICY IF EXISTS "products_delete" ON public.products;

CREATE POLICY "products_select" ON public.products
  FOR SELECT USING (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

CREATE POLICY "products_insert" ON public.products
  FOR INSERT WITH CHECK (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

CREATE POLICY "products_update" ON public.products
  FOR UPDATE USING (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

CREATE POLICY "products_delete" ON public.products
  FOR DELETE USING (get_my_role() = 'super_admin');

-- ============================================================
-- 10. PRODUCT_TYPES (Data Master - Global Read)
-- ============================================================
ALTER TABLE public.product_types ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "product_types_select" ON public.product_types;
DROP POLICY IF EXISTS "product_types_insert" ON public.product_types;
DROP POLICY IF EXISTS "product_types_update" ON public.product_types;
DROP POLICY IF EXISTS "product_types_delete" ON public.product_types;

-- Semua authenticated user bisa baca product_types
CREATE POLICY "product_types_select" ON public.product_types
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- Hanya super admin yang bisa CRUD
CREATE POLICY "product_types_insert" ON public.product_types
  FOR INSERT WITH CHECK (get_my_role() = 'super_admin');

CREATE POLICY "product_types_update" ON public.product_types
  FOR UPDATE USING (get_my_role() = 'super_admin');

CREATE POLICY "product_types_delete" ON public.product_types
  FOR DELETE USING (get_my_role() = 'super_admin');

-- ============================================================
-- 11. HJE_RATES (Data Master - Global Read)
-- ============================================================
ALTER TABLE public.hje_rates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "hje_rates_select" ON public.hje_rates;
DROP POLICY IF EXISTS "hje_rates_insert" ON public.hje_rates;
DROP POLICY IF EXISTS "hje_rates_update" ON public.hje_rates;
DROP POLICY IF EXISTS "hje_rates_delete" ON public.hje_rates;

CREATE POLICY "hje_rates_select" ON public.hje_rates
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "hje_rates_insert" ON public.hje_rates
  FOR INSERT WITH CHECK (get_my_role() = 'super_admin');

CREATE POLICY "hje_rates_update" ON public.hje_rates
  FOR UPDATE USING (get_my_role() = 'super_admin');

CREATE POLICY "hje_rates_delete" ON public.hje_rates
  FOR DELETE USING (get_my_role() = 'super_admin');

-- ============================================================
-- 12. REGIONS (Data Master - Global Read)
-- ============================================================
ALTER TABLE public.regions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "regions_select" ON public.regions;
DROP POLICY IF EXISTS "regions_insert" ON public.regions;
DROP POLICY IF EXISTS "regions_update" ON public.regions;
DROP POLICY IF EXISTS "regions_delete" ON public.regions;

CREATE POLICY "regions_select" ON public.regions
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "regions_insert" ON public.regions
  FOR INSERT WITH CHECK (get_my_role() = 'super_admin');

CREATE POLICY "regions_update" ON public.regions
  FOR UPDATE USING (get_my_role() = 'super_admin');

CREATE POLICY "regions_delete" ON public.regions
  FOR DELETE USING (get_my_role() = 'super_admin');

-- ============================================================
-- 13. DISTRIBUTORS (Global Read, Super Admin Write)
-- ============================================================
ALTER TABLE public.distributors ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "distributors_select" ON public.distributors;
DROP POLICY IF EXISTS "distributors_insert" ON public.distributors;
DROP POLICY IF EXISTS "distributors_update" ON public.distributors;
DROP POLICY IF EXISTS "distributors_delete" ON public.distributors;

CREATE POLICY "distributors_select" ON public.distributors
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "distributors_insert" ON public.distributors
  FOR INSERT WITH CHECK (
    get_my_role() = 'super_admin'
    OR get_my_role() = 'direktur'
  );

CREATE POLICY "distributors_update" ON public.distributors
  FOR UPDATE USING (
    get_my_role() = 'super_admin'
    OR get_my_role() = 'direktur'
  );

CREATE POLICY "distributors_delete" ON public.distributors
  FOR DELETE USING (get_my_role() = 'super_admin');

-- ============================================================
-- 14. NOTIFICATIONS
-- ============================================================
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notifications_select" ON public.notifications;
DROP POLICY IF EXISTS "notifications_insert" ON public.notifications;
DROP POLICY IF EXISTS "notifications_update" ON public.notifications;

-- User bisa lihat notifikasi milik sendiri atau yang ditujukan ke semua
CREATE POLICY "notifications_select" ON public.notifications
  FOR SELECT USING (
    user_id = auth.uid()
    OR get_my_role() = 'super_admin'
  );

-- System/super admin bisa insert notifikasi
CREATE POLICY "notifications_insert" ON public.notifications
  FOR INSERT WITH CHECK (
    get_my_role() = 'super_admin'
    OR user_id = auth.uid()
  );

-- User bisa update (mark as read) notifikasi sendiri
CREATE POLICY "notifications_update" ON public.notifications
  FOR UPDATE USING (
    user_id = auth.uid()
    OR get_my_role() = 'super_admin'
  );

-- ============================================================
-- 15. REPORTS
-- ============================================================
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "reports_select" ON public.reports;
DROP POLICY IF EXISTS "reports_insert" ON public.reports;
DROP POLICY IF EXISTS "reports_update" ON public.reports;
DROP POLICY IF EXISTS "reports_delete" ON public.reports;

CREATE POLICY "reports_select" ON public.reports
  FOR SELECT USING (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

CREATE POLICY "reports_insert" ON public.reports
  FOR INSERT WITH CHECK (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

CREATE POLICY "reports_update" ON public.reports
  FOR UPDATE USING (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

CREATE POLICY "reports_delete" ON public.reports
  FOR DELETE USING (get_my_role() = 'super_admin');

-- ============================================================
-- 16. ARCHIVES
-- ============================================================
ALTER TABLE public.archives ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "archives_select" ON public.archives;
DROP POLICY IF EXISTS "archives_insert" ON public.archives;
DROP POLICY IF EXISTS "archives_update" ON public.archives;
DROP POLICY IF EXISTS "archives_delete" ON public.archives;

CREATE POLICY "archives_select" ON public.archives
  FOR SELECT USING (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

CREATE POLICY "archives_insert" ON public.archives
  FOR INSERT WITH CHECK (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

CREATE POLICY "archives_update" ON public.archives
  FOR UPDATE USING (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

CREATE POLICY "archives_delete" ON public.archives
  FOR DELETE USING (get_my_role() = 'super_admin');

-- ============================================================
-- 17. WAREHOUSES
-- ============================================================
ALTER TABLE public.warehouses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "warehouses_select" ON public.warehouses;
DROP POLICY IF EXISTS "warehouses_insert" ON public.warehouses;
DROP POLICY IF EXISTS "warehouses_update" ON public.warehouses;
DROP POLICY IF EXISTS "warehouses_delete" ON public.warehouses;

-- Semua authenticated user bisa lihat warehouses (data referensi)
-- Akses factory-scoped untuk yang terkait pabrik
CREATE POLICY "warehouses_select" ON public.warehouses
  FOR SELECT USING (
    get_my_role() = 'super_admin'
    OR factory_id = get_my_factory_id()
  );

CREATE POLICY "warehouses_insert" ON public.warehouses
  FOR INSERT WITH CHECK (get_my_role() = 'super_admin');

CREATE POLICY "warehouses_update" ON public.warehouses
  FOR UPDATE USING (get_my_role() = 'super_admin');

CREATE POLICY "warehouses_delete" ON public.warehouses
  FOR DELETE USING (get_my_role() = 'super_admin');

-- ============================================================
-- 18. NOTIFICATIONS - ADD MISSING DELETE POLICY
-- ============================================================
DROP POLICY IF EXISTS "notifications_delete" ON public.notifications;

-- User bisa hapus notifikasi milik sendiri, super admin bisa hapus semua
CREATE POLICY "notifications_delete" ON public.notifications
  FOR DELETE USING (
    user_id = auth.uid()
    OR get_my_role() = 'super_admin'
  );

-- ============================================================
-- DONE! Verifikasi dengan query berikut:
-- ============================================================
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
-- FROM pg_policies
-- WHERE schemaname = 'public'
-- ORDER BY tablename, policyname;
