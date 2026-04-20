# Deployment

Jak deployowac aplikacje.

## Srodowiska

| Srodowisko | URL | Branch | Auto-deploy |
|---|---|---|---|
| dev | https://dev.example.com | dev | tak |
| staging | https://staging.example.com | staging | tak |
| prod | https://example.com | main | manualnie |

## Platforma

{{RENDER / FLY.IO / VERCEL / AWS / ...}}

## Sekrety

Trzymane w {{PANEL_PLATFORMY}} jako env vars. Lista wymaganych - patrz `.env.example`.

## Procedura release

1. Zmiany na branchu feature -> PR do `main`
2. CI sprawdza testy + linter
3. Po merge: auto-deploy na staging
4. Smoke test na staging
5. Manualny trigger deploy prod (button w panelu / `gh workflow run deploy-prod`)

## Rollback

```bash
{{ROLLBACK_COMMAND}}
```

## Monitoring

- Logi: {{LINK}}
- Metryki: {{LINK}}
- Alerty: {{LINK}}
