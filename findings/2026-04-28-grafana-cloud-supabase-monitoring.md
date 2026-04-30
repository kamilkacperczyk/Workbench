---
data: 2026-04-28
tagi: [grafana, supabase, postgresql, monitoring, security, rodo, gotcha]
severity: medium
status: aktualne
related:
  - findings/2026-04-20-architektura-webapp-desktop.md
  - findings/2026-04-20-rodo-zbieranie-danych.md
---

# Grafana Cloud + Supabase Free - monitoring bez wpadek

Wnioski z podlaczania Grafana Cloud Free do Supabase Free (PostgreSQL) jako prywatny dashboard admin.

## Kontekst

Projekt z PostgreSQL na Supabase Free + chcemy dashboard typu "kto i kiedy sie loguje, ile userow, co sie psuje". Grafana Cloud Free zamiast self-hosted - mniej infrastruktury, bez wlasnego serwera.

## Co odkrylismy

### 1. Direct PostgreSQL connection na Supabase Free DZIALA

Wbrew plotkom ze "free wymaga IPv4 add-on", **Supavisor session pooler na porcie 5432 IPv4 jest dostepny bez add-onu**. Connection string: Dashboard Supabase → Settings → Database → Connection pooling → Session mode.

### 2. RLS blokuje SELECT mimo GRANT

Supabase ma domyslnie wlaczone Row Level Security na tabelach. `GRANT SELECT ON ALL TABLES` nie wystarczy - user widzi 0 wierszy bez polityki RLS dla niego.

Najprostsze rozwiazanie dla read-only monitoring usera: `ALTER USER xxx BYPASSRLS`. Bezpieczne bo user ma TYLKO SELECT (bez INSERT/UPDATE/DELETE).

Symptom diagnostyczny: `SELECT count(*) FROM tabela` zwraca 0, mimo ze tabela ma dane (sprawdzone z innego usera). Tabela widoczna w `information_schema.tables`, ale wiersze niewidoczne.

### 3. Browser password manager kasuje Username w formularzu Grafany

Grafana data source PostgreSQL: pole Username **wycina sie po Save & test** mimo wpisania danych. Powod: extension w przegladarce (LastPass/Bitwarden/1Password) wykrywa formularz z polem "Password" i autofill-uje albo czysci sasiednie pole "Username".

Workaround: konfiguruj data source w **trybie incognito** (extensions wylaczone domyslnie).

Symptom diagnostyczny: error `failed to connect to user= database=postgres` (puste user= w error message) mimo wpisania pelnych danych.

### 4. Supavisor wymaga formatu user.project_ref TYLKO dla domyslnego usera

Connection string Supabase ma format `postgres.xxxxxxxxxxxxxxxxxxxx` (z kropka i project ref). To wymagane TYLKO dla `postgres` (default superuser). Dla custom userow (np. `readonly_user`) - sam username bez sufixu wystarczy. Pooler wykrywa projekt po haslu/kontekscie.

### 5. Grafana Cloud nie ma wbudowanego 2FA

Z dokumentacji Grafany: *"Grafana and the Grafana Cloud portal currently do not include built-in support for multi-factor authentication (MFA)."* Rekomendowane: external IdP (Okta, Google Workspace, Entra) - to dla firm.

Dla solo dev: **logowanie przez OAuth (Google/GitHub)** - dziedziczy 2FA z dostawcy. Albo silne unikalne haslo + monitoring sign-in notifications.

### 6. Public dashboard = exposing personal data

Grafana ma feature "Public dashboards" (free tier: 10 paneli). Klikniecie "share publicly" wystawia panele bez autoryzacji.

**RODO problem:** typowy dashboard monitoringu pokazuje:
- Loginy uzytkownikow
- Czas logowan (= profil aktywnosci konkretnej osoby)
- Przyczyny nieudanych prob (= username enumeration vector)
- IP adresy

Userzy zaakceptowali zbieranie tych danych "dla bezpieczenstwa" (art. 6.1.f RODO uzasadniony interes), nie "dla wystawiania publicznie". Public dashboard z tymi panelami = naruszenie regulaminu serwisu + RODO.

**Bezpieczne publiczne metryki** (jesli koniecznie chcesz status page):
- Liczba userow (count, bez nazw)
- Time series logowan (suma per godzina/dzien, bez kogo)
- Dystrybucja planow (count per plan)

Reszta zostaje prywatna.

### 7. Information disclosure poza RODO

Public dashboard nawet bez personal data DALEJ ujawnia atakujacemu:
- Rozmiar bazy = "warto atakowac czy nie"
- Pora aktywnosci adminow = "kiedy zaatakowac z minimalnym ryzykiem detekcji"
- Failure reasons typu "Nieznany login" vs "Nieprawidlowe haslo" = username enumeration
- Stack technologiczny (Grafana + Postgres) = szuka CVE specyficznych dla stacka

Mitigacja: ujawniaj tylko agregaty, ukryj failure reasons za wspolnym "nieudane", nigdy nie pokazuj loginow ani IP. Internet caching (web archive, scraperzy) nie zapomina - co raz publiczne, zostaje na zawsze.

## Dlaczego

Supabase Free defaultuje na security-first (RLS on by default), ale **nie wystawia jasnej dokumentacji o tym dla nowych userow** - dopiero po debugowaniu odkrywasz dlaczego SELECT zwraca 0.

Public dashboard w Grafanie kusza "jednym klikiem" - latwo kliknac bez zastanowienia. Pomaga jasna polityka: **wszystko publiczne = przemyslane i ograniczone do agregatow**.

## Jak rozwiazac / czego unikac

### Setup czystego monitoring usera (kopiuj-wklej)

```sql
-- 1. User read-only
CREATE USER readonly_user WITH PASSWORD '<silne-unikalne-haslo>';

-- 2. Pozwol czytac
GRANT CONNECT ON DATABASE postgres TO readonly_user;
GRANT USAGE ON SCHEMA public TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

-- 3. Przyszle tabele tez auto-grant
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly_user;

-- 4. Bypass RLS (wymaga superuser, na free pg jest)
ALTER USER readonly_user BYPASSRLS;
```

### Konfiguracja Grafana data source (uniknij wpadek)

1. **Tryb incognito** w przegladarce (omija password manager)
2. Host URL: `<projekt-ref>.pooler.supabase.com:5432` (Session mode pooler z dashboardu Supabase)
3. Database: `postgres`
4. Username: czysty `readonly_user` (bez kropki, bez sufixu - to dla custom usera)
5. Password: haslo z `CREATE USER`
6. TLS Mode: `require`
7. Save & test → oczekiwane `Database Connection OK`

### Dashboard prywatny vs publiczny

Domyslnie - **prywatny** (wymaga logowania, dostep tylko admin). Publiczny TYLKO jesli:
- Specjalnie zaprojektowany "status page" z agregatami
- Zero personal data (loginow, IP, failure reasons)
- Zero info disclosure (rozmiary bazy ukryte, czas aktywnosci adminow tez)

### Jak pochwalic sie projektem (portfolio) bez exposing

Zamiast public dashboard:
- **Screenshot do README projektu** (kontrolowane co pokazujesz, raz, mozesz zamazac)
- **Krotki opis "co monitoruje, jak chronione"** (myslenie inzynierskie > tylko narzedzie)
- **2FA na koncie Grafany** przez OAuth login (Google/GitHub) - dziedziczy 2FA z dostawcy

To wyglada profesjonalnie i pokazuje rekruterowi ze:
- Ogarniasz Grafana Cloud
- Wiesz czym jest RLS i potrafisz z nim pracowac
- Myslisz o RODO (rzadkosc u juniorow)
- Ogarniasz hierarchie uprawnien bazy

## Zrodla

- [Supabase docs - Connecting to Postgres](https://supabase.com/docs/guides/database/connecting-to-postgres)
- [Grafana docs - PostgreSQL data source](https://grafana.com/docs/grafana/latest/datasources/postgres/)
- [Grafana docs - MFA brak built-in](https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/)
- Real-world setup: BeSafeFish (2026-04-28, dashboard prywatny + podglad screenshot w README projektu)
