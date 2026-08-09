"""
Peuplement de la base e-commerce avec des données réalistes (Faker).
Reproductible (seed fixe) et idempotent (TRUNCATE avant insertion).

Usage :
    pip install -r seed/requirements.txt
    python seed/seed.py                       # utilise DATABASE_URL ou la valeur par défaut Docker
    DATABASE_URL=postgresql://u:p@host/db python seed/seed.py
"""
import os
import random
from datetime import datetime, timedelta, timezone

import psycopg2
from psycopg2.extras import execute_values
from faker import Faker

# --- Reproductibilité : mêmes données à chaque exécution -------------------
SEED = 42
random.seed(SEED)
fake = Faker()
Faker.seed(SEED)

# --- Volumes (choisis pour que les index changent le plan d'exécution) -----
N_CUSTOMERS = 5_000
N_PRODUCTS = 2_000
N_ORDERS = 40_000
MAX_ITEMS_PER_ORDER = 5

CATEGORIES = [
    "Électronique", "Informatique", "Maison", "Jardin", "Sport",
    "Mode", "Livres", "Jouets", "Beauté", "Alimentation",
]
STATUSES = ["pending", "paid", "shipped", "delivered", "cancelled"]
METHODS = ["card", "paypal", "transfer"]

DSN = os.environ.get(
    "DATABASE_URL",
    "postgresql://portfolio:portfolio@127.0.0.1:5433/ecommerce",
)


def main() -> None:
    conn = psycopg2.connect(DSN)
    conn.autocommit = False
    cur = conn.cursor()

    # Idempotent : on repart d'une base vide (RESTART IDENTITY remet les compteurs).
    cur.execute(
        "TRUNCATE payment, order_item, orders, product, category, customer "
        "RESTART IDENTITY CASCADE;"
    )

    # --- category ---------------------------------------------------------
    execute_values(cur, "INSERT INTO category (name) VALUES %s",
                   [(c,) for c in CATEGORIES])
    cur.execute("SELECT id FROM category")
    category_ids = [r[0] for r in cur.fetchall()]

    # --- customer ---------------------------------------------------------
    customers = []
    seen_emails = set()
    while len(customers) < N_CUSTOMERS:
        email = fake.unique.email().lower()
        if email in seen_emails:
            continue
        seen_emails.add(email)
        customers.append((email, fake.first_name(), fake.last_name(),
                          fake.country_code()))
    execute_values(cur,
        "INSERT INTO customer (email, first_name, last_name, country) VALUES %s",
        customers)
    cur.execute("SELECT id FROM customer")
    customer_ids = [r[0] for r in cur.fetchall()]

    # --- product ----------------------------------------------------------
    products = [
        (f"SKU-{i:06d}", fake.catch_phrase()[:80], random.choice(category_ids),
         round(random.uniform(2, 500), 2), random.random() > 0.1)
        for i in range(N_PRODUCTS)
    ]
    execute_values(cur,
        "INSERT INTO product (sku, name, category_id, price, is_active) VALUES %s",
        products)
    cur.execute("SELECT id, price FROM product")
    product_rows = cur.fetchall()               # [(id, price), ...]
    product_ids = [r[0] for r in product_rows]
    price_by_id = {r[0]: r[1] for r in product_rows}

    # --- orders -----------------------------------------------------------
    start = datetime.now(timezone.utc) - timedelta(days=730)
    orders = [
        (random.choice(customer_ids),
         start + timedelta(seconds=random.randint(0, 730 * 86400)),
         random.choices(STATUSES, weights=[1, 3, 3, 6, 1])[0])
        for _ in range(N_ORDERS)
    ]
    execute_values(cur,
        "INSERT INTO orders (customer_id, order_date, status) VALUES %s",
        orders, page_size=1000)
    cur.execute("SELECT id, status FROM orders")
    order_rows = cur.fetchall()

    # --- order_item + payment --------------------------------------------
    items, payments = [], []
    for order_id, status in order_rows:
        chosen = random.sample(product_ids, k=random.randint(1, MAX_ITEMS_PER_ORDER))
        total = 0
        for pid in chosen:
            qty = random.randint(1, 4)
            unit = price_by_id[pid]
            total += qty * float(unit)
            items.append((order_id, pid, qty, unit))
        # Une commande non annulée et non "pending" a été payée.
        if status not in ("pending", "cancelled"):
            payments.append((order_id, round(total, 2),
                             random.choice(METHODS)))

    execute_values(cur,
        "INSERT INTO order_item (order_id, product_id, quantity, unit_price) VALUES %s",
        items, page_size=1000)
    execute_values(cur,
        "INSERT INTO payment (order_id, amount, method) VALUES %s",
        payments, page_size=1000)

    conn.commit()
    print(f"OK — {N_CUSTOMERS} clients, {N_PRODUCTS} produits, "
          f"{N_ORDERS} commandes, {len(items)} lignes, {len(payments)} paiements.")
    cur.close()
    conn.close()


if __name__ == "__main__":
    main()
