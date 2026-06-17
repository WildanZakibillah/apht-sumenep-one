-- Migration 012: Extend factories table columns & add factory-logos storage bucket

-- 1. Extend factories table with details
ALTER TABLE factories 
  ADD COLUMN IF NOT EXISTS owner_name TEXT,
  ADD COLUMN IF NOT EXISTS director_name TEXT,
  ADD COLUMN IF NOT EXISTS nppbkc TEXT,
  ADD COLUMN IF NOT EXISTS nib TEXT,
  ADD COLUMN IF NOT EXISTS npwp TEXT,
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD COLUMN IF NOT EXISTS email TEXT,
  ADD COLUMN IF NOT EXISTS latitude TEXT,
  ADD COLUMN IF NOT EXISTS longitude TEXT,
  ADD COLUMN IF NOT EXISTS logo_url TEXT;

-- 2. Add RLS policy to allow factory admin/director to update their own factory details
DROP POLICY IF EXISTS "Factory admin/director can update own factory" ON factories;
CREATE POLICY "Factory admin/director can update own factory" ON factories
  FOR UPDATE USING (
    id = public.user_factory_id() 
    AND public.user_role() IN ('admin_pabrik', 'direktur')
  )
  WITH CHECK (
    id = public.user_factory_id() 
    AND public.user_role() IN ('admin_pabrik', 'direktur')
  );

-- 3. Create factory-logos storage bucket if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('factory-logos', 'factory-logos', true)
ON CONFLICT (id) DO NOTHING;

-- Drop existing storage policies on factory-logos to avoid conflicts
DROP POLICY IF EXISTS "Factory Logos Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Factory Logos Auth Upload" ON storage.objects;
DROP POLICY IF EXISTS "Factory Logos Auth Update" ON storage.objects;
DROP POLICY IF EXISTS "Factory Logos Auth Delete" ON storage.objects;

-- Allow public read access
CREATE POLICY "Factory Logos Public Access" ON storage.objects FOR SELECT
USING (bucket_id = 'factory-logos');

-- Allow authenticated users to upload factory logos
CREATE POLICY "Factory Logos Auth Upload" ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'factory-logos' AND auth.role() = 'authenticated');

-- Allow authenticated users to update factory logos
CREATE POLICY "Factory Logos Auth Update" ON storage.objects FOR UPDATE
USING (bucket_id = 'factory-logos' AND auth.role() = 'authenticated');

-- Allow authenticated users to delete factory logos
CREATE POLICY "Factory Logos Auth Delete" ON storage.objects FOR DELETE
USING (bucket_id = 'factory-logos' AND auth.role() = 'authenticated');

-- 4. Update seed data for existing factories to look professional
UPDATE factories SET
  owner_name = 'H. Ahmad Sumenep',
  director_name = 'Budi Santoso',
  nppbkc = '0714.1.3.0001',
  nib = '9120101234567',
  npwp = '01.234.567.8-609.000',
  phone = '+628123456789',
  email = 'kontak@bintangtimur.com',
  latitude = '-7.012543',
  longitude = '113.865432'
WHERE code = 'FCT-001';

UPDATE factories SET
  owner_name = 'H. Mulyadi',
  director_name = 'Joko Susilo',
  nppbkc = '0714.1.3.0002',
  nib = '9120101234568',
  npwp = '01.234.567.8-609.001',
  phone = '+628123456790',
  email = 'info@tembakauemas.com',
  latitude = '-7.015432',
  longitude = '113.868765'
WHERE code = 'FCT-002';

UPDATE factories SET
  owner_name = 'H. Rasyid',
  director_name = 'Achmad Syah',
  nppbkc = '0714.1.3.0003',
  nib = '9120101234569',
  npwp = '01.234.567.8-609.002',
  phone = '+628123456791',
  email = 'sinarmakmur@gmail.com',
  latitude = '-7.010123',
  longitude = '113.860123'
WHERE code = 'FCT-003';
