import react from "@vitejs/plugin-react";
import { createLogger, defineConfig, loadEnv } from "vite";

function redactQueryValues(message: string): string {
  return message.replace(/([?&][^=&#\s]+)=([^&#\s]*)/g, "$1=[REDACTED]");
}

const logger = createLogger();
const originalInfo = logger.info.bind(logger);
const originalWarn = logger.warn.bind(logger);
const originalError = logger.error.bind(logger);
logger.info = (message, options) => originalInfo(redactQueryValues(message), options);
logger.warn = (message, options) => originalWarn(redactQueryValues(message), options);
logger.error = (message, options) => originalError(redactQueryValues(message), options);

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), "");
  const target = (
    env.VITE_API_PROXY_TARGET || env.VITE_API_BASE_URL || "http://127.0.0.1:8000"
  ).replace(/\/+$/, "");
  const proxy = {
    target,
    changeOrigin: true,
    secure: true,
  };
  return {
    base: "/NanoBioAI/",
    customLogger: logger,
    plugins: [react()],
    server: {
      proxy: {
        "/api/v1": proxy,
        "/health": proxy,
      },
    },
  };
});
