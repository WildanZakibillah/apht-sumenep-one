-- ============================================================
-- Migration 005: Assign factory & role to existing users
-- Jalankan ini di Supabase SQL Editor untuk mengikat akun
-- yang sudah ada ke pabrik tertentu.
-- ============================================================

-- Cek user yang ada (untuk lihat email & status profile)
-- SELECT id, email, full_name, role, factory_id FROM profiles;

-- Contoh: ikat user dengan email tertentu ke FCT-001 sebagai admin_pabrik
UPDATE profiles
SET
  factory_id = (SELECT id FROM factories WHERE code = 'FCT-001'),
  role = 'admin_pabrik'
WHERE email = 'GANTI_EMAIL_USER_DI_SINI@example.com';

-- Untuk super_admin (tidak perlu factory_id):
-- UPDATE profiles SET role = 'super_admin'
-- WHERE email = 'GANTI_EMAIL_ADMIN_DI_SINI@example.com';
