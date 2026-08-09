-- =====================================================================
-- Tests d'intégrité : on PROUVE que les contraintes rejettent l'invalide.
-- Chaque bloc tente une insertion illégale et doit lever une exception.
-- Sortie attendue : "PASS" pour chaque test, aucune ligne insérée.
-- =====================================================================

-- 1. prix négatif -> CHECK (price > 0)
DO $$ BEGIN
    INSERT INTO product (sku, name, category_id, price)
    VALUES ('BAD-1', 'Prix négatif', 1, -5);
    RAISE EXCEPTION 'FAIL: prix négatif accepté';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS: prix négatif rejeté';
END $$;

-- 2. statut inconnu -> CHECK (status IN (...))
DO $$ BEGIN
    INSERT INTO orders (customer_id, status) VALUES (1, 'wizard');
    RAISE EXCEPTION 'FAIL: statut invalide accepté';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS: statut invalide rejeté';
END $$;

-- 3. email en double -> UNIQUE
DO $$
DECLARE existing_email TEXT;
BEGIN
    SELECT email INTO existing_email FROM customer LIMIT 1;
    INSERT INTO customer (email, first_name, last_name, country)
    VALUES (existing_email, 'Doublon', 'Test', 'FR');
    RAISE EXCEPTION 'FAIL: email en double accepté';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS: email en double rejeté';
END $$;

-- 4. FK produit inexistant -> foreign_key_violation
DO $$ BEGIN
    INSERT INTO order_item (order_id, product_id, quantity, unit_price)
    VALUES (1, 999999999, 1, 10);
    RAISE EXCEPTION 'FAIL: FK produit inexistant acceptée';
EXCEPTION WHEN foreign_key_violation THEN RAISE NOTICE 'PASS: FK produit inexistant rejetée';
END $$;

-- 5. quantité nulle -> CHECK (quantity > 0)
DO $$ BEGIN
    INSERT INTO order_item (order_id, product_id, quantity, unit_price)
    VALUES (1, 1, 0, 10);
    RAISE EXCEPTION 'FAIL: quantité 0 acceptée';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS: quantité 0 rejetée';
END $$;
