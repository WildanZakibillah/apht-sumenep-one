-- APHT Sumenep One — Migration 025: Fix dashboard_stats view to filter by approved status for outgoing goods

DROP VIEW IF EXISTS dashboard_stats;

CREATE OR REPLACE VIEW dashboard_stats AS
SELECT
  (SELECT COUNT(*) FROM factories WHERE status = 'active') AS total_active_factories,
  (SELECT COUNT(*) FROM factories) AS total_factories,
  (SELECT COALESCE(SUM(jumlah_isi), 0) FROM productions
    WHERE doc_date >= date_trunc('month', CURRENT_DATE)) AS production_this_month,
  (SELECT COALESCE(SUM(remaining), 0) FROM cukai_allocations) AS total_remaining_cukai,
  (SELECT COALESCE(SUM(volume), 0) FROM outgoing_goods
    WHERE status = 'approved' AND transaction_date >= date_trunc('month', CURRENT_DATE)) AS outgoing_this_month,
  (SELECT COALESCE(SUM(total_value), 0) FROM outgoing_goods
    WHERE status = 'approved' AND transaction_date >= date_trunc('month', CURRENT_DATE)) AS revenue_this_month;
