#!/bin/bash
# Installs the design skills listed in skills.lock.json into ~/.claude for this cloud session.
# Called from the environment's Setup script; reads the lock from this public repo.
set -euo pipefail

LOCK_URL="${LOCK_URL:-https://raw.githubusercontent.com/ddibara5/claude-skills/main/skills.lock.json}"
S="$HOME/.claude/skills"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
mkdir -p "$S"
curl -fsSL "$LOCK_URL" -o "$T/lock.json"

# One line per skill repo: "<repo> <commit> <path> <path> ..."
python3 -c '
import json, sys
for s in json.load(open(sys.argv[1]))["skills"]:
    print(s["repo"], s["commit"], *s["paths"])
' "$T/lock.json" | while read -r repo commit paths; do
  dir="$T/$(echo "$repo" | tr / _)"
  git clone -q --filter=blob:none "https://github.com/$repo" "$dir"
  git -C "$dir" checkout -q "$commit"
  for p in $paths; do
    name="$(basename "$p")"
    rm -rf "$S/$name"
    cp -R "$dir/$p" "$S/$name"
  done
done

# Plugins: register each marketplace and enable the plugin; turn off disabledPlugins (e.g. synced account plugins).
python3 - "$T/lock.json" <<'PY'
import json, os, sys
lock = json.load(open(sys.argv[1]))
p = os.path.expanduser("~/.claude/settings.json")
s = json.load(open(p)) if os.path.exists(p) else {}
for pl in lock.get("plugins", []):
    s.setdefault("extraKnownMarketplaces", {})[pl["name"]] = {"source": {"source": "github", "repo": pl["marketplace"]}}
    s.setdefault("enabledPlugins", {})[f'{pl["name"]}@{pl["name"]}'] = True
for name in lock.get("disabledPlugins", []):
    s.setdefault("enabledPlugins", {})[name] = False
os.makedirs(os.path.dirname(p), exist_ok=True)
json.dump(s, open(p, "w"), indent=2)
PY

# Pre-install so plugin skills are listed from the first turn; launch-time install lands after the skill list is built.
if command -v claude >/dev/null; then
  python3 -c 'import json,sys; [print(p["marketplace"], p["name"]) for p in json.load(open(sys.argv[1])).get("plugins", [])]' "$T/lock.json" |
  while read -r mp name; do
    claude plugin marketplace add "$mp" >/dev/null 2>&1 || true
    claude plugin install "$name@$name" >/dev/null 2>&1 || echo "Plugin $name not pre-installed; Claude Code installs it at launch."
  done
fi

echo "Design skills ready: $(ls "$S" | tr '\n' ' ')"
