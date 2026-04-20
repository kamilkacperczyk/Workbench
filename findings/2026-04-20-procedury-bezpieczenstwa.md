---
data: 2026-04-20
tagi: [bezpieczenstwo, git, sekrety, pre-commit, procedury]
severity: critical
status: aktualne
related:
  - findings/2026-04-20-postgresql-managed-services.md
  - hooks/pre-commit.sh
---

# Procedury bezpieczenstwa - git, sekrety, reakcja na wyciek

Bazuje na iteracyjnie doskonalonych zasadach z wielu projektow. Traktuj jako checklist + playbook.

## 1. Co NIGDY nie trafia do repo

### Sekrety
- Hasla (w jakiejkolwiek formie - plain, base64, zakodowane)
- Tokeny API (GitHub PAT, Supabase service key, OpenAI, Cloudflare itp.)
- Connection stringi z prawdziwym hoslem (`postgres://user:pass@...`)
- Klucze prywatne (`*.pem`, `*.key`, `id_rsa`, `*.p12`, `*.pfx`, `*.cer`, `*.crt`)
- Keystore (`.keystore`, `*.jks`)
- Certyfikaty z kluczem prywatnym (nie publiczne CA)
- `.env` w jakiejkolwiek postaci
- Backupy bazy (`*.sql.gz`, `*.dump` z danymi)

### Dane osobowe
- Realne emaile uzytkownikow
- Hashe hasel (nawet bcrypt - ulatwia brute force offline)
- IP uzytkownikow w logach
- Dokumenty (PDF, skany) z danymi klientow

### IP/know-how
- Hardcoded algorytmy ML ktore byly trenowane na poufnych danych
- Wewnetrzne dokumenty biznesowe (strategie, finanse)

---

## 2. `.gitignore` - template uniwersalny

```gitignore
# Sekrety
.env
.env.*
!.env.example
*.pem
*.key
*.keystore
*.jks
*.p12
*.pfx
*.cer
*.crt
id_rsa*
*.ppk
credentials.json
secrets.json

# Backupy
*.sql
*.sql.gz
*.dump
backup_*
*.bak

# Prywatne deweloperskie
PRIV/
PRIVATE/
.claude/settings.local.json

# Runtime
__pycache__/
*.pyc
.venv/
venv/
node_modules/
dist/
build/
*.egg-info/

# IDE
.vscode/
.idea/
*.swp
.DS_Store
Thumbs.db

# Logi
*.log
logs/
```

`!.env.example` - explicit unignore dla przykladu (bez wartosci).

---

## 3. Pre-commit hook - 30+ wzorcow

Pelny kod w [hooks/pre-commit.sh](../hooks/pre-commit.sh).

Zasada: skanuje `git diff --cached` (tylko staged), blokuje commit gdy znajdzie match.

### Wzorce ktore zawsze lapie
- `-----BEGIN (RSA |DSA |EC |OPENSSH )?PRIVATE KEY-----`
- `password\s*=\s*['"][^'"]{8,}['"]` (plain password)
- `postgres(ql)?://[^\s]*:[^\s]*@` (connection string z hoslem)
- `(api[_-]?key|secret|token)\s*[:=]\s*['"][A-Za-z0-9_-]{20,}['"]`
- `ghp_[A-Za-z0-9]{36}` (GitHub PAT)
- `sk-[A-Za-z0-9]{32,}` (OpenAI/Anthropic)
- `AKIA[0-9A-Z]{16}` (AWS access key)
- `eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+` (JWT)

### Whitelist
Komentarz `# pragma: allowlist secret` na tej samej linii -> skipp.

### Setup
```bash
ln -s ../../hooks/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

Dodaj do [setup/ONBOARDING.md](../setup/ONBOARDING.md) jako wymagany krok.

---

## 4. GitHub - wlacz te funkcje

### Dependabot
Settings -> Code security -> Dependabot alerts (ON).
Dodatkowo `dependabot.yml` dla automatycznych PR:
```yaml
version: 2
updates:
  - package-ecosystem: pip
    directory: /
    schedule:
      interval: weekly
```

### Secret Scanning
Settings -> Code security -> Secret scanning (ON).
Push protection - blokuje push z sekretem przed trafieniem do remote.

### CodeQL
Settings -> Code security -> Code scanning -> Setup CodeQL (default).
Znajduje podatnosci (SQL injection, XSS, path traversal) w PR.

### Branch protection
Settings -> Branches -> Add rule dla `main`:
- Require pull request reviews
- Require status checks (CI musi przejsc)
- Include administrators (nawet ty nie mozesz wrzucic do main bez PR)

---

## 5. Playbook - reakcja na wyciek sekretu

### Scenariusz A - sekret w ostatnim commicie, nie pushniety
```bash
git reset --soft HEAD~1
# usun sekret, dodaj do .env, do .gitignore
git add .
git commit
```

### Scenariusz B - sekret w ostatnim commicie, PUSHNIETY
1. **NATYCHMIAST** zrotuj sekret (zmien haslo/token u providera)
2. Dopiero potem sprzatanie historii (sekret juz publiczny)
3. `git revert HEAD` albo BFG (patrz nizej)

### Scenariusz C - sekret glebiej w historii, nie pushniety
```bash
git rebase -i HEAD~N
# oznacz commit jako `edit`, usun sekret, `git rebase --continue`
```

### Scenariusz D - sekret glebiej w historii, pushniety
1. **ZAWSZE najpierw**: zrotuj sekret
2. BFG Repo-Cleaner (szybsze niz git filter-branch):
   ```bash
   # Klon kopii
   git clone --mirror git@github.com:ORG/REPO.git
   cd REPO.git
   # Zamien wzorzec na ***REMOVED***
   bfg --replace-text secrets.txt
   # secrets.txt zawiera linie z sekretem do zamiany
   git reflog expire --expire=now --all && git gc --prune=now --aggressive
   git push --force
   ```
3. **Problem**: inni maja kopie z sekretem. Musza `git clone` od nowa (rebase history-rewrite jest brzydki).

### Scenariusz E - sekret w publicznym repo
1. Zaloz ze sekret jest w bazach danych scrapowaczy (GitHub search, archive.org)
2. Rotacja sekretu OBOWIAZKOWA (nawet jesli repo sprzatniesz)
3. Sprawdz logi providera czy ktos uzyl wyciekniotego klucza
4. Jesli byl uzywany - incident response (audyt, powiadomienie klientow jesli dane osobowe)

---

## 6. Bezwzgledne zakazy dla AI agenta (Claude, Copilot)

Wzorzec do wkladania w `CLAUDE.md` / `.cursor/rules`:

```markdown
## Bezwzgledne zakazy

1. NIGDY nie czytaj `.env` przez Read/cat - tresc zostanie w transkrypcie/logach.
   Zamiast tego: `source .env && uzyj $ZMIENNA`.

2. NIGDY nie commituj `.env`, `.pem`, `.key`, backupow bazy, plikow z danymi klientow.

3. NIGDY nie pisz hasel do kodu (nawet "tymczasowo do testow").

4. NIGDY nie wrzucaj danych klientow (email, IP, nazwisko) do logow, testow, dumpow.

5. NIGDY nie laczy sie klient (GUI/frontend) bezposrednio do bazy. Zawsze przez API.

6. NIGDY nie uzywaj `git push --force` na `main` bez explicitnego polecenia.

7. NIGDY nie skipuj pre-commit hooka (`--no-verify`).

8. Przed commitem sprawdz `git diff --cached` czy nie ma danych wrazliwych.
```

---

## 7. Periodyczny audyt

### Kwartalnie
- Przegladnij Dependabot alerts (powinno byc 0)
- Rotuj sekrety (zwlaszcza te ktore byly uzywane przez osoby ktore opuscily projekt)
- Sprawdz GitHub audit log (kto sie logowal, z jakiego IP)
- Przegladnij kto ma dostep do repo/bazy/PaaS

### Rocznie
- Penetration test (zewnetrzny jesli masz budzet, self-scan OWASP ZAP jesli nie)
- Review uprawnien na produkcji (principle of least privilege)
- Update .gitignore + pre-commit hook (nowe wzorce sekretow)

---

## 8. Onboarding dewelopera - sekcja bezpieczenstwo

W [setup/ONBOARDING.md](../setup/ONBOARDING.md) powinny byc:
1. Aktywacja pre-commit hooka (symlink)
2. Uzyskanie `.env` bezpiecznym kanalem (1Password, Bitwarden, **nie email**)
3. Weryfikacja `.env` jest w `.gitignore`
4. Test: `echo TEST_SECRET=abc123 > .env.test && git add .env.test` -> hook powinien zablokowac
5. Zapoznanie z `findings/2026-04-20-procedury-bezpieczenstwa.md` (ten plik)

---

## 9. Offboarding dewelopera

Checklist gdy ktos opuszcza projekt:
- [ ] Revoke dostep do GitHub (remove from org/team)
- [ ] Revoke dostep do PaaS (Render/Supabase/AWS)
- [ ] Rotuj WSZYSTKIE sekrety ktore mogl widziec (nie "czy mial aktywnie uzywane")
- [ ] Revoke jego SSH klucze z serwerow
- [ ] Jesli byl adminem DB - zmien hasla rol systemowych
- [ ] Audyt ostatnich 30 dni aktywnosci na wypadek sabotazu
