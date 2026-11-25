# claude-skills

Design and Swift skills for Dave's Claude Code sessions: cloud sessions, and the desktop app on his Mac.

- `skills.lock.json`: which skills install, from which repo, at which commit. `removedSkills` lists skills taken
  off on purpose; `setup.sh` deletes them, and they must not be re-added. `disabledPlugins` turns off plugins by id.
- `setup.sh`: installs the lock into `~/.claude`. It only installs skills made of documentation and images (no
  scripts or binaries), swaps each skill in place so a failed copy never leaves it missing, and never touches
  skills that are not in the lock (such as `ios-reference-build`).
- `test-setup.sh`: runs `setup.sh` against a throwaway HOME and checks the rules above. Run it after editing `setup.sh`.
- `UPDATE.md`: what the weekly update job does (auto-merge policy).
- `skills/`: skills written by the monthly review job, installed through lock entries that point at this repo
  (`source: skills-review`, with an `added` date). Rules are in `UPDATE.md`.

Where it runs:

- Cloud environment Setup script, at the start of every session:

      curl -fsSL https://raw.githubusercontent.com/ddibara5/claude-skills/main/setup.sh | bash

- Dave's Mac: launchd job `com.dave.claude-skills`, Sundays 18:39, an hour after the weekly update job.
  New desktop sessions pick up changes after that run. To get them sooner, run `setup.sh` by hand.

Plugins synced from the claude.ai account (frontend-design, design and others) are not installed by this repo.
`disabledPlugins` turns them off in settings, but the reliable switch is the plugin list in the Claude app.

To roll back a bad update: revert the commit that changed `skills.lock.json`; the next run uses the old pins.
No secrets live here.
