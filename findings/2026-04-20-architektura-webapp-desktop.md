---
data: 2026-04-20
tagi: [architektura, api, render, deployment, gui, pyside, connection-pool]
severity: high
status: aktualne
related:
  - findings/2026-04-20-postgresql-managed-services.md
  - findings/2026-04-20-procedury-bezpieczenstwa.md
---

# Architektura webapp + desktop client - wzorce

Wnioski z wdrozen gdzie aplikacja desktopowa (GUI, .exe) oraz frontend web laczy sie do bazy przez API na PaaS (Render/Koyeb/Railway/Fly.io).

## 1. Klient NIGDY bezposrednio do bazy

### Problem
Aplikacja kliencka (GUI .exe, frontend) z bezposrednim connection stringiem do bazy = connection string w binarce/bundle. Kazdy kto rozpakuje aplikacje ma pelne haslo do bazy.

### Wzorzec - API jako proxy
```
Klient (GUI/frontend)  ->  API (HTTPS)  ->  PostgreSQL
         |                    |                 |
      HTTPS only         Token/auth         Hidden
```

- Klient wie tylko o API (URL + token)
- API trzyma sekrety bazy w env vars na PaaS
- Kazda operacja idzie przez endpoint (nie przez `SELECT/INSERT` z klienta)
- Token w kliencie moze wyciec, ale ogranicza sie do uprawnien tego tokenu (nie pelna baza)

### Minimalne zabezpieczenia endpointu
- Authorization header (Bearer token per klient/uzytkownik)
- Rate limiting (per IP + per token)
- HTTPS only (HSTS na PaaS)
- Walidacja inputu (pydantic, marshmallow)

---

## 2. Connection pool z lazy init

### Problem
Gunicorn worker przy starcie laczy sie do bazy. Jesli baza niedostepna (albo DNS wolno odpowiada) - worker crashuje, Render oznacza deploy jako failed i robi rollback.

### Wzorzec - `ThreadedConnectionPool` z lazy init
```python
from psycopg2.pool import ThreadedConnectionPool
import os

_pool = None

def get_pool():
    global _pool
    if _pool is None:
        _pool = ThreadedConnectionPool(
            minconn=1,
            maxconn=5,  # Render free/starter ma mala pamiec
            dsn=os.environ["DATABASE_URL"],
        )
    return _pool

def get_conn():
    return get_pool().getconn()

def put_conn(conn):
    get_pool().putconn(conn)
```

Worker startuje bez bazy, laczy sie przy pierwszym requescie. Wiecej tolerancji na przejsciowe problemy z siecia.

### Pulapka - `maxconn`
Supabase ma limit polaczen (np. 60 na projekt). 3 workery x `maxconn=20` = 60. Jesli inna aplikacja tez sie laczy - wyczerpujesz limit.

Zasada: `workers * maxconn <= limit_bazy / 2` (zostaw margines na migracje, pgAdmin, backupy).

---

## 3. Gunicorn na 512 MB RAM

### Problem
Render free/starter = 512 MB. Domyslny gunicorn (2 workery x 4 threads, sync) nie miesci sie, OOM kill.

### `gunicorn.conf.py`
```python
workers = 2
threads = 2
worker_class = "gthread"
timeout = 60
max_requests = 500  # restart workera po 500 req (leak mitigation)
max_requests_jitter = 50
preload_app = False  # lazy init connection pool
```

- `workers = 2` - min. dla redundancji (jak 1 restartuje, drugi dziala)
- `threads = 2` - dodatkowa concurrency bez dodatkowej pamieci
- `max_requests` + `jitter` - wymusza recycling (chroni przed memory leakami lib-ow)
- `preload_app = False` - kazdy worker tworzy swoj pool (wazne bo pool nie jest fork-safe)

---

## 4. Render.com i inne PaaS - dziwactwa

### Cold start
Free tier usypia po 15 min bez ruchu. Pierwszy request po uspieniu = 30-60s. Healthcheck z innego serwisu co 10 min = obejscie (ale narusza ToS).

### Auto-deploy z `rootDir`
Jesli monorepo - `rootDir: backend/` w `render.yaml`. Bez tego Render bierze root repo i nie znajduje `requirements.txt`.

### `render.yaml` w repo
```yaml
services:
  - type: web
    name: moja-api
    runtime: python
    rootDir: backend
    buildCommand: pip install -r requirements.txt
    startCommand: gunicorn -c gunicorn.conf.py app:app
    envVars:
      - key: DATABASE_URL
        sync: false  # musisz ustawic w panelu
```

`sync: false` = Render pyta przy tworzeniu, nie commituje do git.

### Alternatywy
- **Koyeb** - free tier bez cold start, ale 512 MB
- **Railway** - $5/mies kredyt, bez cold start, DX bardzo dobry
- **Fly.io** - free 3 mikro-VM, wlasne regiony, bardziej low-level
- **Vercel** - dla frontendu/serverless JS (nie dla dlugo-chodzacych workerow)

---

## 5. Pliki > 100 MB (modele ML, binarki)

### Problem
GitHub blokuje push plikow > 100 MB. LFS placi sie za ruch.

### Wzorzec - GitHub Releases
- Commituj tylko kod + `download_model.py` ktory sciaga z Release
- W CI/CD (Render build): `python download_model.py` przed startem aplikacji
- Release = `v1.0-models` - tag + zalaczniki (do 2 GB na plik)

### Uwagi
- Release zalaczniki sa publiczne jesli repo publiczne - zadaj sobie pytanie czy model mozna upubliczniac
- Dla prywatnych modeli: S3/R2 + presigned URL w env var

---

## 6. Budowanie `.exe` (PyInstaller)

### Pulapki
- `--onefile` = kazde uruchomienie rozpakowuje do `%TEMP%` - wolno, widoczne w AV
- `--onedir` = folder z .exe + dll - szybciej, ale trzeba zipowac
- Antywirusy flaguja `--onefile` PyInstaller jako trojan (false positive) - sign code albo uzyj `--onedir`

### Co NIE trafia do .exe
- `.env` (sekrety baza)
- Connection stringi
- Hashowane hasla admin
- Tokeny API prod (chyba ze publiczny read-only)

### Co MOZE trafic
- URL do API (jawny)
- Token klienta (anonymous/readonly jesli API sie broni)
- Klucz publiczny do weryfikacji podpisu odpowiedzi z API

---

## 7. GUI - HTTP calls bez blokowania UI

### Problem
PySide6/PyQt - `requests.get(...)` w slocie = zamroznie UI na czas HTTP (timeout moze byc 30s).

### Wzorzec - QThread + signals
```python
class HttpWorker(QThread):
    finished = Signal(dict)
    failed = Signal(str)

    def __init__(self, url, token):
        super().__init__()
        self.url = url
        self.token = token

    def run(self):
        try:
            r = requests.get(self.url, headers={"Authorization": f"Bearer {self.token}"}, timeout=10)
            r.raise_for_status()
            self.finished.emit(r.json())
        except Exception as e:
            self.failed.emit(str(e))

# Uzycie
worker = HttpWorker(url, token)
worker.finished.connect(self.on_data)
worker.failed.connect(self.on_error)
worker.start()
```

### Timeout ZAWSZE
Bez `timeout=` requests wisi w nieskonczonosc jesli serwer nie odpowiada. Min. 10s, max 30s.

---

## 8. Fail-open dla botow (health probes, crawlers)

### Problem
Aplikacja zwraca 500 dla bota skanujacego (np. `/.env`, `/wp-admin`). Logi zasmiecone, a i tak bot sie nie obraza - przychodzi co 5 min.

### Wzorzec
- Endpointy nieistniejace -> 404 (szybko, krotko)
- `/.env`, `/.git/config` -> 404 + alert do loga (probe detected)
- `/health` -> 200 zawsze jesli proces zyje (nie sprawdza bazy - cold connect daje false negative)
- `/ready` -> 200 tylko jak pool do bazy dziala

Render healthcheck na `/health`, nie `/ready` - inaczej restart loop przy przejsciowych problemach z baza.

---

## 9. X-Forwarded-For - poprawne wyciaganie IP

### Problem
Za reverse proxy (Render, Cloudflare) `request.remote_addr` = IP proxy, nie klienta. `X-Forwarded-For` moze miec liste IP.

### Wzorzec
```python
def get_client_ip(request):
    xff = request.headers.get("X-Forwarded-For", "")
    if xff:
        # pierwszy IP = oryginalny klient
        return xff.split(",")[0].strip()
    return request.remote_addr
```

### Pulapka
Bez reverse proxy `X-Forwarded-For` moze byc spoofowany przez klienta. Akceptuj ten header TYLKO za zaufanym proxy (na Render - tak, w lokalnym dev - nie).

---

## 10. Struktura repo - webapp + desktop

```
repo/
├── backend/             # Flask/FastAPI + Gunicorn
│   ├── app.py
│   ├── gunicorn.conf.py
│   ├── requirements.txt
│   └── db/
│       ├── pool.py
│       └── queries.py
├── desktop/             # PySide6 klient
│   ├── main.py
│   ├── workers/         # HTTP workers (QThread)
│   └── requirements.txt
├── frontend/            # opcjonalnie web UI
├── migrations/          # SQL migracje
├── docs/
├── .env.example
├── .gitignore
├── render.yaml          # config PaaS
└── README.md
```

Dwa `requirements.txt` - desktop nie potrzebuje `gunicorn/flask`, backend nie potrzebuje `PySide6`.

---

## 11. Uzytkownicy systemowi vs biznesowi

### Problem
Aplikacja potrzebuje wykonywac operacje planowe (cron, czyszczenie tokenow). Nie ma realnego uzytkownika - kto jest autorem?

### Wzorzec
- W tabeli `users` wpis `system@local` z flaga `is_system = true`
- Cron joby pisza `author = 'system@local'` do logow
- RLS/polityki: `is_system` ma ograniczone uprawnienia (tylko operacje planowe)
- UI: `is_system = true` nie pokazuje sie w listach uzytkownikow
