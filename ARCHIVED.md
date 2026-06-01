# ARCHIVED

This repository is a local, reversible archive snapshot. It has not been pushed.

## How to restore the working tree

All archive normalization is committed. To discard any later uncommitted edits and
return to the archived state:

```bash
git restore .            # discard unstaged changes to tracked files
git restore --staged .   # unstage anything staged
git status -s            # should be empty (ignored files excluded)
```

To inspect or check out a specific archived commit:

```bash
git log --oneline        # find the archive commits
git checkout <sha>       # detached view of that snapshot
```

## Credentials

- No credential files (`*.env`, `cookies.txt`, `*.pem`, `*.key`) exist in this
  repository's tracked tree or in the local branch history.
- History was scanned: the local branch (codex/windows-capsule-contract-evidence)
  contains only the evidence bundle. No secrets are present, so no history
  rewrite was needed (backup mode: history is never rewritten).
- `.gitignore` blocks common credential patterns from future commits.

## Remote

- Configured remote `fork`: https://github.com/Cooper-X-Oak/openless.git
- This archive was prepared locally and is NOT pushed. Pushing is a manual,
  deliberate step performed only by the maintainer.
- Remote placeholder for any future archive remote: <git@github.com:OWNER/REPO.git>
