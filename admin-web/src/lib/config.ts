export type RuntimeConfig = { apiBaseUrl: string };

export function readRuntimeConfig(): RuntimeConfig {
  const configured = String(import.meta.env.VITE_API_BASE_URL ?? "").trim();
  const apiBaseUrl = (configured || window.location.origin).replace(/\/+$/, "");
  let url: URL;
  try {
    url = new URL(apiBaseUrl);
  } catch {
    throw new Error("Địa chỉ API chưa hợp lệ. Hãy kiểm tra VITE_API_BASE_URL.");
  }
  const local = ["localhost", "127.0.0.1", "[::1]"].includes(url.hostname);
  if (url.protocol !== "https:" && !(local && url.protocol === "http:")) {
    throw new Error("Kết nối API cần dùng HTTPS.");
  }
  if (url.username || url.password || url.pathname !== "/" || url.search || url.hash) {
    throw new Error("VITE_API_BASE_URL chỉ nhận địa chỉ gốc của API.");
  }
  return { apiBaseUrl };
}
