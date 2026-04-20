---
name: EXAMPLE-skill
description: Przykladowy skill - sluzy jako wzor. Uzyj gdy chcesz zobaczyc format SKILL.md przed napisaniem wlasnego.
---

# EXAMPLE-skill

## Kiedy uzywac

- User pisze "pokaz mi przyklad skilla"
- User pyta o format SKILL.md
- User tworzy pierwszy wlasny skill w projekcie

## Wymagania

- Brak (to przyklad, nie robi nic)

## Workflow

1. Przeczytaj `skills/README.md` zeby zrozumiec konwencje
2. Skopiuj ten folder na `skills/twoja-nazwa/`
3. Wypelnij wlasny `SKILL.md`
4. Dodaj scripty do `scripts/` jesli skill ich potrzebuje

## Co zwrocic

W tym przypadku: nic (skill instruktazowy).

## Przyklady

Patrz `scripts/README.md`.

## Czego unikac

- Skille bez sekcji "Kiedy uzywac" - Claude nie bedzie wiedzial kiedy je odpalic
- Description bez slow kluczowych - skill nie zostanie zmatchowany
- Workflow bez kolejnosci krokow - nie do odtworzenia
