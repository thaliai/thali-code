<div align="center">

# Thali Code

**An AI coding agent in your terminal — every model, one API, priced in ₹.**

Thali Code is [OpenCode](https://github.com/sst/opencode) pointed at
[Thali](https://thaliai.in): the same great open-source terminal agent, wired to
Thali's OpenAI-compatible gateway so you code against DeepSeek, Qwen, Llama,
Claude, GPT and more — billed in rupees, with 1,000,000 free tokens to start.

</div>

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/thali-ai/thali-code/main/install.sh | bash
```

This installs the OpenCode CLI (if needed), drops in the Thali provider config,
and adds a `thali-code` command. It backs up any existing OpenCode config first.

## Set up (30 seconds)

1. Get your API key — **1,000,000 free tokens, no card** — at **https://thaliai.in**
2. Export it:
   ```bash
   export THALI_API_KEY=thali-sk-…
   ```
3. From any project:
   ```bash
   thali-code
   ```

That's it. You're running an agentic coding assistant on Thali.

## Every Thali model, in the picker — automatically

The install pulls Thali's **live catalog** into OpenCode. Open the `/models`
picker and you'll see every model Thali currently serves — DeepSeek, Qwen,
Llama, Sarvam, Kimi, Claude, GPT and the rest — no hand-editing.

When Thali adds models (new providers, new releases), refresh the list:

```bash
thali-code sync
```

Thali Code defaults to **DeepSeek V3** (strong, cheap, great tool use). Pick any
other in the TUI, or pin a default in `~/.config/opencode/opencode.json`:

```json
{ "model": "thali/anthropic/claude-sonnet-4.6" }
```

> **Credit:** the 1,000,000 free tokens work on Thali's open-model tier
> (DeepSeek, Qwen, Llama, Sarvam, …). Frontier models (Claude, GPT, Kimi K3) draw
> on topped-up credit — pick one before you've added funds and Thali replies with
> a clear "insufficient credit" message, not a silent failure.

## What this is — and isn't

Thali Code **is** a thin, MIT-licensed distribution: a provider config, an
installer, and branding around the unmodified OpenCode agent. The coding
intelligence is OpenCode's; the Thali integration is ours. Full credit and
license terms are in [NOTICE](./NOTICE).

If you want raw OpenCode with your own providers, use
[OpenCode](https://opencode.ai) directly — it's excellent. Thali Code just makes
"OpenCode on Thali, in rupees" a one-line install.

## License

MIT © 2026 Thali Tech Pvt Ltd. Bundles OpenCode (MIT © 2025 opencode). See
[LICENSE](./LICENSE) and [NOTICE](./NOTICE).
