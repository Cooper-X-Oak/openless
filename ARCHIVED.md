# ARCHIVED

This repository is a local, archived evidence bundle. It has been normalized
for archival (gitignore hardening, identity normalization, baseline docs).
No history was rewritten. Nothing was pushed.

## Status

- Mode: backup (history NOT rewritten).
- Credentials: none found in tracked files, working tree, or this branch's
  committed history. No scrubbing was necessary.
- Branch: `codex/pr497-evidence-20260519-083148` (a standalone 1-commit
  evidence branch; its own ancestry contains only the four evidence files).

## How to restore the working tree

If you have local modifications you want to discard and return to the last
committed state:

```bash
git restore .            # discard unstaged changes to tracked files
git checkout .           # equivalent for older git
```

To recover the exact archived snapshot from a fresh clone:

```bash
git checkout codex/pr497-evidence-20260519-083148
```

## Where credentials live

None are stored in this repository. Credential-pattern files
(`*.env`, `cookies.txt`, `*.pem`, `*.key`, etc.) are excluded via
`.gitignore`. If credentials are ever needed for related OpenLess work,
they belong outside the repo (environment variables or a secret manager),
never committed.

## Remote

- Configured origin: `https://github.com/Cooper-X-Oak/openless.git`
- This archival prep performed NO push, NO force-push, and NO ref deletion.
  Pushing is a deliberate manual step left to the maintainer.
