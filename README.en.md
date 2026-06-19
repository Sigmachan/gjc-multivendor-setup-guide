<div align="center">

# 🧩 GJC Multi-Vendor Extreme Setup

### claude · gpt · grok · gemini · opencode go — a verified setup that splits 5 subscriptions *by role*

Stop agonizing over model choice. **Install in one line** and let each role get its best-fit model automatically.

[![GJC](https://img.shields.io/badge/for-Gajae%20Code%20(GJC)-e23?style=flat-square)](https://github.com/Yeachan-Heo/gajae-code)
[![Version](https://img.shields.io/badge/version-1.3-2496ED?style=flat-square)](./CHANGELOG.md)
[![Upstream](https://img.shields.io/badge/upstream-merged%20into%20GJC%20docs-brightgreen?style=flat-square)](https://github.com/Yeachan-Heo/gajae-code/pull/860)
![Profiles](https://img.shields.io/badge/profiles-10-blue?style=flat-square)
![Vendors](https://img.shields.io/badge/vendors-5-success?style=flat-square)
![Verified](https://img.shields.io/badge/selectors-live%20tested%202026--06--18-brightgreen?style=flat-square)
![License](https://img.shields.io/badge/license-CC%20BY%204.0-lightgrey?style=flat-square)

<img src="assets/role-winners.svg" alt="ultimate setup — strongest model per role" width="100%">

</div>

**[한국어](./README.md) · English (this page) · [中文](./README.zh.md) · [日本語](./README.ja.md)**

> [!NOTE]
> **The core of this guide was adopted into the official GJC docs** — a condensed version was merged upstream as [`docs/multi-vendor-profiles.md`](https://github.com/Yeachan-Heo/gajae-code/blob/dev/docs/multi-vendor-profiles.md) ([PR #860](https://github.com/Yeachan-Heo/gajae-code/pull/860), `dev`). Treat the **official GJC docs as the canonical reference** for the role/selector concepts; this repo provides what those docs do not — the **one-line installer**, the **full set of 10 profiles** (incl. `solo-*` / `claude-codex*`), and [maintenance & validation tooling](./MAINTAINING.md) (static-check CI + live selector battery + catalog drift tracking).

---

## ⚡ 30-second install (one-line copy-paste)

```bash
curl -fsSL https://raw.githubusercontent.com/project820/gjc-multivendor-setup-guide/main/install.sh | bash
```

This single line **safely merges 10 profiles into `~/.gjc/agent/models.yml`** and sets `daily` as the default profile. Your existing config is backed up automatically, and re-running cleanly updates in place.

```bash
gjc --mpreset daily        # this session only
gjc                        # new sessions use daily automatically
```

> [!IMPORTANT]
> **You must log in to providers after installing.** GJC uses its own OAuth (not shared with the native `agy`/`grok` CLI logins), so open GJC and run each of these once (browser auth):
>
> ```text
> /login anthropic           # claude
> /login openai-codex        # gpt (ChatGPT account → serves base GPT)
> /login google-antigravity  # gemini (Google AI Pro/Ultra subscription)
> /login xai                 # grok full lineup + Composer
> ```
> opencode-go uses an API key: `/provider add`, or the `OPENCODE_API_KEY` env var. Check auth state with `/provider`.

> [!TIP]
> Pick the default profile: `curl -fsSL …/install.sh | GJC_SETUP_DEFAULT=ultimate bash` · skip default-setting: `GJC_SETUP_DEFAULT=none`.

---

## 1. 🎯 Why multi-vendor

Subscribing to claude·gpt·grok·gemini·opencode go and then using only one model means running a *second-best* model in every role. Verified benchmarks show **the leading vendor differs per role**:

| Role | What it does | Best model |
|---|---|---|
| 🧠 **reasoning/planning** (planner) | sequencing, acceptance criteria | **Gemini 3.1 Pro** (GPQA 94.3 / ARC-AGI-2 77.1) |
| 🔨 **implementation** (executor) | writing/editing real code | **Claude Opus 4.8** (SWE-bench Verified 88.6) |
| 🔭 **code review** (architect) | large-repo navigation, architecture | **Gemini 3.1 Pro** (multimodal MMMU-Pro 81%) · ultra-long-context (>200k) → **Opus** |
| ⚖️ **independent critique** (critic) | adversarial verification | **cross-family** (different vendor than the main loop) |
| 🎛️ **orchestration** (default) | tool-calling, routing, honesty | **Claude Opus 4.8** (router quality caps the whole system) |

> Fill all 5 roles from one vendor and at least one role is not the best. This guide fills each of the 5 with its best-fit vendor — weighed against cost, accessibility, and reliability — into a combo that **actually works**. It cross-validates three independent deep-research passes (GPT-5.5 · Claude Opus 4.8 · Gemini 3.1 Pro) and **verifies every profile selector with live calls** ([§6](#6--verification-matrix)).

---

## 2. 🧭 Core design

> **One strong main loop, fixed (default = Opus) + signal-driven delegation + failure-driven effort escalation.**

The only model that runs on every turn is `default` (the main loop). executor/architect/planner/critic are sub-agents the main loop **delegates to via `task` only when warranted** (fresh context).

<div align="center">
<img src="assets/architecture.svg" alt="one main loop (default) + 4 sub-agents — signal-driven delegation" width="100%">
</div>

Three design principles:

- **The main loop is non-negotiable.** Most median tasks are handled by the main loop alone, so dropping `default` to a weak model collapses perceived quality across the board. Always Opus.
- **Diversity pays off only in *verification*.** Keep `critic` on a different vendor for independence, but keep serial chains short (reliability decays as `0.99ⁿ`).
- **Effort is asymmetric economics.** `medium→high` is +1–2 points for ~23× the tokens. Blindly maxing is waste — escalate only "because it couldn't solve it."

---

## 3. 🔧 GJC engine facts

### 3-1. The five roles

| Role | Where it runs | Top priority |
|---|---|---|
| `default` | **main loop** | tool-calling reliability · honesty |
| `executor` | sub-agent (only on `task` delegation) | real coding (SWE-bench) |
| `architect` | sub-agent | large-ctx · multimodal code review |
| `planner` | sub-agent | top-tier reasoning · sequencing |
| `critic` | sub-agent | independent adversarial critique |

### 3-2. Effort cheatsheet

```text
Opus 4.6/4.7/4.8        minimal low medium high xhigh max   ← all 6 tiers
Sonnet 4.6              minimal low medium high              ← no xhigh/max
GPT 5.4 / 5.5 (base)    low medium high xhigh                ← 5.5 defaults to xhigh
Grok 4.x (e.g. 4.3)     minimal low medium high xhigh
opencode-go deepseek-v4  minimal low medium high xhigh
opencode-go others       ── omit the :effort suffix (default) ──
google-antigravity Gemini  gemini-3.1-pro-low:high (high reasoning) · gemini-3.1-pro-low (low effort)
```

> [!IMPORTANT]
> **Four hard rules**: ① Gemini Pro supports only `low`/`high` ② openai-codex has a **272k ctx cap** (excluded from huge codebases) ③ Sonnet cannot do `xhigh`/`max` ④ opencode-go: omit `:effort`. Out-of-range tiers are **clamped**, not errored.

### 3-3. Subscription → provider

| Subscription | provider-id | Notes |
|---|---|---|
| claude | `anthropic` | all efforts |
| gpt | `openai-codex` | **ChatGPT account → serves base GPT (gpt-5.5/5.4)**. 272k ctx |
| grok | `xai` | full lineup + Composer |
| gemini | `google-antigravity` | **Google AI Pro/Ultra subscription token**. Gemini + bundled Claude (Opus 4.6) |
| opencode go | `opencode-go` | API key (`OPENCODE_API_KEY`) |

> [!NOTE]
> **openai-codex path caveat**: logging in with a ChatGPT (Codex) account serves the **base GPT models (`gpt-5.5`, `gpt-5.4`)**. Standalone `-codex` variants (`gpt-5.3-codex`, `gpt-5.2-codex`, `gpt-5.1-codex-max/mini`) are **not supported** on this path (`not supported when using Codex with a ChatGPT account`), so this guide uses verified **base GPT** for coding roles too.
>
> Alternative path: `google-vertex` (API key, paid per-token, 1M ctx) — a fallback independent of subscription/quota.

### 3-4. Selector syntax

```text
<provider-id>/<model-id>:<effort>            e.g. anthropic/claude-opus-4-8:high
google-antigravity/gemini-3.1-pro-low:high   (Gemini high reasoning — the engine's canonical path)
opencode-go/<model>                           (omit effort = model default)
```

---

## 4. 📊 Benchmark basis

**Verified per-role leader** (vals.ai independent boards · official model cards)

| Role (axis) | Leader | Figure |
|---|---|---|
| executor (SWE-bench Verified) | **Opus 4.8** | 88.6% (GPT-5.5 82.6 · Gemini 3.1 Pro 80.6) |
| planner (reasoning GPQA/ARC-AGI) | **Gemini 3.1 Pro** | GPQA 94.3 · ARC-AGI-2 77.1 |
| architect (ctx · multimodal) | **Gemini 3.1 Pro** | 1M ctx · MMMU-Pro 81% |
| default (tool-calling · honesty) | **Opus 4.8** | router quality = whole-system ceiling |
| critic (independence) | **cross-family** | meta-judge > debate aggregation |

**Consensus principles**

1. **default = Opus 4.8, fixed** (multi-vendor profiles) — router quality is the ceiling. `solo-*` use the single vendor's strongest as default.
2. **architect = Gemini 3.1 Pro (multimodal) / Opus (ultra-long-context)** — Gemini is best for vision and mid ctx; for 200k+ text retrieval use Opus (MRCR 76%@1M, where Gemini collapses to 26%).
3. **critic = cross-family** — a different vendor than the main loop/planner mitigates self-preference bias.
4. **Structure = strong main loop + signal-driven delegation + failure-driven effort escalation.**
5. **No per-query profile swapping** — cache loss > benefit. Swap only at mode boundaries.

> Benchmarks are time-sensitive → re-verify quarterly. Absolute rankings limited to vals.ai independent boards.

---

## 5. 🗂️ Final catalog (10 profiles)

<div align="center">
<img src="assets/profiles-matrix.svg" alt="profiles × roles matrix" width="100%">
</div>

> ★ = everyday recommendation. The top banner = the **`ultimate` setup** (strongest per role, accuracy first). Lowering it for cost balance gives the recommended **`daily`** (only executor·critic swapped to cheaper). Multi-vendor profiles keep `default=Opus` and `critic=cross-family` (solo-* use the single vendor's strongest), all pass the engine effort hard-rules, and **every selector is live-verified** ([§6](#6--verification-matrix)).

| Profile | One-liner | Use when |
|---|---|---|
| ⭐ **daily** | Opus main loop + delegation to each role's best vendor | **everyday default** |
| 🏆 **ultimate** | cost-no-object, best per role | accuracy matters more than cost |
| 🏎️ **coding-sprint** | executor-led + coding-aware critic | pure implementation throughput |
| 🛡️ **escalation** | max tier everywhere + multi-vendor critic panel | merges · security · billing · irreversible changes |
| 💸 **eco** | only the main loop is Opus; delegation all cheap/subscription | cost pressure · bulk work |
| 🗺️ **monorepo** | ≥1M ctx everywhere (codex excluded) | huge codebases |
| 🧱 **solo-anthropic** | every role on Anthropic | single-vendor operation |
| 🤖 **solo-openai** | every role on base GPT (272k ctx) | ChatGPT-only subscriber |
| 🤝 **claude-codex** | Claude = execution/ctx, Codex = reasoning/critique | Claude + Codex (2 subs only) |
| 🥇 **claude-codex-max** | cost-no-object version of claude-codex | Claude + Codex · accuracy first |

<details>
<summary><b>📋 Expand the full YAML (identical to gjc-profiles.yml)</b></summary>

```yaml
profiles:

  daily:                               # ★ everyday default (--default daily)
    required_providers: [anthropic, openai-codex, google-antigravity, xai]
    model_mapping:
      default:   anthropic/claude-opus-4-8:medium               # main-loop efficiency knee
      executor:  openai-codex/gpt-5.4:high                      # coding-capable, mid price ($2.5/15), vendor spread
      planner:   google-antigravity/gemini-3.1-pro-low:high     # verified #1 reasoning (GPQA 94.3 / ARC-AGI-2 77.1)
      architect: google-antigravity/gemini-3.1-pro-low:high     # 1M ctx · multimodal (MMMU-Pro 81%)
      critic:    xai/grok-4.3:medium                            # cross-family cheap independent critic ($1.25/2.5)

  ultimate:                            # cost-no-object, best per role + vendor spread
    required_providers: [anthropic, openai-codex, google-antigravity, xai]
    model_mapping:
      default:   anthropic/claude-opus-4-8:high
      executor:  anthropic/claude-opus-4-8:max                  # accessible coding #1 (SWE-bench Verified 88.6)
      planner:   openai-codex/gpt-5.5:xhigh                     # top reasoning + OpenAI diversity
      architect: google-antigravity/gemini-3.1-pro-low:high     # 1M ctx · multimodal
      critic:    xai/grok-4.3:high                              # cross-family independent critic

  coding-sprint:                       # implementation throughput. executor-led + coding-aware critic
    required_providers: [anthropic, openai-codex, google-antigravity]
    model_mapping:
      default:   anthropic/claude-opus-4-8:medium               # main-loop orchestration
      executor:  anthropic/claude-opus-4-8:max                  # accessible coding #1 (88.6)
      planner:   google-antigravity/gemini-3.1-pro-low:high     # #1 reasoning for lightweight planning
      architect: google-antigravity/gemini-3.1-pro-low:high     # 1M ctx review
      critic:    openai-codex/gpt-5.4:high                      # coding-aware critic (catches real bugs), cross-family vs gemini

  escalation:                          # high failure cost. max tier + multi-vendor critic panel (§9)
    required_providers: [anthropic, openai-codex, google-antigravity, xai]
    model_mapping:
      default:   anthropic/claude-opus-4-8:high
      executor:  anthropic/claude-opus-4-8:max
      planner:   openai-codex/gpt-5.5:xhigh
      architect: google-antigravity/gemini-3.1-pro-low:high
      critic:    xai/grok-4.3:xhigh                             # + 3-vote cross-vendor critic panel (independent vote → main loop tallies)

  eco:                                 # cheapest — only the main loop is Opus (effort trimmed), delegation ultra-cheap/subscription
    required_providers: [anthropic, opencode-go, google-antigravity, xai]
    model_mapping:
      default:   anthropic/claude-opus-4-8:low                  # can't lower the router, only its effort
      executor:  opencode-go/deepseek-v4-flash                  # $0.14/0.28, 1M, cheapest coder (5th vendor)
      planner:   xai/grok-4-1-fast:high                         # $0.2/0.5, 2M, cheap reasoning
      architect: google-antigravity/gemini-3.1-pro-low          # subscription token, low effort, 1M ctx
      critic:    google-antigravity/gemini-3.5-flash            # subscription token, light, cross-family vs executor (opencode-go)

  monorepo:                            # huge codebases — ≥1M ctx everywhere (★codex 272k excluded)
    required_providers: [anthropic, google-antigravity, opencode-go]
    model_mapping:
      default:   anthropic/claude-opus-4-8:medium               # 1M
      executor:  anthropic/claude-opus-4-8:high                 # 1M
      planner:   google-antigravity/gemini-3.1-pro-low:high     # reasoning (scoped input)
      architect: anthropic/claude-opus-4-8:high                 # Opus 4.8 = GJC 1M ctx window (best multi-turn retrieval). Single-message paste cap ~400k — for one-shot >400k use opencode-go/deepseek-v4-pro
      critic:    opencode-go/glm-5.2                            # new open-weight #1 (AA 51 > V4 Pro 44), cross-family vs anthropic (alt: deepseek-v4-pro)

  solo-anthropic:                      # single-vendor operation, avoids 0.99^N reliability collapse
    required_providers: [anthropic]
    model_mapping:
      default:   anthropic/claude-opus-4-8:high
      executor:  anthropic/claude-opus-4-8:max
      planner:   anthropic/claude-opus-4-8:max
      architect: anthropic/claude-opus-4-8:high                 # 1M, Gemini replacement (fallback #1)
      critic:    anthropic/claude-sonnet-4-6:high               # ⚠same vendor = weak independence (tradeoff)

  solo-openai:                         # ChatGPT (Codex) account only — base GPT only (★272k ctx cap)
    required_providers: [openai-codex]
    model_mapping:
      default:   openai-codex/gpt-5.5:high                      # router (strongest base GPT)
      executor:  openai-codex/gpt-5.5:xhigh                     # this account's strongest coder
      planner:   openai-codex/gpt-5.5:xhigh                     # top reasoning
      architect: openai-codex/gpt-5.4:high                      # 272k cap — unfit for huge codebases
      critic:    openai-codex/gpt-5.4:high                      # ⚠same vendor = weak independence (tradeoff)

  claude-codex:                        # ★Claude+Codex (2 subs) only — everyday balance. Anthropic = execution/ctx, Codex = reasoning/critique
    required_providers: [anthropic, openai-codex]
    model_mapping:
      default:   anthropic/claude-opus-4-8:medium               # router · tool reliability
      executor:  anthropic/claude-opus-4-8:high                 # coding #1 (SWE-bench 88.6)
      planner:   openai-codex/gpt-5.5:high                      # OpenAI reasoning flagship
      architect: anthropic/claude-opus-4-8:high                 # 1M window (avoids codex 272k limit)
      critic:    openai-codex/gpt-5.4:high                      # cross-family vs Opus (executor), coding-aware

  claude-codex-max:                    # Claude+Codex (2 subs) strongest — cost-no-object
    required_providers: [anthropic, openai-codex]
    model_mapping:
      default:   anthropic/claude-opus-4-8:high
      executor:  anthropic/claude-opus-4-8:max                  # SWE-bench 88.6 coding #1
      planner:   openai-codex/gpt-5.5:xhigh                     # top reasoning (strong ARC-AGI-2)
      architect: anthropic/claude-opus-4-8:high                 # 1M window
      critic:    openai-codex/gpt-5.5:high                      # cross-family independent critique vs Opus
```

</details>

For per-profile design rationale, the by-need cheatsheet, and the full deep-research benchmark analysis (planner reasoning split, architect long-context correction, GJC effective-context measurements), see the **[Korean canonical README](./README.md#5--최종-카탈로그-10종)** and the official **[GJC docs](https://github.com/Yeachan-Heo/gajae-code/blob/dev/docs/multi-vendor-profiles.md)**.

---

## 6. ✅ Verification matrix

> Every selector was **actually called** in this environment via `gjc -p --no-session --no-tools --model <sel> "..."` (2026-06-18). "Works" means a real call, not a guess.

| Provider | Verified selectors (✅ working) |
|---|---|
| `anthropic` | `claude-opus-4-8` (low·medium·high·max) · `claude-sonnet-4-6:high` |
| `openai-codex` | `gpt-5.5` (high·xhigh) · `gpt-5.4:high` · `gpt-5.4-mini:high` |
| `xai` | `grok-4.3` (high·xhigh) · `grok-4-1-fast:high` · `grok-4-fast:high` · `grok-code-fast-1` · `grok-composer-2.5-fast` |
| `google-antigravity` | `gemini-3.1-pro-low` · `gemini-3.1-pro-low:high` · `gemini-3.5-flash` · `gemini-3-flash` · `claude-opus-4-6-thinking` |
| `opencode-go` | `deepseek-v4-flash` · `deepseek-v4-pro` · `glm-5.2` · `glm-5.1` · `minimax-m2.7` · `qwen3.7-max` · `kimi-k2.6` · `mimo-v2.5` (needs `OPENCODE_API_KEY`) |

> [!WARNING]
> **Selectors that did NOT work here** (avoid): `openai-codex/gpt-5.3-codex`·`gpt-5.2-codex`·`gpt-5.1-codex-max`·`gpt-5.1-codex-mini` (unsupported on ChatGPT accounts) · `google-antigravity/gemini-3.1-pro-high` (the engine uses `gemini-3.1-pro-low:high`) · `gemini-3-pro` (retired) · `claude-sonnet-4-6-thinking` (404) · `gpt-oss-120b` (500). `opencode-go/*` fails **only when `OPENCODE_API_KEY` is unset** (works per the table once set).

> [!NOTE]
> `opencode-go/glm-5.2` and `google-antigravity/gemini-3.5-flash` are ids that come from the **provider's live catalog, not the bundled snapshot** (`packages/ai/src/models.json`). They resolve once online discovery has populated the registry after login (verified ✅ above). But `required_providers` only verifies credentials — not discovery freshness — so before a refresh, activation can fail with `selector did not resolve`. If that happens, re-login/retry to refresh, or substitute a bundled id: `opencode-go/deepseek-v4-pro` for the critic, or `zai/glm-5.2` (add `zai` to `required_providers`).

Reproduce:
```bash
gjc -p --no-session --no-tools --model "google-antigravity/gemini-3.1-pro-low:high" "Reply exactly: OK"
gjc -p --no-session --no-tools --model "openai-codex/gpt-5.4:high" "Reply exactly: OK"
```

> **Deep role-placement review and the GJC effective-context measurements** (§6-2 / §6-3 in the Korean canonical) confirmed the skeleton is near-optimal: `gemini-3.1-pro-low:high` invokes Gemini's native high-reasoning mode (not a degraded one); the planner reasoning axis splits (Gemini wins GPQA, GPT-5.5 wins ARC-AGI-2); Opus holds 1M-context retrieval where Gemini collapses (hence monorepo architect = Opus); and the single-message `@file` input cap (~400k on anthropic/antigravity) is separate from the 1M context window (chunk huge inputs across turns). Full tables: **[Korean README §6](./README.md#6--검증-매트릭스)**.

---

## 7. 🛠️ Install / uninstall

### One-click (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/project820/gjc-multivendor-setup-guide/main/install.sh | bash
```

What the installer does: safely merges the 10 profiles into `~/.gjc/agent/models.yml` (auto-updates on re-run), backs up existing files, and sets `daily` as default. Needs only `curl` + `python3`.

```bash
# options
curl -fsSL …/install.sh | GJC_SETUP_DEFAULT=ultimate bash    # pick default profile
curl -fsSL …/install.sh | GJC_SETUP_DEFAULT=none bash        # skip default-setting
curl -fsSL …/install.sh | GJC_CODING_AGENT_DIR=/path bash    # override agent dir
```

### Provider auth (required)

Install only lays down the profiles. Open GJC and log in to each vendor once:

```text
/login anthropic           # claude
/login openai-codex        # gpt (base GPT)
/login google-antigravity  # gemini (Google AI Pro/Ultra subscription)
/login xai                 # grok full lineup + Composer
```

opencode-go: `/provider add` or the `OPENCODE_API_KEY` env var.

### Manual install / verify / uninstall

Paste the `profiles:` block from [`gjc-profiles.yml`](./gjc-profiles.yml) under `profiles:` in `~/.gjc/agent/models.yml`, then `gjc --mpreset daily --default`.

```bash
gjc --list-models daily                       # confirm
cp ~/.gjc/agent/models.yml.bak-*  ~/.gjc/agent/models.yml   # revert (restore backup)
```

---

## 8. 🔀 Dynamic routing

> **"Swap profile per query" ❌ / "one strong main loop + one thin rule layer" ✅.** The router is the main loop (Opus); profiles are the destination pool.

> [!TIP]
> To make the main loop follow the routing rules below, put [`routing-rules.md`](./routing-rules.md) in your project `AGENTS.md`, or inject it via `gjc --append-system-prompt @routing-rules.md` (installed profiles + verified-selector hard-rules + GJC effective ctx caps, all in one file).

### 8-1. Work signal → delegation

<div align="center">
<img src="assets/routing-tree.svg" alt="work signal → delegation routing" width="100%">
</div>

Rule: **delegate only when the signal is clear.** If the main loop can do it directly, it does.

### 8-2. Adaptive effort escalation

<div align="center">
<img src="assets/effort-ladder.svg" alt="adaptive effort escalation" width="100%">
</div>

- ✅ Raising because it couldn't solve it is valid / ❌ "raising to be safe" is waste.
- No minimal. Floor at `low`. Gemini does a single `low↔high` jump.

### 8-3. Profile swap (mode boundaries only)

| Signal | Swap → |
|---|---|
| session start · general work | `daily` |
| pre-merge/release · security · billing | `escalation` |
| bulk refactor · migration | `eco` |
| entering a huge codebase | `monorepo` |
| single-vendor operation | `solo-anthropic` |

---

## 9. 🧪 Parallel agents + reliability

Serial hand-offs decay as `0.99ⁿ`, and multi-agent setups, wired wrong, harden into "false consensus." Design parallelism to defend against both.

```text
serial chain, 5 steps (0.99 each):  0.99^5 ≈ 95.1%    → collapses with length
parallel independent, 5 (OR-success): 1-(0.01)^5 ≈ 100%  → diversity raises reliability
```

**Design principles**
- critic = **different vendor from the main loop, parallel independent vote, then the main loop tallies** (no debate — meta-judge wins).
- critic panel example: `{xai/grok-4.3, openai-codex/gpt-5.4, google-antigravity/gemini-3.1-pro-low:high}` in parallel → discard if 2/3 reject.
- executor fan-out only when **the work is truly independent** (no shared state).
- keep chains short, main loop as the single source of truth (no direct sub-agent consensus).

---

## 10. 💰 Cost

Gemini (`google-antigravity`) runs on the **Google AI Pro/Ultra subscription token** (included in the subscription, not per-token billed). The rest are per-token; key model prices ($/1M, in/out):

| Model | $/1M (in/out) | Role |
|---|---|---|
| Claude Opus 4.8 | 5 / 25 | default·executor |
| Claude Sonnet 4.6 | 3 / 15 | solo critic |
| GPT-5.5 | 5 / 30 | planner (ultimate) |
| GPT-5.4 | 2.5 / 15 | executor/critic (daily·sprint) |
| Grok 4.3 | 1.25 / 2.5 | critic |
| Grok 4.1 Fast | 0.2 / 0.5 | eco planner |
| DeepSeek V4 Flash / Pro (opencode-go) | 0.14/0.28 · 1.74/3.48 | eco executor · monorepo critic |
| Gemini 3.1 Pro / 3.5 Flash | subscription token | planner·architect·critic |

**Relative profile cost**

| Profile | Cost | Main driver |
|---|---|---|
| ultimate / escalation | ●●●●● | executor Opus `:max` + planner GPT-5.5 `:xhigh` |
| coding-sprint | ●●●●○ | executor Opus `:max` |
| daily | ●●●○○ | main loop Opus `:medium`, delegation mid/cheap |
| monorepo | ●●●○○ | executor Opus + Grok/Gemini (subscription) |
| solo-anthropic | ●●●○○ | all Opus (critic Sonnet) |
| eco | ●○○○○ | executor DeepSeek V4 Flash ($0.14) + subscription Gemini |

> **Three savings levers**: ① push delegated work onto ultra-cheap models (DeepSeek V4 Flash $0.14, Grok Fast $0.2) / subscription tokens (Gemini) ② escalate effort only on failure ③ keep the main loop on Opus (it's the quality ceiling) but `:medium` for everyday, `:low` under cost pressure.

---

## 11. 📖 Sources

**Coding (executor)** · [Vals SWE-bench Verified](https://www.vals.ai/benchmarks/swebench) · [swebench.com](https://www.swebench.com/verified.html) · [Terminal-Bench 2.0](https://www.tbench.ai/leaderboard/terminal-bench/2.0)

**Reasoning (planner)** · [Gemini 3.1 Pro card](https://deepmind.google/models/model-cards/gemini-3-1-pro/) · [AA Index](https://artificialanalysis.ai/evaluations/artificial-analysis-intelligence-index)

**ctx · multimodal (architect)** · [Gemini 3](https://blog.google/products-and-platforms/products/gemini/gemini-3/)

**Tool-calling · honesty (default)** · [BFCL](https://gorilla.cs.berkeley.edu/leaderboard.html) · [τ²-Bench](https://arxiv.org/abs/2506.07982)

**Independence · routing (critic + design)** · [self-preference bias](https://arxiv.org/abs/2410.21819) · [Judging with Many Minds](https://arxiv.org/abs/2505.19477) · [RouteLLM](https://www.lmsys.org/blog/2024-07-01-routellm/)

**Official models/pricing** · [Anthropic](https://docs.anthropic.com/en/docs/about-claude/models) · [OpenAI](https://openai.com/api/pricing/) · [xAI](https://docs.x.ai/developers/models)

---

<div align="center">

**Install in one line, best model per role.**

**v1.3** · [CHANGELOG](./CHANGELOG.md) · [Maintenance playbook](./MAINTAINING.md) · License [CC BY 4.0](./LICENSE) · GJC = [Gajae Code](https://github.com/Yeachan-Heo/gajae-code)

</div>
