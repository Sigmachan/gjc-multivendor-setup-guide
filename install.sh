#!/usr/bin/env bash
# ============================================================================
#  GJC multi-vendor setup — one-click installer
#  https://github.com/Sigmachan/gjc-multivendor-setup-guide
#
#  Usage:
#    curl -fsSL https://raw.githubusercontent.com/Sigmachan/gjc-multivendor-setup-guide/main/install.sh | bash
#
#  Options (env vars):
#    GJC_SETUP_DEFAULT=ultimate  # pick the default profile (default: daily). 'none' skips default-setting
#      e.g. curl -fsSL <url>/install.sh | GJC_SETUP_DEFAULT=ultimate bash
#    GJC_CODING_AGENT_DIR=...    # override the GJC agent dir (default: ~/.gjc/agent)
#
#  Safety: auto-backs up existing models.yml / config.yml · managed-block sentinel for a clean re-run swap.
# ============================================================================
set -euo pipefail

REPO_RAW="${GJC_SETUP_REPO:-https://raw.githubusercontent.com/Sigmachan/gjc-multivendor-setup-guide/main}"
PROFILES_URL="$REPO_RAW/gjc-profiles.yml"
DIR="${GJC_CODING_AGENT_DIR:-$HOME/.gjc/agent}"
TARGET="$DIR/models.yml"
CONFIG="$DIR/config.yml"
DEFAULT_PROFILE="${GJC_SETUP_DEFAULT:-daily}"
SENTINEL="gjc-multivendor-setup-guide"

b(){ printf '\033[1;36m%s\033[0m\n' "$*"; }
g(){ printf '\033[32m%s\033[0m\n' "$*"; }
y(){ printf '\033[33m%s\033[0m\n' "$*"; }
die(){ printf '\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

command -v python3 >/dev/null 2>&1 || die "python3 is required (used for the safe YAML merge)."

b "▶ Installing the GJC multi-vendor setup"

# 1) Obtain the profile source (for local testing, point GJC_SETUP_SRC at a file)
SRC="$(mktemp)"; trap 'rm -f "$SRC"' EXIT
if [ -n "${GJC_SETUP_SRC:-}" ]; then
  cp "$GJC_SETUP_SRC" "$SRC"; echo "  · source (local): $GJC_SETUP_SRC"
else
  command -v curl >/dev/null 2>&1 || die "curl is required."
  curl -fsSL "$PROFILES_URL" -o "$SRC" || die "profile download failed: $PROFILES_URL"
  echo "  · source: $PROFILES_URL"
fi

mkdir -p "$DIR"

# 2) Backup
TS="$(date +%Y%m%d-%H%M%S)"
[ -f "$TARGET" ] && { cp "$TARGET" "$TARGET.bak-$TS"; echo "  · backup: $TARGET.bak-$TS"; }
[ -f "$CONFIG" ] && cp "$CONFIG" "$CONFIG.bak-$TS"

# 3) Merge profiles (managed-block sentinel — auto-replaced on re-run; same-named existing profiles are replaced)
python3 - "$TARGET" "$SRC" "$SENTINEL" <<'PY'
import sys, os, re
target, src, name = sys.argv[1], sys.argv[2], sys.argv[3]
START = f"  # >>> {name} (managed block — auto-replaced on re-run) >>>"
END   = f"  # <<< {name} <<<"

s = open(src, encoding="utf-8").read().splitlines()
pi = next((i for i, l in enumerate(s) if l.rstrip() == "profiles:"), None)
if pi is None: sys.exit("source has no profiles: block")
children = s[pi+1:]
while children and not children[0].strip(): children.pop(0)
while children and not children[-1].strip(): children.pop()
managed = [START] + children + [END]
our = {m.group(1) for l in children for m in [re.match(r"^  ([A-Za-z0-9_-]+):\s*(#.*)?$", l)] if m}

content = open(target, encoding="utf-8").read() if os.path.exists(target) else ""
content = re.sub(re.escape(START) + r".*?" + re.escape(END) + r"\n?", "", content, flags=re.S)
lines = content.splitlines()

pidx = next((i for i, l in enumerate(lines) if re.match(r"^profiles:\s*$", l)), None)
replaced = []
if pidx is None:
    base = ("\n".join(lines).rstrip() + "\n\n") if any(l.strip() for l in lines) else ""
    out = base + "profiles:\n" + "\n".join(managed) + "\n"
else:
    end = len(lines)
    for i in range(pidx+1, len(lines)):
        if lines[i] and not lines[i][0].isspace():
            end = i; break
    head, body, tail = lines[:pidx+1], lines[pidx+1:end], lines[end:]
    out_body, i = [], 0
    while i < len(body):
        m = re.match(r"^  ([A-Za-z0-9_-]+):\s*(#.*)?$", body[i])
        if m and m.group(1) in our:
            replaced.append(m.group(1)); i += 1
            while i < len(body) and (not body[i].strip() or body[i].startswith("   ")):
                i += 1
            continue
        out_body.append(body[i]); i += 1
    out = "\n".join(head + managed + out_body + tail).rstrip() + "\n"

open(target, "w", encoding="utf-8").write(out)
if replaced: print("  · replaced existing same-named profiles:", ", ".join(sorted(set(replaced))))
print("  · merged 10 profiles →", target)
PY

# 4) Set the default profile (config.yml). 'none' skips this
if [ "$DEFAULT_PROFILE" != "none" ]; then
python3 - "$CONFIG" "$DEFAULT_PROFILE" <<'PY'
import sys, os, re
cfg, prof = sys.argv[1], sys.argv[2]
content = open(cfg, encoding="utf-8").read() if os.path.exists(cfg) else ""
lines = content.splitlines()
mi = next((i for i, l in enumerate(lines) if re.match(r"^modelProfile:\s*$", l)), None)
if mi is None:
    block = f"modelProfile:\n  default: {prof}"
    content = (content.rstrip() + "\n\n" + block + "\n") if content.strip() else (block + "\n")
else:
    j, found = mi+1, False
    while j < len(lines) and (lines[j].startswith("  ") or not lines[j].strip()):
        if re.match(r"\s+default:\s*", lines[j]):
            lines[j] = re.sub(r"(default:\s*).*", lambda m: m.group(1)+prof, lines[j]); found = True; break
        if lines[j].strip() and not lines[j].startswith("  "): break
        j += 1
    if not found: lines.insert(mi+1, f"  default: {prof}")
    content = "\n".join(lines) + "\n"
open(cfg, "w", encoding="utf-8").write(content)
print(f"  · default profile = {prof} (config.yml)")
PY
fi

echo
g "✓ Install complete"
echo
b "10 profiles installed"
echo "  ★daily  ultimate  coding-sprint  escalation  eco  monorepo  solo-anthropic  solo-openai  claude-codex  claude-codex-max"
echo
b "Next steps"
echo "  gjc --mpreset daily          # this session only"
echo "  gjc --list-models daily      # confirm (cycle with Ctrl+P during a session)"
echo
b "⚠ Provider authentication (required — otherwise 'No API key')"
echo "  After opening GJC, run each once (browser OAuth):"
echo "    /login anthropic           # claude"
echo "    /login openai-codex        # gpt (base GPT: gpt-5.5/5.4)"
echo "    /login google-antigravity  # gemini (Google AI Pro/Ultra subscription)"
echo "    /login xai                 # grok full lineup (grok-4.3, etc.)"
echo "  opencode-go: /provider add or OPENCODE_API_KEY"
[ "$DEFAULT_PROFILE" != "none" ] && y "Default profile is now set to '$DEFAULT_PROFILE' (config.yml). Applied automatically from new sessions."
echo
echo "  Revert: cp \"$TARGET.bak-$TS\" \"$TARGET\"   (if a backup exists)"
