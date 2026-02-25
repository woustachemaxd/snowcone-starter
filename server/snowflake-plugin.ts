import type { Plugin } from "vite";
import snowflake from "snowflake-sdk";
import { config as loadDotenv } from "dotenv";
import fs from "fs";
import path from "path";

// Load .env into process.env (Vite only loads it for client-side import.meta.env)
loadDotenv();

// Disable OCSP checks for trial accounts (avoids connection issues)
snowflake.configure({ ocspFailOpen: true });

let connection: snowflake.Connection | null = null;

function getConnection(): Promise<snowflake.Connection> {
  return new Promise((resolve, reject) => {
    if (connection && connection.isUp()) {
      return resolve(connection);
    }

    const account = process.env.VITE_SNOWFLAKE_ACCOUNT;
    const username = process.env.VITE_SNOWFLAKE_USER;
    const password = process.env.VITE_SNOWFLAKE_PASSWORD;

    if (!account || !username || !password) {
      return reject(
        new Error(
          "Missing Snowflake credentials. Make sure .env exists with VITE_SNOWFLAKE_ACCOUNT, VITE_SNOWFLAKE_USER, and VITE_SNOWFLAKE_PASSWORD."
        )
      );
    }

    const conn = snowflake.createConnection({
      account,
      username,
      password,
      database: process.env.VITE_SNOWFLAKE_DATABASE!,
      schema: process.env.VITE_SNOWFLAKE_SCHEMA!,
      warehouse: process.env.VITE_SNOWFLAKE_WAREHOUSE!,
    });

    conn.connect((err) => {
      if (err) {
        console.error("Snowflake connection failed:", err.message);
        return reject(err);
      }
      console.log("✅ Connected to Snowflake");
      connection = conn;
      resolve(conn);
    });
  });
}

function executeQuery(
  conn: snowflake.Connection,
  sql: string
): Promise<Record<string, unknown>[]> {
  return new Promise((resolve, reject) => {
    conn.execute({
      sqlText: sql,
      complete: (err, _stmt, rows) => {
        if (err) return reject(err);
        resolve((rows as Record<string, unknown>[]) ?? []);
      },
    });
  });
}

/**
 * Vite plugin that provides /api/query during dev
 * and snapshots all table data into static JSON files during build.
 */
export function snowflakePlugin(): Plugin {
  return {
    name: "snowflake-api",

    // Dev server: proxy /api/query to Snowflake
    configureServer(server) {
      server.middlewares.use("/api/query", async (req, res) => {
        if (req.method !== "POST") {
          res.writeHead(405, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ error: "Method not allowed" }));
          return;
        }

        let body = "";
        for await (const chunk of req) body += chunk;

        let sql: string;
        try {
          const parsed = JSON.parse(body);
          sql = parsed.sql;
          if (!sql || typeof sql !== "string") throw new Error("Missing sql");
        } catch {
          res.writeHead(400, { "Content-Type": "application/json" });
          res.end(
            JSON.stringify({
              error: "Request body must be JSON with a 'sql' field",
            })
          );
          return;
        }

        // Block anything that isn't a SELECT
        if (!/^\s*SELECT/i.test(sql)) {
          res.writeHead(403, { "Content-Type": "application/json" });
          res.end(
            JSON.stringify({ error: "Only SELECT queries are allowed" })
          );
          return;
        }

        try {
          const conn = await getConnection();
          const rows = await executeQuery(conn, sql);
          res.writeHead(200, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ data: rows }));
        } catch (err: unknown) {
          const message = err instanceof Error ? err.message : "Unknown error";
          console.error("Snowflake query error:", message);
          res.writeHead(500, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ error: message }));
        }
      });
    },

    // Build: snapshot all tables into /data/*.json so the static site works
    async writeBundle() {
      // Find the output directory from the bundle
      const outDir = path.resolve(process.cwd(), "dist");
      const dataDir = path.join(outDir, "data");
      fs.mkdirSync(dataDir, { recursive: true });

      console.log("\n📸 Snapshotting Snowflake data for static build...");

      try {
        const conn = await getConnection();

        const tables = ["LOCATIONS", "DAILY_SALES", "CUSTOMER_REVIEWS", "INVENTORY"];
        for (const table of tables) {
          const rows = await executeQuery(conn, `SELECT * FROM ${table}`);
          const filePath = path.join(dataDir, `${table}.json`);
          fs.writeFileSync(filePath, JSON.stringify(rows));
          console.log(`  ✅ ${table}: ${rows.length} rows → data/${table}.json`);
        }

        console.log("📸 Snapshot complete!\n");
      } catch (err) {
        console.error("⚠️  Could not snapshot Snowflake data:", err instanceof Error ? err.message : err);
        console.error("   The built site will not have data. Run with a valid .env to include data.\n");
      }
    },
  };
}
