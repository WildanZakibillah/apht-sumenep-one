-- ============================================================
-- APHT Sumenep One — Seed Data
-- Migration 004: Initial data from existing mock/hardcoded values
-- ============================================================

-- ============================================================
-- REGIONS
-- ============================================================
INSERT INTO regions (name) VALUES
  ('Jawa Timur'),
  ('Jawa Tengah'),
  ('DKI Jakarta'),
  ('Jawa Barat'),
  ('Bali');

-- ============================================================
-- FACTORIES (from mockSupabase.js MOCK_FACTORIES)
-- ============================================================
INSERT INTO factories (code, name, golongan, address, status) VALUES
  ('FCT-001', 'PT Bintang Timur Semesta', 'SKT-I', 'Jl. Industri Raya 45, Sumenep', 'active'),
  ('FCT-002', 'CV Tembakau Emas', 'SKM-II', 'Jl. Tembakau No. 12, Sumenep', 'active'),
  ('FCT-003', 'PD Sinar Makmur', 'SKT-II', 'Jl. Makmur No. 8, Sumenep', 'inactive'),
  ('FCT-004', 'PT Gudang Daun', 'SKM-I', 'Jl. Gudang Daun No. 3, Sumenep', 'active'),
  ('FCT-005', 'CV Aroma Jaya', 'SKT-I', 'Jl. Aroma No. 15, Sumenep', 'active'),
  ('FCT-006', 'PT Cipta Rasa', 'SKM-II', 'Jl. Cipta Rasa No. 20, Sumenep', 'active'),
  ('FCT-007', 'CV Sinar Harapan', 'SKT-II', 'Jl. Harapan No. 5, Sumenep', 'inactive'),
  ('FCT-008', 'PT Nusantara Tobacco', 'SKM-I', 'Jl. Nusantara No. 10, Sumenep', 'active'),
  ('FCT-009', 'CV Tembakau Wangi', 'SKT-I', 'Jl. Wangi No. 7, Sumenep', 'active'),
  ('FCT-010', 'PD Karya Maju', 'SKM-II', 'Jl. Karya Maju No. 2, Sumenep', 'inactive'),
  ('FCT-011', 'PT Sejahtera', 'SKT-II', 'Jl. Sejahtera No. 1, Sumenep', 'active');

-- ============================================================
-- WAREHOUSES
-- ============================================================
INSERT INTO warehouses (name, address, factory_id) VALUES
  ('Gudang 1', 'Jl. Industri Raya 45', (SELECT id FROM factories WHERE code = 'FCT-001'));

-- ============================================================
-- PRODUCT TYPES (Data Master)
-- ============================================================
INSERT INTO product_types (name, category, isi_per_pak) VALUES
  ('SKM Filter Premium', 'SKM', 16),
  ('SKT Kretek Tangan', 'SKT', 12),
  ('SPM Putih Mesin', 'SPM', 20);

-- ============================================================
-- BRANDS
-- ============================================================
INSERT INTO brands (name, product_type_id, factory_id) VALUES
  ('DEN HAAG', (SELECT id FROM product_types WHERE name = 'SKT Kretek Tangan'), (SELECT id FROM factories WHERE code = 'FCT-001')),
  ('Karaoke Merah', (SELECT id FROM product_types WHERE name = 'SKT Kretek Tangan'), (SELECT id FROM factories WHERE code = 'FCT-001')),
  ('Karaoke Biru 12', (SELECT id FROM product_types WHERE name = 'SKT Kretek Tangan'), (SELECT id FROM factories WHERE code = 'FCT-001'));

-- ============================================================
-- PRODUCTS
-- ============================================================
INSERT INTO products (brand_id, product_type_id, hje, isi, satuan, bahan_kemasan, factory_id) VALUES
  (
    (SELECT id FROM brands WHERE name = 'DEN HAAG'),
    (SELECT id FROM product_types WHERE name = 'SKT Kretek Tangan'),
    10325.00, 12, 'btg', 'Kertas dan Sejenisnya',
    (SELECT id FROM factories WHERE code = 'FCT-001')
  );

-- ============================================================
-- DISTRIBUTORS
-- ============================================================
INSERT INTO distributors (name, region_id, contact_info) VALUES
  ('PT Surya Sakti Raya', (SELECT id FROM regions WHERE name = 'Jawa Timur'), '031-12345678'),
  ('CV Bintang Harapan', (SELECT id FROM regions WHERE name = 'Jawa Tengah'), '024-87654321'),
  ('Maju Jaya Logistik', (SELECT id FROM regions WHERE name = 'DKI Jakarta'), '021-11223344'),
  ('PT Nusantara Distribusi', (SELECT id FROM regions WHERE name = 'Jawa Barat'), '022-55667788'),
  ('Koperasi Sinar Mas', (SELECT id FROM regions WHERE name = 'Bali'), '0361-99887766');

-- ============================================================
-- CUKAI ALLOCATIONS (seed for monitoring dashboard)
-- ============================================================
INSERT INTO cukai_allocations (factory_id, quota, used, damaged, period) VALUES
  ((SELECT id FROM factories WHERE code = 'FCT-001'), 50000, 40000, 0, 'Q3-2026'),
  ((SELECT id FROM factories WHERE code = 'FCT-002'), 35000, 25000, 0, 'Q3-2026'),
  ((SELECT id FROM factories WHERE code = 'FCT-004'), 50000, 48000, 0, 'Q3-2026'),
  ((SELECT id FROM factories WHERE code = 'FCT-005'), 20000, 15000, 0, 'Q3-2026'),
  ((SELECT id FROM factories WHERE code = 'FCT-008'), 15000, 5000, 0, 'Q3-2026');
