-- ============================================================
-- SEED DATA (skip existing profiles)
-- ============================================================

-- 1. BUAT AKUN ADMIN PER PABRIK (skip jika sudah ada)
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
    
    -- Skip if profile already exists for this factory
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE factory_id = factory_rec.id AND role = 'admin_pabrik') THEN
      -- Check if auth user exists
      SELECT id INTO new_user_id FROM auth.users WHERE email = admin_email;
      
      IF new_user_id IS NULL THEN
        INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role, created_at, updated_at, confirmation_token, recovery_token)
        VALUES (gen_random_uuid(), '00000000-0000-0000-0000-000000000000', admin_email, crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', jsonb_build_object('full_name', admin_name), 'authenticated', 'authenticated', now(), now(), '', '')
        RETURNING id INTO new_user_id;

        INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
        VALUES (gen_random_uuid(), new_user_id, jsonb_build_object('sub', new_user_id::text, 'email', admin_email), 'email', new_user_id::text, now(), now(), now());
      END IF;

      -- Only insert profile if not exists
      IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = new_user_id) THEN
        INSERT INTO profiles (id, full_name, email, phone, role, factory_id, is_active)
        VALUES (new_user_id, admin_name, admin_email, '+6281200000' || counter, 'admin_pabrik', factory_rec.id, true);
      ELSE
        -- Update existing profile to link to factory
        UPDATE profiles SET factory_id = factory_rec.id, role = 'admin_pabrik' WHERE id = new_user_id;
      END IF;
    END IF;
    
    counter := counter + 1;
  END LOOP;
END $$;

-- 2. PRODUKSI
DO $$
DECLARE
  prod_id UUID;
  fact_id UUID;
  admin_id UUID;
  i INT;
BEGIN
  SELECT id INTO prod_id FROM products LIMIT 1;
  FOR fact_id IN SELECT id FROM factories WHERE status = 'active' LOOP
    SELECT id INTO admin_id FROM profiles WHERE factory_id = fact_id LIMIT 1;
    IF admin_id IS NULL THEN SELECT id INTO admin_id FROM profiles WHERE role = 'super_admin' LIMIT 1; END IF;
    FOR i IN 1..4 LOOP
      INSERT INTO productions (doc_number, doc_date, product_id, factory_id, jenis, merek, hje, bahan_kemasan, isi, satuan, jumlah_kemasan, jumlah_isi, created_by)
      VALUES ('PRD-2026-' || LPAD((random()*9999)::int::text,4,'0'), CURRENT_DATE-(random()*30)::int, prod_id, fact_id, (ARRAY['SKT','SKM','SPM'])[floor(random()*3+1)], (ARRAY['DEN HAAG','Karaoke Merah','Karaoke Biru','Surya Gold','Nusantara'])[floor(random()*5+1)], 10325.00, 'Kertas', 12, 'btg', (random()*5000+500)::int, (random()*60000+6000)::int, admin_id);
    END LOOP;
  END LOOP;
END $$;

-- 3. PENGAJUAN CUKAI
DO $$
DECLARE
  fact_rec RECORD;
  admin_id UUID;
  i INT := 1;
BEGIN
  FOR fact_rec IN SELECT id, code FROM factories WHERE status = 'active' LIMIT 8 LOOP
    SELECT id INTO admin_id FROM profiles WHERE factory_id = fact_rec.id LIMIT 1;
    IF admin_id IS NULL THEN SELECT id INTO admin_id FROM profiles WHERE role = 'super_admin' LIMIT 1; END IF;
    INSERT INTO cukai_requests (doc_number, request_date, factory_id, jenis_pengajuan, lokasi_penyediaan, jenis_hasil_tembakau, tarif_cukai, hje, isi_per_bks, jumlah_lembar, status, created_by)
    VALUES ('CK-2026-' || LPAD(i::text,3,'0'), CURRENT_DATE-(random()*14)::int, fact_rec.id, (ARRAY['AWAL','TAMBAHAN','PELENGKAP'])[floor(random()*3+1)], 'KPPBC Sumenep', 'SKT', (random()*500+200)::numeric(12,2), 10325.00, 12, (random()*10000+1000)::int, (ARRAY['pending','pending','approved','approved','approved','rejected','pending','approved'])[i], admin_id);
    i := i + 1;
  END LOOP;
END $$;

-- 4. LAPORAN BULANAN
DO $$
DECLARE
  fact_rec RECORD;
  i INT := 1;
BEGIN
  FOR fact_rec IN SELECT id FROM factories ORDER BY code LOOP
    INSERT INTO reports (factory_id, period, date_sent, status, status_label, ttd_direktur, validasi_apht)
    VALUES (fact_rec.id, 'Mei 2026', now()-interval '3 days',
      CASE WHEN i<=7 THEN 'verified' WHEN i<=9 THEN 'pending' ELSE 'rejected' END,
      CASE WHEN i<=7 THEN 'Terverifikasi' WHEN i<=9 THEN 'Menunggu' ELSE 'Ditolak' END,
      CASE WHEN i>10 THEN false ELSE true END,
      CASE WHEN i<=7 THEN true ELSE false END);
    i := i + 1;
  END LOOP;
END $$;

-- 5. BARANG KELUAR
DO $$
DECLARE
  fact_id UUID;
  reg_id UUID;
  prod_id UUID;
  admin_id UUID;
  i INT;
BEGIN
  SELECT id INTO prod_id FROM products LIMIT 1;
  FOR fact_id IN SELECT id FROM factories WHERE status = 'active' LIMIT 6 LOOP
    SELECT id INTO reg_id FROM regions ORDER BY random() LIMIT 1;
    SELECT id INTO admin_id FROM profiles WHERE factory_id = fact_id LIMIT 1;
    IF admin_id IS NULL THEN SELECT id INTO admin_id FROM profiles WHERE role = 'super_admin' LIMIT 1; END IF;
    FOR i IN 1..3 LOOP
      INSERT INTO outgoing_goods (transaction_date, customer_name, region_id, product_id, factory_id, volume, total_value, payment_method, created_by)
      VALUES (CURRENT_DATE-(random()*30)::int, (ARRAY['Toko Jaya','CV Mitra','UD Berkah','PT Sinar','Koperasi Mandiri','Toko Harapan'])[floor(random()*6+1)], reg_id, prod_id, fact_id, (random()*50000+5000)::int, (random()*500000000+50000000)::numeric(15,2), (ARRAY['tunai','kredit'])[floor(random()*2+1)], admin_id);
    END LOOP;
  END LOOP;
END $$;

-- 6. CUKAI USAGE LOG
DO $$
DECLARE
  alloc_rec RECORD;
  admin_id UUID;
  i INT;
BEGIN
  FOR alloc_rec IN SELECT id, factory_id FROM cukai_allocations LOOP
    SELECT id INTO admin_id FROM profiles WHERE factory_id = alloc_rec.factory_id LIMIT 1;
    IF admin_id IS NULL THEN SELECT id INTO admin_id FROM profiles WHERE role = 'super_admin' LIMIT 1; END IF;
    FOR i IN 1..5 LOOP
      INSERT INTO cukai_usage_log (allocation_id, factory_id, usage_date, used_amount, added_amount, notes, created_by)
      VALUES (alloc_rec.id, alloc_rec.factory_id, CURRENT_DATE-(i*3), (random()*2000+500)::int, 0, 'Pemakaian batch ' || i, admin_id);
    END LOOP;
  END LOOP;
END $$;

-- 7. ARSIP
INSERT INTO archives (report_id, factory_id, name, period, verified_date)
SELECT r.id, r.factory_id, f.name, r.period, CURRENT_DATE - (random()*5)::int
FROM reports r JOIN factories f ON r.factory_id = f.id
WHERE r.status = 'verified'
ON CONFLICT DO NOTHING;

-- 8. NOTIFIKASI
DO $$
DECLARE sa_id UUID;
BEGIN
  SELECT id INTO sa_id FROM profiles WHERE role = 'super_admin' LIMIT 1;
  IF sa_id IS NOT NULL THEN
    INSERT INTO notifications (user_id, title, message, type, icon, is_read, created_at) VALUES
      (sa_id, 'Pengajuan Cukai Baru', 'PT Bintang Timur mengajukan 5000 lembar pita cukai.', 'info', 'request_page', false, now()-interval '1 hour'),
      (sa_id, 'Laporan Masuk', 'CV Tembakau Emas mengirimkan laporan Mei 2026.', 'info', 'description', false, now()-interval '3 hours'),
      (sa_id, 'Cukai Kritis', 'PT Gudang Daun sisa pita cukai < 5%.', 'warning', 'warning', false, now()-interval '6 hours'),
      (sa_id, 'Laporan Diverifikasi', 'Laporan CV Aroma Jaya berhasil diverifikasi.', 'success', 'check_circle', true, now()-interval '1 day'),
      (sa_id, 'Pengajuan Ditolak', 'Pengajuan PD Karya Maju ditolak.', 'error', 'cancel', true, now()-interval '2 days'),
      (sa_id, 'Produksi Tercatat', 'PT Bintang Timur mencatat 3500 kemasan.', 'info', 'inventory_2', true, now()-interval '4 days');
  END IF;
END $$;

-- 9. Tambah alokasi cukai untuk pabrik yang belum punya
INSERT INTO cukai_allocations (factory_id, quota, used, damaged, period)
SELECT f.id, (random()*30000+10000)::int, (random()*20000+5000)::int, (random()*200)::int, 'Q2-2026'
FROM factories f
WHERE f.status = 'active' AND NOT EXISTS (SELECT 1 FROM cukai_allocations ca WHERE ca.factory_id = f.id);
