/**
 * Query Snowflake directly from the browser.
 *
 * Uses Snowflake's SQL REST API with session token authentication.
 * Credentials are read from your VITE_SNOWFLAKE_* env vars.
 *
 * Usage:
 *   import { querySnowflake } from "@/lib/snowflake";
 *
 *   const locations = await querySnowflake("SELECT * FROM LOCATIONS");
 *   const sales = await querySnowflake(`
 *     SELECT l.NAME, SUM(s.REVENUE) AS TOTAL_REVENUE
 *     FROM DAILY_SALES s
 *     JOIN LOCATIONS l ON l.LOCATION_ID = s.LOCATION_ID
 *     GROUP BY l.NAME
 *   `);
 */

const ACCOUNT = import.meta.env.VITE_SNOWFLAKE_ACCOUNT;
const USER = import.meta.env.VITE_SNOWFLAKE_USER;
const PASSWORD = import.meta.env.VITE_SNOWFLAKE_PASSWORD;
const DATABASE = import.meta.env.VITE_SNOWFLAKE_DATABASE;
const SCHEMA = import.meta.env.VITE_SNOWFLAKE_SCHEMA;
const WAREHOUSE = import.meta.env.VITE_SNOWFLAKE_WAREHOUSE;

const BASE_URL = `https://${ACCOUNT}.snowflakecomputing.com`;

let sessionToken: string | null = null;

/**
 * Authenticate with Snowflake and get a session token.
 */
async function login(): Promise<string> {
  if (sessionToken) return sessionToken;

  const res = await fetch(`${BASE_URL}/session/v1/login-request`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      data: {
        ACCOUNT_NAME: ACCOUNT,
        LOGIN_NAME: USER,
        PASSWORD: PASSWORD,
        CLIENT_APP_ID: "SnowconeApp",
        CLIENT_APP_VERSION: "1.0.0",
      },
    }),
  });

  if (!res.ok) {
    throw new Error(`Snowflake login failed (${res.status})`);
  }

  const json = await res.json();
  if (!json.data?.token) {
    throw new Error(json.message || "Snowflake login failed — no token returned");
  }

  sessionToken = json.data.token;
  return sessionToken!;
}

/**
 * Execute a SQL query against Snowflake and return the rows.
 */
export async function querySnowflake<T = Record<string, unknown>>(
  sql: string
): Promise<T[]> {
  const token = await login();

  const res = await fetch(`${BASE_URL}/api/v2/statements`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Snowflake Token="${token}"`,
      "X-Snowflake-Authorization-Token-Type": "SNOWFLAKE",
    },
    body: JSON.stringify({
      statement: sql,
      database: DATABASE,
      schema: SCHEMA,
      warehouse: WAREHOUSE,
      timeout: 30,
    }),
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({ message: res.statusText }));
    throw new Error(err.message || `Query failed (${res.status})`);
  }

  const json = await res.json();

  // The SQL API returns data in a columnar format — convert to row objects
  const columns: string[] = json.resultSetMetaData?.rowType?.map(
    (col: { name: string }) => col.name
  ) ?? [];
  const rows: string[][] = json.data ?? [];

  return rows.map((row) => {
    const obj: Record<string, unknown> = {};
    columns.forEach((col, i) => {
      obj[col] = row[i];
    });
    return obj;
  }) as T[];
}
