# Snowcone Starter

Starter project for the **Data Mavericks — Data Apps Specialization Test**.

Build an operations dashboard for The Snowcone Warehouse ice cream chain.

## Quick Start

```bash
git clone https://github.com/datamavericks/snowcone-starter
cd snowcone-starter
cp .env.example .env
npm install
npm run dev
```

Opens at [http://localhost:5173](http://localhost:5173).

## Snowflake

Credentials are already filled in `.env.example` — just copy it to `.env`. The dev server connects to Snowflake automatically.

Query from your React code:

```ts
import { querySnowflake } from "@/lib/snowflake";

const locations = await querySnowflake("SELECT * FROM LOCATIONS");
```

---

## Database Schema

### LOCATIONS
15 ice cream stores across Texas.

| Column | Type | Description |
|--------|------|-------------|
| `LOCATION_ID` | INT | Primary key |
| `NAME` | VARCHAR | Store name (e.g. "Downtown Flagship") |
| `CITY` | VARCHAR | City (Austin, Dallas, Houston, San Antonio, etc.) |
| `STATE` | VARCHAR | State code (TX) |
| `ADDRESS` | VARCHAR | Street address |
| `MANAGER_NAME` | VARCHAR | Store manager |
| `OPEN_DATE` | DATE | Date the store opened |
| `SEATING_CAPACITY` | INT | Number of seats |
| `IS_ACTIVE` | BOOLEAN | Whether the store is currently active |

### DAILY_SALES
Daily revenue broken down by order type. ~90 days of data (Nov 2025 – Jan 2026).

| Column | Type | Description |
|--------|------|-------------|
| `SALE_ID` | INT | Primary key (auto-increment) |
| `LOCATION_ID` | INT | Foreign key → LOCATIONS |
| `SALE_DATE` | DATE | Date of the sales record |
| `ORDER_TYPE` | VARCHAR | `'dine-in'`, `'takeout'`, or `'delivery'` |
| `REVENUE` | DECIMAL | Total revenue for this order type on this day |
| `NUM_ORDERS` | INT | Number of orders |
| `AVG_ORDER_VALUE` | DECIMAL | Average order value |

### CUSTOMER_REVIEWS
Customer ratings and review text per location.

| Column | Type | Description |
|--------|------|-------------|
| `REVIEW_ID` | INT | Primary key (auto-increment) |
| `LOCATION_ID` | INT | Foreign key → LOCATIONS |
| `REVIEW_DATE` | DATE | Date of the review |
| `RATING` | DECIMAL | 1.0 to 5.0 |
| `REVIEW_TEXT` | VARCHAR | Review comment |
| `CUSTOMER_NAME` | VARCHAR | Reviewer name |

### INVENTORY
Weekly inventory records by category per location.

| Column | Type | Description |
|--------|------|-------------|
| `INVENTORY_ID` | INT | Primary key (auto-increment) |
| `LOCATION_ID` | INT | Foreign key → LOCATIONS |
| `RECORD_DATE` | DATE | Week start date (Mondays) |
| `CATEGORY` | VARCHAR | `'dairy'`, `'produce'`, `'cones_cups'`, `'toppings'`, or `'syrups'` |
| `UNITS_RECEIVED` | INT | Units received that week |
| `UNITS_USED` | INT | Units consumed |
| `UNITS_WASTED` | INT | Units wasted/expired |
| `WASTE_COST` | DECIMAL | Dollar cost of waste |

### Useful Queries

```sql
-- Revenue by location
SELECT l.NAME, ROUND(SUM(s.REVENUE), 0) AS TOTAL_REVENUE
FROM DAILY_SALES s JOIN LOCATIONS l ON l.LOCATION_ID = s.LOCATION_ID
GROUP BY l.NAME ORDER BY TOTAL_REVENUE DESC;

-- Average rating per location
SELECT l.NAME, ROUND(AVG(r.RATING), 1) AS AVG_RATING
FROM CUSTOMER_REVIEWS r JOIN LOCATIONS l ON l.LOCATION_ID = r.LOCATION_ID
GROUP BY l.NAME ORDER BY AVG_RATING DESC;

-- Waste by location and category
SELECT l.NAME, i.CATEGORY, SUM(i.UNITS_WASTED) AS TOTAL_WASTE, ROUND(SUM(i.WASTE_COST), 2) AS TOTAL_WASTE_COST
FROM INVENTORY i JOIN LOCATIONS l ON l.LOCATION_ID = i.LOCATION_ID
GROUP BY l.NAME, i.CATEGORY ORDER BY TOTAL_WASTE_COST DESC;

-- Daily revenue trend for a specific location
SELECT s.SALE_DATE, SUM(s.REVENUE) AS DAILY_REVENUE
FROM DAILY_SALES s WHERE s.LOCATION_ID = 1
GROUP BY s.SALE_DATE ORDER BY s.SALE_DATE;

-- Revenue breakdown by order type
SELECT ORDER_TYPE, ROUND(SUM(REVENUE), 0) AS TOTAL
FROM DAILY_SALES GROUP BY ORDER_TYPE;
```

---

## Tech Stack

| Tech | Purpose |
|------|---------|
| [React](https://react.dev) + [Vite](https://vite.dev) | Framework |
| [shadcn/ui](https://ui.shadcn.com) | Components |
| [Recharts](https://recharts.org) | Charts |
| [Snowflake](https://snowflake.com) | Data layer |

## Submit

When you're done:

```bash
./submit.sh your.name@datamavericks.com
```

Your app goes live at `data-apps-spec.deepanshu.tech/submission/your-name`.

Good luck!
