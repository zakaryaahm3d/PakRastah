# Index Justifications — PakRastah

Run these commands in psql after `init_db.sh` to capture EXPLAIN ANALYZE output.

---

## 1. `idx_users_role` on `users(role)`

**Query served:**
```sql
EXPLAIN ANALYZE
SELECT user_id, email, full_name FROM users WHERE role = 'business';
```

**Justification:** Login redirect and nav queries filter users by role. Without the index,
Postgres scans all users rows. With 17+ users this is trivial, but with thousands of
registered users (realistic scale) a seq scan grows linearly. This index enables an
index scan in O(log n) + k rows.

---

## 2. `idx_waste_events_business_date` on `waste_events(business_id, event_date DESC)`

**Query served:**
```sql
EXPLAIN ANALYZE
SELECT event_id, event_date, tonnage, waste_type, status
FROM waste_events
WHERE business_id = 1
  AND event_date >= CURRENT_DATE - INTERVAL '90 days'
ORDER BY event_date DESC;
```

**Justification:** The business dashboard and trigger function both scan waste events
scoped to one business in a date window. The composite index (business_id leading)
eliminates a full table scan. The DESC on event_date means ORDER BY requires no
additional sort. Without this index: Seq Scan + Sort. With it: Index Only Scan.

---

## 3. `idx_certifications_status` on `certifications(status)`

**Query served:**
```sql
EXPLAIN ANALYZE
SELECT certification_id, business_id, cert_number, tier, expiry_date
FROM certifications
WHERE status = 'active';
```

**Justification:** The procedure cursor, auditor views, and business dashboard all
filter certifications by status. A seq scan on this table doubles the I/O of every
auditor page load as the table grows.

---

## 4. `idx_cert_queue_business_status` on `certification_queue(business_id, status)`

**Query served:**
```sql
EXPLAIN ANALYZE
SELECT queue_id, status, tier, submitted_at
FROM certification_queue
WHERE business_id = 1
  AND status IN ('eligible_for_review','under_review');
```

**Justification:** Trigger 2 runs this exact predicate on every `business_metrics`
update — i.e., every waste event insert. Without the index this is a seq scan
inside a trigger, adding latency to every write path.

---

## 5. `idx_marketplace_category_status` on `marketplace_listings(category, status)`

**Query served:**
```sql
EXPLAIN ANALYZE
SELECT listing_id, title, price_pkr, city
FROM marketplace_listings
WHERE category = 'electronics'
  AND status = 'active'
ORDER BY listed_at DESC;
```

**Justification:** The marketplace stub page filters by category and status. Composite
index covers both predicates in one pass. Without it: Seq Scan with filter on a
potentially large listings table.

---

## How to capture output for the viva

```bash
psql -U postgres -d pakrastah -c "
  EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
  SELECT event_id, event_date, tonnage FROM waste_events
  WHERE business_id = 1 AND event_date >= CURRENT_DATE - INTERVAL '90 days'
  ORDER BY event_date DESC;
" > db/explain_waste_events.txt
```

Repeat for each index above. Show the `Index Scan` vs `Seq Scan` in the output.
