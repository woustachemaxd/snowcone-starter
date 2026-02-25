import { useEffect, useState, useMemo } from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { querySnowflake } from "@/lib/snowflake";

interface Location {
  LOCATION_ID: number;
  NAME: string;
  CITY: string;
  STATE: string;
}

interface DailySale {
  LOCATION_ID: number;
  SALE_DATE: string;
  ORDER_TYPE: string;
  REVENUE: number;
  NUM_ORDERS: number;
}

export default function App() {
  const [locations, setLocations] = useState<Location[]>([]);
  const [sales, setSales] = useState<DailySale[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchData() {
      try {
        const [locs, dailySales] = await Promise.all([
          querySnowflake<Location>("SELECT * FROM LOCATIONS ORDER BY LOCATION_ID"),
          querySnowflake<DailySale>("SELECT * FROM DAILY_SALES"),
        ]);
        setLocations(locs);
        setSales(dailySales);
      } catch (e) {
        setError(e instanceof Error ? e.message : "Failed to connect");
      } finally {
        setLoading(false);
      }
    }
    fetchData();
  }, []);

  // Aggregate revenue by location (client-side so it works in dev + production)
  const revenueByLocation = useMemo(() => {
    const totals: Record<number, number> = {};
    for (const s of sales) {
      totals[s.LOCATION_ID] = (totals[s.LOCATION_ID] || 0) + Number(s.REVENUE);
    }
    return locations
      .map((loc) => ({
        name: loc.NAME,
        revenue: Math.round(totals[loc.LOCATION_ID] || 0),
      }))
      .sort((a, b) => b.revenue - a.revenue);
  }, [locations, sales]);

  const totalRevenue = revenueByLocation.reduce((sum, r) => sum + r.revenue, 0);

  return (
    <div className="min-h-screen bg-background">
      {/* Nav */}
      <nav className="border-b px-6 py-3 flex items-center justify-between">
        <span className="text-xs tracking-widest text-muted-foreground uppercase">
          Data Mavericks — Data Apps Specialization Test
        </span>
        <span className="text-xs tracking-wider text-muted-foreground">
          snowcone-starter
        </span>
      </nav>

      <main className="max-w-5xl mx-auto px-6 py-10 space-y-8">
        {/* Hero */}
        <div>
          <p className="text-xs tracking-widest text-primary font-semibold mb-2">
            ◆ YOUR STARTING POINT
          </p>
          <h1 className="text-3xl font-bold tracking-tight">
            Delete this file and build something great
            <span className="text-primary">.</span>
          </h1>
          <p className="text-muted-foreground mt-2 max-w-lg">
            This page demos the Snowflake connection with live data. Everything
            below is fetched from your <code className="text-xs bg-muted px-1.5 py-0.5 rounded">SNOWCONE_DB</code> database.
          </p>
        </div>

        {/* Connection status */}
        {loading && (
          <Card>
            <CardContent className="py-8 text-center text-muted-foreground">
              Connecting to Snowflake...
            </CardContent>
          </Card>
        )}

        {error && (
          <Card className="border-destructive">
            <CardContent className="py-6">
              <p className="font-semibold text-destructive">Connection failed</p>
              <p className="text-sm text-muted-foreground mt-1">{error}</p>
              <p className="text-sm text-muted-foreground mt-3">
                Make sure you've copied <code className="bg-muted px-1.5 py-0.5 rounded text-xs">.env.example</code> to{" "}
                <code className="bg-muted px-1.5 py-0.5 rounded text-xs">.env</code> and run the SQL setup scripts.
              </p>
            </CardContent>
          </Card>
        )}

        {!loading && !error && (
          <>
            {/* Stats row */}
            <div className="grid grid-cols-3 gap-4">
              <Card>
                <CardContent className="pt-6">
                  <p className="text-sm text-muted-foreground">Locations</p>
                  <p className="text-2xl font-bold">{locations.length}</p>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="pt-6">
                  <p className="text-sm text-muted-foreground">Total Revenue</p>
                  <p className="text-2xl font-bold">
                    ${totalRevenue.toLocaleString()}
                  </p>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="pt-6">
                  <p className="text-sm text-muted-foreground">Top Location</p>
                  <p className="text-2xl font-bold">{revenueByLocation[0]?.name ?? "—"}</p>
                </CardContent>
              </Card>
            </div>

            {/* Chart */}
            <Card>
              <CardHeader>
                <CardTitle>Revenue by Location</CardTitle>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={320}>
                  <BarChart
                    data={revenueByLocation}
                    margin={{ top: 0, right: 0, left: -10, bottom: 0 }}
                  >
                    <CartesianGrid strokeDasharray="3 3" className="stroke-border" />
                    <XAxis
                      dataKey="name"
                      tick={{ fontSize: 11 }}
                      angle={-35}
                      textAnchor="end"
                      height={80}
                    />
                    <YAxis
                      tick={{ fontSize: 11 }}
                      tickFormatter={(v) => `$${(v / 1000).toFixed(0)}k`}
                    />
                    <Tooltip formatter={(v) => [`$${Number(v).toLocaleString()}`, "Revenue"]} />
                    <Bar dataKey="revenue" fill="var(--color-primary)" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>

            {/* Locations table */}
            <Card>
              <CardHeader>
                <CardTitle>All Locations</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b text-left">
                        <th className="pb-2 font-medium text-muted-foreground">ID</th>
                        <th className="pb-2 font-medium text-muted-foreground">Name</th>
                        <th className="pb-2 font-medium text-muted-foreground">City</th>
                        <th className="pb-2 font-medium text-muted-foreground">State</th>
                      </tr>
                    </thead>
                    <tbody>
                      {locations.map((loc) => (
                        <tr key={loc.LOCATION_ID} className="border-b last:border-0">
                          <td className="py-2 text-muted-foreground">{loc.LOCATION_ID}</td>
                          <td className="py-2 font-medium">{loc.NAME}</td>
                          <td className="py-2">{loc.CITY}</td>
                          <td className="py-2">
                            <Badge variant="secondary">{loc.STATE}</Badge>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </CardContent>
            </Card>

            {/* How to query */}
            <Card className="bg-muted/50">
              <CardHeader>
                <CardTitle className="text-base">How to query Snowflake</CardTitle>
              </CardHeader>
              <CardContent>
                <pre className="text-sm bg-foreground text-background rounded-md p-4 overflow-x-auto">
{`import { querySnowflake } from "@/lib/snowflake";

const locations = await querySnowflake("SELECT * FROM LOCATIONS");
const sales = await querySnowflake(\`
  SELECT l.NAME, SUM(s.REVENUE) AS TOTAL_REVENUE
  FROM DAILY_SALES s
  JOIN LOCATIONS l ON l.LOCATION_ID = s.LOCATION_ID
  GROUP BY l.NAME
\`);`}
                </pre>
              </CardContent>
            </Card>
          </>
        )}
      </main>

      <footer className="border-t px-6 py-4 flex items-center justify-between text-xs text-muted-foreground">
        <span>DATA MAVERICKS — THE SNOWCONE WAREHOUSE CHALLENGE</span>
        <span>Build something great. We're rooting for you.</span>
      </footer>
    </div>
  );
}
