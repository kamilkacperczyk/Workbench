---
data: 2026-04-20
tagi: [rodo, gdpr, prawo, dane-osobowe, compliance]
severity: high
status: aktualne
related:
  - findings/2026-04-20-procedury-bezpieczenstwa.md
---

# RODO / GDPR przy zbieraniu danych - wzorce

Universalia ktore powinny byc w kazdym projekcie zbierajacym jakiekolwiek dane od uzytkownika (nie tylko B2C - SaaS B2B tez). To NIE jest porada prawna - przy wdrozeniu prod skonsultuj z prawnikiem. Ale 90% projektow popelnia te same bledy i mozna ich uniknac.

## 1. Co jest dana osobowa

### Oczywiste
- Imie, nazwisko
- Email (tak, sluzbowy tez)
- Numer telefonu
- Adres
- PESEL, numer dowodu

### Mniej oczywiste (ale tez dane osobowe wg RODO)
- **Adres IP** (stanowisko polskich sadow i EROD)
- **Cookie ID / device ID**
- **Hash emaila** (jesli da sie odwrocic = nadal dana osobowa)
- Zdjecie, glos, dane biometryczne
- Dane o lokalizacji (GPS, WiFi triangulation)
- Historia zachowan w aplikacji jesli da sie powiazac z osoba

### Dane szczegolnej kategorii (art. 9 RODO)
Wymagaja EXPLICIT consent + dodatkowej ochrony:
- Stan zdrowia
- Pochodzenie rasowe/etniczne
- Pogladi polityczne/religijne
- Orientacja seksualna
- Dane biometryczne do identyfikacji

---

## 2. Podstawa prawna (art. 6 RODO) - jedna z 6

Nie "chce zbierac email" - musisz wskazac PODSTAWE.

### a) Zgoda (`consent`)
- Checkbox domyslnie ODZNACZONY
- Explicit statement ("Wyrazam zgode na..." - nie "Akceptuje regulamin i zgadzam sie na wszystko")
- Granularnosc - osobna zgoda na marketing, osobna na newsletter, osobna na cookies analityczne
- Mozliwosc wycofania (tak samo latwo jak udzielenia)

### b) Wykonanie umowy (`contract`)
Email do logowania w SaaS - nie potrzebuje zgody bo bez emaila nie ma konta. ALE: marketingowy newsletter to osobna sprawa (wymaga zgody).

### c) Obowiazek prawny (`legal_obligation`)
Np. przechowywanie faktur 5 lat (ustawa o rachunkowosci).

### d) Zywotne interesy (`vital_interests`)
Rzadko. Ratowanie zycia.

### e) Interes publiczny (`public_task`)
Wiekszosc nie dotyczy - zostaw prawnikom.

### f) Prawnie uzasadniony interes (`legitimate_interest`)
- Security (wykrywanie fraud)
- Analytics WEWNETRZNE (bez profilowania)
- Trzeba udokumentowac LIA (legitimate interest assessment)

---

## 3. Checkbox pattern - poprawny rejestracja

```html
<label>
  Email: <input type="email" required />
  <!-- podstawa: art. 6 ust. 1 lit. b (wykonanie umowy) -->
</label>

<label>
  <input type="checkbox" required />
  Akceptuje <a href="/regulamin">regulamin</a>
  i zapoznalem sie z <a href="/privacy">polityka prywatnosci</a>
</label>

<label>
  <input type="checkbox" name="marketing" />
  (Opcjonalnie) Chce otrzymywac newsletter
  <!-- podstawa: art. 6 ust. 1 lit. a (zgoda) -->
</label>
```

### NIE robic
- `checked` domyslnie dla marketingu = invalid consent
- Jeden checkbox "akceptuje wszystko" laczacy regulamin + marketing = dark pattern, nielegalne
- "Zgoda" ukryta w regulaminie = nie liczy sie

---

## 4. Retencja - nie trzymaj w nieskonczonosc

### Zasada minimalizacji (art. 5 ust. 1 lit. e)
Przechowuj tylko tak dlugo jak potrzebne do celu.

### Przyklady retencji
- Konto aktywne: przechowywane dopoki nie usunie
- Konto nieaktywne > 2 lata: soft delete + email powiadomienie o czyszczeniu
- Logi aplikacji: 90 dni (wystarczy do debugowania, >90 dni = zbyt dlugo)
- Logi bezpieczenstwa (failed login, suspicious activity): 12 miesiecy
- Faktury: 5 lat (obowiazek prawny)
- Marketing consent history: tak dlugo jak zgoda aktywna + 3 lata (dowod)

### Implementacja - cron job
```sql
-- Codziennie o 03:00
DELETE FROM logi_aplikacji WHERE utworzono < NOW() - INTERVAL '90 days';

-- Soft delete nieaktywnych kont
UPDATE users
SET deleted_at = NOW(), email = CONCAT('deleted-', id, '@local'), password_hash = NULL
WHERE last_login < NOW() - INTERVAL '2 years' AND deleted_at IS NULL;
```

---

## 5. Prawa uzytkownika

Musi byc **kanal** do realizacji tych praw (nie "wyslij email" - tzn. moze byc email, ale max 30 dni na odpowiedz):

### Prawo dostepu (art. 15)
"Jakie moje dane macie?" -> eksport JSON/CSV z wszystkimi danymi.

### Prawo do sprostowania (art. 16)
Edycja profilu w UI = spelnione.

### Prawo do usuniecia / "bycia zapomnianym" (art. 17)
Endpoint / button "Usun konto". W bazie: albo hard delete, albo anonimizacja (jesli obowiazek prawny wymaga zachowania logow).

### Prawo do przenoszenia danych (art. 20)
Eksport do formatu czytelnego maszynowo (JSON, CSV, XML).

### Prawo sprzeciwu (art. 21)
"Zatrzymaj marketing" - unsubscribe.

### Prawo do ograniczenia przetwarzania (art. 18)
Zamrozenie konta na czas weryfikacji zadzalnia.

---

## 6. Logi IP - jak robic poprawnie

### Pulapka
`request.remote_addr` za reverse proxy = IP proxy, nie klienta. W `X-Forwarded-For` pierwszy IP to oryginalny.

Patrz [findings/2026-04-20-architektura-webapp-desktop.md](2026-04-20-architektura-webapp-desktop.md) pkt 9.

### Retencja IP
- Logi operacyjne (debug, error): 90 dni max
- Logi bezpieczenstwa (brute force, suspicious): 12 miesiecy
- Po retencji: hash (SHA-256 z salt) lub anonimizacja (`1.2.3.0/24` zamiast `1.2.3.4`)

### Czy trzeba zgody na logowanie IP?
- Logi techniczne dla bezpieczenstwa: `legitimate_interest` (art. 6 f) - zgoda nie potrzebna
- Analityka/profilowanie: zgoda potrzebna
- Musisz to opisac w polityce prywatnosci

---

## 7. Polityka prywatnosci - minimum

1. Kto jest administratorem (nazwa, adres, email DPO jesli jest)
2. Jakie dane zbierasz (lista konkretna)
3. Po co (cel - per kategoria danych)
4. Podstawa prawna (per cel)
5. Jak dlugo trzymasz (retencja)
6. Komu przekazujesz (subprocessors - np. Supabase, Render, Stripe)
7. Czy dane ida poza EOG (np. do USA - Supabase jest w US, wymaga SCC albo adequacy decision)
8. Prawa uzytkownika (lista + kanal realizacji)
9. Prawo skargi do PUODO (pl) / inny DPA
10. Kontakt (email do kwestii RODO)

### Przechowuj wersjonowanie
Zmiana polityki -> uzytkownicy powinni byc powiadomieni. Wersjonuj w kodzie (`privacy_v1.md`, `privacy_v2.md`), w bazie trzymaj `privacy_version_accepted` per uzytkownik.

---

## 8. Incident response - data breach

### Gdy odkryjesz wyciek danych
1. **72 godziny** na zgloszenie do PUODO (jesli wyciek "prawdopodobnie bedzie skutkowal ryzykiem dla praw i wolnosci osob")
2. Jesli wysokie ryzyko - **rowniez powiadom uzytkownikow** (bez zbednej zwloki)
3. Dokumentuj breach: co wyciekly, ile osob, kiedy, co zrobiles
4. Rotacja kompromitowanych sekretow natychmiast

### Co jest breach
- Baza uzytkownikow wyciekla na GitHub
- Sekret .env wyciekly i ktos sie dostal do prod bazy
- Laptop dewelopera z dostepem do prod skradziony
- Email z kopia danych wyslany do zlego odbiorcy

Nie kazdy incydent to breach - ale w watpliwosci dokumentuj i konsultuj z DPO/prawnikiem.

---

## 9. Subprocessors - trzymaj liste

Kazda usluga zewnetrzna do ktorej trafiaja dane osobowe = subprocessor. Musisz:
- Miec z nimi DPA (Data Processing Agreement) - zwykle standardowy dokument u providera
- Wymienic ich w polityce prywatnosci
- Wiedziec czy sa w EOG czy poza (poza = wymaga SCC)

### Typowi subprocessors (check per projekt)
- Supabase (US) - dane bazy
- Render / Vercel / AWS - hosting
- Stripe - platnosci
- Sentry / Datadog - logi bledow (tam leca dane userow jesli nie filtrujesz!)
- Google Analytics - IP + behavior
- Resend / SendGrid - emaile (adresy)
- Cloudflare - IP wszystkich wizyt

---

## 10. Co sprawdzic przy starcie projektu

- [ ] Checkbox pattern (odznaczone domyslnie, granularne zgody)
- [ ] Polityka prywatnosci napisana i widoczna (stopka, rejestracja)
- [ ] Regulamin (terms of service) oddzielnie od polityki
- [ ] Endpoint/button "usun konto" i "eksport danych"
- [ ] Unsubscribe w kazdym marketingowym emailu
- [ ] Cron job czyszczacy stare logi
- [ ] Dokumentacja retencji (wewnetrzna, nie musi byc publiczna)
- [ ] Lista subprocessors aktualna
- [ ] Kontakt RODO (dedykowany email, np. `privacy@domena`)
- [ ] Sprawdz czy musisz wyznaczyc DPO (zalezy od skali)
