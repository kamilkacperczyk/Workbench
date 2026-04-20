# Konfiguracja Claude Code dla tego projektu

## Pliki

- `settings.json` - konfiguracja wspoldzielona (commitowana). Stworz z `settings.json.example`.
- `settings.local.json` - lokalne nadpisania per-deweloper (w `.gitignore`)

## Permissions

Lista whitelistowanych komend (Bash, MCP, etc.) zeby Claude nie pytal za kazdym razem.

Format: `"Bash(git status)"`, `"Bash(git diff:*)"` (`:*` = z dowolnymi argumentami).

## Hooks

Skrypty wywolywane automatycznie przez harness Claude Code na rozne eventy (PreToolUse, PostToolUse, Stop, UserPromptSubmit).

Skrypty trzymamy w `hooks/`, settings.json je referuje przez `$CLAUDE_PROJECT_DIR/hooks/...`.

Patrz `hooks/README.md`.
