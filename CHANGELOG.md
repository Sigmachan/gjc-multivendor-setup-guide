# Changelog

Every change to this guide is recorded in this file.

**Versioning (SemVer-ish — `MAJOR.MINOR`)**
- **MINOR ↑** — adding/changing profile or model placement (must ship with live-call verification)
- **PATCH/Docs** — typos, wording, rationale (keep version, or `x.y.z`)
- **MAJOR ↑** — structural redesign (role definitions, setup flow, routing model)

Each release is pinned with a git tag (`vX.Y`).

---

## v1.3 — 2026-06-18

### Added
- **i18n**: added English `README.en.md` · Chinese `README.zh.md` · Japanese `README.ja.md`. A language nav at the top of all 4 files including the Korean canonical. Selectors/YAML verbatim, prose/YAML comments translated, the deep analysis (§6-2/6-3) summarized + linked to the Korean canonical · official docs.
- Extended `scripts/validate-profiles.py`: a parity check that **every `README*.md` embedded YAML == `gjc-profiles.yml`** (prevents translation drift). Included in CI.

> Fork note (English edition): `README.md` is now the full English canonical; the original Korean canonical moved to `README.ko.md`. Install/raw URLs point to the `Sigmachan` fork.

## v1.2 — 2026-06-18

### Added
- **Upstream adoption**: a condensed version of the guide was merged into the GJC main repo as `docs/multi-vendor-profiles.md` ([PR #860](https://github.com/Yeachan-Heo/gajae-code/pull/860), `dev`). Added an official-docs banner + positioning (this repo = installer · full profiles · validation tooling) at the top of the README.

### Docs
- Added a **live-catalog caveat** to the verified-selector table: `opencode-go/glm-5.2` · `google-antigravity/gemini-3.5-flash` are absent from the bundled snapshot and resolve only via provider discovery, so before a refresh activation can fail with `selector did not resolve` — re-login/retry or substitute a bundled id (`opencode-go/deepseek-v4-pro` / `zai/glm-5.2`). (Reflects the upstream PR #860 red-team review.)

### Infra
- **Added a durable maintenance base** — so the repo can self-validate, benchmark, and track drift independent of any session:
  - `scripts/validate-profiles.py` (credential-free static validation: 5 roles · router invariant · cross-family [with exception allowlist] · effort hard-rules · README embed sync) + GitHub Actions `validate-profiles`.
  - `scripts/revalidate.sh` (live selector battery on an authed machine → `evidence/<date>-selectors.md`, non-zero exit on regression).
  - `scripts/catalog-snapshot.sh` (live catalog snapshot + `--diff` drift detection).
  - `evidence/` dated audit-trail seed (2026-06-18) · `MAINTAINING.md` playbook.

## v1.1 — 2026-06-18

### Added
- **Two Claude+Codex 2-vendor profiles**: `claude-codex` (everyday balance), `claude-codex-max` (cost-no-object strongest).
  Design — **Anthropic = execution/context** (default·executor·architect=Opus; codex is 272k, so only Opus gives 1M ctx),
  **Codex = reasoning/critique** (planner=gpt-5.5 / critic=GPT, cross-family vs the Opus executor).
- **Introduced version management**: CHANGELOG · version badge · git tags (`v1.0`/`v1.1`).

### Changed
- Profiles **8 → 10**. Synced the matrix SVG · README tables/embedded YAML · install.sh.

---

## v1.0 — 2026-06-18

### Added
- Initial release. claude·gpt·grok·gemini·opencode go — **5-vendor role split, 8 profiles**
  (daily★/ultimate/coding-sprint/escalation/eco/monorepo/solo-anthropic/solo-openai).
- `routing-rules.md` (main-loop operating rules, injectable via `@`) · `install.sh` (one-click safe merge) · 5 SVGs (matrix·role-winners·architecture·routing·effort).
- §6 validation matrix · §6-2 optimality review · §6-3 remaining gaps · GJC effective-ctx measurements.

### Verified (GJC live calls, 2026-06-18 · 20/20 internal re-verification in GJC)
- `gemini-3.1-pro-low:high` = native high reasoning (`gemini-3.1-pro-high` 400s — no such backend id).
- `openai-codex` serves base GPT only (`gpt-5.5`/`gpt-5.4`) — `-codex` variants unsupported.
- `opencode-go/glm-5.2` serving confirmed → adopted as monorepo critic (new open-weight #1).
- Opus 4.8 context window = **1M** (multi-turn accumulation). The ~400k single-message input limit is separate from the window.
- architect long context: nominal 1M ≠ effective — Gemini 1M collapses to 26.3% / Opus 4.6 holds 76%.
