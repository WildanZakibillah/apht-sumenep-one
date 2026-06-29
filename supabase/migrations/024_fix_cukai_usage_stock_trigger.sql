-- ============================================================
-- APHT Sumenep One — Migration 024: Fix Cukai Usage Stock Update Trigger
-- ============================================================

-- Ensure the trigger on_cukai_usage_stok_update exists on public.cukai_usage_log
DROP TRIGGER IF EXISTS on_cukai_usage_stok_update ON public.cukai_usage_log;

CREATE TRIGGER on_cukai_usage_stok_update
  AFTER INSERT OR UPDATE OR DELETE ON public.cukai_usage_log
  FOR EACH ROW EXECUTE FUNCTION public.update_stok_on_cukai_usage();
