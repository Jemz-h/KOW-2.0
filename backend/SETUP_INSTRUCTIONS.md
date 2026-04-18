# Backend Setup Instructions (Oracle + SQLite)

## 1. Database Schema

Oracle schema file:
- `backend/src/config/KOW.sql`

SQLite schema is bootstrapped automatically by the backend when `DB_CLIENT=sqlite`.

Oracle schema contains:
- cleanup block
- sequences
- lookup + core tables (`studentTb`, `scoreTb`, `questionTb`, etc.)
- procedures (`sp_upsert_student`, `sp_upload_score`, `sp_refresh_analytics`, `sp_bump_content_version`)
- triggers for Oracle 11g auto-increment behavior
- views, roles, synonyms, and seed data

## 2. Apply Schema

### SQL*Plus
```bash
sqlplus system/<SYSTEM_PASSWORD>@localhost:1521/XE
@backend/src/config/KOW.sql
```

Note:
- The script includes `CREATE USER kow_admin ...`.
- If the user already exists, either drop it first or comment that section before re-running.

## 3. Backend Environment

Use `backend/.env.development` for local dev (`npm run dev`):
```env
PORT=3010
NODE_ENV=development

DB_CLIENT=oracle
DB_FALLBACK_SQLITE=false

DB_USER=kow_admin
DB_PASSWORD=your_oracle_password
DB_CONNECTION_STRING=localhost:1521/XEPDB1

SQLITE_DB_PATH=./data/kow_offline.db
TOKEN_SECRET=replace_with_long_random_secret
```

Notes:
- `DB_CLIENT` defaults to `sqlite` when omitted.
- `DB_FALLBACK_SQLITE=false` is recommended in dev when validating Oracle sync.
- `SQLITE_DB_PATH` is optional; default is `./data/kow_offline.db`.
- Startup now auto-selects the next free port if `PORT` is occupied.

## 4. Install and Run

```bash
cd backend
npm install
npm run dev
```

Verify runtime mode:
```bash
# Expect db_provider=oracle
http://localhost:3010/api/health
```

If 3010 is busy, backend will log the auto-selected port (3011, 3012, etc.).

## 5. Quick Smoke Test

With backend running:
```bash
node test_all.js
```

## 6. Import KOW Questions (HTML + Images)

Source folder format:
- `backend/data/kow_questions/KOWQuestions.html`
- `backend/data/kow_questions/images/`

Commands:

```bash
cd backend
npm run import:kow-questions
```

- Imports to the currently active DB mode (`DB_MODE` / `DB_CLIENT`).
- Imports both question images and answer option images (`option_a_image` ... `option_d_image`).

```bash
cd backend
npm run import:kow-questions:all
```

- Runs import twice automatically:
  - Oracle (`DB_MODE=online`)
  - SQLite (`DB_MODE=offline`)
- Useful when you want data available both online and offline.

SQLite compatibility note:
- The importer now auto-adds missing image columns in `questionTb` for older SQLite files:
  - `question_image`
  - `option_a_image`
  - `option_b_image`
  - `option_c_image`
  - `option_d_image`

## 7. API Notes (Current Contract)

- `POST /api/auth/register`
  - body: `firstName`, `lastName`, `nickname`, `birthday`, optional `sex`, `area`, `teacherId`, `deviceUuid`
  - duplicate nickname handling:
    - exact retry with same nickname+birthday returns success with existing student
    - conflicting nickname returns `409` with `NICKNAME_CONFLICT`
- `POST /api/auth/login`
  - body: `nickname`, `birthday`
- `GET /api/quiz/questions?grade=Punla&subject=Mathematics&difficulty=Easy`
- `POST /api/quiz/score`
  - body: `studentId`, `grade`, `subject`, `difficulty`, `score`, optional `total`, `playedAt`, `deviceUuid`
- `GET /api/quiz/scores/:studentId`
- `POST /api/progress`
  - body: `studentId` (or `userID`), plus subject/grade identifiers

## 8. Troubleshooting

- ORA-01017: verify `DB_USER`/`DB_PASSWORD`.
- ORA-12514 / ORA-12154: verify `DB_CONNECTION_STRING` (`localhost:1521/XEPDB1` for this setup).
- ORA-01920/ORA-01918 on re-run: user/role exists; clean up first or comment create statements.

### Flutter cannot sign up (saved offline only)

This indicates the app cannot reach backend from device.

- Android emulator: use `http://10.0.2.2:<PORT>`.
- Physical Android device:
  - run with LAN URL:
    - `flutter run --dart-define=API_BASE_URL=http://<YOUR_PC_IP>:<PORT>`
  - or use adb reverse:
    - `adb reverse tcp:<PORT> tcp:<PORT>` then use `http://localhost:<PORT>`.
