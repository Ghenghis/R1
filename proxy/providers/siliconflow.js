// SiliconFlow provider (OpenAI-compatible).
// Reads SILICONFLOW_API_KEY and SILICONFLOW_BASE_URL from the environment.
// Base URL is kept configurable because SiliconFlow docs show both .cn and .com hosts.
import { chatCompletion } from "./openaiCompatible.js";

export const id = "siliconflow";

export function isConfigured() {
  return Boolean(process.env.SILICONFLOW_API_KEY);
}

export function defaultModel() {
  return process.env.SILICONFLOW_MODEL || "deepseek-ai/DeepSeek-V3";
}

export async function chat({ messages, model, temperature }) {
  return chatCompletion({
    baseUrl: process.env.SILICONFLOW_BASE_URL || "https://api.siliconflow.cn/v1",
    apiKey: process.env.SILICONFLOW_API_KEY,
    model: model || defaultModel(),
    messages,
    temperature,
  });
}
