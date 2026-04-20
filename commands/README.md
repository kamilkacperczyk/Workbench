# commands/

Slash commands Claude Code - skroty do czesto powtarzanych zadan.

## Konwencja

- Plik: `commands/nazwa-komendy.md`
- Wywolanie: `/nazwa-komendy [argumenty]`
- Kebab-case w nazwie

## Format pliku

```markdown
---
description: Krotki opis co komenda robi (pokazuje sie w /help)
argument-hint: <opcjonalny hint o argumentach>
---

Tresc promptu ktory zostanie wstrzykniety do Claude.

Mozesz uzywac $ARGUMENTS do referowania argumentow.

Mozesz dolaczac inne pliki: @path/to/file.md
```

## Co tworzyc tutaj

- Audyty (np. `/audyt-bezpieczenstwa`)
- Powtarzalne workflow (np. `/nowy-feature`, `/przygotuj-pr`)
- Onboarding ("przeczytaj te pliki na poczatku sesji")
- Generatory boilerplate

## Przyklad

Patrz `EXAMPLE-przyklad.md`.
