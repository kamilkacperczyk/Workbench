# {{NAZWA_BAZY}} / {{NAZWA_API}}

## Overview

- Typ: PostgreSQL / BigQuery / REST API / GraphQL
- Owner: {{KTO}}
- Srodowiska: prod / staging / dev
- Connection: w `.env` (`{{NAZWA_ENV_VAR}}`)

## Schematy / datasety / endpointy

### {{NAZWA_SCHEMATU}}

Cel: {{DO_CZEGO_SLUZY}}

Tabele / endpointy:

| Nazwa | Opis | Klucz | Uwagi |
|---|---|---|---|
| `tabela_a` | Co przechowuje | `id` | np. soft-delete, audit |

## Konwencje

- Naming: snake_case, prefiks `tbl_` itp.
- Klucze obce: `<tabela>_id`
- Timestampy: `created_at`, `updated_at` (TIMESTAMPTZ)
- Soft delete: kolumna `deleted_at`

## Gotchas

- {{ZNANE_DZIWACTWA}}
