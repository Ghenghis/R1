// Shared client for OpenAI-compatible chat completion APIs.
// Used by the MiniMax, DeepSeek, and SiliconFlow provider modules.
//
// Keys and base URLs are read from environment variables by the calling module and
// passed in here. This file never reads process.env directly and never logs secrets.

/**
 * Call an OpenAI-compatible /chat/completions endpoint.
 *
 * @param {object} opts
 * @param {string} opts.baseUrl  e.g. https://api.deepseek.com
 * @param {string} opts.apiKey   your own provider API key
 * @param {string} opts.model    model id
 * @param {Array<{role:string,content:string}>} opts.messages
 * @param {number} [opts.temperature]
 * @param {number} [opts.timeoutMs]
 * @returns {Promise<{content:string, model:string, raw:object}>}
 */
export async function chatCompletion({
  baseUrl,
  apiKey,
  model,
  messages,
  temperature = 0.7,
  timeoutMs = 60000,
}) {
  if (!apiKey) {
    const err = new Error("Missing API key for provider");
    err.status = 500;
    err.code = "NO_KEY";
    throw err;
  }
  if (!Array.isArray(messages) || messages.length === 0) {
    const err = new Error("`messages` must be a non-empty array");
    err.status = 400;
    throw err;
  }

  const url = joinUrl(baseUrl, "/chat/completions");
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  let res;
  try {
    res = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({ model, messages, temperature }),
      signal: controller.signal,
    });
  } catch (e) {
    clearTimeout(timer);
    const err = new Error(`Network error contacting provider: ${e.message}`);
    err.status = 502;
    err.code = "UPSTREAM_NETWORK";
    throw err;
  }
  clearTimeout(timer);

  const text = await res.text();
  let data;
  try {
    data = text ? JSON.parse(text) : {};
  } catch {
    data = { raw: text };
  }

  if (!res.ok) {
    // Surface upstream status but never include the api key.
    const msg =
      data?.error?.message || data?.message || `Provider returned ${res.status}`;
    const err = new Error(msg);
    err.status = res.status >= 500 ? 502 : res.status;
    err.code = "UPSTREAM_ERROR";
    err.upstreamStatus = res.status;
    throw err;
  }

  const content =
    data?.choices?.[0]?.message?.content ??
    data?.choices?.[0]?.text ??
    "";

  return { content, model: data?.model || model, raw: data };
}

function joinUrl(base, path) {
  const b = String(base || "").replace(/\/+$/, "");
  const p = String(path || "").replace(/^\/+/, "");
  return `${b}/${p}`;
}
