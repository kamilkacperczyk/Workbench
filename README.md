# Workbench

Szablon repo do projektow opartych o Claude Code / Claude Agent SDK.

Sklonuj, zmien nazwe, podmien placeholdery `{{...}}` w `CLAUDE.md` i zaczynaj.

## Jak uzywac

1. Sklonuj lub uzyj jako template na GitHub
2. Wypelnij `CLAUDE.md` (placeholdery: `{{PROJECT_NAME}}`, `{{TECH_STACK}}`, `{{LANGUAGE}}`)
3. Skopiuj `.env.example` do `.env` i wypelnij sekrety
4. Skopiuj `.claude/settings.json.example` do `.claude/settings.json` jesli chcesz hooki/permissions
5. Stworz lokalnie folder `PRIV/` na swoje prywatne notatki (nie trafia do gita)

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
