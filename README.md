# Git Hooks

This repository uses a shared `.githooks/` directory for Git hooks so they are version-controlled and available to every contributor.

## Setup

After cloning, point Git to the hooks directory:

```bash
git config core.hooksPath .githooks
```

## Hooks

### pre-commit

Automatically sets the executable bit (`+x`) on every staged `.sh` file before the commit is created. This ensures shell scripts always have mode `100755` in the repository, regardless of the local filesystem.
