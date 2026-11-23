#!/bin/bash
# Runs setup.sh against a throwaway HOME and checks it: every listed skill installs, unlisted skills
# are kept, removedSkills are deleted, and an upstream skill that ships scripts is refused.
# Needs network (it clones the upstream repos). Usage: bash test-setup.sh
set -euo pipefail
cd "$(dirname "$0")"
H="$(mktemp -d)"
trap 'rm -rf "$H"' EXIT
mkdir -p "$H/.claude/skills/mine" "$H/.claude/skills/mobile-native"
touch "$H/.claude/skills/mine/SKILL.md" "$H/.claude/skills/mobile-native/SKILL.md"

# Fixture: the real lock plus one upstream skill that ships Python scripts, which setup.sh must skip.
python3 -c '
import json, sys
lock = json.load(open(sys.argv[1]))
lock["skills"].append({"repo": "AvdLee/SwiftUI-Agent-Skill", "commit": "62bd760f005093d1e2e4de5db156e456a5f96400", "paths": ["skills/swiftui-expert-skill"]})
json.dump(lock, open(sys.argv[2], "w"))
' skills.lock.json "$H/lock.json"

# PATH without claude, so the test never installs plugins.
out="$(HOME="$H" LOCK_URL="file://$H/lock.json" PATH=/usr/bin:/bin:/usr/sbin:/sbin bash setup.sh)"
echo "$out"

fail() { echo "FAIL: $1"; exit 1; }
for n in $(python3 -c 'import json; print(*[p.split("/")[-1] for s in json.load(open("skills.lock.json"))["skills"] for p in s["paths"]])'); do
  [ -f "$H/.claude/skills/$n/SKILL.md" ] || fail "listed skill $n not installed"
done
[ -f "$H/.claude/skills/mine/SKILL.md" ] || fail "deleted a skill that is not in the lock"
[ ! -e "$H/.claude/skills/mobile-native" ] || fail "removedSkills entry mobile-native still installed"
[ ! -e "$H/.claude/skills/swiftui-expert-skill" ] || fail "installed a skill that ships scripts"
grep -q "SKIPPED swiftui-expert-skill" <<<"$out" || fail "no SKIPPED message for the script skill"
python3 -c 'import json,sys; e=json.load(open(sys.argv[1]))["enabledPlugins"]; assert e["frontend-design@claude-plugins-official"] is False and e["impeccable@impeccable"] is True' "$H/.claude/settings.json" || fail "plugin settings wrong"
echo "PASS"
