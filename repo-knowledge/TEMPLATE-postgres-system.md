# Szablon dokumentu opisujacego system PostgreSQL w projekcie

Template. W kazdym projekcie z PostgreSQL warto miec plik taki jak ten (np. `docs/struktura-bazy.md`, `docs/db-system.md`). Claude Code (albo nowy developer) w 5 minut rozumie cala baze bez czytania kazdego pliku SQL.

Wypelnij sekcje realnymi wartosciami z projektu. Nie usuwaj naglowkow - lepiej "brak" niz pominiete.

---

## 1. Overview (1 akapit)

Po co istnieje ta baza, jaka domena, ile mniej wiecej tabel, czy jest managed (Supabase/RDS/Neon) czy self-hosted.

Przyklad: _"Baza `nunczaku` trzyma dane uzytkownikow, zakupy, uprawnienia. Managed przez Supabase (Free tier), PostgreSQL 15. Ok. 20 tabel, 15 funkcji SECURITY DEFINER."_

---

## 2. Srodowiska

| Srodowisko | Host | Rola app | Rola admin | Uwagi |
|---|---|---|---|---|
| dev (lokalnie) | `localhost:5432` | `adm_dev` | `postgres` | Docker compose |
| staging | `db.stg.xxx.supabase.co` | `adm_stg` | `postgres` | Session pooler IPv4 |
| prod | `db.prd.xxx.supabase.co` | `adm_prd` | `postgres` | Direct IPv6 + session pooler |

Connection stringi trzymamy w `.env` (nie commitowane). `.env.example` ma placeholdery.

---

## 3. Diagram (ASCII lub link do dbdiagram.io)

Nawet prosty ASCII > nic. Dla wiekszych baz - link do [dbdiagram.io](https://dbdiagram.io) albo `.dbml` w repo.

```
users
  |-- uzytkownik.id (PK)
  |-- email (UNIQUE)
  |-- password_hash
  |
  +--< purchases (FK: user_id)
  |     |-- id (PK)
  |     |-- created_at
  |     |-- amount
  |
  +--< sessions (FK: user_id)
        |-- token
        |-- expires_at
```

---

## 4. Tabele - lista z jedna linia opisu

| Tabela | Opis | Kluczowe kolumny |
|---|---|---|
| `users` | Konta uzytkownikow | `id, email, password_hash, role, created_at` |
| `purchases` | Zakupy | `id, user_id, amount, created_at` |
| `sessions` | Sesje login | `token, user_id, expires_at` |
| `audit_log` | Trigger-based audit | `table_name, row_id, action, before, after, changed_by` |

Dla kazdej: czy ma RLS, czy ma triggery, czy ma CHECK constraints - odsylaj do osobnej sekcji ponizej.

---

## 5. Role PostgreSQL

| Rola | Uprawnienia | Uzywana przez |
|---|---|---|
| `postgres` | SUPERUSER (na Supabase ograniczony) | Migracje, reczne DDL |
| `adm_app` | CRUD na `public.*`, brak DDL | API produkcyjne |
| `adm_readonly` | SELECT na `public.*` | Reporting, BI |

Konwencja: `adm_*` dla aplikacji, `postgres` do admin only.

---

## 6. Rozszerzenia

| Rozszerzenie | Schemat | Po co |
|---|---|---|
| `pgcrypto` | `extensions` | `gen_salt`, `crypt` dla hasel |
| `uuid-ossp` | `extensions` | UUID v4 dla PK |
| `pg_stat_statements` | `extensions` | Monitoring (tylko prod) |

Na Supabase rozszerzenia trafiaja do `extensions` - funkcje uzywajace ich musza miec `SET search_path = public, extensions`.

---

## 7. Funkcje SECURITY DEFINER

Lista + kto moze wywolac + co robi. Kazda funkcja SECURITY DEFINER to potencjalna powierzchnia ataku - pilnuj zeby bylo jasne co jest i po co.

| Funkcja | Rola wywolujaca | Cel |
|---|---|---|
| `app.login(p_email, p_password)` | anon + authenticated | Weryfikacja hasla, zwraca token |
| `app.purchase_create(p_amount)` | authenticated | Insert z audytem |
| `admin.create_role(p_login, p_haslo)` | adm_* | Tworzenie rol uzytkownikow |

Wszystkie maja `SET search_path = public, extensions` i buduja dynamiczny SQL przez `format('%I %L', ...)`.

---

## 8. Triggery

| Tabela | Trigger | Kiedy | Co robi |
|---|---|---|---|
| `users` | `trg_users_audit` | AFTER UPDATE | Insert do `audit_log` (bez `password_hash`) |
| `sessions` | `trg_sessions_expire` | BEFORE INSERT | Ustawia `expires_at = NOW() + interval '7 days'` |

---

## 9. Polityki RLS

Jesli RLS wlaczony - lista polityk per tabela.

```sql
-- users: admin widzi wszystko
CREATE POLICY admin_all ON users
  USING (current_user LIKE 'adm_%');

-- purchases: uzytkownik widzi swoje, admin widzi wszystko
CREATE POLICY own_purchases ON purchases
  USING (user_id = current_setting('app.current_user_id')::int);
```

Patrz [findings/2026-04-20-postgresql-managed-services.md](../findings/2026-04-20-postgresql-managed-services.md) pkt 5 - pulapka infinite recursion.

---

## 10. ENUM i CHECK constraints

Lista ograniczen biznesowych w bazie (nie w aplikacji).

```sql
CREATE TYPE user_role AS ENUM ('admin', 'user', 'readonly');

ALTER TABLE purchases
  ADD CONSTRAINT positive_amount CHECK (amount > 0);
```

### Zasada dla ENUM
- Nowa wartosc: `ALTER TYPE ... ADD VALUE 'new'` (nie mozna usunac wartosci - trzeba stworzyc nowy typ i migrowac)
- Kolejnosc: `AFTER` / `BEFORE` - ale w wiekszosci przypadkow nie ma znaczenia

---

## 11. Sekwencje i wartosci domyslne

Sekwencje (zwykle implicit przez `SERIAL`/`BIGSERIAL`) - lista z nazwa i ostatnia wartoscia (do debugowania migracji).

`DEFAULT` dla kolumn - szczegolnie `NOW()`, `gen_random_uuid()`, `extensions.gen_salt('bf')`.

---

## 12. Migracje

Jak sie dzieja:
- Narzedzie (alembic, sqlx migrate, flyway, liquibase, wlasne)
- Folder w repo (`migrations/` albo `db/migrations/`)
- Naming convention (`YYYYMMDDHHMM_nazwa.sql` albo `NNNN_nazwa.sql`)
- CI/CD - czy auto, czy recznie
- Rollback - jak

---

## 13. Backupy

- Automatyczne u providera (Supabase: 7 dni free tier)
- Reczne: `pg_dump` przez direct connection, `--no-owner --no-privileges --schema=public`
- Gdzie trzymane (S3, dysk lokalny, NIE w repo)
- Test restore (czy regularnie testujesz ze backup jest dobry)

Patrz [findings/2026-04-20-postgresql-managed-services.md](../findings/2026-04-20-postgresql-managed-services.md) pkt 8.

---

## 14. Konwencje

- Tabele: `snake_case`, liczba mnoga (`users`, nie `user`)
- Kolumny: `snake_case`
- Parametry funkcji: `p_nazwa`
- Zmienne lokalne: `v_nazwa`
- Timestampy: `TIMESTAMPTZ` (z strefa), `NUMERIC` dla pieniedzy (nie `FLOAT`)
- PK: `id` jako `BIGSERIAL` albo `UUID`
- Timestamps na kazdej tabeli: `created_at`, `updated_at`

---

## 15. Gotchas specyficzne dla tego projektu

Sekcja na anomalie ktore trzeba znac zanim sie cokolwiek zmieni:
- "Trigger `trg_X` robi Y - nie usuwaj bez zmiany aplikacji"
- "Funkcja `app.foo` jest wywolywana przez cron - nie zmieniaj sygnatury"
- "Tabela `legacy_foo` jest do usuniecia od pol roku - nie dodawaj nic nowego tam"
