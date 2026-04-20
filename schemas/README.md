# schemas/

Schematy baz danych, API, struktur danych.

## Konwencja

Jeden folder per zrodlo:

```
schemas/
├── postgres-main/
│   ├── README.md       # Overview - jakie schematy/tabele, owner
│   ├── tabele.md       # Lista tabel z opisem
│   └── relacje.md      # FK, diagramy
├── bigquery/
│   ├── README.md
│   └── datasety.md
└── api-zewnetrzne/
    └── nazwa-api.md
```

## Co tam trafia

- Opis tabel/kolumn (po co, jakie dane)
- Constrainty, indeksy, triggery
- Diagramy relacji
- Wzorce uzycia ("ta tabela jest writeonly", "tu trzymamy soft-delete")
- Przyklady zapytan -> `reference-queries/`

## Co NIE trafia

- Realne dane / rekordy
- Connection stringi (te w `.env`)
- ID konkretnych projektow GCP / Supabase z tokenami

Patrz `TEMPLATE.md` jako wzor pliku schematu.
