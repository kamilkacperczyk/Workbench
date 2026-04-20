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

## SKILL.md - wymagany frontmatter

```markdown
---
name: nazwa-skilla
description: Krotki opis. Kiedy Claude ma to wywolac (kluczowe slowa wyzwalajace).
---

# Nazwa skilla

## Kiedy uzywac (When to Use)

Konkretne triggery - co user pisze / co Claude widzi w kodzie/repo.

## Wymagania (Prerequisites)

- Co musi byc dostepne (narzedzia, env vars, dostep)

## Workflow (krok po kroku)

1. Krok 1
2. Krok 2
3. Krok 3

## Co zwrocic

Format wyjscia.

## Przyklady

Patrz `examples/`.

## Czego unikac

- Anti-patterns
```

## Konwencja nazewnictwa

- Folder: kebab-case, krotko (`db-schema`, `nowy-feature`, `audyt-bezpieczenstwa`)
- Description w frontmatter ma byc **bogata w kluczowe slowa** - po nich Claude decyduje czy skill pasuje

## Jakie skille tworzyc

- Workflow ktore powtarzasz (np. "dodaj nowa tabele do PG")
- Specjalistyczne audyty (security review, perf check)
- Onboardowanie do podsystemu ("zanim zaczniesz pracowac z X, zrob te kroki")
- Integracje z konkretnymi narzedziami
