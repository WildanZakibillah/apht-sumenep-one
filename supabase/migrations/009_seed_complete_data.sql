-- ============================================================
-- Migration 009: Complete Seed Data for Super Admin Dashboard
-- Jalankan di Supabase SQL Editor
-- ============================================================

-- ============================================================
-- 1. BUAT AKUN ADMIN PER PABRIK (11 admin pabrik)
-- Password semua: password123
-- ============================================================

-- Helper: create user + profile in one go
DO $$
DECLARE
  factory_rec RECORD;
  new_user_id UUID;
  admin_email TEXT;
  admin_name TEXT;
  counter INT := 1;
BEGIN
  FOR factory_rec IN SELECT id, code, name FROM factories ORDER BY code LOOP
    admin_email := 'admin' || counter || '@apht.com';
    admin_name := 'Admin ' || factory_rec.name;
    
    -- Check if user already exists
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = admin_email) THEN
      -- Create auth user
      INSERT INTO auth.users (
        id, instance_id, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, aud, role, created_at, updated_at,
        confirmation_token, recovery_token
      ) VALUES (
        gen_random_uuid(), '00000000-0000-0000-0000-000000000000',
        admin_email, crypt('password123', gen_salt('bf')), now(),
        '{"provider":"email","providers":["email"]}',
        jsonb_build_object('full_name', admin_name),
        'authenticated', 'authenticated', now(), now(), '', ''
      ) RETURNING id INTO new_user_id;

      -- Create identity
      INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
      VALUES (gen_random_uuid(), new_user_id, jsonb_build_object('sub', new_user_id::text, 'email', admin_email), 'email', new_user_id::text, now(), now(), now());

      -- Create profile
      INSERT INTO profiles (id, full_name, email, phone, role, factory_id, is_active)
      VALUES (new_user_id, admin_name, admin_email, '+6281200000' || counter, 'admin_pabrik', factory_rec.id, true);
    END IF;
    
    counter := counter + 1;
  END LOOP;
END $$;

-- ============================================================
-- 2. DATA PRODUKSI (productions) - 30+ records across factories
-- ============================================================

-- Get product ID for reference
DO $$
DECLARE
  prod_id UUID;
  fact_id UUID;
  admin_id UUID;
  i INT;
BEGIN
  -- Get first product
  SELECT id INTO prod_id FROM products LIMIT 1;
  
  -- If no product exists, create one
  IF prod_id IS NULL THEN
    SELECT id INTO prod_id FROM products LIMIT 1;
  END IF;

  -- Insert productions for each active factory
  FOR fact_id IN SELECT id FROM factories WHERE status = 'active' LOOP
    -- Get admin for this factory
    SELECT id INTO admin_id FROM profiles WHERE factory_id = fact_id AND role = 'admin_pabrik' LIMIT 1;
    IF admin_id IS NULL THEN
      SELECT id INTO admin_id FROM profiles WHERE role = 'super_admin' LIMIT 1;
    END IF;

    -- Insert 3-5 production records per factory
    FOR i IN 1..4 LOOP
      INSERT INTO productions (doc_number, doc_date, product_id, factory_id, jenis, merek, hje, bahan_kemasan, isi, satuan, jumlah_kemasan, jumlah_isi, created_by)
      VALUES (
        'PRD-' || EXTRACT(YEAR FROM CURRENT_DATE) || '-' || LPAD((random() * 9999)::int::text, 4, '0'),
        CURRENT_DATE - (random() * 30)::int,
        prod_id,
        fact_id,
        (ARRAY['SKT', 'SKM', 'SPM'])[floor(random() * 3 + 1)],
        (ARRAY['DEN HAAG', 'Karaoke Merah', 'Karaoke Biru 12', 'Surya Gold', 'Nusantara'])[floor(random() * 5 + 1)],
        10325.00,
        'Kertas dan Sejenisnya',
        12,
        'btg',
        (random() * 5000 + 500)::int,
        (random() * 60000 + 6000)::int,
        admin_id
      )
      ON CONFLICT DO NOTHING;
    END LOOP;
  END LOOP;
END $$;

-- ============================================================
-- 3. PENGAJUAN CUKAI (cukai_requests) - various statuses
-- ============================================================

DO $$
DECLARE
  fact_rec RECORD;
  admin_id UUID;
  req_status TEXT;
  i INT;
BEGIN
  i := 1;
  FOR fact_rec IN SELECT id, code FROM factories WHERE status = 'active' LIMIT 8 LOOP
    SELECT id INTO admin_id FROM profiles WHERE factory_id = fact_rec.id AND role = 'admin_pabrik' LIMIT 1;
    IF admin_id IS NULL THEN
      SELECT id INTO admin_id FROM profiles WHERE role = 'super_admin' LIMIT 1;
    END IF;

    -- Assign different statuses
    req_status := (ARRAY['pending', 'pending', 'approved', 'approved', 'approved', 'rejected', 'pending', 'approved'])[i];

    INSERT INTO cukai_requests (doc_number, request_date, factory_id, jenis_pengajuan, lokasi_penyediaan, jenis_hasil_tembakau, kode_personalisasi, seri, warna, tarif_cukai, hje, isi_per_bks, jumlah_lembar, status, created_by)
    VALUES (
      'CK-' || EXTRACT(YEAR FROM CURRENT_DATE) || '-' || LPAD(i::text, 3, '0'),
      CURRENT_DATE - (random() * 14)::int,
      fact_rec.id,
      (ARRAY['AWAL', 'TAMBAHAN', 'PELENGKAP'])[floor(random() * 3 + 1)],
      'KPPBC Sumenep',
      'Sigaret Kretek Tangan',
      'SKT-' || LPAD(i::text, 2, '0'),
      'Seri ' || (ARRAY['A', 'B', 'C'])[floor(random() * 3 + 1)],
      (ARRAY['Merah', 'Biru', 'Hijau', 'Kuning'])[floor(random() * 4 + 1)],
      (random() * 500 + 200)::numeric(12,2),
      10325.00,
      12,
      (random() * 10000 + 1000)::int,
      req_status,
      admin_id
    )
    ON CONFLICT DO NOTHING;

    i := i + 1;
  END LOOP;
END $$;

-- ============================================================
-- 4. LAPORAN BULANAN (reports) - from each factory
-- ============================================================

DO $$
DECLARE
  fact_rec RECORD;
  rep_status TEXT;
  i INT;
BEGIN
  i := 1;
  FOR fact_rec IN SELECT id FROM factories ORDER BY code LOOP
    -- Mix of statuses
    rep_status := CASE
      WHEN i <= 7 THEN 'verified'
      WHEN i <= 9 THEN 'pending'
      ELSE 'rejected'
    END;

    INSERT INTO reports (factory_id, period, date_sent, status, status_label, ttd_direktur, validasi_apht)
    VALUES (
      fact_rec.id,
      'Mei 2026',
      CASE WHEN rep_status != 'pending' THEN now() - interval '5 days' ELSE now() - interval '1 day' END,
      rep_status,
      CASE rep_status
        WHEN 'verified' THEN 'Terverifikasi'
        WHEN 'pending' THEN 'Menunggu Review'
        ELSE 'Ditolak'
      END,
      CASE WHEN rep_status = 'rejected' THEN false ELSE true END,
      CASE WHEN rep_status = 'verified' THEN true ELSE false END
    )
    ON CONFLICT DO NOTHING;

    i := i + 1;
  END LOOP;
END $$;

-- ============================================================
-- 5. BARANG KELUAR (outgoing_goods) - sales transactions
-- ============================================================

DO $$
DECLARE
  fact_rec RECORD;
  reg_id UUID;
  prod_id UUID;
  admin_id UUID;
  i INT;
BEGIN
  SELECT id INTO prod_id FROM products LIMIT 1;
  
  i := 1;
  FOR fact_rec IN SELECT id FROM factories WHERE status = 'active' LIMIT 6 LOOP
    SELECT id INTO reg_id FROM regions ORDER BY random() LIMIT 1;
    SELECT id INTO admin_id FROM profiles WHERE factory_id = fact_rec.id LIMIT 1;
    IF admin_id IS NULL THEN
      SELECT id INTO admin_id FROM profiles WHERE role = 'super_admin' LIMIT 1;
    END IF;

    -- 2-3 transactions per factory
    FOR i IN 1..3 LOOP
      INSERT INTO outgoing_goods (transaction_date, customer_name, region_id, product_id, factory_id, volume, total_value, payment_method, created_by)
      VALUES (
        CURRENT_DATE - (random() * 30)::int,
        (ARRAY['Toko Jaya Abadi', 'CV Mitra Sejahtera', 'UD Berkah Makmur', 'PT Sinar Distribusi', 'Koperasi Mandiri', 'Toko Harapan Baru'])[floor(random() * 6 + 1)],
        reg_id,
        prod_id,
        fact_rec.id,
        (random() * 50000 + 5000)::int,
        (random() * 500000000 + 50000000)::numeric(15,2),
        (ARRAY['tunai', 'kredit'])[floor(random() * 2 + 1)],
        admin_id
      )
      ON CONFLICT DO NOTHING;
    END LOOP;
  END LOOP;
END $$;

-- ============================================================
-- 6. CUKAI USAGE LOG - pemakaian pita cukai harian
-- ============================================================

DO $$
DECLARE
  alloc_rec RECORD;
  admin_id UUID;
  i INT;
BEGIN
  FOR alloc_rec IN SELECT id, factory_id FROM cukai_allocations LOOP
    SELECT id INTO admin_id FROM profiles WHERE factory_id = alloc_rec.factory_id LIMIT 1;
    IF admin_id IS NULL THEN
      SELECT id INTO admin_id FROM profiles WHERE role = 'super_admin' LIMIT 1;
    END IF;

    FOR i IN 1..5 LOOP
      INSERT INTO cukai_usage_log (allocation_id, factory_id, usage_date, used_amount, added_amount, notes, created_by)
      VALUES (
        alloc_rec.id,
        alloc_rec.factory_id,
        CURRENT_DATE - (i * 3),
        (random() * 2000 + 500)::int,
        0,
        'Pemakaian produksi harian batch ' || i,
        admin_id
      )
      ON CONFLICT DO NOTHING;
    END LOOP;
  END LOOP;
END $$;

-- ============================================================
-- 7. ARSIP DIGITAL - verified reports archived
-- ============================================================

DO $$
DECLARE
  rep_rec RECORD;
BEGIN
  FOR rep_rec IN SELECT r.id, r.factory_id, r.period, f.name 
    FROM reports r JOIN factories f ON r.factory_id = f.id 
    WHERE r.status = 'verified' LOOP
    
    INSERT INTO archives (report_id, factory_id, name, period, verified_date)
    VALUES (
      rep_rec.id,
      rep_rec.factory_id,
      rep_rec.name,
      rep_rec.period,
      CURRENT_DATE - (random() * 5)::int
    )
    ON CONFLICT DO NOTHING;
  END LOOP;
END $$;

-- ============================================================
-- 8. NOTIFIKASI untuk Super Admin
-- ============================================================

DO $$
DECLARE
  sa_id UUID;
BEGIN
  SELECT id INTO sa_id FROM profiles WHERE role = 'super_admin' LIMIT 1;
  
  IF sa_id IS NOT NULL THEN
    INSERT INTO notifications (user_id, title, message, type, icon, is_read, created_at) VALUES
      (sa_id, 'Pengajuan Cukai Baru', 'PT Bintang Timur Semesta mengajukan 5000 lembar pita cukai jenis AWAL.', 'info', 'request_page', false, now() - interval '1 hour'),
      (sa_id, 'Laporan Masuk', 'CV Tembakau Emas mengirimkan laporan bulanan Mei 2026.', 'info', 'description', false, now() - interval '3 hours'),
      (sa_id, 'Cukai Kritis', 'PT Gudang Daun memiliki sisa pita cukai < 5%. Segera tindak lanjuti.', 'warning', 'warning', false, now() - interval '6 hours'),
      (sa_id, 'Laporan Diverifikasi', 'Laporan CV Aroma Jaya periode Mei 2026 berhasil diverifikasi.', 'success', 'check_circle', true, now() - interval '1 day'),
      (sa_id, 'Pengajuan Ditolak', 'Pengajuan cukai PD Karya Maju ditolak karena dokumen tidak lengkap.', 'error', 'cancel', true, now() - interval '2 days'),
      (sa_id, 'User Baru Terdaftar', 'Admin baru untuk PT Nusantara Tobacco telah berhasil didaftarkan.', 'success', 'person_add', true, now() - interval '3 days'),
      (sa_id, 'Produksi Tercatat', 'PT Bintang Timur mencatat produksi 3500 kemasan SKT hari ini.', 'info', 'inventory_2', true, now() - interval '4 days'),
      (sa_id, 'Sistem Update', 'Sistem APHT Sumenep One telah diperbarui ke versi 1.0.0.', 'info', 'system_update', true, now() - interval '7 days')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;

-- ============================================================
-- 9. UPDATE cukai_allocations agar lebih realistis
-- ============================================================

-- Tambah alokasi untuk pabrik yang belum punya
DO $$
DECLARE
  fact_rec RECORD;
BEGIN
  FOR fact_rec IN 
    SELECT f.id FROM factories f 
    WHERE f.status = 'active' 
    AND NOT EXISTS (SELECT 1 FROM cukai_allocations ca WHERE ca.factory_id = f.id)
  LOOP
    INSERT INTO cukai_allocations (factory_id, quota, used, damaged, period)
    VALUES (
      fact_rec.id,
      (random() * 30000 + 10000)::int,
      (random() * 20000 + 5000)::int,
      (random() * 200)::int,
      'Q2-2026'
    );
  END LOOP;
END $$;

-- ============================================================
-- DONE! Data lengkap untuk demo super admin dashboard
-- ============================================================
-- Akun admin pabrik: admin1@apht.com s/d admin11@apht.com (password: password123)
-- Super admin: admin@apht.com (password yang sudah Anda set)
