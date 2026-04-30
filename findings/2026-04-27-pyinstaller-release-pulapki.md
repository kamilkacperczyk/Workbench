---
data: 2026-04-27
tagi: [pyinstaller, release, build, deployment, gotcha, python]
severity: high
status: aktualne
related:
  - findings/2026-04-20-architektura-webapp-desktop.md
---

# PyInstaller release - jak nie wypuscic popsutej paczki

Wpadka: release `.exe` opublikowany na GitHub i pobrany przez uzytkownikow zanim ktokolwiek go odpalil. GUI dzialalo, glowna funkcjonalnosc crashowala na `ModuleNotFoundError`.

## Kontekst

Projekt: Python + PySide6 GUI + bot z OpenCV/ONNX, pakowany przez PyInstaller. Restrukturyzacja repo (przeniesienie `.spec` do podfolderu) zlamala sciezki w spec, build sie udawal exit 0 ale bez modulow aplikacji.

## Co odkrylismy

### 1. PyInstaller `Build complete!` exit 0 nie znaczy ze paczka dziala

Brakujace moduly = ostrzezenie w `build/<name>/warn-<name>.txt` ktore nikt nie czyta. Crash dopiero w runtime.

**Reguła:** zawsze odpal `.exe` lokalnie i przejdz pelny flow (GUI → login → glowna funkcja) PRZED uploadem na release. Build success != paczka dziala.

### 2. Spadek rozmiaru paczki >30% to ALARM

Stary release: 107 MB, nowy popsuty: 48 MB. Tlumaczylem to "lepsza kompresja" - **bledne**. Biblioteki natywne (cv2, numpy, ONNX) sa juz skompresowane wewnetrznie. Drastyczny spadek = cos zniknelo.

**Reguła:** zawsze porownaj `du -sh dist/` z poprzednia wersja. Spadek >30% bez zmian w `requirements.txt` = bug.

### 3. PyInstaller .spec - sciezki niespojne

W PyInstaller 6.x:
- `Analysis(['main.py'])`, `datas`, `icon` → wzgledem **pliku .spec**
- `pathex` → wzgledem **CWD** (gdzie odpalasz `pyinstaller`)

Mnemotechnika: **"PathEx Cwd, reszta Spec"**.

W logu PyInstallera "Module search paths" sprawdz ze rozwiazane sciezki zaczynaja sie od oczekiwanego prefixu repo. Jesli widzisz np. `Repos\\versions\\` zamiast `Repos\\MyApp\\versions\\` - `pathex` jest zly.

### 4. Dynamiczne importy nie sa wykrywane

PyInstaller analizuje statycznie. Nie wykryje:
- `sys.path.insert(...) + import x`
- `importlib.import_module(...)`
- Plugin loaders

Wszystko co wciagasz dynamicznie → `hiddenimports=[...]` w `.spec`.

### 5. Push na main = czasem deploy na produkcje

Jesli backend ma auto-deploy (Render, Heroku, Railway) - zmiana w kodzie backendu = produkcja w 2-5 min. Bez lokalnego testu = potencjalna awaria.

**Klasy zmian:**
- Frontend/.exe → push bezpieczny, test przed releasem
- Backend/API → **lokalny test serwera + curl PRZED pushem** ALBO branch + PR
- SQL migracje → migracja na bazie + test endpointu PRZED commitem aplikacji
- Docs → push bez ograniczen

## Dlaczego

PyInstaller jest "optymistyczny" - nie wybija exit > 0 przy brakach, dziala "best effort". Filozofia ma sens dla wczesnych etapow developmentu (wiele iteracji), ale przy releasie wymaga aktywnej weryfikacji.

Dodatkowo niespojnosc sciezek `.spec` to historyczny dlug PyInstallera - nie zostanie naprawiony, trzeba go akceptowac.

## Jak rozwiazac / czego unikac

### Minimalna checklist release

```
[ ] Sklasyfikuj zmiany (frontend / backend / SQL / docs) - klasa 2+3 wymaga testu PRZED pushem
[ ] git push na main + weryfikacja produkcji (curl)
[ ] Bump wersji w UI

[ ] Backup .spec
[ ] Modyfikacja na debug (console=True, uac_admin=False)
[ ] Build + odpal .exe + przejdz flow GUI/login/glowna_funkcja
[ ] BLAD = STOP, nie wrzucaj releasu

[ ] Restore .spec
[ ] Czysty rebuild prod
[ ] Sanity check: rozmiar prod ~= debug build, ~= poprzedni release (+/-10%)
[ ] Pakowanie zip + gh release upload

[ ] Smoke test: pobierz .zip z PUBLICZNEGO linka, rozpakuj, odpal jako user
```

### Sanity checks przed uploadem

```bash
# Rozmiar paczki - czy zgodny z oczekiwanym
du -sh dist/AppName/

# Czy moduly aplikacji w PYZ archive
grep -oE "'<pakiet_apki>\.[a-z._]+'" build/AppName/PYZ-00.toc | sort -u

# Czy biblioteki natywne w _internal/
ls dist/AppName/_internal/ | grep -E "cv2|numpy|onnxruntime|PIL"

# Czego brakuje (zignoruj platforma-specific: Quartz/Xlib/AppKit dla mac/linux)
grep "missing module" build/AppName/warn-AppName.txt | grep -vE "Quartz|Xlib|AppKit|olefile|tkinter|matplotlib"
```

### Najczestsza pulapka - rebuild miedzy testem a uploadem

NIE buduj prod build PO tescie debug, tylko zeby uploadowac inny build. PRODUKCYJNY build ktory wrzucasz musi byc TEN SAM build ktory testowales (lub pelny rebuild + sanity check rozmiaru).

## Zrodla

- [PyInstaller manual - Spec File Operation](https://pyinstaller.org/en/stable/spec-files.html)
- [PyInstaller manual - Hidden Imports](https://pyinstaller.org/en/stable/when-things-go-wrong.html#hidden-imports)
- Real-world incydent: BeSafeFish v1.2.6 (popsuta paczka 48MB zamiast 118MB, wykryta przez uzytkownika po pobraniu)
