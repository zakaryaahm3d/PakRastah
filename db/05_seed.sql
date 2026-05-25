-- PakRastah Seed Data
-- Triggers are disabled during seeding so metrics and cert states are set precisely.
-- All event_date values use NOW() - INTERVAL to stay inside the rolling 90-day window.
-- Three businesses are calibrated to straddle the 0.60 threshold:
--   B1 Lahore Textiles    → Silver (ratio ~0.82), already approved, has prior tax credit
--   B2 Karachi Foods      → Bronze (ratio ~0.64), eligible_for_review  ← demo business login
--   B3 Islamabad Energy   → Below threshold (ratio ~0.41), no queue entry

-- ---------------------------------------------------------------------------
-- Disable trigger chain during seeding
-- ---------------------------------------------------------------------------
ALTER TABLE waste_events        DISABLE TRIGGER trg_waste_events_metrics;
ALTER TABLE processing_outputs  DISABLE TRIGGER trg_processing_outputs_metrics;
ALTER TABLE business_metrics    DISABLE TRIGGER trg_business_metrics_certification;

-- ---------------------------------------------------------------------------
-- USERS  (passwords set to 'PLACEHOLDER'; init_db.sh calls set_passwords.py)
-- ---------------------------------------------------------------------------
INSERT INTO users (email, password_hash, role, full_name, phone) VALUES
  ('admin@pakrastah.gov.pk',    'PLACEHOLDER', 'admin',     'Admin Console',              '+92-51-9999001'),
  ('lahore@textiles.pk',        'PLACEHOLDER', 'business',  'Muhammad Tariq Mahmood',     '+92-42-3561234'),
  ('karachi@foods.pk',          'PLACEHOLDER', 'business',  'Sana Mirza',                 '+92-21-3456789'),
  ('islamabad@energy.pk',       'PLACEHOLDER', 'business',  'Bilal Hussain Khan',         '+92-51-2345678'),
  ('facility@recyclepak.pk',    'PLACEHOLDER', 'facility',  'RecyclePak Operations',      '+92-42-7891234'),
  ('auditor@pakrastah.gov.pk',  'PLACEHOLDER', 'auditor',   'Khalid Mehmood Chaudhry',    '+92-51-9206601'),
  ('developer@pakrastah.gov.pk','PLACEHOLDER', 'developer', 'Arif Nawaz Siddiqui',        '+92-51-9206602'),
  -- Eateries (food rescue stub)
  ('eatery1@hotmail.com',       'PLACEHOLDER', 'eatery',    'Burning Brownie Café',       '+92-42-3781234'),
  ('eatery2@hotmail.com',       'PLACEHOLDER', 'eatery',    'Salt & Pepper Restaurant',   '+92-21-3112233'),
  ('eatery3@hotmail.com',       'PLACEHOLDER', 'eatery',    'Monal Lahore',               '+92-42-3588899'),
  -- Charities (food rescue stub)
  ('charity1@gmail.com',        'PLACEHOLDER', 'charity',   'Edhi Foundation Lahore',     '+92-42-3590001'),
  ('charity2@gmail.com',        'PLACEHOLDER', 'charity',   'Saylani Welfare Trust',      '+92-21-3456001'),
  -- Citizens (marketplace stub)
  ('citizen1@gmail.com',        'PLACEHOLDER', 'citizen',   'Ayesha Raza',                '+92-300-1234567'),
  ('citizen2@gmail.com',        'PLACEHOLDER', 'citizen',   'Hassan Iqbal',               '+92-301-9876543'),
  ('citizen3@gmail.com',        'PLACEHOLDER', 'citizen',   'Fatima Noor',                '+92-321-5554433'),
  ('citizen4@gmail.com',        'PLACEHOLDER', 'citizen',   'Usman Ali Sheikh',           '+92-333-1122334'),
  ('citizen5@gmail.com',        'PLACEHOLDER', 'citizen',   'Zainab Perveen',             '+92-345-9988776');

-- ---------------------------------------------------------------------------
-- BUSINESSES
-- ---------------------------------------------------------------------------
INSERT INTO businesses (user_id, name, address, city, category, registration_number) VALUES
  ((SELECT user_id FROM users WHERE email='lahore@textiles.pk'),
   'Lahore Textiles Pvt Ltd',
   'Plot 14-B, Industrial Estate, Kot Lakhpat', 'Lahore', 'textile', 'SECP-LHR-2018-0042'),

  ((SELECT user_id FROM users WHERE email='karachi@foods.pk'),
   'Karachi Foods Distribution Co',
   'Warehouse 7, SITE Area, Manghopir Road', 'Karachi', 'food_processing', 'SECP-KHI-2019-0117'),

  ((SELECT user_id FROM users WHERE email='islamabad@energy.pk'),
   'Islamabad Clean Energy Solutions',
   'Office 3-C, Blue Area Commercial Zone', 'Islamabad', 'manufacturing', 'SECP-ISB-2021-0289');

-- ---------------------------------------------------------------------------
-- PROCESSING FACILITY
-- ---------------------------------------------------------------------------
INSERT INTO processing_facilities (user_id, name, address, city, capacity_tonnes_per_day) VALUES
  ((SELECT user_id FROM users WHERE email='facility@recyclepak.pk'),
   'RecyclePak Processing Center',
   'Sector B-2, Sundar Industrial Estate', 'Lahore', 5.50);

-- ---------------------------------------------------------------------------
-- WASTE EVENTS — Business 1 (Lahore Textiles) — 16 events, spread over 85 days
-- Target total tonnage: ~7,800 kg | Target recovered: ~6,400 kg → ratio ~0.821
-- ---------------------------------------------------------------------------
INSERT INTO waste_events (business_id, facility_id, event_date, tonnage, waste_type, status, notes) VALUES
  (1, 1, CURRENT_DATE - INTERVAL '85 days', 580.0, 'textile',    'processed', 'Batch 1 — offcuts'),
  (1, 1, CURRENT_DATE - INTERVAL '79 days', 430.0, 'recyclable', 'processed', 'Cardboard and paper'),
  (1, 1, CURRENT_DATE - INTERVAL '74 days', 620.0, 'textile',    'processed', 'Dye waste fabric'),
  (1, 1, CURRENT_DATE - INTERVAL '68 days', 390.0, 'mixed',      'processed', 'Mixed floor waste'),
  (1, 1, CURRENT_DATE - INTERVAL '63 days', 510.0, 'recyclable', 'processed', 'Plastic thread spools'),
  (1, 1, CURRENT_DATE - INTERVAL '57 days', 480.0, 'textile',    'processed', 'Woven scraps'),
  (1, 1, CURRENT_DATE - INTERVAL '51 days', 600.0, 'textile',    'processed', 'Q3 excess stock offcuts'),
  (1, 1, CURRENT_DATE - INTERVAL '45 days', 350.0, 'recyclable', 'processed', 'Metal hardware'),
  (1, 1, CURRENT_DATE - INTERVAL '40 days', 520.0, 'mixed',      'processed', 'Mixed production waste'),
  (1, 1, CURRENT_DATE - INTERVAL '35 days', 460.0, 'textile',    'processed', 'Velvet off-rolls'),
  (1, 1, CURRENT_DATE - INTERVAL '29 days', 490.0, 'recyclable', 'processed', 'PET bottles + cans'),
  (1, 1, CURRENT_DATE - INTERVAL '22 days', 540.0, 'textile',    'processed', 'Embroidery thread waste'),
  (1, 1, CURRENT_DATE - INTERVAL '16 days', 410.0, 'mixed',      'processed', 'End-of-line packaging'),
  (1, 1, CURRENT_DATE - INTERVAL '10 days', 470.0, 'textile',    'processed', 'Denim offcuts'),
  (1, 1, CURRENT_DATE - INTERVAL '5  days', 500.0, 'recyclable', 'received',  'Latest shipment'),
  (1, 1, CURRENT_DATE - INTERVAL '1  day',  450.0, 'textile',    'pending',   'Awaiting pickup');

-- ---------------------------------------------------------------------------
-- WASTE EVENTS — Business 2 (Karachi Foods) — 12 events
-- Target total: ~3,100 kg | Target recovered: ~1,990 kg → ratio ~0.642
-- ---------------------------------------------------------------------------
INSERT INTO waste_events (business_id, facility_id, event_date, tonnage, waste_type, status, notes) VALUES
  (2, 1, CURRENT_DATE - INTERVAL '82 days', 280.0, 'organic',    'processed', 'Produce waste batch 1'),
  (2, 1, CURRENT_DATE - INTERVAL '75 days', 220.0, 'organic',    'processed', 'Cold-storage clearance'),
  (2, 1, CURRENT_DATE - INTERVAL '68 days', 310.0, 'recyclable', 'processed', 'Packaging materials'),
  (2, 1, CURRENT_DATE - INTERVAL '61 days', 250.0, 'organic',    'processed', 'Expired stock'),
  (2, 1, CURRENT_DATE - INTERVAL '54 days', 190.0, 'mixed',      'processed', 'Mixed kitchen waste'),
  (2, 1, CURRENT_DATE - INTERVAL '47 days', 270.0, 'organic',    'processed', 'Bulk vegetable trims'),
  (2, 1, CURRENT_DATE - INTERVAL '40 days', 300.0, 'recyclable', 'processed', 'Cartons and wrapping'),
  (2, 1, CURRENT_DATE - INTERVAL '32 days', 240.0, 'organic',    'processed', 'Seasonal fruit surplus'),
  (2, 1, CURRENT_DATE - INTERVAL '24 days', 210.0, 'mixed',      'processed', 'General warehouse waste'),
  (2, 1, CURRENT_DATE - INTERVAL '16 days', 260.0, 'organic',    'received',  'Oct batch'),
  (2, 1, CURRENT_DATE - INTERVAL '8  days', 285.0, 'recyclable', 'received',  'Recent packaging run'),
  (2, 1, CURRENT_DATE - INTERVAL '2  days', 285.0, 'organic',    'pending',   'Awaiting collection');

-- ---------------------------------------------------------------------------
-- WASTE EVENTS — Business 3 (Islamabad Energy) — 9 events
-- Target total: ~3,700 kg | Target recovered: ~1,510 kg → ratio ~0.408
-- ---------------------------------------------------------------------------
INSERT INTO waste_events (business_id, facility_id, event_date, tonnage, waste_type, status, notes) VALUES
  (3, 1, CURRENT_DATE - INTERVAL '80 days', 450.0, 'hazardous',  'processed', 'Battery component waste'),
  (3, 1, CURRENT_DATE - INTERVAL '70 days', 380.0, 'general',    'processed', 'Office renovation debris'),
  (3, 1, CURRENT_DATE - INTERVAL '60 days', 410.0, 'recyclable', 'processed', 'Aluminium panel scraps'),
  (3, 1, CURRENT_DATE - INTERVAL '50 days', 430.0, 'hazardous',  'processed', 'Solar panel off-cuts'),
  (3, 1, CURRENT_DATE - INTERVAL '40 days', 390.0, 'general',    'processed', 'Mixed construction waste'),
  (3, 1, CURRENT_DATE - INTERVAL '28 days', 420.0, 'recyclable', 'received',  'Copper wire scraps'),
  (3, 1, CURRENT_DATE - INTERVAL '18 days', 480.0, 'general',    'received',  'Workshop clearance'),
  (3, 1, CURRENT_DATE - INTERVAL '8  days', 360.0, 'mixed',      'pending',   'New batch'),
  (3, 1, CURRENT_DATE - INTERVAL '2  days', 380.0, 'hazardous',  'pending',   'Awaiting facility slot');

-- ---------------------------------------------------------------------------
-- PROCESSING OUTPUTS — Business 1 (events 1–14 processed; 15,16 pending)
-- Achieving ~82% recovery rate
-- ---------------------------------------------------------------------------
INSERT INTO processing_outputs (event_id, facility_id, recovered_tonnage, output_type, processed_date, notes) VALUES
  (1,  1, 476.0, 'recycled',        CURRENT_DATE - INTERVAL '84 days', 'Textile fibres to mill'),
  (2,  1, 354.0, 'recycled',        CURRENT_DATE - INTERVAL '78 days', 'Paper to recycler'),
  (3,  1, 510.0, 'reused',          CURRENT_DATE - INTERVAL '73 days', 'Fabric donated to Saylani'),
  (4,  1, 318.0, 'recycled',        CURRENT_DATE - INTERVAL '67 days', 'Sorted mixed → recyclables'),
  (5,  1, 418.0, 'recycled',        CURRENT_DATE - INTERVAL '62 days', 'Plastic spools to granulator'),
  (6,  1, 394.0, 'reused',          CURRENT_DATE - INTERVAL '56 days', 'Woven scraps to NGO'),
  (7,  1, 492.0, 'recycled',        CURRENT_DATE - INTERVAL '50 days', 'Cotton to spinning unit'),
  (8,  1, 287.0, 'recycled',        CURRENT_DATE - INTERVAL '44 days', 'Metal to scrap dealer'),
  (9,  1, 427.0, 'energy_recovery', CURRENT_DATE - INTERVAL '39 days', 'Waste-to-energy facility'),
  (10, 1, 377.0, 'recycled',        CURRENT_DATE - INTERVAL '34 days', 'Velvet bales processed'),
  (11, 1, 402.0, 'recycled',        CURRENT_DATE - INTERVAL '28 days', 'Plastics sorted and sold'),
  (12, 1, 443.0, 'reused',          CURRENT_DATE - INTERVAL '21 days', 'Thread to cooperative'),
  (13, 1, 336.0, 'recycled',        CURRENT_DATE - INTERVAL '15 days', 'Packaging to paper mill'),
  (14, 1, 385.0, 'recycled',        CURRENT_DATE - INTERVAL '9  days', 'Denim to shredder');
-- events 15, 16 still pending → no processing output yet

-- ---------------------------------------------------------------------------
-- PROCESSING OUTPUTS — Business 2 (events 17–24 processed; 25,26,27 pending)
-- Achieving ~64% recovery rate
-- ---------------------------------------------------------------------------
INSERT INTO processing_outputs (event_id, facility_id, recovered_tonnage, output_type, processed_date, notes) VALUES
  (17, 1, 179.0, 'composted',       CURRENT_DATE - INTERVAL '81 days', 'Compost facility Lahore'),
  (18, 1, 141.0, 'composted',       CURRENT_DATE - INTERVAL '74 days', 'Organic batch composted'),
  (19, 1, 198.0, 'recycled',        CURRENT_DATE - INTERVAL '67 days', 'Cardboard baled and sold'),
  (20, 1, 160.0, 'composted',       CURRENT_DATE - INTERVAL '60 days', 'Expired stock composted'),
  (21, 1, 122.0, 'energy_recovery', CURRENT_DATE - INTERVAL '53 days', 'Kitchen waste to digester'),
  (22, 1, 173.0, 'composted',       CURRENT_DATE - INTERVAL '46 days', 'Vegetable trims composted'),
  (23, 1, 192.0, 'recycled',        CURRENT_DATE - INTERVAL '39 days', 'Cartons to paper recycler'),
  (24, 1, 154.0, 'composted',       CURRENT_DATE - INTERVAL '31 days', 'Fruit batch composted');
-- events 25,26,27,28 still received/pending

-- ---------------------------------------------------------------------------
-- PROCESSING OUTPUTS — Business 3 (only 4 of 9 events processed → low ratio)
-- ---------------------------------------------------------------------------
INSERT INTO processing_outputs (event_id, facility_id, recovered_tonnage, output_type, processed_date, notes) VALUES
  (29, 1, 360.0, 'recycled',        CURRENT_DATE - INTERVAL '69 days', 'Aluminium panels smelted'),
  (30, 1, 328.0, 'energy_recovery', CURRENT_DATE - INTERVAL '49 days', 'Mixed waste to incinerator'),
  (31, 1, 415.0, 'recycled',        CURRENT_DATE - INTERVAL '39 days', 'General recyclables'),
  (33, 1, 407.0, 'recycled',        CURRENT_DATE - INTERVAL '27 days', 'Copper wire to smelter');
-- events 32, 34, 35, 36, 37 not yet processed → ratio stays ~0.408

-- ---------------------------------------------------------------------------
-- BUSINESS METRICS  (manually set to match seed data above)
-- diversion_ratio = diverted_90d / total_90d
--   B1: 6619/8078 = 0.81932
--   B2: 1319/3100 = 0.64226   (last 4 events still pending → outputs for events 17–24 only)
--   B3: 1510/3660 = 0.41257   (4 events processed out of 7 within 90 days)
-- ---------------------------------------------------------------------------
INSERT INTO business_metrics
    (business_id, diversion_ratio, total_tonnage_90d, diverted_tonnage_90d, diverted_tonnage_30d, last_updated)
VALUES
  (1, 0.81932, 7800.0, 6619.0, 1566.0, NOW()),
  (2, 0.64226, 3100.0, 1990.0,  694.0, NOW()),
  (3, 0.41257, 3660.0, 1510.0,  407.0, NOW());

-- ---------------------------------------------------------------------------
-- CERTIFICATION QUEUE
--   B1 → approved (pre-demo state)
--   B2 → eligible_for_review (auditor will approve during demo)
-- ---------------------------------------------------------------------------
INSERT INTO certification_queue (business_id, status, tier, submitted_at, reviewed_at, reviewer_id, notes) VALUES
  (1, 'approved',            'silver', NOW() - INTERVAL '52 days',
      NOW() - INTERVAL '50 days',
      (SELECT user_id FROM users WHERE email='auditor@pakrastah.gov.pk'),
      'Consistent diversion above 75% for 3 consecutive months.'),
  (2, 'eligible_for_review', 'bronze', NOW() - INTERVAL '2 days',
      NULL, NULL,
      NULL);

-- ---------------------------------------------------------------------------
-- CERTIFICATIONS  (B1 only — B2 gets theirs when auditor approves during demo)
-- ---------------------------------------------------------------------------
INSERT INTO certifications
    (business_id, queue_id, cert_number, tier, issued_date, expiry_date, status)
VALUES
  (1, 1, 'CERT-PKR-2025-0001', 'silver',
   CURRENT_DATE - INTERVAL '50 days',
   CURRENT_DATE - INTERVAL '50 days' + INTERVAL '1 year',
   'active');

-- ---------------------------------------------------------------------------
-- TAX CREDITS  (one prior credit for B1 — procedure was run last month)
-- ---------------------------------------------------------------------------
INSERT INTO tax_credits
    (business_id, certification_id, amount_pkr, diverted_tonnage,
     tier, rate_per_tonne_pkr, calculation_date, procedure_run_id)
VALUES
  (1, 1, 1251.20, 1564.0, 'silver', 800.00,
   CURRENT_DATE - INTERVAL '30 days', 'RUN-SEED-PRIOR-MONTH');

-- ---------------------------------------------------------------------------
-- FOOD RESCUE STUBS  (eateries → charities)
-- ---------------------------------------------------------------------------
INSERT INTO food_donations (eatery_id, charity_id, food_type, quantity_kg, donation_date, status, notes) VALUES
  ((SELECT user_id FROM users WHERE email='eatery1@hotmail.com'),
   (SELECT user_id FROM users WHERE email='charity1@gmail.com'),
   'Baked goods — muffins, croissants', 12.5, CURRENT_DATE - INTERVAL '1 day',  'delivered', 'Evening surplus'),
  ((SELECT user_id FROM users WHERE email='eatery2@hotmail.com'),
   (SELECT user_id FROM users WHERE email='charity2@gmail.com'),
   'Cooked rice and curry', 28.0, CURRENT_DATE - INTERVAL '2 days', 'delivered', 'Lunch leftover'),
  ((SELECT user_id FROM users WHERE email='eatery3@hotmail.com'),
   (SELECT user_id FROM users WHERE email='charity1@gmail.com'),
   'Mixed vegetables — raw', 18.5, CURRENT_DATE - INTERVAL '3 days', 'collected', 'Morning prep waste'),
  ((SELECT user_id FROM users WHERE email='eatery1@hotmail.com'),
   (SELECT user_id FROM users WHERE email='charity2@gmail.com'),
   'Bread loaves', 9.0, CURRENT_DATE - INTERVAL '4 days', 'delivered', 'End-of-day unsold'),
  ((SELECT user_id FROM users WHERE email='eatery2@hotmail.com'),
   (SELECT user_id FROM users WHERE email='charity1@gmail.com'),
   'Dal and roti', 35.0, CURRENT_DATE - INTERVAL '5 days', 'delivered', 'Iftar surplus'),
  ((SELECT user_id FROM users WHERE email='eatery3@hotmail.com'),
   (SELECT user_id FROM users WHERE email='charity2@gmail.com'),
   'Fruit platter — mixed', 22.0, CURRENT_DATE - INTERVAL '6 days', 'delivered', 'Wedding function leftover'),
  ((SELECT user_id FROM users WHERE email='eatery1@hotmail.com'),
   (SELECT user_id FROM users WHERE email='charity1@gmail.com'),
   'Sandwiches and wraps', 14.0, CURRENT_DATE - INTERVAL '7 days', 'delivered', 'Corporate event surplus'),
  ((SELECT user_id FROM users WHERE email='eatery2@hotmail.com'),
   (SELECT user_id FROM users WHERE email='charity1@gmail.com'),
   'Biryani — chicken', 42.0, CURRENT_DATE - INTERVAL '8 days', 'delivered', 'Weekend extra batch'),
  ((SELECT user_id FROM users WHERE email='eatery3@hotmail.com'),
   (SELECT user_id FROM users WHERE email='charity2@gmail.com'),
   'Samosas and pakoras', 16.5, CURRENT_DATE - INTERVAL '1 day', 'pending',   'Ready for collection today'),
  ((SELECT user_id FROM users WHERE email='eatery1@hotmail.com'),
   (SELECT user_id FROM users WHERE email='charity2@gmail.com'),
   'Doughnuts and pastries', 8.0,  CURRENT_DATE,                'pending',   'This morning surplus');

-- ---------------------------------------------------------------------------
-- MARKETPLACE STUBS  (C2C listings)
-- ---------------------------------------------------------------------------
INSERT INTO marketplace_listings (seller_id, title, description, category, price_pkr, quantity, status, city) VALUES
  ((SELECT user_id FROM users WHERE email='citizen1@gmail.com'),
   'Barely Used Samsung LED 32"',
   'Working condition, minor scratch on bezel, original remote included.',
   'electronics', 18500.00, 1, 'active', 'Lahore'),
  ((SELECT user_id FROM users WHERE email='citizen2@gmail.com'),
   'Wooden Study Table',
   'Solid sheesham wood, 5 years old, minor stain on corner.',
   'furniture', 8000.00, 1, 'active', 'Karachi'),
  ((SELECT user_id FROM users WHERE email='citizen3@gmail.com'),
   'Bundle of 20 English Novels',
   'Mix of classics and thrillers, all in readable condition.',
   'books', 1500.00, 20, 'active', 'Islamabad'),
  ((SELECT user_id FROM users WHERE email='citizen4@gmail.com'),
   'Ladies Lawn Suits — 3 Pieces',
   'Unstitched, never worn, lawn quality.',
   'clothing', 2200.00, 3, 'active', 'Lahore'),
  ((SELECT user_id FROM users WHERE email='citizen5@gmail.com'),
   'Manual Washing Machine (Portable)',
   'Mini washing machine, works fine, bought for hostel.',
   'appliances', 4500.00, 1, 'active', 'Karachi'),
  ((SELECT user_id FROM users WHERE email='citizen1@gmail.com'),
   'Iron Rods — Construction Leftover',
   '12mm TMT rods, 6 pieces, 10 ft each, left from renovation.',
   'materials', 3200.00, 6, 'active', 'Lahore'),
  ((SELECT user_id FROM users WHERE email='citizen2@gmail.com'),
   'HP LaserJet Printer',
   'P1102 model, works fine, slightly yellowed body.',
   'electronics', 9800.00, 1, 'sold', 'Karachi'),
  ((SELECT user_id FROM users WHERE email='citizen3@gmail.com'),
   'Kids Bicycle — 20" Wheels',
   'Good condition, new brake pads fitted last month.',
   'other', 5500.00, 1, 'active', 'Islamabad'),
  ((SELECT user_id FROM users WHERE email='citizen4@gmail.com'),
   'Steel Almirah — Double Door',
   'Slightly rusted on top edge, functional lock.',
   'furniture', 7000.00, 1, 'active', 'Lahore'),
  ((SELECT user_id FROM users WHERE email='citizen5@gmail.com'),
   'Tiles — Surplus from Renovation',
   'White 12"×12" floor tiles, approximately 40 pieces.',
   'materials', 2800.00, 40, 'active', 'Karachi');

-- ---------------------------------------------------------------------------
-- Seed a few audit log entries to demo the log viewer
-- ---------------------------------------------------------------------------
INSERT INTO audit_log (table_name, operation, row_id, performed_by, performed_at, old_data, context) VALUES
  ('waste_events', 'DELETE', 99, 'postgres',
   NOW() - INTERVAL '15 days',
   '{"event_id":99,"business_id":1,"tonnage":120.0,"waste_type":"general","status":"pending"}',
   'Test entry deleted during data cleanup'),
  ('businesses', 'DELETE', 9, 'postgres',
   NOW() - INTERVAL '10 days',
   '{"business_id":9,"name":"Test Business Pvt Ltd","city":"Peshawar"}',
   'Duplicate registration removed by admin'),
  ('tax_credits', 'DELETE', 5, 'postgres',
   NOW() - INTERVAL '5 days',
   '{"credit_id":5,"business_id":2,"amount_pkr":450.00}',
   'Erroneous credit reversed after audit finding');

-- ---------------------------------------------------------------------------
-- CITIZEN WALLET BALANCES + SEED TRANSACTIONS
-- ---------------------------------------------------------------------------
UPDATE users SET wallet_balance = 25000.00 WHERE email = 'citizen1@gmail.com';
UPDATE users SET wallet_balance = 15000.00 WHERE email = 'citizen2@gmail.com';
UPDATE users SET wallet_balance = 50000.00 WHERE email = 'citizen3@gmail.com';
UPDATE users SET wallet_balance =  8000.00 WHERE email = 'citizen4@gmail.com';
UPDATE users SET wallet_balance = 30000.00 WHERE email = 'citizen5@gmail.com';

INSERT INTO wallet_transactions (user_id, amount, txn_type, description, created_at) VALUES
  ((SELECT user_id FROM users WHERE email='citizen1@gmail.com'),  25000.00, 'topup', 'Initial wallet top-up', NOW() - INTERVAL '10 days'),
  ((SELECT user_id FROM users WHERE email='citizen2@gmail.com'),  10000.00, 'topup', 'Initial wallet top-up', NOW() - INTERVAL '12 days'),
  ((SELECT user_id FROM users WHERE email='citizen2@gmail.com'),   5000.00, 'topup', 'Top-up',               NOW() - INTERVAL '5 days'),
  ((SELECT user_id FROM users WHERE email='citizen3@gmail.com'),  50000.00, 'topup', 'Initial wallet top-up', NOW() - INTERVAL '8 days'),
  ((SELECT user_id FROM users WHERE email='citizen4@gmail.com'),   8000.00, 'topup', 'Initial wallet top-up', NOW() - INTERVAL '7 days'),
  ((SELECT user_id FROM users WHERE email='citizen5@gmail.com'),  30000.00, 'topup', 'Initial wallet top-up', NOW() - INTERVAL '9 days');

-- ---------------------------------------------------------------------------
-- Re-enable trigger chain
-- ---------------------------------------------------------------------------
ALTER TABLE waste_events        ENABLE TRIGGER trg_waste_events_metrics;
ALTER TABLE processing_outputs  ENABLE TRIGGER trg_processing_outputs_metrics;
ALTER TABLE business_metrics    ENABLE TRIGGER trg_business_metrics_certification;
