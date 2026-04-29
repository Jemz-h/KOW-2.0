# KOW Application

This project consists of a **Flutter** frontend interface and a **Node.js backend** that supports **Oracle SQL** and **SQLite**.

## Quick Links

- [Documentation Index](docs/README.md)
- [Project Overview](docs/01_PROJECT_OVERVIEW.md)
- [Tech Stack](docs/02_TECH_STACK.md)
- [Backend Setup](backend/SETUP_INSTRUCTIONS.md)
- [Implementation Status](IMPLEMENTATION_STATUS.md)

##  First Time Setup

### Option 1: Setting up the Backend (Node.js & Oracle SQL)

The backend provides the API necessary for the Flutter application to interact with your data.

1. **Install Prerequisites**: Assure you have [Node.js](https://nodejs.org/) installed.
2. **Navigate to the Backend Directory**:
   ```bash
   cd backend
   ```
3. **Install Dependencies**:
   ```bash
   npm install
   ```
4. **Configure Oracle Database Environment**:
   Use `backend/.env.development` for local development. Add your Oracle credentials:

   *Note: Install Oracle locally or use Oracle cloud. Run `backend/src/config/KOW.sql` in SQL Developer/DataGrip to initialize schema. For strict Oracle testing, keep `DB_FALLBACK_SQLITE=false`.*
5. **Start the Development Server**:
   ```bash
   npm run dev
   ```
   The backend will attempt to connect to Oracle and run on `http://localhost:3010` (or the next free port if 3010 is occupied).

---

### Option 2: Setting up the Frontend (Flutter)

The frontend project is located in the root of the workspace.

1. **Install Prerequisites**: Ensure you have [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
2. **Retrieve Packages**: 
   Inside the main project folder run:
   ```bash
   flutter pub get
   ```
3. **Connect to the Backend**:
    Confirm API target matches backend host/port:
    - Android emulator: `http://10.0.2.2:3010`
    - Physical Android device: run with
       `flutter run --dart-define=API_BASE_URL=http://<YOUR_PC_IP>:3010`
    - Optional adb reverse flow:
       `adb reverse tcp:3010 tcp:3010` then use `http://localhost:3010`
4. **Run the App**:
   ```bash
   flutter run
   ```

### Frontend API Target Profiles

Run on Chrome with explicit target:

```bash
flutter run -d chrome --dart-define-from-file=.env.dev
```

Run on Chrome against prod profile:

```bash
flutter run -d chrome --dart-define-from-file=.env.prod
```

## 📂 Backend Structure
Endpoints have been separated dynamically within the backend configuration:
* `src/config/db.js` Handles the active pool connecting Node to Oracle.
* `src/controllers/` Contains logic and direct SQL mapping functions (`userController.js`, `levelController.js`).
* `src/routes/` Defines access point URIs connecting to controllers (`/api/users`, `/api/levels`).
