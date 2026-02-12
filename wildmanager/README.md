# WildManager

Flutter-app voor Wild Life NL: inloggen, kaart met living lab-gebieden.

Deze handleiding is voor iemand die nog nooit lokaal een Flutter-project heeft gedraaid.

---

## 1. Wat je nodig hebt

- **Git** – om het project op te halen. [Download Git](https://git-scm.com/downloads)
- **Flutter SDK** – om de app te bouwen en te runnen. [Flutter installeren](https://docs.flutter.dev/get-started/install)

Na het installeren van Flutter controleer je in een terminal:

```bash
flutter doctor
```

Los eventuele meldingen op (bijv. ontbrekende licenties of tools) voordat je verdergaat.

---

## 2. Project ophalen

Kloon of download dit project naar een map op je computer, bijvoorbeeld:

```bash
cd C:\Users\JouwNaam\Documents
git clone <url-van-de-wildmanager-repo> wildmanager
```

Open daarna de **binnenste** projectmap (waar `pubspec.yaml` in staat). Vaak is dat:

```
wildmanager/wildmanager/
```

Die map open je in je editor  VS Code als projectmap.

De login- en kaart-packages worden automatisch van GitHub gehaald bij `flutter pub get`; je hoeft geen andere repos lokaal te clonen.

---

## 3. Environment (.env)

De API-URL staat niet in de code maar in een bestand `.env` in de projectroot (de map waar `pubspec.yaml` staat).

1. Ga in de projectroot naar het bestand **`.env`**.
2. Als het niet bestaat: maak een nieuw bestand met de naam `.env` (zonder extensie) in de projectroot.
3. Zet er minimaal dit in (vervang de waarde door de juiste API-base-URL):

```env
DEV_BASE_URL=<jouw-api-base-url>
```

Er mag geen spatie rond de `=` staan. Vraag de API-URL bij de projectbeheerder als je die niet hebt.

---

## 4. Dependencies installeren

In een terminal, in de **projectroot** (de map met `pubspec.yaml`):

```bash
cd pad/naar/wildmanager/wildmanager
flutter pub get
```

Als je de map al in je editor hebt geopend, kun je in de geïntegreerde terminal ook gewoon `flutter pub get` doen (zorg dat je in de juiste map zit).

---

## 5. App starten

### In de browser (meest eenvoudig)

```bash
flutter run -d chrome
```

De app opent in Chrome. Je kunt inloggen en de kaart met living labs bekijken.

### Op een ander apparaat of emulator

- **Android/iOS:** sluit een apparaat aan of start een emulator, daarna:  
  `flutter run`
- **Windows:**  
  `flutter run -d windows`
- **macOS:**  
  `flutter run -d macos`

Beschikbare apparaten zie je met:

```bash
flutter devices
```

---

## 6. Samenvatting stappen

1. Flutter (en eventueel Git) installeren → `flutter doctor` oké.
2. WildManager-project clonen en **projectroot** openen (map met `pubspec.yaml`).
3. In de projectroot een **`.env`** maken/aanpassen met `DEV_BASE_URL=...`.
4. In de projectroot: **`flutter pub get`**.
5. **`flutter run -d chrome`** (of een ander device).

Als iets niet werkt, controleer of je in de juiste map zit (waar `pubspec.yaml` staat) en of het bestand `.env` aanwezig is.
