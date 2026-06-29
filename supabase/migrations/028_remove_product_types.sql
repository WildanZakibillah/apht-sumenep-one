-- Migration 028: Remove product_types Table and Constraints with Safety Checks

DO $$
BEGIN
  -- 1. Ensure all products in cigarettes have a valid cukai_category_id mapped
  IF EXISTS (
    SELECT 1 
    FROM public.cigarettes 
    WHERE cukai_category_id IS NULL
  ) THEN
    RAISE EXCEPTION 'Safety check failed: Terdapat produk rokok (cigarettes) yang belum terhubung ke Kategori Cukai (cukai_category_id IS NULL).';
  END IF;
  
  -- 2. Check if we need to drop the columns
  IF EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'cigarettes' 
      AND column_name = 'product_type_id'
  ) THEN
    ALTER TABLE public.cigarettes DROP COLUMN product_type_id CASCADE;
  END IF;

  IF EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'brands' 
      AND column_name = 'product_type_id'
  ) THEN
    ALTER TABLE public.brands DROP COLUMN product_type_id CASCADE;
  END IF;

  -- 3. Verify no other table contains foreign keys referencing product_types
  IF EXISTS (
    SELECT 1 
    FROM information_schema.table_constraints tc 
    JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name 
    WHERE tc.constraint_type = 'FOREIGN KEY' 
      AND ccu.table_name = 'product_types'
  ) THEN
    RAISE EXCEPTION 'Safety check failed: Masih ada relasi foreign key lain ke tabel product_types dari tabel selain cigarettes/brands.';
  END IF;

  -- 4. Drop the table
  DROP TABLE IF EXISTS public.product_types CASCADE;
END $$;
