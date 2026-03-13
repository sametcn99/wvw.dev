---
on:
  pull_request:
    types: [opened, synchronize]
  push:
    branches: [master]
    paths: [stores.json]
permissions:
  contents: read
  pull-requests: read
safe-outputs:
  update-pull-request-branch:
    merge-strategy: rebase
  comment-on-pull-request:
    labels: [auto-fixed]
---

## Fix stores.json Conflicts in Pull Requests

When a new PR is opened or master changes, check all open PRs that modify `stores.json` for merge conflicts.

### Context

This repository is a distributed app store (World Vibe Web). Contributors add their store by appending a single entry to the `stores.json` array. Because multiple PRs modify the same file, conflicts are frequent and always follow the same pattern: each PR adds a new line to the JSON array.

### What to do

1. List all open pull requests that modify `stores.json`
2. For each conflicting PR:
   - Read the current `stores.json` on master
   - Read the PR's version of `stores.json`
   - Identify which new entries the PR is trying to add (entries not in master)
   - Rebase the PR branch onto master, keeping all existing entries and adding the new ones
3. If successfully rebased, comment on the PR: "Auto-rebased `stores.json` onto master. This PR should now be mergeable."
4. If the conflict cannot be resolved automatically (e.g., the PR modifies files other than `stores.json`), comment with instructions:
   ```
   This PR has a conflict. Please rebase on master:
   git fetch upstream && git rebase upstream/master && git push --force
   ```

### Important rules

- Only fix conflicts in `stores.json` — do not touch any other files
- The merged `stores.json` must be valid JSON: an array of strings
- Never remove existing entries from master's `stores.json`
- Preserve the order: master entries first, then new entries at the end
- Each entry is either a GitHub repo path (e.g. `"owner/repo"`) or a full URL (e.g. `"https://..."`)
