---
data: 2026-04-20
tagi: [postgresql, supabase, rds, neon, security, deployment]
severity: high
status: aktualne
related:
  - findings/2026-04-20-migracje-postgresql.md
  - findings/2026-04-20-procedury-bezpieczenstwa.md
---

# PostgreSQL na managed services - wzorce i pulapki

Wnioski z pracy z Supabase. Wiekszosc dotyczy tez RDS/Neon/Railway/Render Postgres.

## 1. Sekrety i polaczenia

### Bezwzglednie nigdy nie commituj
- Hasel rol PostgreSQL
- Connection stringow (`postgres://user:pass@host:5432/db`)
- Realnych hashy hasel
- Backupow z danymi

### Sekrety trzymamy w `.env` (zawsze w `.gitignore`)
```bash
DATABASE_URL_POSTGRES=postgresql://postgres.ID_PROJEKTU:HASLO@HOST:5432/postgres
DATABASE_URL_ADMIN=postgresql://adm_login.ID_PROJEKTU:HASLO@HOST:5432/postgres
```
Dwie role: `postgres` (DDL/admin, wyjatkowo) i admin (codzienna praca).

### Z bashu/Pythona
```bash
source .env
psql "$DATABASE_URL_ADMIN" -c "SELECT * FROM users;"
```
**NIGDY** nie czytaj `.env` narzedziem typu `cat`/`Read` - haslo zostanie w transcript/logach.

### W `.env.example` placeholdery, nie prawdziwe wartosci
```
DATABASE_URL_ADMIN=postgresql://adm_login.ID_PROJEKTU:HASLO@HOST:5432/postgres
```

---

## 2. Role PostgreSQL na managed services

### Problem
Lokalnie tworzymy role z `SUPERUSER`. Supabase blokuje `SUPERUSER`, `CREATEROLE`, `REPLICATION`. AWS RDS daje `rds_superuser` (inne ograniczenia). Neon, Railway - kazdy ma inne limity.

### Rozwiazanie
Najszersze uprawnienia na Supabase: `CREATEDB` + pelne `GRANT` na schemat `public` z `WITH GRANT OPTION`.

### Sprawdz przed migracja
- Jakie atrybuty rol sa dozwolone
- Jakie rozszerzenia dostepne (`SELECT * FROM pg_extension`)
- W jakim schemacie lapuja rozszerzenia (Supabase: `extensions`, RDS: `public`)

---

## 3. Rozszerzenia i `search_path`

### Problem
Lokalnie `pgcrypto` (gen_salt, crypt) instaluje sie w `public`. Na Supabase - w `extensions`. Funkcje uzywajace `gen_salt()` przestaja dzialac po migracji.

### Rozwiazanie A - w funkcjach `SECURITY DEFINER`
```sql
CREATE OR REPLACE FUNCTION moja_funkcja()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions  -- KLUCZOWE
AS $$ ... $$;
```
**NIE** rob tego przez `ALTER FUNCTION ... SET search_path` - nadpisze sie przy `CREATE OR REPLACE`.

### Rozwiazanie B - w zapytaniach z aplikacji (psycopg2)
```sql
-- Z prefiksem extensions.
WHERE password_hash = extensions.crypt('haslo', password_hash)
```

### Plus
Daj rolom `GRANT USAGE ON SCHEMA extensions TO rola`.

---

## 4. `SECURITY DEFINER` vs `session_user` vs `current_user`

### Problem
`SECURITY DEFINER` zmienia `current_user` na ownera funkcji (zwykle `postgres`). Supabase przez pooler dodatkowo zwraca `postgres` jako `current_user` nawet bez SECURITY DEFINER.

### Wzorzec identyfikacji uzytkownika
1. Najpierw `app.current_user_id` (ustawione przez aplikacje przez `SET LOCAL`)
2. Fallback `session_user` (rola PG ktora sie polaczono - dziala w DBeaver/pgAdmin)
3. **Nigdy** nie polegaj wylacznie na `current_user` w SECURITY DEFINER

### Pulapka pooler
PgBouncer/Supavisor czesto laczy przez wspolna role poolera. Wtedy `session_user` tez nie pomoze - jedynym zrodlem jest `app.current_user_id` ustawione przez aplikacje.

### Wzorzec aplikacji
```sql
SET LOCAL app.current_user_id = '5';  -- dziala tylko w transakcji
SELECT moja_funkcja(...);
```
`SET LOCAL` nie wycieknie do innych zapytan - bezpieczne.

---

## 5. Row Level Security (RLS)

### Supabase domyslnie wlacza RLS
Bez polityk - tabele zablokowane dla wszystkich rol poza `postgres`.

### Wzorzec polityki dla adminow
```sql
CREATE POLICY admin_full_access ON moja_tabela
  USING (current_user LIKE 'adm_%');
```

### Pulapka: infinite recursion na `users`
**NIE** rob `USING (EXISTS (SELECT 1 FROM users WHERE login = current_user AND role = 'admin'))` na samej tabeli `users` - polityka odpyta tabele rekurencyjnie. Sprawdzaj nazwe roli PG (`current_user LIKE 'adm_%'`) lub przenies info do innej tabeli.

### Inne managed
RDS, Neon - RLS wylaczony domyslnie, trzeba wlaczyc recznie.

---

## 6. Hashowanie hasel

```sql
-- Tworzenie/zmiana hasla
INSERT INTO users (..., password_hash) VALUES (..., crypt(p_password, gen_salt('bf')));

-- Weryfikacja
WHERE password_hash = crypt(p_password_input, password_hash)
```

**Bezwzglednie:**
- Nigdy plaintext
- Nigdy nie loguj (audit trigger powinien usuwac `password_hash` z logow zmian)
- Min. dlugosc hasla waliduj w aplikacji (PG nie wie nic o "silnym hasle")

---

## 7. SQL injection w `SECURITY DEFINER`

Funkcje SECURITY DEFINER ktore buduja dynamiczny SQL (np. CREATE ROLE, CREATE TABLE z parametru) - **zawsze** przez `format()`:

```sql
EXECUTE format('CREATE ROLE %I WITH LOGIN PASSWORD %L', p_login, p_haslo);
```
- `%I` - identyfikator (nazwa roli, tabeli) - cytuje
- `%L` - literal (wartosc) - cytuje + escape'uje

**Nigdy** konkatenacja stringow (`'CREATE ROLE ' || p_login`) - to direct SQL injection.

---

## 8. Backupy

### Automatyczne (Supabase)
- Codziennie. Free tier: 7 dni wstecz. Settings → Database → Backups.

### Reczne backupy (uniwersalne dla kazdego managed PG)
```bash
source .env
pg_dump "$DATABASE_URL_POSTGRES" \
  --no-owner \
  --no-privileges \
  --schema=public \
  > backup_$(date +%F).sql
```

Flagi:
- `--no-owner` - pomija wlasciciela (na nowym serwerze inne role)
- `--no-privileges` - pomija GRANT/REVOKE (role moga sie roznic)
- `--schema=public` - tylko `public` (pomija wewnetrzne schematy serwisu)

### Wazne
- pg_dump przez **direct connection** (port 5432), nie pooler
- Backup zawiera dane - NIGDY nie commituj
- Trzymaj poza repo (lokalna lokalizacja per deweloper)
- Backup z tymi flagami nadaje sie tez jako zrodlo do migracji na inny serwer

### Przywracanie
```bash
psql "$DATABASE_URL_POSTGRES" < backup_2026-04-20.sql
```
Po imporcie recznie odtworz: role PG, polityki RLS, search_path na funkcjach.

---

## 9. Connection pooling i IPv4/IPv6

### Supabase
- Direct (port 5432, IPv6) - wiekszosc sieci PL nie ma IPv6
- Session Pooler (port 5432 inny host, IPv4) - zalecane do aplikacji
- Transaction Pooler - **nie obsluguje** prepared statements i `SET` (wiec nie obsluguje `SET LOCAL app.current_user_id`)

### Username przez pooler
`rola.ID_PROJEKTU` (np. `postgres.abcdefghijklmnopqrst`). Direct: same `postgres`.

### Wzorzec
Aplikacja → Session Pooler. pg_dump → Direct.
