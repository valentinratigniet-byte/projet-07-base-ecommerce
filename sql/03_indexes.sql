-- =====================================================================
-- Index de performance — à exécuter APRÈS la démo EXPLAIN (voir 04).
-- On ne crée QUE les index qui servent des requêtes réelles (pas de sur-indexation).
-- Les colonnes PK / UNIQUE sont déjà indexées automatiquement par Postgres.
-- =====================================================================

-- Requête clé : "toutes les lignes d'un produit" (analyse ventes par produit).
-- Sans cet index -> Seq Scan sur order_item (la plus grosse table).
CREATE INDEX IF NOT EXISTS idx_order_item_product ON order_item(product_id);

-- Requête clé : "commandes d'un client sur une période".
CREATE INDEX IF NOT EXISTS idx_orders_customer_date ON orders(customer_id, order_date);

-- Requête clé : filtrage/agrégation par date de commande (reporting).
CREATE INDEX IF NOT EXISTS idx_orders_date ON orders(order_date);

ANALYZE;  -- rafraîchit les statistiques pour le planificateur.
