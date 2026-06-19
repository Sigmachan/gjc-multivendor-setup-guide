# Maintaining this guide — research & validation playbook

This repo is meant to stay correct as model catalogs, prices, and provider behavior drift.
Anything in here can be picked up by a fresh session (human or a `gjc` agent) **without prior context** — clone the repo and follow this file.

> One-line orientation: the profiles assign GJC's five roles (`default` / `executor` / `architect` / `planner` / `critic`) to the best model per role across vendors. `default` stays on the strongest router (Anthropic Opus when available); `critic` stays cross-family. Everything is **user config** (`~/.gjc/agent/models.yml`), not bundled defaults.

---

## 1. Durable invariants (never silently break these)

1. **`default` = strongest router.** If `anthropic` is in `required_providers`, `default` must be Anthropic Opus. A weak router caps whole-system quality.
2. **`critic` is cross-family** from the `executor`/`planner` it reviews — except where impossible (single-vendor `solo-*`, 2-vendor `claude-codex*`) or ctx-forced (`monorepo`). Documented exceptions live in `scripts/validate-profiles.py` (`SAME_FAMILY_OK`).
3. **Effort hard-rules** (engine-enforced): Opus 4.6+ `minimal..max`; Sonnet 4.6 `≤high`; GPT 5.2+/codex `low..xhigh`; **Gemini Pro `low`/`high` only**; Gemini Flash `minimal..high`; Grok `minimal..xhigh`; opencode-go: omit `:effort`.
4. **Antigravity high reasoning = `gemini-3.1-pro-low:high`** (the `gemini-3.1-pro-high` id 400s — backend has no such model; `thinkingLevel` is a per-request param).
5. **`-codex` variants don't work on a ChatGPT/Codex account** — use base `gpt-5.5` / `gpt-5.4`.
6. **Single-message `@file` input limit (~400k) ≠ context window (1M).** Chunk huge inputs across turns.
7. **Bundled vs live catalog**: `opencode-go` and `google-antigravity` discover models from the provider API after `/login`. `glm-5.2` / `gemini-3.5-flash` resolve at runtime but are absent from the bundled snapshot, so document them as live-only with bundled fallbacks (`opencode-go/deepseek-v4-pro`, `zai/glm-5.2`).

Every claim in `README.md` is **time-sensitive (catalog at validation date)** — keep the dated caveat.

---

## 2. Tooling

| Script | Needs creds? | What it does |
| --- | --- | --- |
| `scripts/validate-profiles.py` | no | Static guard: YAML valid, 5 roles, router invariant, cross-family (with allowlist), effort legality, `required_providers` coverage, README-embed == `gjc-profiles.yml`. **Runs in CI.** |
| `scripts/revalidate.sh` | yes (`/login`) | Live battery: every profile selector via real `gjc -p`; records `evidence/<date>-selectors.md`; non-zero exit on regression. `SELECTORS_ONLY=1` skips long-context probes. |
| `scripts/catalog-snapshot.sh` | yes | Dumps the live catalog to `evidence/<date>-catalog.txt`; `--diff` compares the two newest snapshots (new/retired models, price/ctx drift). |

```bash
python3 scripts/validate-profiles.py          # before every commit / in CI
bash scripts/revalidate.sh                     # on an authed machine (quarterly / on catalog news)
bash scripts/catalog-snapshot.sh               # snapshot; later: scripts/catalog-snapshot.sh --diff
```

`evidence/` is the durable audit trail — committed, dated, never rewritten. It backs the README's "verified" claims.

---

## 3. Maintenance cadence

- **Quarterly, or on any model launch/retirement/price change:**
  1. `bash scripts/catalog-snapshot.sh` then `--diff` vs the last snapshot → spot drift.
  2. `bash scripts/revalidate.sh` → regenerate the selector evidence; fix any regression.
  3. If a better model appears for a role (benchmark + live-verified), update `gjc-profiles.yml` **and** the README embedded YAML + cheatsheet, re-run `validate-profiles.py`, and add a CHANGELOG entry.
- **Benchmark sourcing**: rank by role axis — executor=SWE-bench Verified (vals.ai), planner=GPQA/ARC-AGI, architect=ctx+MMMU, default=tool-calling/honesty, critic=independence. Cite vals.ai / Artificial Analysis / official model cards; avoid single-source absolute rankings. Latency is GJC-routed indicative only.

---

## 4. Release discipline (SemVer-ish `MAJOR.MINOR`)

- **MINOR** — profile/model placement change (must ship with `revalidate.sh` evidence).
- **PATCH/Docs** — wording/rationale; keep version or `x.y.z`.
- **MAJOR** — structural redesign (role model, setup flow, routing).
- Every release: `python3 scripts/validate-profiles.py` green → update `CHANGELOG.md` → tag `vX.Y`.
- Keep `README` embedded YAML, `gjc-profiles.yml`, and `install.sh` in sync (the validator enforces README↔file).
- **i18n**: when `gjc-profiles.yml` or the catalog changes, update the YAML block + tables in **all** language READMEs (`README.md` KO canonical · `README.en.md` · `README.zh.md` · `README.ja.md`). `validate-profiles.py` enforces YAML parity across every `README*.md`. Prose/comments translate; selectors stay verbatim; deep §6-2/§6-3 analysis stays only in the KO canonical (translations link to it).

---

## 5. Upstream (Yeachan-Heo/gajae-code)

A compressed version of this guide is proposed upstream as `docs/multi-vendor-profiles.md` (PRs target **`dev`**, not `main`; `main` is protected). The maintainer bot requires:
- docs-only diff (+ regenerated `packages/coding-agent/src/internal-urls/docs-index.generated.ts` via `bun --cwd=packages/coding-agent run generate-docs-index`),
- selector verification evidence in the PR body,
- **owner confirmation** for normative product claims (axis leaders, rankings, price/latency).

This standalone repo keeps the **one-line installer + full profile set (incl. `solo-*`, `claude-codex*`) + benchmarking tooling** that the upstream docs page does not carry, so it stays useful after any upstream merge.

---

## 6. Quick context for a cold-start session

Read in order: this file → `README.md` (§ verified selector notes) → `gjc-profiles.yml`. The newest `evidence/*-selectors.md` shows the last live-verified state. Re-verify before trusting any selector: `gjc -p --no-session --no-tools --model <selector> "Reply OK"`.
