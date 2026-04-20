# PRIV/ - prywatne notatki dewelopera

**Ten folder (PRIV.example/) jest commitowany jako wzor.**

**Folder PRIV/ ktory faktycznie uzywasz - nie jest commitowany** (jest w `.gitignore`).

## Po co

Kazdy deweloper ma swoje:
- Brudnopisy
- TODOs prywatne
- Skrawki SQL ktore aktualnie testuje
- Notatki ze spotkan
- Snippety configu z innych projektow

Te rzeczy NIE powinny trafiac do wspolnego repo, ale fajnie jak masz je w jednym miejscu obok kodu (zeby Claude Code mogl do nich siegnac jak go o to poprosisz).

## Jak zaczac

```bash
mkdir PRIV
echo "# Moje notatki" > PRIV/notatki.md
```

## Co trafia do PRIV/

- `PRIV/notatki.md` - dziennik / scratchpad
- `PRIV/todos.md` - moje TODOs
- `PRIV/sql-eksperymenty/` - SQL ktorego nie chce pokazywac zespolowi (jeszcze)
- `PRIV/spotkania/YYYY-MM-DD.md`

## Co NIE trafia do PRIV/

Sekrety produkcyjne dalej trzymamy w `.env`, nie w PRIV. PRIV moze trafic na backup, do innego komputera itp.
