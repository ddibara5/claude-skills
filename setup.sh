#!/bin/bash
# Installs the skills and plugins listed in skills.lock.json into ~/.claude.
# Runs from the cloud environment's Setup script at session start, and weekly on Dave's Mac (launchd com.dave.claude-skills).
set -euo pipefail

LOCK_URL="${LOCK_URL:-https://raw.githubusercontent.com/ddibara5/claude-skills/main/skills.lock.json}"
S="$HOME/.claude/skills"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
mkdir -p "$S"
curl -fsSL "$LOCK_URL" -o "$T/lock.json"

# Upstream skills must be documentation only, so no upstream script or binary ever lands in ~/.claude/skills.
DOC_ONLY='\.(md|markdown|txt|ya?ml|json|png|jpe?g|gif|svg|webp)$'

# Validate names, then print one line per skill repo: "<repo> <commit> <path> <path> ..."
python3 -c '
import json, re, sys
lock = json.load(open(sys.argv[1]))
ok = re.compile(r"^[a-z0-9][a-z0-9-]*$")
removed = set(lock.get("removedSkills", []))
seen = set()
for s in lock["skills"]:
    for p in s["paths"]:
        n = p.rstrip("/").split("/")[-1]
        if not ok.match(n) or n in seen or n in removed:
            sys.exit(f"skills.lock.json: bad, duplicate or removed skill name: {n}")
        seen.add(n)
bad = [n for n in removed if not ok.match(n)]
if bad:
    sys.exit(f"skills.lock.json: bad removedSkills name: {bad}")
for s in lock["skills"]:
    print(s["repo"], s["commit"], *s["paths"])
' "$T/lock.json" > "$T/skills.txt"

while read -r repo commit paths; do
  dir="$T/$(echo "$repo" | tr / _)"
  git clone -q --filter=blob:none "https://github.com/$repo" "$dir"
  git -C "$dir" checkout -q "$commit"
  for p in $paths; do
    name="$(basename "$p")"
    if [ ! -f "$dir/$p/SKILL.md" ]; then echo "MISSING $repo/$p at $commit; kept the installed copy."; continue; fi
    bad="$( (cd "$dir/$p" && { find . -type f | grep -Eiv "$DOC_ONLY"; find . -type f -perm -u+x; }) || true)"
    if [ -n "$bad" ]; then echo "SKIPPED $name: non-documentation files:" $bad; continue; fi
    # Copy beside the old version, then swap, so a failed copy never leaves the skill missing.
    rm -rf "$S/.$name.new"
    cp -R "$dir/$p" "$S/.$name.new"
    rm -rf "$S/$name"
    mv "$S/.$name.new" "$S/$name"
  done
done < "$T/skills.txt"

# Skills taken off the list: delete only these names, never other skills in ~/.claude/skills.
for name in $(python3 -c 'import json,sys; print(*json.load(open(sys.argv[1])).get("removedSkills", []))' "$T/lock.json"); do
  if [ -d "$S/$name" ]; then rm -rf "$S/$name"; echo "Removed $name"; fi
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
