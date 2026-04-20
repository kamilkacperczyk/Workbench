# reference-queries/

Gotowe, sprawdzone zapytania ktorych regularnie potrzebujesz.

## Konwencja

Jeden folder per system/zrodlo:

```
reference-queries/
├── postgres-main/
│   ├── README.md
│   └── *.sql
├── bigquery/
│   └── *.sql
└── kubectl/
    └── *.sh
```

## Naming plikow zapytan

`<NAZWA_W_UPPERCASE>_<TYP>.<ext>`

- `_PG` - PostgreSQL
- `_BQ` - BigQuery
- `_GF` - Grafana
- `_K8S` - kubectl

Przyklady:
- `AKTYWNI_USERZY_PG.sql`
- `KOSZTY_OSTATNI_MIESIAC_BQ.sql`
- `PODY_W_CRASHLOOPIE_K8S.sh`

## Format zapytania

Pierwsze linie = komentarz wyjasniajacy:

```sql
-- Cel: Lista aktywnych userow z ostatnich 30 dni
-- Autor: kkacperczyk
-- Data: 2026-04-20
-- Zalezy od: tabel users, login_history
-- Przyklad uruchomienia: psql "$DATABASE_URL" -f AKTYWNI_USERZY_PG.sql

SELECT ...
```

## Co NIE wrzucamy

- Connection stringi
- Hardcoded ID prod/staging
- Realne ID userow / dane wrazliwe (uzyj placeholderow `{{USER_ID}}`)
