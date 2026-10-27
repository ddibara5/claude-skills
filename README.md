# claude-skills

Design skills for Dave's Claude Code cloud sessions (Hearth, App Studio and the other Floot apps).

- `skills.lock.json`: which skills install, from which repo, at which commit.
- `setup.sh`: run by the environment's Setup script at the start of every session.
- `UPDATE.md`: what the weekly update job does (auto-merge policy).

Environment Setup script (Claude Code cloud environment, Edit, Setup script):

    curl -fsSL https://raw.githubusercontent.com/ddibara5/claude-skills/main/setup.sh | bash

To roll back a bad update: revert the commit that changed `skills.lock.json`; the next session uses the old pins.
No secrets live here.
