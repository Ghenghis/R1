// MiniMax provider (OpenAI-compatible).
// Reads MINIMAX_API_KEY and MINIMAX_BASE_URL from the environment.
import { chatCompletion } from "./openaiCompatible.js";

export const id = "minimax";

export function isConfigured() {
  return Boolean(process.env.MINIMAX_API_KEY);
}

export function defaultModel() {
  return process.env.MINIMAX_MODEL || "MiniMax-Text-01";
}

export async function chat({ messages, model, temperature }) {
  return chatCompletion({
    baseUrl: process.env.MINIMAX_BASE_URL || "https://api.minimax.io/v1",
    apiKey: process.env.MINIMAX_API_KEY,
    model: model || defaultModel(),
    messages,
    temperature,
  });
}
