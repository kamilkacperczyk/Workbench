# skills/

Custom skills dla Claude Code - wielokrotnie uzywalne procedury z opisem "kiedy uzywac" i "krok po kroku".

## Konwencja

Jeden folder per skill:

```
skills/
└── nazwa-skilla/
    ├── SKILL.md          # Wymagane: metadane + instrukcje
    ├── scripts/          # Opcjonalne: skrypty pomocnicze
    └── examples/         # Opcjonalne: przyklady wejscia/wyjscia
```

## Filozofia - skille to ORCHESTRATORY, nie wiedza

Skill = "kiedy to zrobic + jakie kroki + gdzie znalezc detale".
Cala wiedza domenowa nie siedzi w skillu - jest poza nim.

### Gdzie skill ma szukac wiedzy

Skill moze (i powinien) odsylac do WSZYSTKICH tych miejsc, zaleznie od potrzeby:

- `findings/` - wnioski, lekcje, gotchas, playbooki (np. jak zrobic migracje, jakie pulapki pgcrypto)
- `repo-knowledge/` - opisy systemow i konwencji projektu (struktura bazy, architektura, konwencje nazewnicze)
- `schemas/` - schematy danych (OpenAPI, JSON Schema, DDL, dbml)
- `reference-queries/` - gotowe zapytania SQL / skrypty diagnostyczne do ponownego uzycia
- `hooks/` - skrypty (np. pre-commit do sprawdzenia sekretow przed commitowaniem)
- `docs/`, `README.md`, `CLAUDE.md` - jesli tam jest potrzebna informacja

**Zly skill**: 300 linii opisu jak dziala pgcrypto + wszystkie pulapki + cala struktura bazy.
**Dobry skill**: 30 linii "krok 1, krok 2. Pelne pulapki: `findings/...managed-services.md`. Struktura bazy: `repo-knowledge/postgres-system.md`. Zapytania diagnostyczne: `reference-queries/pg-diagnostyka.sql`".

Dzieki temu:
- Wiedza jest w jednym miejscu - jeden update, wszystkie skille dostaja nowa wersje
- Skille sa krotkie i czytelne
- Latwo widac ktore skille sa zalezne od ktorych zrodel
- Nie ma duplikacji = nie ma rozjazdu miedzy wersjami wiedzy

## SKILL.md - wymagany frontmatter

```markdown
---
name: nazwa-skilla
description: Krotki opis. Kiedy Claude ma to wywolac (kluczowe slowa wyzwalajace).
---

# Nazwa skilla

## Kiedy uzywac (When to Use)

Konkretne triggery - co user pisze / co Claude widzi w kodzie/repo.

## Zrodla wiedzy (WYMAGANE)

Sciezki do plikow zawierajacych pelne tlo. Claude MA je przeczytac przed wykonaniem skilla.
Wymieniaj wszystkie istotne miejsca - nie tylko `findings/`.

- `findings/YYYY-MM-DD-tytul.md` - kontekst X (gotchas, wnioski)
- `repo-knowledge/PLIK.md` - opis systemu Y (struktura, konwencje)
- `schemas/PLIK.sql` - schema referencyjna (jesli dotyczy)
- `reference-queries/PLIK.sql` - gotowe zapytania (jesli dotyczy)

## Wymagania (Prerequisites)

- Co musi byc dostepne (narzedzia, env vars, dostep)

## Workflow (krok po kroku)

1. Krok 1 (jesli szczegoly - odsylaj do findings, nie duplikuj)
2. Krok 2
3. Krok 3

## Co zwrocic

Format wyjscia.

## Przyklady

Patrz `examples/`.

## Czego unikac

- Anti-patterns (jesli duzo - odsylaj do findings)
```

## Konwencja nazewnictwa

- Folder: kebab-case, krotko (`db-schema`, `nowy-feature`, `audyt-bezpieczenstwa`)
- Description w frontmatter ma byc **bogata w kluczowe slowa** - po nich Claude decyduje czy skill pasuje

## Jakie skille tworzyc

- Workflow ktore powtarzasz (np. "dodaj nowa tabele do PG")
- Specjalistyczne audyty (security review, perf check)
- Onboardowanie do podsystemu ("zanim zaczniesz pracowac z X, zrob te kroki")
- Integracje z konkretnymi narzedziami
