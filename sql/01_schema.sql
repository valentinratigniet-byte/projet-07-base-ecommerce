-- =====================================================================
-- Projet 07 — Base e-commerce (OLTP) — Schéma relationnel 3NF
-- PostgreSQL 16
-- Choix de modélisation documentés dans le README.
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- customer : un compte client.
--   email UNIQUE = règle de gestion (pas deux comptes même adresse).
-- ---------------------------------------------------------------------
CREATE TABLE customer (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email       TEXT        NOT NULL UNIQUE,
    first_name  TEXT        NOT NULL,
    last_name   TEXT        NOT NULL,
    country     CHAR(2)     NOT NULL,                 -- ISO 3166-1 alpha-2
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT customer_email_lower CHECK (email = lower(email))
);

-- ---------------------------------------------------------------------
-- category : hiérarchie auto-référencée (une catégorie a un parent option.).
--   3NF : le nom ne dépend que de la clé ; le parent est une FK, pas une répétition.
-- ---------------------------------------------------------------------
CREATE TABLE category (
    id         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       TEXT NOT NULL UNIQUE,
    parent_id  INT  REFERENCES category(id) ON DELETE SET NULL
);

-- ---------------------------------------------------------------------
-- product : un article vendable, rattaché à une catégorie.
--   price > 0 garanti par CHECK ; sku UNIQUE = identifiant métier.
-- ---------------------------------------------------------------------
CREATE TABLE product (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku          TEXT          NOT NULL UNIQUE,
    name         TEXT          NOT NULL,
    category_id  INT           NOT NULL REFERENCES category(id),
    price        NUMERIC(10,2) NOT NULL CHECK (price > 0),
    is_active    BOOLEAN       NOT NULL DEFAULT true,
    created_at   TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- orders : une commande passée par un client ("order" est un mot réservé).
--   status contraint à un ensemble fini (empêche les états invalides).
-- ---------------------------------------------------------------------
CREATE TABLE orders (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id  BIGINT      NOT NULL REFERENCES customer(id),
    order_date   TIMESTAMPTZ NOT NULL DEFAULT now(),
    status       TEXT        NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending','paid','shipped','delivered','cancelled'))
);

-- ---------------------------------------------------------------------
-- order_item : ligne de commande. Table associative (N-N order<->product).
--   PK composite (order_id, product_id) = un produit apparaît 1x par commande.
--   unit_price figé au moment de l'achat (le prix produit peut changer après).
-- ---------------------------------------------------------------------
CREATE TABLE order_item (
    order_id    BIGINT        NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id  BIGINT        NOT NULL REFERENCES product(id),
    quantity    INT           NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    PRIMARY KEY (order_id, product_id)
);

-- ---------------------------------------------------------------------
-- payment : un règlement rattaché à une commande.
--   Séparé de orders (3NF) : une commande peut avoir 0..n paiements.
-- ---------------------------------------------------------------------
CREATE TABLE payment (
    id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id  BIGINT        NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    amount    NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    method    TEXT          NOT NULL CHECK (method IN ('card','paypal','transfer')),
    paid_at   TIMESTAMPTZ   NOT NULL DEFAULT now()
);

COMMIT;
