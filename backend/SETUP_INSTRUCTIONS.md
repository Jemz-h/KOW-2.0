# Backend Setup Instructions (Oracle + SQLite)

## 1. Database Schema

Oracle schema file:
- `backend/src/KOW.sql`

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
@backend/src/KOW.sql
```

Note:
- The script includes `CREATE USER kow_admin ...`.
- If the user already exists, either drop it first or comment that section before re-running.

## 3. Backend Environment

Set `backend/.env`:
```env
PORT=3000
DB_CLIENT=oracle
DB_USER=kow_admin
DB_PASSWORD=KOW_Password_2026!
DB_CONNECTION_STRING=localhost:1521/XE
```

SQLite mode (`backend/.env`):
```env
PORT=3000
DB_CLIENT=sqlite
SQLITE_DB_PATH=./backend/data/kow_offline.db
```

Notes:
- `DB_CLIENT` defaults to `oracle` when omitted.
- `SQLITE_DB_PATH` is optional; default is `./backend/data/kow_offline.db`.

## 4. Install and Run

```bash
cd backend
npm install
npm run dev
```

## 5. Quick Smoke Test

With backend running:
```bash
node test_all.js
```

## 6. API Notes (Current Contract)

- `POST /api/auth/register`
  - body: `firstName`, `lastName`, `nickname`, `birthday`, optional `sex`, `area`, `teacherId`, `deviceUuid`
- `POST /api/auth/login`
  - body: `nickname`, `birthday`
- `GET /api/quiz/questions?grade=Punla&subject=Mathematics&difficulty=Easy`
- `POST /api/quiz/score`
  - body: `studentId`, `grade`, `subject`, `difficulty`, `score`, optional `total`, `playedAt`, `deviceUuid`
- `GET /api/quiz/scores/:studentId`
- `POST /api/progress`
  - body: `studentId` (or `userID`), plus subject/grade identifiers

## 7. Troubleshooting

- ORA-01017: verify `DB_USER`/`DB_PASSWORD`.
- ORA-12514 / ORA-12154: verify `DB_CONNECTION_STRING` (`localhost:1521/XE`).
- ORA-01920/ORA-01918 on re-run: user/role exists; clean up first or comment create statements.
