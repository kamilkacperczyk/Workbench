# hooks/

Skrypty hookow - wywolywane automatycznie przez Claude Code lub gita.

## Dwa rodzaje hookow

### 1. Hooki Claude Code

Wywolywane przez harness na eventy (PreToolUse, PostToolUse, Stop, UserPromptSubmit, SessionStart).

Konfiguracja w `.claude/settings.json`. Skrypty referuje przez `$CLAUDE_PROJECT_DIR/hooks/...`.

Konwencja nazwy: `<event>-<co-robi>.sh` lub `.py`
- `pre-bash-check.sh`
- `post-edit-format.sh`
- `stop-summary.sh`

### 2. Hooki Gita

Klasyczne pre-commit / pre-push.

Konwencja: `pre-commit.sh`, `pre-push.sh`, etc.

Aktywacja (jednorazowo po sklonowaniu repo):
```bash
ln -s ../../hooks/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## Co warto miec

- `pre-commit.sh` - skan staged plikow pod katem wrazliwych danych (gitleaks/regex)
- `pre-bash-check.sh` - blokowanie niebezpiecznych komend (rm -rf /, force push na main)
- `stop-summary.sh` - podsumowanie sesji

## Wymagania

Skrypty bash dzialaja na Linux/macOS i Windows (Git Bash). Pamietaj o `#!/usr/bin/env bash` na poczatku.
