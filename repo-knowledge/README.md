# repo-knowledge/

Wiedza o systemach, integracjach, repozytoriach z ktorymi pracujemy. Knowledge base.

## Konwencja

Jeden folder per system. Nazwa folderu = krotka, jednoznaczna nazwa systemu (kebab-case).

```
repo-knowledge/
├── nazwa-systemu/
│   ├── README.md           # Quick lookup - co to, gdzie, dla kogo
│   ├── workflows.md        # Glowne przeplywy
│   ├── glossary.md         # Slownik pojec
│   ├── monitoring.md       # Gdzie patrzec gdy cos sie psuje
│   └── ...
```

## README systemu - co tam ma byc

- Cel systemu w jednym zdaniu
- Owner / kontakt
- URL produkcyjny + staging
- Repo (link)
- Quick lookup table - "gdy potrzebujesz X → idz do Y"

## Co tworzyc

Wszystko czego nie znajdziesz w kodzie ale jest potrzebne zeby z systemem skutecznie pracowac:
- Konwencje zespolu (np. naming gallow w S3)
- Wiedza tribal (np. "ten serwis ma cold start - zawsze wolaj /health pierwsze")
- Mapowanie biznes -> tech (slownik)
- Diagramy architektury
- Linki do dashboardow, runbookow
