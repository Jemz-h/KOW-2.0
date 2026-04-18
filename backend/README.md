# KOW Backend

Express + Node.js API that supports two data modes:
- `DB_MODE=online` -> Oracle
- `DB_MODE=offline` -> SQLite

## Setup

```bash
cd backend
npm install
copy .env.example .env
```

Edit `.env` values.

## Run

```bash
npm run dev
```

## Endpoints

- `GET /api/health`
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/students`
- `GET /api/students/:studentId`
- `POST /api/progress`
- `GET /api/progress/:studentId`
- `POST /api/achievements`
- `GET /api/achievements/:studentId`
- `GET /api/leaderboard`

## SQL Schemas

- Oracle: `src/db/oracle/schema.sql`
- SQLite: `src/db/sqlite/schema.sql`
