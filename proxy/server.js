// Rabbit R1 Safe Proxy
//
// A minimal backend that the R1 Creation app calls over HTTPS. It holds your own
// provider keys server-side so they never ship to the device. It only ever talks to
// MiniMax / DeepSeek / SiliconFlow with keys you supply in proxy/.env.
//
// It does NOT talk to Rabbit's cloud and uses no Rabbit credentials.

import express from "express";
import cors from "cors";
import dotenv from "dotenv";

import * as minimax from "./providers/minimax.js";
import * as deepseek from "./providers/deepseek.js";
import * as siliconflow from "./providers/siliconflow.js";

dotenv.config();

const PORT = Number(process.env.PORT || 8787);
const ALLOWED_ORIGIN = process.env.ALLOWED_ORIGIN || "*";
const APP_TOKEN = process.env.APP_TOKEN || ""; // optional, YOUR app token (not Rabbit's)
const ENABLE_FALLBACK = String(process.env.ENABLE_FALLBACK || "false") === "true";

const PROVIDERS = {
  [minimax.id]: minimax,
  [deepseek.id]: deepseek,
  [siliconflow.id]: siliconflow,
};

const DEFAULT_PROVIDER = process.env.DEFAULT_PROVIDER || "minimax";
const FALLBACKS = [
  process.env.FALLBACK_PROVIDER,
  process.env.SECOND_FALLBACK_PROVIDER,
].filter(Boolean);

const app = express();
app.use(express.json({ limit: "1mb" }));
app.use(cors({ origin: ALLOWED_ORIGIN }));

// Optional app-token gate. This is your own token, not a Rabbit token.
app.use((req, res, next) => {
  if (!APP_TOKEN) return next();
  if (req.path === "/health") return next();
  const auth = req.get("authorization") || "";
  const token = auth.startsWith("Bearer ") ? auth.slice(7) : "";
  if (token !== APP_TOKEN) {
    return res.status(401).json({ error: "Unauthorized" });
  }
  next();
});

app.get("/health", (req, res) => {
  res.json({
    ok: true,
    providersConfigured: {
      minimax: minimax.isConfigured(),
      deepseek: deepseek.isConfigured(),
      siliconflow: siliconflow.isConfigured(),
    },
    defaultProvider: DEFAULT_PROVIDER,
    fallbackEnabled: ENABLE_FALLBACK,
  });
});

app.post("/r1/chat", async (req, res) => {
  const { provider, messages, model, temperature } = req.body || {};

  if (!Array.isArray(messages) || messages.length === 0) {
    return res
      .status(400)
      .json({ error: "`messages` must be a non-empty array" });
  }

  const order = buildProviderOrder(provider);
  if (order.length === 0) {
    return res.status(400).json({ error: `Unknown provider: ${provider}` });
  }

  let lastErr;
  for (const name of order) {
    const mod = PROVIDERS[name];
    if (!mod || !mod.isConfigured()) {
      lastErr = new Error(`Provider not configured: ${name}`);
      lastErr.status = 503;
      continue;
    }
    try {
      const result = await mod.chat({ messages, model, temperature });
      return res.json({
        provider: name,
        model: result.model,
        content: result.content,
      });
    } catch (e) {
      lastErr = e;
      // Only fall through to the next provider on upstream/server errors.
      const retryable = (e.status || 500) >= 502;
      if (!ENABLE_FALLBACK || !retryable) break;
    }
  }

  const status = lastErr?.status || 500;
  return res.status(status).json({
    error: lastErr?.message || "Upstream error",
    provider: order[0],
  });
});

function buildProviderOrder(requested) {
  const start = requested || DEFAULT_PROVIDER;
  if (!PROVIDERS[start]) return [];
  const order = [start];
  if (ENABLE_FALLBACK) {
    for (const f of FALLBACKS) {
      if (f && PROVIDERS[f] && !order.includes(f)) order.push(f);
    }
  }
  return order;
}

app.listen(PORT, () => {
  // No secrets in logs — just confirm what is configured.
  console.log(`[rabbit-r1-safe-proxy] listening on :${PORT}`);
  console.log(
    `[rabbit-r1-safe-proxy] configured: ` +
      `minimax=${minimax.isConfigured()} ` +
      `deepseek=${deepseek.isConfigured()} ` +
      `siliconflow=${siliconflow.isConfigured()}`
  );
});

export default app;
