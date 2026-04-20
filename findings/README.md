# findings/

Wnioski, odkrycia, gotchas, lessons learned. Wszystko czego sie nauczylismy w trakcie pracy.

## Konwencja nazewnictwa

`YYYY-MM-DD-krotki-tytul-kebab-case.md`

Przyklady:
- `2026-04-15-render-cold-start-30s.md`
- `2026-04-20-supabase-pooling-limity.md`
- `2026-04-22-pyinstaller-onnx-paths.md`

## Format pliku

```markdown
---
data: 2026-04-20
tagi: [render, deployment, gotcha]
severity: medium
status: aktualne
related:
  - findings/2026-04-15-inny-finding.md
---

# Krotki tytul

## Kontekst

Co robilismy, jakie srodowisko, jaka wersja.

## Co odkrylismy

Konkretny opis problemu/odkrycia.

## Dlaczego

Root cause - co siedzi pod spodem.

## Jak rozwiazac / czego unikac

Konkretny krok / fix / workaround.

## Zrodla

Linki do dokumentacji, issue, PR-ow.
```

## Severity

- `low` - kosmetyka, drobne quirki
- `medium` - utrudnia prace, ale jest workaround
- `high` - blokuje, traci sie czas, nie ma oczywistego workaround
- `critical` - bezpieczenstwo, dane, produkcja

## Status

- `aktualne` - wciaz prawda
- `nieaktualne` - juz nie dotyczy (zostaw historie + dopisz dlaczego)
- `do-weryfikacji` - moze juz nie byc aktualne, sprawdzic
