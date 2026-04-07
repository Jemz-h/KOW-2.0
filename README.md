# KOW Application

This project consists of a **Flutter** frontend interface and a **Node.js backend** that supports **Oracle SQL** and **SQLite**.

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
   Inside the `backend` folder, you will notice a `.env` file (or create one if it isn't listed). You need to place your Oracle DB credentials there:
   ```env
   PORT=3000
   DB_CLIENT=oracle
   DB_USER=your_oracle_username
   DB_PASSWORD=your_oracle_password
   DB_CONNECTION_STRING=localhost:1521/XEPDB1
   ```
   *Note: Install an Oracle Database locally or use a cloud solution (like Oracle Autonomous Database). Run the provided setup script located at `backend/src/config/KOW.sql` in your preferred Oracle SQL client (such as SQL Developer or DataGrip) to initialize the database schema and all associated tables. For offline mode, set `DB_CLIENT=sqlite`.*
5. **Start the Development Server**:
   ```bash
   npm run dev
   ```
   The backend will attempt to connect to your Oracle database and run on `http://localhost:3000`.

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
   Confirm that any API calls in `lib/api_config.dart` or `lib/api_service.dart` aim at `http://localhost:3000/api` or your appropriate machine IP if testing on an emulator.
4. **Run the App**:
   ```bash
   flutter run
   ```

## 📂 Backend Structure
Endpoints have been separated dynamically within the backend configuration:
* `src/config/db.js` Handles the active pool connecting Node to Oracle.
* `src/controllers/` Contains logic and direct SQL mapping functions (`userController.js`, `levelController.js`).
* `src/routes/` Defines access point URIs connecting to controllers (`/api/users`, `/api/levels`).
