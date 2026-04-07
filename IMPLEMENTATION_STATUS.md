# KOW Implementation Status

This file groups the current workspace changes into completed, partial, and unfinished items so the remaining work is explicit.

## Completed Changes

- Backend now supports Oracle and SQLite bootstrap paths.
- Oracle provider can bootstrap schema objects from `backend/src/config/KOW.sql`.
- SQLite provider now includes local tables for admin, device, content version, and sync logging.
- Student lookup and registration endpoints were added under `/api/students`.
- Auth routes now expose `/api/auth/admin/login` and `/api/auth/device/register`.
- Content pull endpoint exists at `/api/content`.
- Sync batch endpoint exists at `/api/sync`.
- Admin endpoints now exist for dashboard, students, student detail, devices, and question CRUD.
- Admin endpoints now include question listing and soft-delete behavior.
- Flutter API service now supports offline score/progress queuing and remote submission.
- Flutter local sync store now has pending score and progress queues.
- Flutter quiz screen now fetches remote questions and submits score/progress at session end.
- Date formatting for student onboarding screens now uses ISO-style `YYYY-MM-DD`.
- Role-aware auth middleware now exists and is wired into admin/sync/content/student protected routes.
- Device auth flow is now integrated into Flutter API calls (best-effort bootstrap with offline-safe fallback).
- WebSocket server hub is now integrated and broadcasts admin events (`sync_complete`, `student_registered`, `content_updated`).
- Sync endpoint now supports the documented `device_id + batches[]` payload shape while preserving backward compatibility.
- Content endpoint now returns `up_to_date` and `version_tag` contract fields.
- Flutter sync queue replay now uses explicit retry/backoff handling for transient connectivity errors.
- Flutter client now runs content version polling and defers refresh while a learning session is active.
- Backend integration tests now cover device registration, admin login, content version contract pulls, offline registration sync, temp-ID remapping, duplicate score replay idempotency, and progress replay idempotency.
- Backend app bootstrap has been refactored into a reusable app factory for testable in-process integration runs.
- Quiz screen now uses a fallback-first rendering strategy (no blocking loading screen) and only hydrates remote questions before interaction to keep UX stable.
- API question fetching now uses in-memory cache with background refresh for faster repeat loads.
- Oracle content version reads now handle schema timestamp differences (`changed_at` in Oracle vs `updated_at` in SQLite), removing an Oracle-specific contract risk.

## Partial Changes

- Offline registration sync and temp-ID remapping now have backend integration test coverage; queue replay ordering and partial failure recovery still need deeper scenario testing.
- Admin and sync routes are protected, but Flutter admin panel token lifecycle and reconnect behavior still need full e2e validation.
- The quiz screen now loads remote questions, but the fallback/remote reconciliation logic still needs manual QA across all difficulty and subject combinations.
- Admin login supports bcrypt-hashed values and legacy hashes, but database migration to fully bcrypt-only credentials is still pending.
- Oracle procedure/view parity review found remaining architectural gaps:
  - Stored procedures exist in KOW.sql (`sp_upsert_student`, `sp_upload_score`, `sp_refresh_analytics`, `sp_bump_content_version`) but runtime paths mostly use inline SQL instead of procedure calls.
  - Oracle analytics workflow is defined around `sp_refresh_analytics`, but current runtime writes do not consistently refresh `analyticsTb`.
  - Oracle reporting views (`vw_student_profile`, `vw_score_summary`, `vw_age_group_progress`, `vw_device_status`) are defined but current admin endpoints query base tables directly.

## Unfinished / Pending Work

- Add Flutter admin web screens for dashboard, student management, device management, and question CRUD.
- Add tests for:
  - admin CRUD updates bumping content version
- Close remaining Oracle procedure/view parity gaps identified in this status report.

## Files Touched So Far

- `README.md`
- `backend/SETUP_INSTRUCTIONS.md`
- `backend/src/config/providers/oracleProvider.js`
- `backend/src/config/providers/sqliteProvider.js`
- `backend/src/controllers/authController.js`
- `backend/src/controllers/contentController.js`
- `backend/src/controllers/studentController.js`
- `backend/src/controllers/syncController.js`
- `backend/src/controllers/adminController.js`
- `backend/src/controllers/progressController.js`
- `backend/src/controllers/quizController.js`
- `backend/src/controllers/userController.js`
- `backend/src/middleware/authMiddleware.js`
- `backend/src/services/wsHub.js`
- `backend/src/models/userModel.js`
- `backend/src/models/quizModel.js`
- `backend/src/routes/authRoutes.js`
- `backend/src/routes/contentRoutes.js`
- `backend/src/routes/studentRoutes.js`
- `backend/src/routes/syncRoutes.js`
- `backend/src/routes/adminRoutes.js`
- `backend/src/index.js`
- `backend/src/app.js`
- `backend/tests/api.integration.test.js`
- `backend/package.json`
- `backend/package-lock.json`
- `lib/api_service.dart`
- `lib/local_sync_store.dart`
- `lib/quiz_screen.dart`
- `lib/grade_select/level_map.dart`
- `lib/screens/welcome_back.dart`
- `lib/screens/welcome_student.dart`

## Verification

- `node --check` passed on the newly added or updated backend controllers, routes, and entry file.
- `flutter analyze lib/api_service.dart lib/local_sync_store.dart` passed cleanly.
- `npm test` (backend) passed with 5/5 integration tests.
- `npm test` (backend) passed with 6/6 integration tests.
- `flutter analyze lib/api_service.dart lib/quiz_screen.dart` passed cleanly after loading-performance optimization.
- No current workspace diagnostics errors are reported.

## Notes

- The current implementation is intentionally staged: core offline sync and admin contract endpoints exist, but auth guards, richer admin UI, and real-time notifications are still pending.
- The status above reflects the current workspace state, not the final product scope from the documentation set.
