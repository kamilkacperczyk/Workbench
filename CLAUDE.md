# {{PROJECT_NAME}} - Instrukcje dla Claude

## O projekcie

{{KROTKI_OPIS_PROJEKTU}}

Stack: {{TECH_STACK}}

## Komunikacja

- Jezyk: {{LANGUAGE}}
- Bez emoji chyba ze user poprosi
- Krotko i na temat

## Struktura repo

Patrz `README.md` - drzewo i opis kazdego folderu.

Wazne katalogi do czytania na poczatku sesji:
- `findings/` - co juz wiemy, jakie gotchas
- `repo-knowledge/` - dokumentacja systemow ktorych dotykamy
- `skills/` - dostepne custom skills
- `hooks/` - aktywne hooki (pre-commit, post-tool-use, stop) - **przed kazda akcja ktora moze je odpalic** (commit, edit, bash) sprawdz co tam jest, zeby wiedziec co sie wydarzy automatycznie

## Zasady pracy

### Commity

- Format: `<typ>: <opis>` (np. `feat: dodanie X`, `fix: naprawa Y`)
- Typy: `feat`, `fix`, `refactor`, `docs`, `chore`
- Commit message po {{LANGUAGE}}
- NIE dodawaj Co-Authored-By Claude

### Bezpieczenstwo

- NIGDY nie commituj hasel, tokenow, kluczy, connection stringow
- NIGDY nie czytaj plikow `.env` narzedziem Read - uzyj `source` w bashu
- Sekrety: zmienne srodowiskowe lub `.env` (jest w `.gitignore`)
- Prywatne notatki: folder `PRIV/` (jest w `.gitignore`)

### Bezwzgledne zakazy dla AI agenta

1. NIGDY nie czytaj `.env` przez Read/cat - tresc zostanie w transkrypcie/logach.
   Zamiast tego: `source .env && uzyj $ZMIENNA`.
2. NIGDY nie commituj `.env`, `.pem`, `.key`, backupow bazy, plikow z danymi klientow.
3. NIGDY nie pisz hasel do kodu (nawet "tymczasowo do testow").
4. NIGDY nie wrzucaj danych klientow (email, IP, nazwisko) do logow, testow, dumpow.
5. NIGDY nie laczy sie klient (GUI/frontend) bezposrednio do bazy. Zawsze przez API.
6. NIGDY nie uzywaj `git push --force` na `main` bez explicitnego polecenia.
7. NIGDY nie skipuj pre-commit hooka (`--no-verify`).
8. Przed commitem sprawdz `git diff --cached` czy nie ma danych wrazliwych.

Pelne procedury: [findings/2026-04-20-procedury-bezpieczenstwa.md](findings/2026-04-20-procedury-bezpieczenstwa.md).

### Eksploracja kodu - delegowanie do subagentow

Gdy zadanie wymaga przeczytania **wiecej niz 3 plikow na raz** (typowo: eksploracja codebase, mapowanie systemu) ALBO **plik ma > 1000 linii a potrzebujesz tylko fragmentu** - **deleguj do Task/Agent subagenta** zamiast czytac wszystko w glownym kontekscie.

Zasady:
- Subagent dostaje budzet **10-15 plikow max** + konkretne pytanie do odpowiedzi
- Wracajacy raport ma byc **zwarty** ("under N words"), nie surowe outputy
- Dla wielu niezaleznych watkow eksploracji - **rownolegle subagenty** (jedna wiadomosc, wiele Task wywolan)
- Nie deleguj jesli wiesz dokladnie czego szukasz - uzyj odpowiedniej metody bezposrednio (Read na konkretny plik, Grep na konkretny wzorzec, Glob na pattern nazwy)
- **Zakazy z sekcji "Bezwzgledne zakazy" obowiazuja zawsze** - nawet w "odpowiedniej metodzie bezposrednio". `.env`, klucze, backupy bazy NIGDY przez Read - niezaleznie od kontekstu.

Po co: glowny kontekst zostaje czysty na implementacje, a subagent zwraca syntetyczna odpowiedz.

### Findings (OBOWIAZKOWE)

Na biezaco, w trakcie pracy zapisuj do `findings/`:
1. Gdy naprawisz buga - co go spowodowalo
2. Gdy odkryjesz ograniczenie platformy
3. Gdy zmienisz architekture/podejscie - dlaczego
4. Gdy cos zadziala dobrze - potwierdzone podejscie

Format: `findings/YYYY-MM-DD-krotki-tytul.md` z YAML frontmatter (patrz `findings/README.md`).

## Specyficzne dla projektu

{{TUTAJ_DODAJ_REGULY_SPECYFICZNE_DLA_TEGO_PROJEKTU}}
