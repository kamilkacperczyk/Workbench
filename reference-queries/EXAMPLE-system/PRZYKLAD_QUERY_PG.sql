-- Cel: Przyklad zapytania - sluzy jako wzor formatu
-- Autor: {{TWOJ_LOGIN}}
-- Data: {{YYYY-MM-DD}}
-- Zalezy od: tabel users, sessions
-- Przyklad uruchomienia: psql "$DATABASE_URL" -f PRZYKLAD_QUERY_PG.sql

SELECT
    u.id,
    u.email,
    COUNT(s.id) AS liczba_sesji
FROM users u
LEFT JOIN sessions s ON s.user_id = u.id
WHERE u.created_at > now() - INTERVAL '30 days'
GROUP BY u.id, u.email
ORDER BY liczba_sesji DESC
LIMIT 50;
