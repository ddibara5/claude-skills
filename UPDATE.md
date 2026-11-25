# Weekly update job

Instructions for the scheduled Claude Code session that keeps `skills.lock.json` current.
Policy (Dave, Oct 27, 2026): always auto-merge. Commit straight to `main`; no pull request.

1. Clone this repo. Read `skills.lock.json`.
2. For each entry in `skills`: `git ls-remote https://github.com/<repo> HEAD`. If the SHA equals `commit`, skip it.
   For an entry whose `repo` is `ddibara5/claude-skills` (skills written by the monthly review), skip it unless
   `git diff --stat <commit>..<new> -- <paths>` is non-empty; this repo's HEAD moves with every lock commit.
3. If it changed: clone the repo, run `git diff --stat <old>..<new> -- <paths>` and read the diff for those paths only.
   Write a 1 to 3 line plain-English summary per skill. Flag in capitals any NEW or CHANGED file that is not
   Markdown (scripts, hooks, binaries, package files), and any skill folder in `paths` that was removed upstream.
   If a listed path no longer exists at the new commit, leave that repo's `commit` unchanged and report it.
   `setup.sh` refuses to install a skill that contains anything other than documentation and images, so a
   flagged script or binary means that skill stops updating until Dave decides; say so in the notification.
4. For each entry in `plugins`: `git ls-remote https://github.com/<marketplace> HEAD`; if it differs from `seen`,
   summarise the change the same way and update `seen` (plugins install their latest at session start anyway).
5. If anything changed: update the SHAs and `updated` (YYYY-MM-DD), commit with the message
   `Update skills: <names>` and the summaries in the body, push to `main`.
6. Send Dave one push notification: what updated, the flags from step 3, and the commit link. If nothing changed, send nothing.
7. This weekly job never adds, removes or renames skills. Only Dave, or the monthly review ("AI | Monthly | Skills Review")
   under the rules below, changes the list. Never re-add a name in `removedSkills`.

## Monthly review rules (Dave, Nov 25, 2026)

- It may write up to 2 new skills a month, each tied to an active project in Dave's vault, after an overlap check.
- A new skill lives in `skills/<name>/SKILL.md` in this repo (documentation only) and gets a lock entry
  `{"repo": "ddibara5/claude-skills", "commit": <sha of the commit that added it>, "paths": ["skills/<name>"],
  "added": "YYYY-MM-DD", "source": "skills-review"}`. Commit and push straight to `main`.
- It removes a skill it added (`source: skills-review`) 60 days after `added` unless there is evidence it was used
  or Dave said keep. Removal: delete the folder, drop the lock entry, add the name to `removedSkills`, push to `main`.
- It never auto-removes upstream skills or skills Dave chose; it only suggests those.
