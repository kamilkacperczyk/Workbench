---
data: 2026-04-20
tagi: [postgresql, migracje, supabase, deployment, backup]
severity: high
status: aktualne
related:
  - findings/2026-04-20-postgresql-managed-services.md
  - findings/2026-04-20-procedury-bezpieczenstwa.md
---

# Migracje PostgreSQL - tryby, pulapki, checklist

Wnioski z migracji lokalny PG -> Supabase (ale schemat uniwersalny dla dowolnego managed PG).

## Trzy tryby migracji

### Tryb A - tylko struktura (DDL)
Przenosimy tabele, funkcje, triggery, typy, widoki. **Bez danych.** Przydatne gdy nowe srodowisko startuje puste (staging, test, nowy klient).

```bash
pg_dump --schema-only --no-owner --no-privileges --schema=public \
  "$SOURCE_URL" > schema.sql
```

### Tryb B - struktura + dane
Pelna kopia. Dane ida jako `INSERT` (wolno) albo `COPY` (szybko, ale wrazliwe na encoding).

```bash
pg_dump --no-owner --no-privileges --schema=public \
  "$SOURCE_URL" > full.sql
```

### Tryb C - tylko dane (do istniejacej struktury)
Struktura juz jest (np. z migracji w CI/CD). Dociskamy dane.

```bash
pg_dump --data-only --no-owner --no-privileges --schema=public \
  "$SOURCE_URL" > data.sql
```

**Pulapka**: `--data-only` nie resetuje sekwencji. Po imporcie:
```sql
SELECT setval('moja_tabela_id_seq', (SELECT MAX(id) FROM moja_tabela));
```

---

## 8 pulapek ktore zjadlyby dzien

### 1. Role nie istnieja na docelowym
`pg_dump` bez `--no-owner` generuje `ALTER TABLE ... OWNER TO nazwa_roli`. Na docelowym serwerze ta rola nie istnieje -> blad.

**Rozwiazanie**: `--no-owner --no-privileges`.

### 2. Rozszerzenia w innym schemacie
Lokalnie `pgcrypto` w `public`, Supabase w `extensions`. Funkcje z `gen_salt(...)` breakuja.

**Rozwiazanie**: przed migracja zamien wszystkie wywolania na `extensions.gen_salt(...)` albo dodaj `SET search_path = public, extensions` w funkcjach. Patrz [findings/2026-04-20-postgresql-managed-services.md](2026-04-20-postgresql-managed-services.md).

### 3. `SECURITY DEFINER` bez search_path
Na lokalnym dziala bo `public` jest pierwszy w search_path. Na managed - pooler ma inny default, funkcja nie znajduje tabeli.

**Rozwiazanie**: `SET search_path = public, extensions` w kazdej `SECURITY DEFINER`.

### 4. RLS wlaczony bez polityk
Supabase wlacza RLS domyslnie na nowe tabele. Po imporcie bez polityk = tabela zablokowana.

**Rozwiazanie**: po imporcie sprawdz `SELECT schemaname, tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public'`. Dla kazdej z `rowsecurity = true` sprawdz czy maja polityki.

### 5. Sekwencje nie zresetowane
Patrz wyzej. Po `--data-only` sekwencje zostaja na 1 -> `duplicate key value` przy nastepnym INSERT.

### 6. `pg_dump` przez pooler
Transaction pooler zrywa dlugie polaczenia, session pooler moze miec inny schemat default. pg_dump ZAWSZE przez direct connection (port 5432, nie pooler).

### 7. Typy ENUM kolejnosc
Jesli funkcje/widoki uzywaja ENUM - ENUM musi byc stworzony PRZED funkcja. pg_dump respektuje kolejnosc, ale recznie przenoszenie SQL - latwo pomylic.

**Rozwiazanie**: pg_dump generuje w dobrej kolejnosci. Nie modyfikuj.

### 8. Plpgsql funkcje z `$$ ... $$`
Jesli edytujesz dump recznie - uwaga na dollar quoting. `$$` moze kolidowac jesli w ciele funkcji tez jest `$$`. Uzywaj `$func$ ... $func$` jako tag.

---

## Checklist migracji

### Przed
- [ ] Backup zrodla (`pg_dump` pelny)
- [ ] Backup celu jesli nie jest pusty
- [ ] Lista rozszerzen zrodla vs docelowego (`SELECT * FROM pg_extension`)
- [ ] Lista rol potrzebnych (kto sie laczy, z jakimi uprawnieniami)
- [ ] Plan rollback (jak wrocic w <15 min)

### Eksport
- [ ] `pg_dump` przez direct connection, nie pooler
- [ ] Flagi: `--no-owner --no-privileges --schema=public`
- [ ] Sprawdz rozmiar dumpu (sanity check)
- [ ] Sprawdz czy zawiera oczekiwane tabele (`grep "CREATE TABLE" dump.sql | wc -l`)

### Import
- [ ] Przez direct connection (psql), nie pooler
- [ ] Rozszerzenia docelowego (`CREATE EXTENSION IF NOT EXISTS pgcrypto SCHEMA extensions`)
- [ ] Role docelowe stworzone PRZED importem (patrz nizej)
- [ ] `psql "$TARGET_URL" < dump.sql`
- [ ] Sprawdz bledy w outputcie psql (nie tylko exit code)

### Po imporcie
- [ ] `SELECT count(*)` na kluczowych tabelach - zgodne ze zrodlem
- [ ] Reset sekwencji jesli `--data-only`
- [ ] Przegladnij funkcje z `SECURITY DEFINER` - search_path
- [ ] Utworz polityki RLS jesli wlaczony
- [ ] Przeteestuj kluczowe scenariusze (login, zapis, odczyt)
- [ ] Sprawdz logi aplikacji podlaczonej do nowej bazy

---

## Wzorzec odtwarzania rol po migracji

```sql
-- Idempotentny skrypt - dziala wielokrotnie bez bledu
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'adm_app') THEN
    CREATE ROLE adm_app WITH LOGIN PASSWORD 'PLACEHOLDER_SET_MANUALLY';
  END IF;
END
$$;

GRANT CONNECT ON DATABASE postgres TO adm_app;
GRANT USAGE ON SCHEMA public TO adm_app;
GRANT USAGE ON SCHEMA extensions TO adm_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO adm_app;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO adm_app;

-- Default dla przyszlych tabel
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO adm_app;
```

Haslo ustawiaj **po** imporcie przez `ALTER ROLE adm_app PASSWORD '...'` - NIE commituj do skryptu.

---

## Rollback plan

### Wariant 1 - baza celu byla pusta
Usun wszystko w `public`:
```sql
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT USAGE ON SCHEMA public TO postgres;
```

### Wariant 2 - baza celu miala dane
Przywroc z backupu celu (ktory zrobiles PRZED migracja, prawda?):
```bash
psql "$TARGET_URL" < backup_target_before_migration.sql
```

### Wariant 3 - migracja tylko czesciowa (pojedyncza tabela)
`BEGIN; ... ROLLBACK;` - zawsze migracje pojedynczych tabel w transakcji.

---

## IPv4/IPv6 i pooler - gotchy przy imporcie

- Wiele sieci PL/DE nie ma IPv6. Supabase direct connection = IPv6-only.
- Obejscie: **Session Pooler** (ma IPv4) - ale tylko do aplikacji, NIE do pg_dump/psql z duzym dumpem
- Dla migracji: VPS z IPv6 (np. Hetzner) jako proxy, `ssh -L`, albo platny dodatek IPv4 od Supabase

### Username przez pooler vs direct
- Direct: `postgres`
- Session pooler: `postgres.ID_PROJEKTU`

Jesli kopiujesz connection string z panelu - zauwaz ktora opcja wybrales.

---

## Schema-only dump do review przed importem

Zanim zaimportujesz do prod - zrob schema dump i **przeczytaj go**:
```bash
pg_dump --schema-only ... | less
```

Szukaj:
- `SECURITY DEFINER` bez `SET search_path`
- `OWNER TO` (jesli `--no-owner` zadzialal - nie powinno byc)
- `CREATE EXTENSION` z hardcoded schema
- Referencje do rol ktore nie istnieja na docelowym
