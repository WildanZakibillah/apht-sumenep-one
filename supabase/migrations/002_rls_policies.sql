-- ============================================================
-- APHT Sumenep One — Row Level Security Policies
-- Migration 002: RLS for all tables
-- ============================================================

-- ============================================================
-- Helper function: get current user's role
-- ============================================================
CREATE OR REPLACE FUNCTION auth.user_role()
RETURNS TEXT AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Helper function: get current user's factory_id
CREATE OR REPLACE FUNCTION auth.user_factory_id()
RETURNS UUID AS $$
  SELECT factory_id FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Helper: check if user is super_admin
CREATE OR REPLACE FUNCTION auth.is_super_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'super_admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ============================================================
-- PROFILES
-- ============================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (id = auth.uid());

CREATE POLICY "Super admin can view all profiles"
  ON profiles FOR SELECT
  USING (auth.is_super_admin());

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY "Super admin can manage all profiles"
  ON profiles FOR ALL
  USING (auth.is_super_admin());

-- ============================================================
-- FACTORIES
-- ============================================================
ALTER TABLE factories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view factories"
  ON factories FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Super admin can manage factories"
  ON factories FOR ALL
  USING (auth.is_super_admin());

-- ============================================================
-- WAREHOUSES
-- ============================================================
ALTER TABLE warehouses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view warehouses"
  ON warehouses FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Super admin can manage warehouses"
  ON warehouses FOR ALL
  USING (auth.is_super_admin());

-- ============================================================
-- REGIONS
-- ============================================================
ALTER TABLE regions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view regions"
  ON regions FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Super admin can manage regions"
  ON regions FOR ALL
  USING (auth.is_super_admin());

-- ============================================================
-- PRODUCT_TYPES
-- ============================================================
ALTER TABLE product_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view product types"
  ON product_types FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Super admin can manage product types"
  ON product_types FOR ALL
  USING (auth.is_super_admin());

-- ============================================================
-- BRANDS
-- ============================================================
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view brands"
  ON brands FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Factory users can manage own brands"
  ON brands FOR ALL
  USING (
    factory_id = auth.user_factory_id()
    OR auth.is_super_admin()
  );

-- ============================================================
-- HJE_RATES
-- ============================================================
ALTER TABLE hje_rates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view HJE rates"
  ON hje_rates FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Super admin can manage HJE rates"
  ON hje_rates FOR ALL
  USING (auth.is_super_admin());

-- ============================================================
-- PRODUCTS
-- ============================================================
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view products"
  ON products FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Factory users can manage own products"
  ON products FOR ALL
  USING (
    factory_id = auth.user_factory_id()
    OR auth.is_super_admin()
  );

-- ============================================================
-- PRODUCTIONS
-- ============================================================
ALTER TABLE productions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Factory users can view own productions"
  ON productions FOR SELECT
  USING (
    factory_id = auth.user_factory_id()
    OR auth.is_super_admin()
  );

CREATE POLICY "Factory users can create productions"
  ON productions FOR INSERT
  WITH CHECK (
    factory_id = auth.user_factory_id()
    AND auth.user_role() IN ('admin_pabrik', 'staf_lapangan')
  );

CREATE POLICY "Super admin full access to productions"
  ON productions FOR ALL
  USING (auth.is_super_admin());

-- ============================================================
-- CUKAI_ALLOCATIONS
-- ============================================================
ALTER TABLE cukai_allocations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Factory users can view own allocations"
  ON cukai_allocations FOR SELECT
  USING (
    factory_id = auth.user_factory_id()
    OR auth.is_super_admin()
  );

CREATE POLICY "Super admin can manage allocations"
  ON cukai_allocations FOR ALL
  USING (auth.is_super_admin());

-- ============================================================
-- CUKAI_USAGE_LOG
-- ============================================================
ALTER TABLE cukai_usage_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Factory users can view own usage log"
  ON cukai_usage_log FOR SELECT
  USING (
    factory_id = auth.user_factory_id()
    OR auth.is_super_admin()
  );

CREATE POLICY "Factory users can create usage entries"
  ON cukai_usage_log FOR INSERT
  WITH CHECK (
    factory_id = auth.user_factory_id()
    AND auth.user_role() IN ('admin_pabrik', 'staf_lapangan')
  );

CREATE POLICY "Super admin full access to usage log"
  ON cukai_usage_log FOR ALL
  USING (auth.is_super_admin());

-- ============================================================
-- CUKAI_REQUESTS
-- ============================================================
ALTER TABLE cukai_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Factory users can view own requests"
  ON cukai_requests FOR SELECT
  USING (
    factory_id = auth.user_factory_id()
    OR auth.is_super_admin()
  );

CREATE POLICY "Factory admin can create requests"
  ON cukai_requests FOR INSERT
  WITH CHECK (
    factory_id = auth.user_factory_id()
    AND auth.user_role() IN ('admin_pabrik')
  );

CREATE POLICY "Super admin can manage requests"
  ON cukai_requests FOR ALL
  USING (auth.is_super_admin());

-- ============================================================
-- DISTRIBUTORS
-- ============================================================
ALTER TABLE distributors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view distributors"
  ON distributors FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Super admin can manage distributors"
  ON distributors FOR ALL
  USING (auth.is_super_admin());

-- ============================================================
-- OUTGOING_GOODS
-- ============================================================
ALTER TABLE outgoing_goods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Factory users can view own outgoing goods"
  ON outgoing_goods FOR SELECT
  USING (
    factory_id = auth.user_factory_id()
    OR auth.is_super_admin()
  );

CREATE POLICY "Factory users can create outgoing entries"
  ON outgoing_goods FOR INSERT
  WITH CHECK (
    factory_id = auth.user_factory_id()
    AND auth.user_role() IN ('admin_pabrik', 'staf_lapangan')
  );

CREATE POLICY "Super admin full access to outgoing goods"
  ON outgoing_goods FOR ALL
  USING (auth.is_super_admin());

-- ============================================================
-- REPORTS
-- ============================================================
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Factory users can view own reports"
  ON reports FOR SELECT
  USING (
    factory_id = auth.user_factory_id()
    OR auth.is_super_admin()
  );

CREATE POLICY "Factory admin can create reports"
  ON reports FOR INSERT
  WITH CHECK (
    factory_id = auth.user_factory_id()
    AND auth.user_role() IN ('admin_pabrik', 'direktur')
  );

CREATE POLICY "Super admin can manage reports"
  ON reports FOR ALL
  USING (auth.is_super_admin());

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own notifications (mark read)"
  ON notifications FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "System and super admin can insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (auth.is_super_admin() OR user_id = auth.uid());

-- ============================================================
-- ARCHIVES
-- ============================================================
ALTER TABLE archives ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view archives"
  ON archives FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Super admin can manage archives"
  ON archives FOR ALL
  USING (auth.is_super_admin());
