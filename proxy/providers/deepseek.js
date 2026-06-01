// DeepSeek provider (OpenAI-compatible).
// Reads DEEPSEEK_API_KEY and DEEPSEEK_BASE_URL from the environment.
import { chatCompletion } from "./openaiCompatible.js";

export const id = "deepseek";

export function isConfigured() {
  return Boolean(process.env.DEEPSEEK_API_KEY);
}

export function defaultModel() {
  return process.env.DEEPSEEK_MODEL || "deepseek-chat";
}

export async function chat({ messages, model, temperature }) {
  return chatCompletion({
    baseUrl: process.env.DEEPSEEK_BASE_URL || "https://api.deepseek.com",
    apiKey: process.env.DEEPSEEK_API_KEY,
    model: model || defaultModel(),
    messages,
    temperature,
  });
}
