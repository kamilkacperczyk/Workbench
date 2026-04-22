# Workbench

Szablon repo do projektow opartych o Claude Code / Claude Agent SDK.

Sklonuj, zmien nazwe, podmien placeholdery `{{...}}` w `CLAUDE.md` i zaczynaj.

## Pierwsze uruchomienie

1. **Uzyj jako template** na GitHub (przycisk "Use this template") albo `git clone`
2. **Onboarding krok po kroku**: [setup/ONBOARDING.md](setup/ONBOARDING.md)
3. **Deployment**: [setup/DEPLOYMENT.md](setup/DEPLOYMENT.md)

Skrocony quick start (jesli chcesz tylko zerknac):
- Wypelnij placeholdery `{{...}}` w `CLAUDE.md`
- `cp .env.example .env` i wypelnij sekrety
- `cp .claude/settings.json.example .claude/settings.json` (opcjonalnie)
- `mkdir PRIV` na prywatne notatki (gitignored)
- Aktywuj pre-commit hook (instrukcja w ONBOARDING.md)
- (Opcjonalnie) zaadaptuj propozycje globalnego CLAUDE.md z `setup/global-claude-md.example`

Pelne kroki + wymagania + weryfikacja: [setup/ONBOARDING.md](setup/ONBOARDING.md).

## Struktura

| Folder | Co tam trafia |
|---|---|
| `commands/` | Slash commands Claude Code (`.md` z YAML frontmatter) |
| `findings/` | Wnioski/odkrycia z pracy - gotchas, lessons learned (`YYYY-MM-DD-tytul.md`) |
| `hooks/` | Skrypty hookow (pre-commit, post-tool-use, stop) |
| `repo-knowledge/` | Wiedza o systemach/integracjach - jeden folder per system |
| `schemas/` | Schematy DB / API / typy danych |
| `reference-queries/` | Gotowe zapytania (SQL, jq, kubectl) - jeden folder per system |
| `skills/` | Custom skills dla Claude (`skills/nazwa/SKILL.md`) |
| `setup/` | Onboarding nowych developerow + deployment |
| `PRIV/` | **Prywatne, lokalne** - kazdy ma swoje, nie commitujemy |

Kazdy folder ma wlasny `README.md` z konwencjami nazewnictwa i przykladami.

## Bezpieczenstwo

- Sekrety w `.env` (gitignored)
- `PRIV/` w `.gitignore` - prywatne notatki nie trafiaja do repo
- Pre-commit hook w `hooks/` skanuje pod katem wrazliwych danych

Szczegoly: `SECURITY.md`
