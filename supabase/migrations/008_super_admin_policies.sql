-- ============================================================
-- Migration 008: Super Admin Full Access Policies
-- Jalankan di Supabase SQL Editor
-- ============================================================

-- Helper function: check if current user is super_admin
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role = 'super_admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function: get current user role
CREATE OR REPLACE FUNCTION public.user_role()
RETURNS TEXT AS $$
BEGIN
  RETURN (
    SELECT role FROM profiles
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function: get current user factory_id
CREATE OR REPLACE FUNCTION public.user_factory_id()
RETURNS UUID AS $$
BEGIN
  RETURN (
    SELECT factory_id FROM profiles
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- Enable RLS on all tables
-- ============================================================
ALTER TABLE factories ENABLE ROW LEVEL SECURITY;
ALTER TABLE warehouses ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE regions ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE hje_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE productions ENABLE ROW LEVEL SECURITY;
ALTER TABLE cukai_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE cukai_usage_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE cukai_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE distributors ENABLE ROW LEVEL SECURITY;
ALTER TABLE outgoing_goods ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE archives ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- FACTORIES: Super admin full access, others read only
-- ============================================================
DROP POLICY IF EXISTS "Super admin full access factories" ON factories;
CREATE POLICY "Super admin full access factories" ON factories
  FOR ALL USING (public.is_super_admin());

DROP POLICY IF EXISTS "Authenticated users can read factories" ON factories;
CREATE POLICY "Authenticated users can read factories" ON factories
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- ============================================================
-- WAREHOUSES: Super admin full access
-- ============================================================
DROP POLICY IF EXISTS "Super admin full access warehouses" ON warehouses;
CREATE POLICY "Super admin full access warehouses" ON warehouses
  FOR ALL USING (public.is_super_admin());

DROP POLICY IF EXISTS "Authenticated users can read warehouses" ON warehouses;
CREATE POLICY "Authenticated users can read warehouses" ON warehouses
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- ============================================================
-- PROFILES: Super admin full access, users can read own
-- ============================================================
DROP POLICY IF EXISTS "Super admin full access profiles" ON profiles;
CREATE POLICY "Super admin full access profiles" ON profiles
  FOR ALL USING (public.is_super_admin());

DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
CREATE POLICY "Users can read own profile" ON profiles
  FOR SELECT USING (id = auth.uid());

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (id = auth.uid());

-- ============================================================
-- REGIONS: Super admin full access, all can read
-- ============================================================
DROP POLICY IF EXISTS "Super admin full access regions" ON regions;
CREATE POLICY "Super admin full access regions" ON regions
  FOR ALL USING (public.is_super_admin());

DROP POLICY IF EXISTS "Authenticated users can read regions" ON regions;
CREATE POLICY "Authenticated users can read regions" ON regions
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- ============================================================
-- PRODUCT_TYPES: Super admin full access, all can read
-- ============================================================
DROP POLICY IF EXISTS "Super admin full access product_types" ON product_types;
CREATE POLICY "Super admin full access product_types" ON product_types
  FOR ALL USING (public.is_super_admin());

DROP POLICY IF EXISTS "Authenticated users can read product_types" ON product_types;
CREATE POLICY "Authenticated users can read product_types" ON product_types
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- ============================================================
-- BRANDS: Super admin full access, all can read
-- ============================================================
DROP POLICY IF EXISTS "Super admin full access brands" ON brands;
CREATE POLICY "Super admin full access brands" ON brands
  FOR ALL USING (public.is_super_admin());

DROP POLICY IF EXISTS "Authenticated users can read brands" ON brands;
CREATE POLICY "Authenticated users can read brands" ON brands
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- ============================================================
-- HJE_RATES: Super admin full access, all can read
-- ============================================================
DROP POLICY IF EXISTS "Super admin full access hje_rates" ON hje_rates;
CREATE POLICY "Super admin full access hje_rates" ON hje_rates
  FOR ALL USING (public.is_super_admin());

DROP POLICY IF EXISTS "Authenticated users can read hje_rates" ON hje_rates;
CREATE POLICY "Authenticated users can read hje_rates" ON hje_rates
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- ============================================================
-- PRODUCTS: Super admin full access, all can read
-- ============================================================
DROP POLICY IF EXISTS "Super admin full access products" ON products;
CREATE POLICY "Super admin full access products" ON products
  FOR ALL USING (public.is_super_admin());

DROP POLICY IF EXISTS "Authenticated users can read products" ON products;
CREATE POLICY "Authenticated users can read products" ON products
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- ============================================================
-- PRODUCTIONS: Super admin full access, factory users own data
-- ============================================================
DROP POLICY IF EXISTS "Super admin full access productions" ON productions;
CREATE POLICY "Super admin full access productions" ON productions
  FOR ALL USING (public.is_super_admin());

DROP POLICY IF EXISTS "Factory users can read own productions" ON productions;
CREATE POLICY "Factory users can read own productions" ON productions
  FOR SELECT USING (factory_id = public.user_factory_id());

DROP POLICY IF EXISTS "Factory users can insert productions" ON productions;
CREATE POLICY "Factory users can insert productions" ON productions
  FOR INSERT WITH CHECK (factory_id = public.user_factory_id());

-- ============================================================
-- CUKAI_ALLOCATIONS: Super admin full access, factory users read own
-- ============================================================
DROP POLICY IF EXISTS "Super admin full access cukai_allocations" ON cukai_allocations;
CREATE POLICY "Super admin full access cukai_allocations" ON cukai_allocations
  FOR ALL USING (public.is_super_admin());

DROP POLICY IF EXISTS "Factory users can read own allocations" ON cukai_allocations;
CREATE POLICY "Factory users can read own allocations" ON cukai_allocations
  FOR SELECT USING (factory_id = public.user_factory_id());

-- ============================================================
-- CUKAI_USAGE_LOG: Super admin full access, factory users own data
-- ============================================================
DROP POLICY IF EXISTS "Super admin full access cukai_usage_log" ON cukai_usage_log;
CREATE POLICY "Super admin full access cukai_usage_log" ON cukai_usage_log
  FOR ALL USING (public.is_super_admin());

DROP POLICY IF EXISTS "Factory users can read own usage log" ON cukai_usage_log;
CREATE POLICY "Factory users can read own usage log" ON cukai_usage_log
  FOR SELECT USING (factory_id = public.user_factory_id());

DROP POLICY IF EXISTS "Factory users can insert usage log" ON cukai_usage_log;
CREATE POLICY "Factory users can insert usage log" ON cukai_usage_log
  FOR INSERT WITH CHECK (factory_id = public.user_factory_id());

-- ============================================================
-- CUKAI_REQUESTS: Super admin full access, factory users own data
-- ============================================================
DROP POLICY IF EXISTS "Super admin full access cukai_requests" ON cukai_requests;
CREATE POLICY "Super admin full access cukai_requests" ON cukai_requests
  FOR ALL USING (public.is_super_admin());

DROP POLICY IF EXISTS "Factory users can read own requests" ON cukai_requests;
CREATE POLICY "Factory users can read own requests" ON cukai_requests
  FOR SELECT USING (factory_id = public.user_factory_id());

DROP POLICY IF EXISTS "Factory users can insert requests" ON cukai_requests;
CREATE POLICY "Factory users can insert requests" ON cukai_requests
  FOR INSERT WITH CHECK (factory_id = public.user_factory_id());

-- ============================================================
-- DISTRIBUTORS: Super admin full access, all can read
-- ============================================================
DROP POLICY IF EXISTS "Super admin full access distributors" ON distributors;
CREATE POLICY "Super admin full access distributors" ON distributors
  FOR ALL USING (public.is_super_admin());

DROP POLICY IF EXISTS "Authenticated users can read distributors" ON distributors;
CREATE POLICY "Authenticated users can read distributors" ON distributors
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- ============================================================
-- OUTGOING_GOODS: Super admin full access, factory users own data
-- ============================================================
DROP POLICY IF EXISTS "Super admin full access outgoing_goods" ON outgoing_goods;
CREATE POLICY "Super admin full access outgoing_goods" ON outgoing_goods
  FOR ALL USING (public.is_super_admin());

DROP POLICY IF EXISTS "Factory users can read own outgoing" ON outgoing_goods;
CREATE POLICY "Factory users can read own outgoing" ON outgoing_goods
  FOR SELECT USING (factory_id = public.user_factory_id());

DROP POLICY IF EXISTS "Factory users can insert outgoing" ON outgoing_goods;
CREATE POLICY "Factory users can insert outgoing" ON outgoing_goods
  FOR INSERT WITH CHECK (factory_id = public.user_factory_id());

-- ============================================================
-- REPORTS: Super admin full access, factory users own data
-- ============================================================
DROP POLICY IF EXISTS "Super admin full access reports" ON reports;
CREATE POLICY "Super admin full access reports" ON reports
  FOR ALL USING (public.is_super_admin());

DROP POLICY IF EXISTS "Factory users can read own reports" ON reports;
CREATE POLICY "Factory users can read own reports" ON reports
  FOR SELECT USING (factory_id = public.user_factory_id());

DROP POLICY IF EXISTS "Factory users can insert reports" ON reports;
CREATE POLICY "Factory users can insert reports" ON reports
  FOR INSERT WITH CHECK (factory_id = public.user_factory_id());

-- ============================================================
-- NOTIFICATIONS: Super admin full access, users own notifications
-- ============================================================
DROP POLICY IF EXISTS "Super admin full access notifications" ON notifications;
CREATE POLICY "Super admin full access notifications" ON notifications
  FOR ALL USING (public.is_super_admin());

DROP POLICY IF EXISTS "Users can read own notifications" ON notifications;
CREATE POLICY "Users can read own notifications" ON notifications
  FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
CREATE POLICY "Users can update own notifications" ON notifications
  FOR UPDATE USING (user_id = auth.uid());

-- ============================================================
-- ARCHIVES: Super admin full access, all can read
-- ============================================================
DROP POLICY IF EXISTS "Super admin full access archives" ON archives;
CREATE POLICY "Super admin full access archives" ON archives
  FOR ALL USING (public.is_super_admin());

DROP POLICY IF EXISTS "Authenticated users can read archives" ON archives;
CREATE POLICY "Authenticated users can read archives" ON archives
  FOR SELECT USING (auth.uid() IS NOT NULL);
