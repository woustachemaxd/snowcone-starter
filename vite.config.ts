import path from "path"
import tailwindcss from "@tailwindcss/vite"
import react from "@vitejs/plugin-react"
import { defineConfig } from "vite"
import { snowflakePlugin } from "./server/snowflake-plugin"

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss(), snowflakePlugin()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
})
