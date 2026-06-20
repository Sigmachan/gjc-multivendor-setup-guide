<div align="center">

# 🧩 GJC マルチベンダー究極セットアップ

### claude · gpt · grok · gemini · opencode go — 5つの契約を*役割ごと*に振り分ける検証済み構成

モデル選びで悩むのをやめよう。**ワンライナーでインストール**し、各役割に最適なモデルを自動で割り当てる。

[![GJC](https://img.shields.io/badge/for-Gajae%20Code%20(GJC)-e23?style=flat-square)](https://github.com/Yeachan-Heo/gajae-code)
[![Version](https://img.shields.io/badge/version-1.3-2496ED?style=flat-square)](./CHANGELOG.md)
[![Upstream](https://img.shields.io/badge/upstream-merged%20into%20GJC%20docs-brightgreen?style=flat-square)](https://github.com/Yeachan-Heo/gajae-code/pull/860)
![Profiles](https://img.shields.io/badge/profiles-10-blue?style=flat-square)
![Vendors](https://img.shields.io/badge/vendors-5-success?style=flat-square)
![Verified](https://img.shields.io/badge/selectors-live%20tested%202026--06--18-brightgreen?style=flat-square)
![License](https://img.shields.io/badge/license-CC%20BY%204.0-lightgrey?style=flat-square)

<img src="assets/role-winners.svg" alt="ultimate 構成 — 役割ごとの最強モデル" width="100%">

</div>

**[한국어](./README.ko.md) · [English](./README.md) · [中文](./README.zh.md) · 日本語（このページ）**

> [!NOTE]
> **本ガイドの中核は GJC 公式ドキュメントに採用された** — 圧縮版が上流に [`docs/multi-vendor-profiles.md`](https://github.com/Yeachan-Heo/gajae-code/blob/dev/docs/multi-vendor-profiles.md) としてマージ済み（[PR #860](https://github.com/Yeachan-Heo/gajae-code/pull/860)、`dev`）。役割/セレクタの概念は **GJC 公式ドキュメントを正式リファレンス**とし、本リポジトリはそこに無いもの — **ワンライナー・インストーラ**、**10プロファイル一式**（`solo-*` / `claude-codex*` 含む）、そして[保守・検証ツール](./MAINTAINING.md)（静的チェック CI + ライブセレクタ検証 + カタログドリフト追跡）— を提供する。

---

## ⚡ 30秒インストール（ワンライナーをコピペ）

```bash
curl -fsSL https://raw.githubusercontent.com/Sigmachan/gjc-multivendor-setup-guide/main/install.sh | bash
```

この1行で **10個のプロファイルを `~/.gjc/agent/models.yml` に安全にマージ**し、既定プロファイルを `daily` に設定する。既存設定は自動バックアップされ、再実行してもクリーンに更新される。

```bash
gjc --mpreset daily        # このセッションのみ
gjc                        # 新規セッションは自動で daily
```

> [!IMPORTANT]
> **インストール後、各プロバイダへのログインが必要。** GJC は独自の OAuth を使う（ネイティブ `agy`/`grok` CLI のログインとは共有されない）ので、GJC を起動して各コマンドを一度ずつ実行（ブラウザ認証）：
>
> ```text
> /login anthropic           # claude
> /login openai-codex        # gpt（ChatGPT アカウント → base GPT を提供）
> /login google-antigravity  # gemini（Google AI Pro/Ultra サブスク）
> /login xai                 # grok 全ラインナップ + Composer
> ```
> opencode-go は API キー方式：`/provider add` または環境変数 `OPENCODE_API_KEY`。認証状態は `/provider` で確認。

> [!TIP]
> 既定プロファイル指定：`curl -fsSL …/install.sh | GJC_SETUP_DEFAULT=ultimate bash` · 既定設定をスキップ：`GJC_SETUP_DEFAULT=none`。

---

## 1. 🎯 なぜマルチベンダーか

claude·gpt·grok·gemini·opencode go を契約しておきながら1モデルしか使わないのは、すべての役割で*次善*モデルを使うのと同じ。検証済みベンチマークは**役割ごとに首位ベンダーが異なる**ことを示す：

| 役割 | 何をするか | 最適モデル |
|---|---|---|
| 🧠 **推論・設計**（planner） | 手順・受け入れ基準 | **Gemini 3.1 Pro**（GPQA 94.3 / ARC-AGI-2 77.1） |
| 🔨 **実装**（executor） | 実際のコード作成・修正 | **Claude Opus 4.8**（SWE-bench Verified 88.6） |
| 🔭 **コードレビュー**（architect） | 大規模リポ探索・アーキ | **Gemini 3.1 Pro**（マルチモーダル MMMU-Pro 81%）· 超長文脈（>200k）→ **Opus** |
| ⚖️ **独立批評**（critic） | 敵対的検証 | **クロスファミリー**（メインループと別ベンダー） |
| 🎛️ **オーケストレーション**（default） | ツール呼び出し・ルーティング・誠実性 | **Claude Opus 4.8**（ルータ品質が全体の上限） |

> 1ベンダーで5役割を埋めると、必ずどこかが最強でなくなる。本ガイドはその5枠を各々の最適ベンダーで埋め、コスト・アクセス性・信頼性まで勘案して**実際に動く**組み合わせにまとめた。3本の独立ディープリサーチ（GPT-5.5 · Claude Opus 4.8 · Gemini 3.1 Pro）を相互検証し、**全プロファイルのセレクタを実呼び出しで検証**している（[§6](#6--検証マトリクス)）。

---

## 2. 🧭 コア設計

> **強いメインループを1つ固定（default = Opus）+ シグナル駆動の委譲 + 失敗駆動の effort エスカレーション。**

毎ターン実際に走るのは `default`（メインループ）だけ。executor/architect/planner/critic は、メインループが**必要なときだけ `task` で委譲**するサブエージェント（新規コンテキスト）。

<div align="center">
<img src="assets/architecture.svg" alt="1メインループ(default) + 4サブエージェント — シグナル駆動委譲" width="100%">
</div>

3つの設計原則：

- **メインループは絶対に譲らない。** 中央値のタスクはほぼメインループが単独処理するため、`default` を弱モデルに落とすと体感品質が全面崩壊する。常に Opus。
- **多様性は「検証」でのみ効く。** 独立性のため `critic` は別ベンダーに。ただし直列チェーンは短く（信頼性は `0.99ⁿ` で減衰）。
- **effort は非対称な経済学。** `medium→high` は +1〜2点のためにトークン約23倍。無条件 max は無駄 — 「解けなかったとき」だけ上げる。

---

## 3. 🔧 GJC エンジンの事実

### 3-1. 5つの役割

| 役割 | 実行場所 | 最優先能力 |
|---|---|---|
| `default` | **メインループ** | ツール呼び出し信頼性 · 誠実性 |
| `executor` | サブエージェント（`task` 委譲時のみ） | 実コーディング（SWE-bench） |
| `architect` | サブエージェント | 大文脈 · マルチモーダルレビュー |
| `planner` | サブエージェント | 最上位の推論 · 手順化 |
| `critic` | サブエージェント | 独立した敵対的批評 |

### 3-2. Effort チートシート

```text
Opus 4.6/4.7/4.8        minimal low medium high xhigh max   ← 全6段
Sonnet 4.6              minimal low medium high              ← xhigh/max なし
GPT 5.4 / 5.5 (base)    low medium high xhigh                ← 5.5 は既定 xhigh
Grok 4.x（4.3 等）       minimal low medium high xhigh
opencode-go deepseek-v4  minimal low medium high xhigh
opencode-go その他       ── :effort サフィックス省略（既定）──
google-antigravity Gemini  gemini-3.1-pro-low:high（高推論）· gemini-3.1-pro-low（低 effort）
```

> [!IMPORTANT]
> **4つのハードルール**：① Gemini Pro は `low`/`high` のみ ② openai-codex は文脈 **272k 上限**（巨大コードベースから除外）③ Sonnet は `xhigh`/`max` 不可 ④ opencode-go は `:effort` 省略。範囲外の段は**クランプ**され、エラーにならない。

### 3-3. 契約 → プロバイダ

| 契約 | provider-id | 備考 |
|---|---|---|
| claude | `anthropic` | 全 effort |
| gpt | `openai-codex` | **ChatGPT アカウント → base GPT（gpt-5.5/5.4）を提供**。文脈 272k |
| grok | `xai` | 全ラインナップ + Composer |
| gemini | `google-antigravity` | **Google AI Pro/Ultra サブスクトークン**。Gemini + 同梱 Claude（Opus 4.6） |
| opencode go | `opencode-go` | API キー（`OPENCODE_API_KEY`） |

> [!NOTE]
> **openai-codex 経路の注意**：ChatGPT（Codex）アカウントでログインすると **base GPT モデル（`gpt-5.5`、`gpt-5.4`）** が提供される。単体の `-codex` 派生（`gpt-5.3-codex`、`gpt-5.2-codex`、`gpt-5.1-codex-max/mini`）はこの経路では**非対応**（`not supported when using Codex with a ChatGPT account`）なので、本ガイドはコーディング役も検証済みの **base GPT** に統一している。
>
> 代替経路：`google-vertex`（API キー、トークン従量課金、1M 文脈）— サブスク/クォータに依存しないフォールバック。

### 3-4. セレクタ構文

```text
<provider-id>/<model-id>:<effort>            例）anthropic/claude-opus-4-8:high
google-antigravity/gemini-3.1-pro-low:high   （Gemini 高推論 — エンジン公式経路）
opencode-go/<model>                           （effort 省略 = モデル既定）
```

---

## 4. 📊 ベンチマーク根拠

**役割ごとの検証済み首位**（vals.ai 独立ボード · 公式モデルカード）

| 役割（軸） | 首位 | 数値 |
|---|---|---|
| executor（SWE-bench Verified） | **Opus 4.8** | 88.6%（GPT-5.5 82.6 · Gemini 3.1 Pro 80.6） |
| planner（推論 GPQA/ARC-AGI） | **Gemini 3.1 Pro** | GPQA 94.3 · ARC-AGI-2 77.1 |
| architect（文脈 · マルチモーダル） | **Gemini 3.1 Pro** | 1M 文脈 · MMMU-Pro 81% |
| default（ツール呼び出し · 誠実性） | **Opus 4.8** | ルータ品質 = 全体の上限 |
| critic（独立性） | **クロスファミリー** | メタ審判 > 討論型集計 |

**合意原則**

1. **default = Opus 4.8 固定**（マルチベンダー構成）— ルータ品質が上限。`solo-*` は単一ベンダーの最強を default に。
2. **architect = Gemini 3.1 Pro（マルチモーダル）/ Opus（超長文脈）** — Gemini はビジョンと中程度文脈に最適。200k+ のテキスト検索は Opus（MRCR 76%@1M、Gemini は 26% に崩壊）。
3. **critic = クロスファミリー** — メインループ/プランナーと別ベンダーで自己選好バイアスを緩和。
4. **構造 = 強メインループ + シグナル駆動委譲 + 失敗駆動 effort エスカレーション。**
5. **クエリ毎のプロファイル切替 ❌** — キャッシュ損失 > 利得。モード境界でのみ切替。

> ベンチマークは時点依存 → 四半期ごとに再検証推奨。絶対順位は vals.ai 独立ボードに限定。

---

## 5. 🗂️ 最終カタログ（10プロファイル）

<div align="center">
<img src="assets/profiles-matrix.svg" alt="プロファイル × 役割 マトリクス" width="100%">
</div>

> ★ = 日常推奨。上部バナー = **`ultimate` 構成**（役割ごと最強・精度優先）。それをコスト均衡に落としたのが推奨の **`daily`**（executor·critic のみ安価に置換）。マルチベンダー構成は `default=Opus`・`critic=クロスファミリー`（solo-* は単一ベンダー最強）を維持し、全てエンジンの effort ハードルールを通過、**全セレクタを実呼び出し検証**済み（[§6](#6--検証マトリクス)）。

| プロファイル | 一言 | こんな時 |
|---|---|---|
| ⭐ **daily** | Opus メインループ + 各役割の最適ベンダーへ委譲 | **日常の既定** |
| 🏆 **ultimate** | コスト度外視、役割ごと最強 | 精度がコストより重要 |
| 🏎️ **coding-sprint** | executor 主役 + コード理解 critic | 純粋な実装スループット |
| 🛡️ **escalation** | 全域最高段 + マルチベンダー critic パネル | マージ・セキュリティ・決済・不可逆変更 |
| 💸 **eco** | メインループのみ Opus、委譲は全て安価/サブスク | コスト圧・大量作業 |
| 🗺️ **monorepo** | 全域 ≥1M 文脈（codex 除外） | 巨大コードベース |
| 🧱 **solo-anthropic** | 全役割 Anthropic | 単一ベンダー運用 |
| 🤖 **solo-openai** | 全役割 base GPT（272k 文脈） | ChatGPT のみ契約 |
| 🤝 **claude-codex** | Claude=実行・文脈 / Codex=推論・批評 | Claude+Codex の2契約のみ |
| 🥇 **claude-codex-max** | claude-codex のコスト度外視最強版 | Claude+Codex · 精度優先 |

<details>
<summary><b>📋 完全な YAML を展開（gjc-profiles.yml と同一）</b></summary>

```yaml
profiles:

  daily:                               # ★ 日常の既定 (--default daily)
    required_providers: [anthropic, openai-codex, google-antigravity, xai]
    model_mapping:
      default:   anthropic/claude-opus-4-8:medium               # メインループの効率ニー
      executor:  openai-codex/gpt-5.4:high                      # コーディング向き・中価格($2.5/15)・ベンダー分散
      planner:   google-antigravity/gemini-3.1-pro-low:high     # 検証済み推論1位(GPQA 94.3 / ARC-AGI-2 77.1)
      architect: google-antigravity/gemini-3.1-pro-low:high     # 1M 文脈・マルチモーダル(MMMU-Pro 81%)
      critic:    xai/grok-4.3:medium                            # クロスファミリーの安価な独立批評($1.25/2.5)

  ultimate:                            # コスト度外視、役割ごと最強 + ベンダー分散
    required_providers: [anthropic, openai-codex, google-antigravity, xai]
    model_mapping:
      default:   anthropic/claude-opus-4-8:high
      executor:  anthropic/claude-opus-4-8:max                  # 利用可能範囲でコーディング1位(SWE-bench Verified 88.6)
      planner:   openai-codex/gpt-5.5:xhigh                     # 最上位推論 + OpenAI の多様性
      architect: google-antigravity/gemini-3.1-pro-low:high     # 1M 文脈・マルチモーダル
      critic:    xai/grok-4.3:high                              # クロスファミリーの独立批評

  coding-sprint:                       # 実装スループット。executor 主役 + コード理解 critic
    required_providers: [anthropic, openai-codex, google-antigravity]
    model_mapping:
      default:   anthropic/claude-opus-4-8:medium               # メインループのオーケストレーション
      executor:  anthropic/claude-opus-4-8:max                  # 利用可能範囲でコーディング1位(88.6)
      planner:   google-antigravity/gemini-3.1-pro-low:high     # 推論1位で軽量プランニング
      architect: google-antigravity/gemini-3.1-pro-low:high     # 1M 文脈レビュー
      critic:    openai-codex/gpt-5.4:high                      # コード理解 critic(実バグ検出)、クロスファミリー vs gemini

  escalation:                          # 高失敗コスト。全域最高段 + マルチベンダー critic パネル(§9)
    required_providers: [anthropic, openai-codex, google-antigravity, xai]
    model_mapping:
      default:   anthropic/claude-opus-4-8:high
      executor:  anthropic/claude-opus-4-8:max
      planner:   openai-codex/gpt-5.5:xhigh
      architect: google-antigravity/gemini-3.1-pro-low:high
      critic:    xai/grok-4.3:xhigh                             # + 3票クロスベンダー critic パネル(独立投票→メインループ集計)

  eco:                                 # 最安 — メインループのみ Opus(effort 抑制)、委譲は超安価/サブスク
    required_providers: [anthropic, opencode-go, google-antigravity, xai]
    model_mapping:
      default:   anthropic/claude-opus-4-8:low                  # ルータは下げられない、effort のみ削減
      executor:  opencode-go/deepseek-v4-flash                  # $0.14/0.28, 1M, 最安コーダー(5番目のベンダー)
      planner:   xai/grok-4-1-fast:high                         # $0.2/0.5, 2M, 安価な推論
      architect: google-antigravity/gemini-3.1-pro-low          # サブスクトークン、低 effort、1M 文脈
      critic:    google-antigravity/gemini-3.5-flash            # サブスクトークン、軽量、クロスファミリー vs executor(opencode-go)

  monorepo:                            # 巨大コードベース — 全域 1M 文脈(★codex 272k 除外)
    required_providers: [anthropic, google-antigravity, opencode-go]
    model_mapping:
      default:   anthropic/claude-opus-4-8:medium               # 1M
      executor:  anthropic/claude-opus-4-8:high                 # 1M
      planner:   google-antigravity/gemini-3.1-pro-low:high     # 推論(スコープ入力)
      architect: anthropic/claude-opus-4-8:high                 # Opus 4.8 = GJC 1M 文脈ウィンドウ(マルチターン蓄積の検索が最良)。単一メッセージ貼付け上限 約400k — 一括 >400k は opencode-go/deepseek-v4-pro
      critic:    opencode-go/glm-5.2                            # 新オープンウェイト1位(AA 51 > V4 Pro 44)、クロスファミリー vs anthropic(代替: deepseek-v4-pro)

  solo-anthropic:                      # 単一ベンダー運用、0.99^N 信頼性崩壊を回避
    required_providers: [anthropic]
    model_mapping:
      default:   anthropic/claude-opus-4-8:high
      executor:  anthropic/claude-opus-4-8:max
      planner:   anthropic/claude-opus-4-8:max
      architect: anthropic/claude-opus-4-8:high                 # 1M, Gemini 代替(フォールバック1位)
      critic:    anthropic/claude-sonnet-4-6:high               # ⚠同一ベンダー=独立性が弱い(トレードオフ)

  solo-openai:                         # ChatGPT(Codex)アカウントのみ — base GPT 専用(★文脈 272k 上限)
    required_providers: [openai-codex]
    model_mapping:
      default:   openai-codex/gpt-5.5:high                      # ルータ(最強の base GPT)
      executor:  openai-codex/gpt-5.5:xhigh                     # このアカウント最強のコーダー
      planner:   openai-codex/gpt-5.5:xhigh                     # 最上位推論
      architect: openai-codex/gpt-5.4:high                      # 272k 上限 — 巨大コードベースに不向き
      critic:    openai-codex/gpt-5.4:high                      # ⚠同一ベンダー=独立性が弱い(トレードオフ)

  claude-codex:                        # ★Claude+Codex(2契約)のみ — 日常均衡。Anthropic=実行・文脈 / Codex=推論・批評
    required_providers: [anthropic, openai-codex]
    model_mapping:
      default:   anthropic/claude-opus-4-8:medium               # ルータ・ツール信頼
      executor:  anthropic/claude-opus-4-8:high                 # コーディング1位(SWE-bench 88.6)
      planner:   openai-codex/gpt-5.5:high                      # OpenAI 推論フラッグシップ
      architect: anthropic/claude-opus-4-8:high                 # 1M ウィンドウ(codex 272k 制限を回避)
      critic:    openai-codex/gpt-5.4:high                      # クロスファミリー vs Opus(executor)、コード理解

  claude-codex-max:                    # Claude+Codex(2契約)最強 — コスト度外視
    required_providers: [anthropic, openai-codex]
    model_mapping:
      default:   anthropic/claude-opus-4-8:high
      executor:  anthropic/claude-opus-4-8:max                  # SWE-bench 88.6 コーディング1位
      planner:   openai-codex/gpt-5.5:xhigh                     # 最上位推論(ARC-AGI-2 強)
      architect: anthropic/claude-opus-4-8:high                 # 1M ウィンドウ
      critic:    openai-codex/gpt-5.5:high                      # クロスファミリーの独立批評 vs Opus
```

</details>

各プロファイルの設計理由、ニーズ別チートシート、完全なディープリサーチのベンチマーク分析（planner 推論の分裂、architect 長文脈の補正、GJC 実効コンテキスト実測）は、**[韓国語の正本 README](./README.ko.md#5--최종-카탈로그-10종)** と公式 **[GJC ドキュメント](https://github.com/Yeachan-Heo/gajae-code/blob/dev/docs/multi-vendor-profiles.md)** を参照。

---

## 6. ✅ 検証マトリクス

> 全セレクタを本環境で `gjc -p --no-session --no-tools --model <sel> "..."` により**実呼び出し**して動作確認した（2026-06-18）。「動く」は推測ではなく実呼び出しの結果。

| プロバイダ | 検証済みセレクタ（✅ 動作） |
|---|---|
| `anthropic` | `claude-opus-4-8`（low·medium·high·max）· `claude-sonnet-4-6:high` |
| `openai-codex` | `gpt-5.5`（high·xhigh）· `gpt-5.4:high` · `gpt-5.4-mini:high` |
| `xai` | `grok-4.3`（high·xhigh）· `grok-4-1-fast:high` · `grok-4-fast:high` · `grok-code-fast-1` · `grok-composer-2.5-fast` |
| `google-antigravity` | `gemini-3.1-pro-low` · `gemini-3.1-pro-low:high` · `gemini-3.5-flash` · `gemini-3-flash` · `claude-opus-4-6-thinking` |
| `opencode-go` | `deepseek-v4-flash` · `deepseek-v4-pro` · `glm-5.2` · `glm-5.1` · `minimax-m2.7` · `qwen3.7-max` · `kimi-k2.6` · `mimo-v2.5`（`OPENCODE_API_KEY` 必要） |

> [!WARNING]
> **本環境で動かなかったセレクタ**（回避）：`openai-codex/gpt-5.3-codex`·`gpt-5.2-codex`·`gpt-5.1-codex-max`·`gpt-5.1-codex-mini`（ChatGPT アカウント非対応）· `google-antigravity/gemini-3.1-pro-high`（エンジンは `gemini-3.1-pro-low:high` を使用）· `gemini-3-pro`（廃止）· `claude-sonnet-4-6-thinking`（404）· `gpt-oss-120b`（500）。`opencode-go/*` は **`OPENCODE_API_KEY` 未設定時のみ**失敗（設定後は上表どおり動作）。

> [!NOTE]
> `opencode-go/glm-5.2` と `google-antigravity/gemini-3.5-flash` は、**バンドルされたスナップショット（`packages/ai/src/models.json`）には無く、プロバイダのライブカタログから取得される** ID。ログイン後にオンライン探索がレジストリを満たせば解決される（上で検証済み ✅）。ただし `required_providers` は資格情報を検証するだけで探索の鮮度は保証しないため、更新前は `selector did not resolve` で起動に失敗しうる。その場合は再ログイン/リトライで更新するか、バンドル ID に置換する：critic は `opencode-go/deepseek-v4-pro`、GLM は `zai/glm-5.2`（`zai` を `required_providers` に追加）。

再現：
```bash
gjc -p --no-session --no-tools --model "google-antigravity/gemini-3.1-pro-low:high" "Reply exactly: OK"
gjc -p --no-session --no-tools --model "openai-codex/gpt-5.4:high" "Reply exactly: OK"
```

> **役割配置の詳細レビューと GJC 実効コンテキスト実測**（韓国語正本の §6-2 / §6-3）は骨格がほぼ最適と確認：`gemini-3.1-pro-low:high` は Gemini のネイティブ高推論モードを呼ぶ（劣化版ではない）；planner の推論軸は分裂（Gemini が GPQA、GPT-5.5 が ARC-AGI-2 で勝つ）；Opus は 1M 文脈の検索で優位を保つ一方 Gemini は崩壊（ゆえに monorepo architect = Opus）；単一 `@file` 入力上限（anthropic/antigravity で約 400k）は 1M 文脈ウィンドウとは別物（巨大入力はターンに分割）。完全な表は **[韓国語 README §6](./README.ko.md#6--검증-매트릭스)**。

---

## 7. 🛠️ インストール / アンインストール

### ワンクリック（推奨）

```bash
curl -fsSL https://raw.githubusercontent.com/Sigmachan/gjc-multivendor-setup-guide/main/install.sh | bash
```

インストーラの動作：10プロファイルを `~/.gjc/agent/models.yml` に安全マージ（再実行で自動更新）・既存ファイルを自動バックアップ・既定プロファイルを `daily` に設定。`curl` + `python3` だけで動く。

```bash
# オプション
curl -fsSL …/install.sh | GJC_SETUP_DEFAULT=ultimate bash    # 既定プロファイル指定
curl -fsSL …/install.sh | GJC_SETUP_DEFAULT=none bash        # 既定設定をスキップ
curl -fsSL …/install.sh | GJC_CODING_AGENT_DIR=/path bash    # agent ディレクトリ上書き
```

### プロバイダ認証（必須）

インストールはプロファイルを置くだけ。GJC を起動し各ベンダーに一度ログイン：

```text
/login anthropic           # claude
/login openai-codex        # gpt（base GPT）
/login google-antigravity  # gemini（Google AI Pro/Ultra サブスク）
/login xai                 # grok 全ラインナップ + Composer
```

opencode-go は `/provider add` または環境変数 `OPENCODE_API_KEY`。

### 手動インストール / 検証 / アンインストール

[`gjc-profiles.yml`](./gjc-profiles.yml) の `profiles:` ブロックを `~/.gjc/agent/models.yml` の `profiles:` 配下に貼り付け、`gjc --mpreset daily --default`。

```bash
gjc --list-models daily                       # 確認
cp ~/.gjc/agent/models.yml.bak-*  ~/.gjc/agent/models.yml   # 巻き戻し(バックアップ復元)
```

---

## 8. 🔀 動的ルーティング

> **「クエリ毎にプロファイル切替」❌ /「強メインループ1つ + 薄いルール1層」✅。** ルータはメインループ（Opus）、プロファイルは行き先プール。

> [!TIP]
> 下のルーティングルールをメインループに従わせるには、[`routing-rules.md`](./routing-rules.md) をプロジェクトの `AGENTS.md` に入れるか、`gjc --append-system-prompt @routing-rules.md` で注入する（導入プロファイル + 検証済みセレクタのハードルール + GJC 実効 ctx 上限を1ファイルに同梱）。

### 8-1. 作業シグナル → 委譲

<div align="center">
<img src="assets/routing-tree.svg" alt="作業シグナル → 委譲ルーティング" width="100%">
</div>

ルール：**委譲はシグナルが明確なときだけ。** メインループが直接できるなら直接やる。

### 8-2. 適応的 effort エスカレーション

<div align="center">
<img src="assets/effort-ladder.svg" alt="適応的 effort エスカレーション" width="100%">
</div>

- ✅ 解けなかったから上げるのは正当 / ❌「念のため上げる」は無駄。
- minimal 禁止。下限は `low`。Gemini は `low↔high` の単一ジャンプ。

### 8-3. プロファイル切替（モード境界のみ）

| シグナル | 切替 → |
|---|---|
| セッション開始 · 一般作業 | `daily` |
| マージ/リリース前 · セキュリティ · 決済 | `escalation` |
| 大量リファクタ · マイグレーション | `eco` |
| 巨大コードベースへ突入 | `monorepo` |
| 単一ベンダー運用 | `solo-anthropic` |

---

## 9. 🧪 並列エージェント + 信頼性

直列の引き継ぎは `0.99ⁿ` で減衰し、マルチエージェントは繋ぎ方を誤ると「偽の合意」に固まる。並列設計はこの2つを防ぐように組む。

```text
直列チェーン 5段(各 0.99)：  0.99^5 ≈ 95.1%    → 長いほど崩壊
並列独立 5個(OR 成功)：      1-(0.01)^5 ≈ 100%  → 多様性が信頼性を高める
```

**設計原則**
- critic = **メインループと別ベンダー、並列で独立投票しメインループが集計**（討論禁止 — メタ審判が優位）。
- critic パネル例：`{xai/grok-4.3, openai-codex/gpt-5.4, google-antigravity/gemini-3.1-pro-low:high}` を並列 → 2/3 が否なら破棄。
- executor のファンアウトは**作業が真に独立**（共有状態なし）なときだけ。
- チェーンは短く、メインループを単一の真実源に（サブ同士で直接合意させない）。

---

## 10. 💰 コスト

Gemini（`google-antigravity`）は **Google AI Pro/Ultra のサブスクトークン**で動く（トークン従量ではなくサブスクに含まれる）。他は従量課金で、主要モデル単価は以下（$/1M、入力/出力）：

| モデル | $/1M (in/out) | 役割 |
|---|---|---|
| Claude Opus 4.8 | 5 / 25 | default·executor |
| Claude Sonnet 4.6 | 3 / 15 | solo critic |
| GPT-5.5 | 5 / 30 | planner(ultimate) |
| GPT-5.4 | 2.5 / 15 | executor/critic(daily·sprint) |
| Grok 4.3 | 1.25 / 2.5 | critic |
| Grok 4.1 Fast | 0.2 / 0.5 | eco planner |
| DeepSeek V4 Flash / Pro (opencode-go) | 0.14/0.28 · 1.74/3.48 | eco executor · monorepo critic |
| Gemini 3.1 Pro / 3.5 Flash | サブスクトークン | planner·architect·critic |

**プロファイル相対コスト**

| プロファイル | コスト | 主因 |
|---|---|---|
| ultimate / escalation | ●●●●● | executor Opus `:max` + planner GPT-5.5 `:xhigh` |
| coding-sprint | ●●●●○ | executor Opus `:max` |
| daily | ●●●○○ | メインループ Opus `:medium`、委譲は中/低価格に分散 |
| monorepo | ●●●○○ | executor Opus + Grok/Gemini(サブスク) |
| solo-anthropic | ●●●○○ | 全 Opus(critic のみ Sonnet) |
| eco | ●○○○○ | executor DeepSeek V4 Flash($0.14) + サブスク Gemini |

> **3つの節約レバー**：① 委譲作業を超安価モデル（DeepSeek V4 Flash $0.14、Grok Fast $0.2）/ サブスクトークン（Gemini）へ ② 失敗時のみ effort を上げる ③ メインループは Opus（品質の上限）を維持しつつ日常は `:medium`、コスト逼迫時は `:low`。

---

## 11. 📖 出典

**コーディング（executor）** · [Vals SWE-bench Verified](https://www.vals.ai/benchmarks/swebench) · [swebench.com](https://www.swebench.com/verified.html) · [Terminal-Bench 2.0](https://www.tbench.ai/leaderboard/terminal-bench/2.0)

**推論（planner）** · [Gemini 3.1 Pro card](https://deepmind.google/models/model-cards/gemini-3-1-pro/) · [AA Index](https://artificialanalysis.ai/evaluations/artificial-analysis-intelligence-index)

**文脈 · マルチモーダル（architect）** · [Gemini 3](https://blog.google/products-and-platforms/products/gemini/gemini-3/)

**ツール呼び出し · 誠実性（default）** · [BFCL](https://gorilla.cs.berkeley.edu/leaderboard.html) · [τ²-Bench](https://arxiv.org/abs/2506.07982)

**独立性 · ルーティング（critic + 設計）** · [self-preference bias](https://arxiv.org/abs/2410.21819) · [Judging with Many Minds](https://arxiv.org/abs/2505.19477) · [RouteLLM](https://www.lmsys.org/blog/2024-07-01-routellm/)

**公式モデル/価格** · [Anthropic](https://docs.anthropic.com/en/docs/about-claude/models) · [OpenAI](https://openai.com/api/pricing/) · [xAI](https://docs.x.ai/developers/models)

---

<div align="center">

**ワンライナーで導入、役割ごとに最適モデル。**

**v1.3** · [CHANGELOG](./CHANGELOG.md) · [保守プレイブック](./MAINTAINING.md) · ライセンス [CC BY 4.0](./LICENSE) · GJC = [Gajae Code](https://github.com/Yeachan-Heo/gajae-code)

</div>
