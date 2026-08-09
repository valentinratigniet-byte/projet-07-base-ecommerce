-- =====================================================================
-- Démonstration du gain d'un index (critère de réussite du Projet 07).
-- Mode d'emploi :
--   1. Charger schéma + seed (base peuplée, SANS les index de 03).
--   2. Exécuter la section AVANT -> noter "Seq Scan" + le temps.
--   3. Exécuter 03_indexes.sql.
--   4. Exécuter la section APRÈS -> noter "Index Scan" + le temps.
-- =====================================================================

-- ---------- AVANT (aucun index sur order_item.product_id) ----------
-- Attendu : Parallel Seq Scan sur order_item, coût élevé.
EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id, sum(quantity) AS unites, sum(quantity * unit_price) AS ca
FROM order_item
WHERE product_id = 42
GROUP BY product_id;

-- >>> Exécuter maintenant :  \i sql/03_indexes.sql   <<<

-- ---------- APRÈS (index idx_order_item_product présent) ----------
-- Attendu : Index Scan / Bitmap Index Scan, temps très inférieur.
EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id, sum(quantity) AS unites, sum(quantity * unit_price) AS ca
FROM order_item
WHERE product_id = 42
GROUP BY product_id;
