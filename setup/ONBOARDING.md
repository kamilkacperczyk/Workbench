# Onboarding

Krok po kroku jak postawic projekt lokalnie.

## Wymagania

- {{LANG_VERSION}} (np. Python 3.11+, Node 20+)
- {{INNE_NARZEDZIA}}
- gh CLI (do interakcji z GitHubem)

## Setup

1. **Sklonuj repo:**
   ```bash
   git clone https://github.com/{{ORG}}/{{REPO}}.git
   cd {{REPO}}
   ```

2. **Skopiuj env:**
   ```bash
   cp .env.example .env
   # Wypelnij wartosci - zglos sie do {{KONTAKT}} po sekrety
   ```

3. **Zainstaluj zaleznosci:**
   ```bash
   {{INSTALL_COMMAND}}
   ```

4. **Aktywuj pre-commit hook:**
   ```bash
   ln -s ../../hooks/pre-commit.sh .git/hooks/pre-commit
   chmod +x .git/hooks/pre-commit
   ```

5. **Stworz lokalnie folder PRIV:**
   ```bash
   mkdir PRIV
   # Tutaj trzymasz swoje prywatne notatki - nie trafia do repo
   ```

6. **Skopiuj settings.json (opcjonalnie):**
   ```bash
   cp .claude/settings.json.example .claude/settings.json
   ```

## Weryfikacja

```bash
{{HEALTHCHECK_COMMAND}}
```

## Pierwsze kroki w Claude Code

W glownym katalogu repo:
```bash
claude
```

Claude przeczyta `CLAUDE.md` automatycznie. Jesli chcesz dodac wlasne preferencje per-deweloper - `.claude/settings.local.json`.
