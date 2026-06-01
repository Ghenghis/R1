// Configuration for the R1 Creation app.
// IMPORTANT: no API keys here. This app only knows your proxy URL.
// The proxy holds the real provider keys server-side.

window.R1_CONFIG = {
  // Your backend proxy base URL (no trailing slash).
  // For local dev with the proxy on the same machine, use http://localhost:8787
  // For the device, use your deployed HTTPS proxy, e.g. https://api.daveai.tech
  PROXY_BASE_URL: "http://localhost:8787",

  // Optional: if your proxy sets APP_TOKEN, put the SAME token here.
  // This is your own app token, not a Rabbit token. Leave "" if unused.
  APP_TOKEN: "",

  // Providers the user can cycle through. The proxy decides real routing.
  PROVIDERS: ["minimax", "deepseek", "siliconflow"],

  // UI modes.
  MODES: ["chat", "vision", "tool", "voice"],
};
