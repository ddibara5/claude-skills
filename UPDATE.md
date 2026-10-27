# Weekly update job

Instructions for the scheduled Claude Code session that keeps `skills.lock.json` current.
Policy (Dave, Oct 27, 2026): always auto-merge. Commit straight to `main`; no pull request.

1. Clone this repo. Read `skills.lock.json`.
2. For each entry in `skills`: `git ls-remote https://github.com/<repo> HEAD`. If the SHA equals `commit`, skip it.
3. If it changed: clone the repo, run `git diff --stat <old>..<new> -- <paths>` and read the diff for those paths only.
   Write a 1 to 3 line plain-English summary per skill. Flag in capitals any NEW or CHANGED file that is not
   Markdown (scripts, hooks, binaries, package files), and any skill folder in `paths` that was removed upstream.
   If a listed path no longer exists at the new commit, leave that repo's `commit` unchanged and report it.
4. For each entry in `plugins`: `git ls-remote https://github.com/<marketplace> HEAD`; if it differs from `seen`,
   summarise the change the same way and update `seen` (plugins install their latest at session start anyway).
5. If anything changed: update the SHAs and `updated` (YYYY-MM-DD), commit with the message
   `Update skills: <names>` and the summaries in the body, push to `main`.
6. Send Dave one push notification: what updated, the flags from step 3, and the commit link. If nothing changed, send nothing.
7. Never add, remove or rename skills on your own; only Dave changes the list.
