-- Migration 029: Redefine remaining column and threshold check function in cukai_allocations to exclude damaged stamps

-- 1. Redefine remaining generated column
ALTER TABLE public.cukai_allocations
DROP COLUMN IF EXISTS remaining CASCADE;

ALTER TABLE public.cukai_allocations
ADD COLUMN remaining INT GENERATED ALWAYS AS (quota - used) STORED;

-- 2. Redefine check_cukai_threshold function
CREATE OR REPLACE FUNCTION public.check_cukai_threshold()
RETURNS TRIGGER AS $$
DECLARE
  threshold_pct NUMERIC := 0.10;
  remaining_pct NUMERIC;
  factory_name TEXT;
BEGIN
  remaining_pct := (NEW.quota - NEW.used)::NUMERIC / NULLIF(NEW.quota, 0);

  IF remaining_pct IS NOT NULL AND remaining_pct <= threshold_pct THEN
    SELECT name INTO factory_name FROM factories WHERE id = NEW.factory_id;

    -- Notify all super_admins
    INSERT INTO notifications (user_id, title, message, type, icon, metadata)
    SELECT
      p.id,
      'Peringatan Sisa Cukai',
      format('Sisa Pita Cukai di %s tersisa %s%% (%s lembar). Segera lakukan pengajuan.',
        factory_name,
        ROUND(remaining_pct * 100, 1),
        (NEW.quota - NEW.used)
      ),
      'warning',
      'warning_amber_rounded',
      jsonb_build_object(
        'factory_id', NEW.factory_id,
        'cukai_category_id', NEW.cukai_category_id,
        'remaining_qty', (NEW.quota - NEW.used)
      )
    FROM profiles p
    WHERE p.role = 'super_admin' AND p.is_active = true;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
