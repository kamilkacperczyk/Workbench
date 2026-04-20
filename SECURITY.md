# Polityka bezpieczenstwa

## Zglaszanie podatnosci

Jesli znalazles podatnosc - **NIE otwieraj publicznego issue**.

Napisz na: {{SECURITY_CONTACT_EMAIL}}

Odpowiem w ciagu {{SLA_DNI}} dni.

## Co nigdy nie trafia do repo

- Hasla, tokeny, klucze API, connection stringi
- Pliki `.env`, `.env.local`, `*.key`, `*.pem`
- Dump'y bazy danych z PII
- Pliki w `PRIV/`
- Pliki w `.claude/settings.local.json`

## Pre-commit hook

Repo ma w `hooks/pre-commit.sh` skan pod katem wrazliwych danych.

Aktywacja:
```bash
ln -s ../../hooks/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## Co robic gdy sekret trafil do repo

1. Natychmiast **odwolaj** sekret (rotate/regenerate)
2. Usun z historii (`git filter-repo` albo BFG)
3. Force push (po koordynacji z zespolem)
4. Sprawdz logi czy nie zostal uzyty
