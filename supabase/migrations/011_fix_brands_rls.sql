-- Fix brands RLS: ensure all authenticated users can read ALL brands
-- Drop old restrictive policies from 002
DROP POLICY IF EXISTS "Authenticated users can view brands" ON brands;
DROP POLICY IF EXISTS "Factory users can manage own brands" ON brands;

-- Keep super admin full access (from 008)
DROP POLICY IF EXISTS "Super admin full access brands" ON brands;
CREATE POLICY "Super admin full access brands" ON brands
  FOR ALL USING (public.is_super_admin());

-- All authenticated users can read all brands (no factory restriction)
DROP POLICY IF EXISTS "Authenticated users can read brands" ON brands;
CREATE POLICY "Authenticated users can read brands" ON brands
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- Factory users can insert/update/delete only their own brands
DROP POLICY IF EXISTS "Factory users manage own brands" ON brands;
CREATE POLICY "Factory users manage own brands" ON brands
  FOR ALL
  USING (factory_id = public.user_factory_id())
  WITH CHECK (factory_id = public.user_factory_id());


-- ============================================================
-- SEED BRANDS FOR ALL FACTORIES
-- ============================================================

-- FCT-002: CV Tembakau Emas
INSERT INTO brands (name, product_type_id, factory_id) VALUES
  ('Emas Filter', (SELECT id FROM product_types WHERE name = 'SKM Filter Premium'), (SELECT id FROM factories WHERE code = 'FCT-002')),
  ('Emas Kretek', (SELECT id FROM product_types WHERE name = 'SKT Kretek Tangan'), (SELECT id FROM factories WHERE code = 'FCT-002'))
ON CONFLICT DO NOTHING;

-- FCT-003: PD Sinar Makmur
INSERT INTO brands (name, product_type_id, factory_id) VALUES
  ('Sinar Merah', (SELECT id FROM product_types WHERE name = 'SKT Kretek Tangan'), (SELECT id FROM factories WHERE code = 'FCT-003')),
  ('Sinar Putih', (SELECT id FROM product_types WHERE name = 'SPM Putih Mesin'), (SELECT id FROM factories WHERE code = 'FCT-003'))
ON CONFLICT DO NOTHING;

-- FCT-004: PT Gudang Daun
INSERT INTO brands (name, product_type_id, factory_id) VALUES
  ('Gudang Hijau', (SELECT id FROM product_types WHERE name = 'SKM Filter Premium'), (SELECT id FROM factories WHERE code = 'FCT-004')),
  ('Daun Mas', (SELECT id FROM product_types WHERE name = 'SKM Filter Premium'), (SELECT id FROM factories WHERE code = 'FCT-004'))
ON CONFLICT DO NOTHING;

-- FCT-005: CV Aroma Jaya
INSERT INTO brands (name, product_type_id, factory_id) VALUES
  ('Aroma Kretek', (SELECT id FROM product_types WHERE name = 'SKT Kretek Tangan'), (SELECT id FROM factories WHERE code = 'FCT-005')),
  ('Jaya Filter', (SELECT id FROM product_types WHERE name = 'SKM Filter Premium'), (SELECT id FROM factories WHERE code = 'FCT-005'))
ON CONFLICT DO NOTHING;

-- FCT-006: PT Cipta Rasa
INSERT INTO brands (name, product_type_id, factory_id) VALUES
  ('Cipta Mild', (SELECT id FROM product_types WHERE name = 'SKM Filter Premium'), (SELECT id FROM factories WHERE code = 'FCT-006')),
  ('Rasa Kretek', (SELECT id FROM product_types WHERE name = 'SKT Kretek Tangan'), (SELECT id FROM factories WHERE code = 'FCT-006'))
ON CONFLICT DO NOTHING;

-- FCT-007: CV Sinar Harapan
INSERT INTO brands (name, product_type_id, factory_id) VALUES
  ('Harapan Biru', (SELECT id FROM product_types WHERE name = 'SKT Kretek Tangan'), (SELECT id FROM factories WHERE code = 'FCT-007')),
  ('Sinar Jaya', (SELECT id FROM product_types WHERE name = 'SPM Putih Mesin'), (SELECT id FROM factories WHERE code = 'FCT-007'))
ON CONFLICT DO NOTHING;

-- FCT-008: PT Nusantara Tobacco
INSERT INTO brands (name, product_type_id, factory_id) VALUES
  ('Nusantara Gold', (SELECT id FROM product_types WHERE name = 'SKM Filter Premium'), (SELECT id FROM factories WHERE code = 'FCT-008')),
  ('Nusantara Kretek', (SELECT id FROM product_types WHERE name = 'SKT Kretek Tangan'), (SELECT id FROM factories WHERE code = 'FCT-008'))
ON CONFLICT DO NOTHING;

-- FCT-009: CV Tembakau Wangi
INSERT INTO brands (name, product_type_id, factory_id) VALUES
  ('Wangi Kretek', (SELECT id FROM product_types WHERE name = 'SKT Kretek Tangan'), (SELECT id FROM factories WHERE code = 'FCT-009')),
  ('Wangi Mild', (SELECT id FROM product_types WHERE name = 'SKM Filter Premium'), (SELECT id FROM factories WHERE code = 'FCT-009'))
ON CONFLICT DO NOTHING;

-- FCT-010: PD Karya Maju
INSERT INTO brands (name, product_type_id, factory_id) VALUES
  ('Karya Filter', (SELECT id FROM product_types WHERE name = 'SKM Filter Premium'), (SELECT id FROM factories WHERE code = 'FCT-010')),
  ('Maju Kretek', (SELECT id FROM product_types WHERE name = 'SKT Kretek Tangan'), (SELECT id FROM factories WHERE code = 'FCT-010'))
ON CONFLICT DO NOTHING;

-- FCT-011: PT Sejahtera
INSERT INTO brands (name, product_type_id, factory_id) VALUES
  ('Sejahtera Kretek', (SELECT id FROM product_types WHERE name = 'SKT Kretek Tangan'), (SELECT id FROM factories WHERE code = 'FCT-011')),
  ('Sejahtera Putih', (SELECT id FROM product_types WHERE name = 'SPM Putih Mesin'), (SELECT id FROM factories WHERE code = 'FCT-011'))
ON CONFLICT DO NOTHING;


-- ============================================================
-- SEED PRODUCTIONS FOR MULTIPLE FACTORIES (current month)
-- So "Top Merek Produksi" shows brands from various factories
-- ============================================================

-- Make product_id and created_by nullable for seed data
ALTER TABLE productions ALTER COLUMN product_id DROP NOT NULL;
ALTER TABLE productions ALTER COLUMN created_by DROP NOT NULL;
ALTER TABLE productions ALTER COLUMN hje SET DEFAULT 0;
ALTER TABLE productions ALTER COLUMN isi SET DEFAULT 12;

INSERT INTO productions (factory_id, doc_number, doc_date, merek, jenis, hje, isi, jumlah_kemasan, jumlah_isi) VALUES
  -- FCT-002: CV Tembakau Emas
  ((SELECT id FROM factories WHERE code = 'FCT-002'), 'PROD-002-001', CURRENT_DATE, 'Emas Filter', 'SKM', 10500, 16, 1200, 19200),
  ((SELECT id FROM factories WHERE code = 'FCT-002'), 'PROD-002-002', CURRENT_DATE - INTERVAL '2 days', 'Emas Kretek', 'SKT', 9800, 12, 800, 9600),
  -- FCT-004: PT Gudang Daun
  ((SELECT id FROM factories WHERE code = 'FCT-004'), 'PROD-004-001', CURRENT_DATE - INTERVAL '1 day', 'Gudang Hijau', 'SKM', 11000, 16, 1500, 24000),
  ((SELECT id FROM factories WHERE code = 'FCT-004'), 'PROD-004-002', CURRENT_DATE - INTERVAL '3 days', 'Daun Mas', 'SKM', 10200, 16, 900, 14400),
  -- FCT-005: CV Aroma Jaya
  ((SELECT id FROM factories WHERE code = 'FCT-005'), 'PROD-005-001', CURRENT_DATE, 'Aroma Kretek', 'SKT', 9500, 12, 1100, 13200),
  ((SELECT id FROM factories WHERE code = 'FCT-005'), 'PROD-005-002', CURRENT_DATE - INTERVAL '4 days', 'Jaya Filter', 'SKM', 10800, 16, 700, 11200),
  -- FCT-006: PT Cipta Rasa
  ((SELECT id FROM factories WHERE code = 'FCT-006'), 'PROD-006-001', CURRENT_DATE - INTERVAL '2 days', 'Cipta Mild', 'SKM', 11500, 16, 1800, 28800),
  ((SELECT id FROM factories WHERE code = 'FCT-006'), 'PROD-006-002', CURRENT_DATE, 'Rasa Kretek', 'SKT', 9200, 12, 600, 7200),
  -- FCT-008: PT Nusantara Tobacco
  ((SELECT id FROM factories WHERE code = 'FCT-008'), 'PROD-008-001', CURRENT_DATE - INTERVAL '1 day', 'Nusantara Gold', 'SKM', 12000, 16, 2000, 32000),
  ((SELECT id FROM factories WHERE code = 'FCT-008'), 'PROD-008-002', CURRENT_DATE - INTERVAL '3 days', 'Nusantara Kretek', 'SKT', 9800, 12, 950, 11400),
  -- FCT-009: CV Tembakau Wangi
  ((SELECT id FROM factories WHERE code = 'FCT-009'), 'PROD-009-001', CURRENT_DATE, 'Wangi Kretek', 'SKT', 9600, 12, 850, 10200),
  ((SELECT id FROM factories WHERE code = 'FCT-009'), 'PROD-009-002', CURRENT_DATE - INTERVAL '2 days', 'Wangi Mild', 'SKM', 10900, 16, 1300, 20800),
  -- FCT-011: PT Sejahtera
  ((SELECT id FROM factories WHERE code = 'FCT-011'), 'PROD-011-001', CURRENT_DATE - INTERVAL '1 day', 'Sejahtera Kretek', 'SKT', 9400, 12, 750, 9000),
  ((SELECT id FROM factories WHERE code = 'FCT-011'), 'PROD-011-002', CURRENT_DATE, 'Sejahtera Putih', 'SPM', 8500, 20, 500, 10000);
