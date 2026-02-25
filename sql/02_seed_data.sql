-- ============================================================
-- SNOWCONE WAREHOUSE — Seed Data
-- Run after 01_setup.sql. Uses ACCOUNTADMIN.
-- Creates ~90 days of data with realistic patterns.
-- ============================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWCONE_DB;
USE SCHEMA SNOWCONE;
USE WAREHOUSE SNOWCONE_WH;

-- ── LOCATIONS (15 stores) ──────────────────────────────────

INSERT INTO LOCATIONS (LOCATION_ID, NAME, CITY, STATE, ADDRESS, MANAGER_NAME, OPEN_DATE, SEATING_CAPACITY)
VALUES
  (1,  'Downtown Flagship',   'Austin',        'TX', '401 Congress Ave',       'Maria Santos',    '2022-03-15', 60),
  (2,  'Lakeside Plaza',      'Austin',        'TX', '2200 Lake Austin Blvd',  'Jake Thompson',   '2022-06-01', 45),
  (3,  'Midtown Square',      'Dallas',        'TX', '1500 Main St',           'Priya Patel',     '2022-04-20', 50),
  (4,  'Uptown Market',       'Dallas',        'TX', '3200 McKinney Ave',      'Carlos Rivera',   '2022-09-10', 40),
  (5,  'Westside Commons',    'Houston',       'TX', '5000 Westheimer Rd',     'Aisha Johnson',   '2022-07-15', 55),
  (6,  'Heights Hub',         'Houston',       'TX', '350 W 19th St',          'Ben Nakamura',    '2023-01-20', 35),
  (7,  'Pearl District',      'San Antonio',   'TX', '303 Pearl Pkwy',         'Sofia Guerrero',  '2023-02-14', 50),
  (8,  'Riverwalk',           'San Antonio',   'TX', '100 E Commerce St',      'Mike Chen',       '2023-05-01', 65),
  (9,  'Campus Corner',       'College Station','TX','401 University Dr',      'Taylor Kim',      '2023-06-15', 30),
  (10, 'Beachfront',          'Galveston',     'TX', '2100 Seawall Blvd',      'Jordan Lee',      '2023-08-01', 45),
  (11, 'Suburbia',            'Plano',         'TX', '8000 Preston Rd',        'Rachel Green',    '2023-09-01', 40),
  (12, 'Old Town',            'Fort Worth',    'TX', '140 E Exchange Ave',     'David Okafor',    '2023-10-15', 35),
  (13, 'Tech District',       'Austin',        'TX', '11600 Domain Dr',        'Lisa Park',       '2024-01-10', 50),
  (14, 'Mall Location',       'San Marcos',    'TX', '3939 I-35 South',        'Tom Rodriguez',   '2024-03-01', 25),
  (15, 'Airport Terminal',    'Houston',       'TX', 'IAH Terminal C',         'Nina Williams',   '2024-05-15', 20);


-- ── DAILY_SALES ────────────────────────────────────────────
-- 90 days × 15 locations × 3 order types

EXECUTE IMMEDIATE $$
DECLARE
  loc_id INT;
  d DATE;
  start_date DATE := '2025-11-01';
  end_date DATE := '2026-01-31';
  base_rev FLOAT;
  daily_rev FLOAT;
  day_of_week INT;
  trend_mult FLOAT;
  day_num INT;
  order_types ARRAY := ARRAY_CONSTRUCT('dine-in', 'takeout', 'delivery');
  ot VARCHAR;
  ot_split FLOAT;
  num_orders INT;
  seg_rev FLOAT;
  avg_order FLOAT;
  avg_ov FLOAT;
  weekend_mult FLOAT;
  noise FLOAT;
BEGIN
  FOR loc_id IN 1 TO 15 DO
    d := start_date;
    day_num := 0;

    WHILE (d <= end_date) DO
      day_of_week := DAYOFWEEK(d);

      -- Base daily revenue by location tier
      CASE loc_id
        WHEN 1 THEN base_rev := 2800;
        WHEN 2 THEN base_rev := 1600;
        WHEN 3 THEN base_rev := 2400;
        WHEN 4 THEN base_rev := 1400;
        WHEN 5 THEN base_rev := 2200;
        WHEN 6 THEN base_rev := 1300;
        WHEN 7 THEN base_rev := 1700;
        WHEN 8 THEN base_rev := 2500;
        WHEN 9 THEN base_rev := 900;
        WHEN 10 THEN base_rev := 800;
        WHEN 11 THEN base_rev := 1500;
        WHEN 12 THEN base_rev := 1100;
        WHEN 13 THEN base_rev := 1900;
        WHEN 14 THEN base_rev := 700;
        WHEN 15 THEN base_rev := 1000;
      END;

      -- Trend multiplier over 90 days
      CASE loc_id
        WHEN 1 THEN trend_mult := 1.0 + (day_num * 0.002);
        WHEN 3 THEN trend_mult := 1.0 + (day_num * 0.0015);
        WHEN 5 THEN trend_mult := 1.0 + (day_num * 0.0018);
        WHEN 8 THEN trend_mult := 1.0 + (day_num * 0.001);
        WHEN 9 THEN trend_mult := 1.0 - (day_num * 0.003);
        WHEN 10 THEN trend_mult := 1.0 - (day_num * 0.004);
        WHEN 14 THEN trend_mult := 1.0 - (day_num * 0.002);
        WHEN 15 THEN trend_mult := 1.0 + (day_num * 0.003);
        ELSE trend_mult := 1.0 + (day_num * 0.0005);
      END;

      -- Weekend boost
      weekend_mult := 1.0;
      IF (day_of_week = 0 OR day_of_week = 6) THEN
        weekend_mult := 1.3;
      ELSEIF (day_of_week = 5) THEN
        weekend_mult := 1.15;
      END IF;

      -- Random noise ±15%
      noise := 0.85 + ABS(RANDOM() % 30) / 100.0;
      daily_rev := base_rev * trend_mult * weekend_mult * noise;

      -- Split across order types
      FOR i IN 0 TO 2 DO
        ot := order_types[i];
        CASE i
          WHEN 0 THEN ot_split := 0.50 + ABS(RANDOM() % 10 - 5) / 100.0;
          WHEN 1 THEN ot_split := 0.30 + ABS(RANDOM() % 6 - 3) / 100.0;
          WHEN 2 THEN ot_split := 0.20 + ABS(RANDOM() % 6 - 3) / 100.0;
        END;

        seg_rev := ROUND(daily_rev * ot_split, 2);
        avg_order := 8.50 + ABS(RANDOM() % 700) / 100.0;
        num_orders := GREATEST(1, ROUND(seg_rev / avg_order));
        avg_ov := ROUND(seg_rev / num_orders, 2);

        INSERT INTO DAILY_SALES (LOCATION_ID, SALE_DATE, ORDER_TYPE, REVENUE, NUM_ORDERS, AVG_ORDER_VALUE)
        VALUES (:loc_id, :d, :ot, :seg_rev, :num_orders, :avg_ov);
      END FOR;

      d := DATEADD(day, 1, d);
      day_num := day_num + 1;
    END WHILE;
  END FOR;
END;
$$;


-- ── CUSTOMER_REVIEWS ───────────────────────────────────────

EXECUTE IMMEDIATE $$
DECLARE
  loc_id INT;
  d DATE;
  start_date DATE := '2025-11-01';
  end_date DATE := '2026-01-31';
  base_rating FLOAT;
  review_chance INT;
  rating FLOAT;
  review_text VARCHAR;
  cust_name VARCHAR;
BEGIN
  FOR loc_id IN 1 TO 15 DO
    d := start_date;
    WHILE (d <= end_date) DO
      review_chance := ABS(RANDOM() % 100);
      IF (review_chance < 70) THEN
        CASE loc_id
          WHEN 1 THEN base_rating := 4.5;
          WHEN 2 THEN base_rating := 3.8;
          WHEN 3 THEN base_rating := 4.3;
          WHEN 4 THEN base_rating := 3.6;
          WHEN 5 THEN base_rating := 4.2;
          WHEN 6 THEN base_rating := 3.5;
          WHEN 7 THEN base_rating := 4.0;
          WHEN 8 THEN base_rating := 4.4;
          WHEN 9 THEN base_rating := 2.8;
          WHEN 10 THEN base_rating := 3.0;
          WHEN 11 THEN base_rating := 3.7;
          WHEN 12 THEN base_rating := 3.4;
          WHEN 13 THEN base_rating := 4.1;
          WHEN 14 THEN base_rating := 2.5;
          WHEN 15 THEN base_rating := 3.9;
        END;

        rating := GREATEST(1.0, LEAST(5.0,
          ROUND(base_rating + (ABS(RANDOM() % 10) - 5) / 10.0, 1)
        ));

        CASE
          WHEN rating >= 4.5 THEN review_text := 'Amazing ice cream! Best in town. Will definitely come back.';
          WHEN rating >= 4.0 THEN review_text := 'Great flavors and friendly staff. Really enjoyed our visit.';
          WHEN rating >= 3.5 THEN review_text := 'Good ice cream, decent service. Nothing special but solid.';
          WHEN rating >= 3.0 THEN review_text := 'It was okay. The wait was long and some flavors were out.';
          WHEN rating >= 2.5 THEN review_text := 'Disappointing experience. Store was messy and service was slow.';
          WHEN rating >= 2.0 THEN review_text := 'Not great. Ice cream was melty and the place needs cleaning.';
          ELSE review_text := 'Terrible experience. Would not recommend. Staff was rude.';
        END;

        CASE ABS(RANDOM() % 20)
          WHEN 0 THEN cust_name := 'Alex M.';
          WHEN 1 THEN cust_name := 'Jordan P.';
          WHEN 2 THEN cust_name := 'Sam K.';
          WHEN 3 THEN cust_name := 'Chris L.';
          WHEN 4 THEN cust_name := 'Pat R.';
          WHEN 5 THEN cust_name := 'Morgan T.';
          WHEN 6 THEN cust_name := 'Casey B.';
          WHEN 7 THEN cust_name := 'Riley S.';
          WHEN 8 THEN cust_name := 'Quinn D.';
          WHEN 9 THEN cust_name := 'Avery N.';
          WHEN 10 THEN cust_name := 'Jamie W.';
          WHEN 11 THEN cust_name := 'Drew H.';
          WHEN 12 THEN cust_name := 'Peyton F.';
          WHEN 13 THEN cust_name := 'Reese G.';
          WHEN 14 THEN cust_name := 'Skylar J.';
          WHEN 15 THEN cust_name := 'Emerson C.';
          WHEN 16 THEN cust_name := 'Finley A.';
          WHEN 17 THEN cust_name := 'Rowan V.';
          WHEN 18 THEN cust_name := 'Sage O.';
          ELSE cust_name := 'Dakota E.';
        END;

        INSERT INTO CUSTOMER_REVIEWS (LOCATION_ID, REVIEW_DATE, RATING, REVIEW_TEXT, CUSTOMER_NAME)
        VALUES (:loc_id, :d, :rating, :review_text, :cust_name);
      END IF;

      d := DATEADD(day, 1, d);
    END WHILE;
  END FOR;
END;
$$;


-- ── INVENTORY ──────────────────────────────────────────────

EXECUTE IMMEDIATE $$
DECLARE
  loc_id INT;
  d DATE;
  start_date DATE := '2025-11-04';
  end_date DATE := '2026-01-27';
  categories ARRAY := ARRAY_CONSTRUCT('dairy', 'produce', 'cones_cups', 'toppings', 'syrups');
  cat VARCHAR;
  base_units INT;
  waste_pct FLOAT;
  units_recv INT;
  units_waste INT;
  units_used INT;
  cost_per_unit FLOAT;
  noise FLOAT;
  w_cost FLOAT;
BEGIN
  FOR loc_id IN 1 TO 15 DO
    d := start_date;
    WHILE (d <= end_date) DO
      FOR c IN 0 TO 4 DO
        cat := categories[c];

        CASE cat
          WHEN 'dairy'      THEN base_units := 200; cost_per_unit := 3.50;
          WHEN 'produce'    THEN base_units := 150; cost_per_unit := 2.00;
          WHEN 'cones_cups' THEN base_units := 300; cost_per_unit := 0.50;
          WHEN 'toppings'   THEN base_units := 180; cost_per_unit := 1.50;
          WHEN 'syrups'     THEN base_units := 100; cost_per_unit := 4.00;
        END;

        CASE loc_id
          WHEN 1 THEN waste_pct := 0.04;
          WHEN 3 THEN waste_pct := 0.05;
          WHEN 5 THEN waste_pct := 0.05;
          WHEN 8 THEN waste_pct := 0.06;
          WHEN 9 THEN waste_pct := 0.18;
          WHEN 10 THEN waste_pct := 0.22;
          WHEN 14 THEN waste_pct := 0.20;
          WHEN 6 THEN waste_pct := 0.12;
          WHEN 12 THEN waste_pct := 0.14;
          ELSE waste_pct := 0.07;
        END;

        noise := 0.85 + ABS(RANDOM() % 30) / 100.0;
        units_recv := ROUND(base_units * noise);
        units_waste := GREATEST(0, ROUND(units_recv * waste_pct * (0.8 + ABS(RANDOM() % 40) / 100.0)));
        units_used := units_recv - units_waste;
        w_cost := ROUND(units_waste * cost_per_unit, 2);

        INSERT INTO INVENTORY (LOCATION_ID, RECORD_DATE, CATEGORY, UNITS_RECEIVED, UNITS_USED, UNITS_WASTED, WASTE_COST)
        VALUES (:loc_id, :d, :cat, :units_recv, :units_used, :units_waste, :w_cost);
      END FOR;

      d := DATEADD(day, 7, d);
    END WHILE;
  END FOR;
END;
$$;


-- ── Verify ─────────────────────────────────────────────────
SELECT 'LOCATIONS' AS tbl, COUNT(*) AS rows FROM LOCATIONS
UNION ALL SELECT 'DAILY_SALES', COUNT(*) FROM DAILY_SALES
UNION ALL SELECT 'CUSTOMER_REVIEWS', COUNT(*) FROM CUSTOMER_REVIEWS
UNION ALL SELECT 'INVENTORY', COUNT(*) FROM INVENTORY;
