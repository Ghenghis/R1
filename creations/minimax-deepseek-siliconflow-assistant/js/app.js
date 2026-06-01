// R1 Assistant Creation — UI + proxy calls + hardware hooks.
// No API keys live here. All model calls go through window.R1_CONFIG.PROXY_BASE_URL.

(function () {
  "use strict";

  const cfg = window.R1_CONFIG || {};
  const PROVIDERS = cfg.PROVIDERS || ["minimax", "deepseek", "siliconflow"];
  const MODES = cfg.MODES || ["chat", "vision", "tool", "voice"];

  const el = {
    providerBtn: document.getElementById("providerBtn"),
    modeBtn: document.getElementById("modeBtn"),
    transcript: document.getElementById("transcript"),
    input: document.getElementById("input"),
    sendBtn: document.getElementById("sendBtn"),
    status: document.getElementById("status"),
  };

  const state = {
    provider: PROVIDERS[0],
    mode: MODES[0],
    messages: [],
    busy: false,
  };

  function render() {
    el.providerBtn.textContent = state.provider;
    el.modeBtn.textContent = state.mode;
  }

  function setStatus(text) {
    el.status.textContent = text || "";
  }

  function addMessage(role, content) {
    const div = document.createElement("div");
    div.className =
      "msg " + (role === "user" ? "user" : role === "error" ? "err" : "ai");
    div.textContent = content;
    el.transcript.appendChild(div);
    el.transcript.scrollTop = el.transcript.scrollHeight;
  }

  function cycle(list, current) {
    const i = list.indexOf(current);
    return list[(i + 1) % list.length];
  }

  async function send() {
    const text = el.input.value.trim();
    if (!text || state.busy) return;

    state.busy = true;
    el.input.value = "";
    addMessage("user", text);
    state.messages.push({ role: "user", content: text });
    setStatus(`${state.provider} • thinking…`);

    try {
      const headers = { "Content-Type": "application/json" };
      if (cfg.APP_TOKEN) headers["Authorization"] = "Bearer " + cfg.APP_TOKEN;

      const res = await fetch(cfg.PROXY_BASE_URL + "/r1/chat", {
        method: "POST",
        headers,
        body: JSON.stringify({
          provider: state.provider,
          messages: state.messages,
        }),
      });

      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        throw new Error(data.error || "HTTP " + res.status);
      }

      const reply = data.content || "(empty response)";
      addMessage("ai", reply);
      state.messages.push({ role: "assistant", content: reply });
      setStatus(`${data.provider || state.provider} • ${data.model || ""}`);
      speak(reply);
    } catch (e) {
      addMessage("error", "Error: " + e.message);
      setStatus("error");
    } finally {
      state.busy = false;
    }
  }

  // Optional voice output in "voice" mode (browser TTS; on-device speaker via SDK).
  function speak(text) {
    if (state.mode !== "voice") return;
    try {
      if (window.speechSynthesis) {
        const u = new SpeechSynthesisUtterance(text);
        window.speechSynthesis.speak(u);
      }
    } catch (_) {
      /* no-op */
    }
  }

  // ---- UI events ----
  el.providerBtn.addEventListener("click", () => {
    state.provider = cycle(PROVIDERS, state.provider);
    render();
  });
  el.modeBtn.addEventListener("click", () => {
    state.mode = cycle(MODES, state.mode);
    render();
  });
  el.sendBtn.addEventListener("click", send);
  el.input.addEventListener("keydown", (e) => {
    if (e.key === "Enter") send();
  });

  // ---- Rabbit R1 hardware hooks (graceful no-ops in a browser) ----
  // Side / PTT button => ask AI. Scroll wheel => cycle provider.
  // Event names follow the Creations SDK conventions; guard everything.
  function wireHardware() {
    const onPTT = () => send();
    const onScroll = (dir) => {
      state.provider = cycle(PROVIDERS, state.provider);
      render();
    };

    // Common patterns seen across Creation SDK builds; all optional.
    window.addEventListener("sideClick", onPTT);
    window.addEventListener("longPressStart", onPTT);
    window.addEventListener("scrollUp", () => onScroll("up"));
    window.addEventListener("scrollDown", () => onScroll("down"));

    if (window.PluginMessageHandler) {
      // Some SDK builds deliver hardware events via a message handler.
      window.onPluginMessage = function (data) {
        if (!data) return;
        if (data.type === "side" || data.type === "ptt") onPTT();
        if (data.type === "scroll") onScroll(data.direction);
      };
    }
  }

  render();
  wireHardware();
  setStatus("ready • " + cfg.PROXY_BASE_URL);
})();
