---
data: 2026-01-01
tagi: [example, template]
severity: low
status: aktualne
related: []
---

# Przykladowy finding - format wzorcowy

## Kontekst

Tutaj opisz co robiles, jakie srodowisko, jaka wersja narzedzia/biblioteki.

Konkretnie: "Deploy aplikacji Flask na Render plan free, gunicorn 21.2, Python 3.11."

## Co odkrylismy

Konkretny opis problemu lub odkrycia.

Przyklad: "Pierwsza odpowiedz po kilku minutach nieaktywnosci zajmuje ~30s (cold start). Kolejne sa szybkie."

## Dlaczego

Root cause.

Przyklad: "Render plan free zwija kontener po 15min nieaktywnosci - ponowne wybudzenie wymaga restartu Pythona + zaladowania bibliotek."

## Jak rozwiazac / czego unikac

Konkretny fix/workaround/zasada.

Przyklad: "Dla aplikacji ktore musza byc szybkie - upgrade na plan starter ($7/mc) lub uzyj cron zewnetrzny pingujacy /health co 10min."

## Zrodla

- https://render.com/docs/free
- (link do issue/PR)
