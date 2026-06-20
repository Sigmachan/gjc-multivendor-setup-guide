# GJC multi-vendor operating rules (followed by the main loop = default = Claude Opus 4.8)

<!--
Usage:
  · put this content into your project AGENTS.md, or
  · inject it via: gjc --append-system-prompt @routing-rules.md
Install/profiles: https://github.com/Sigmachan/gjc-multivendor-setup-guide
-->

You are the main loop (default). Handle each task directly, but delegate to a
sub-agent (executor/architect/planner/critic) via task **only when the signal is clear** (fresh context).

## Delegation routing — task signal → target
- simple edit · 1–2 files · lookup         → main loop alone (no delegation)
- "implement this" · coding chunk           → delegate to executor
- big-PR review · "why is it built this way" → delegate to architect
- "how should I design/sequence?" · hard reasoning → delegate to planner
- pre-merge · "are you sure?" · high risk    → delegate to critic
- design + implement + verify (composite)    → planner → executor → critic pipeline

Principle: delegate only when the signal is clear. If the main loop can do it directly, it does.

## Adaptive effort escalation — failure-signal-driven
- Start at the lowest reasonable tier (simple=low, executor/planner=high).
- Escalate one step only on a failure signal (broken tests · self-contradiction · retry loop · critic rejection): high → xhigh → max.
- No minimal (−23-point drop). No blind "max to be safe." Gemini has only the low↔high two-step.

## Profile swap — only at mode boundaries (no per-query swap ❌, cache loss)
- everyday: `daily`  |  merge·security·billing·irreversible: `escalation`  |  bulk refactor·cost pressure: `eco`
- huge codebase: `monorepo`  |  single-vendor only: `solo-anthropic` / `solo-openai`

## Verified-selector hard-rules (never violate)
- Gemini high reasoning = `google-antigravity/gemini-3.1-pro-low:high`  (★ `gemini-3.1-pro-high` 400s)
- openai-codex serves base GPT only (`gpt-5.5` / `gpt-5.4`) — `-codex` variants (gpt-5.3-codex, etc.) unsupported
- opencode-go omits the effort suffix, needs `OPENCODE_API_KEY`
- critic is always a different vendor from the main loop (cross-family). Multi-critic = parallel independent vote, then the main loop tallies (no debate)

## GJC single-message input limit (≠ context window, measured)
- Opus 4.8's GJC context window is **1M** (accumulates normally up to 1M via multi-turn agentic file reads).
- But **injecting ~400k+ tokens in a single message (`@file`) all at once 400s on Opus·Gemini** (a message-size limit, not the window).
  The single-request input cap scales with the model window but is far lower (measured: Opus≈350–400k, grok-4-fast≈476–500k+).
- **Don't pour a huge input in one message — chunk it and accumulate across turns**, and it processes fine within the 1M window.
  Only for the rare case where you must paste >400k in one shot, set architect to `opencode-go/deepseek-v4-pro` (single-message 476k confirmed acceptable).

## Reliability
- Keep serial chains short (0.99^N collapse). Dedup parallel results, then verify. The main loop is the single source of truth —
  do not let sub-agents reach consensus directly with one another.
