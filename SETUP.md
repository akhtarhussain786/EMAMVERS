# EXAMVERSE — setup & operations

## 0. Local database (this machine)

The system MySQL uses socket auth for `root`, and a private `mysqld` is blocked by
AppArmor. The working local setup is a Docker container on **port 3307**:

```bash
docker start examverse-mysql          # already created; use `docker ps -a` to confirm
```

To recreate it from scratch:

```bash
docker run -d --name examverse-mysql \
  -e MYSQL_ROOT_PASSWORD='<pick-one>' -e MYSQL_DATABASE=examverse_db \
  -e MYSQL_USER=examverse -e MYSQL_PASSWORD='<pick-one>' \
  -p 3307:3306 mysql:8 \
  --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
```

Put the password you chose into `.env` as `DB_PASS`, and set `DB_PORT=3307`.

Then create the admin account (no default password exists):

```bash
php database/reset_admin.php '<your-admin-password>'
```

Teacher accounts are created from **Admin panel → Question Review → Teachers**.
Student accounts are created through normal signup in the app.

Credentials are never committed — keep them in `.env`, which is git-ignored.

## 1. Configure the environment

```bash
cp .env.example .env
php -r "echo bin2hex(random_bytes(32)), PHP_EOL;"   # paste into APP_KEY
```

`.env` is git-ignored. The API refuses to start without a 32-character `APP_KEY`
unless `APP_DEBUG=true`.

| Key | Notes |
|---|---|
| `APP_DEBUG` | `true` only on a local machine. Enables detailed error bodies, a wildcard CORS origin, and returns dev OTPs in the response. |
| `APP_KEY` | Signs auth tokens and encrypts stored AI provider keys. Changing it invalidates all sessions and makes existing AI keys unreadable. |
| `DB_*` | Database connection. |
| `CORS_ALLOWED_ORIGINS` | Comma-separated origins. Empty denies all cross-origin browser calls; native app clients are unaffected. |
| `PAYMENTS_ENABLED` / `PAYMENTS_MOCK` | Both default to `false`, so paid purchases are refused rather than silently recorded as paid. Set `PAYMENTS_MOCK=true` for local testing only. |
| `GEMINI_MODEL` / `OPENAI_MODEL` | Model ids for AI question generation. |

## 2. Apply the database migrations

Run in order; every script is CLI-only and safe to re-run.

```bash
php database/run_migration.php
php database/run_migration_v3.php
php database/run_migration_v4.php
php database/run_migration_v5.php
php database/run_migration_v6.php     # integrity constraints
php database/run_migration_v7.php     # teacher question authoring
```

`migration_v6` adds the UNIQUE constraints that existing upserts already assumed,
widens `user_otps.otp_code` for hashed codes, adds `users.mobile_hash` for
contact matching, and adds the map-progress counters.

`migration_v7` adds teacher question authoring: a `teacher` account type, an
author and review trail on `questions`, a `rejected` status, and the
`teacher_profiles` table.

## 3a. Question authoring and approval

Two roles can add questions:

| Who | Where | Result |
|---|---|---|
| **Admin / content operator** | Admin panel → Question Bank | Published immediately |
| **Teacher** | Mobile app → Teacher Panel | Enters the review queue as `status='review'` |

A teacher submission is invisible to students until an admin approves it in
**Admin panel → Question Review**. Approving sets `status='published'`;
rejecting records a reason the teacher sees in their submissions list. Either
way the teacher gets an in-app notification.

`assignQuestionsToTest` refuses to attach any question that is not `published`,
so an unreviewed submission cannot reach a live test even by mistake.

Teacher accounts are created by staff (Admin panel → Question Review →
Teachers tab). A student account is never upgraded into a teacher.

## 3. Create the admin account

There is no default password. Set one explicitly:

```bash
php database/reset_admin.php 'a-long-unique-password'
```

## 4. Run the app

```bash
# Local dev against a PHP dev server
cd student_app
flutter run --dart-define=API_HOST=192.168.1.50:8000

# Release build — API_BASE_URL is mandatory and must be HTTPS
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.example.com/EXAMVERSE/api
```

A release build without `API_BASE_URL` fails fast rather than silently pointing
at a hard-coded LAN address.

## 5. Storage

Uploaded study materials live in `storage/materials/`, outside the document
root, and are served only through the entitlement-checked
`GET /v1/marketplace/{id}/file` endpoint using a short-lived signed grant.
`api/storage/ratelimit/` holds rate-limiter counters. Both directories ship with
`.htaccess` deny rules; on nginx, block them in the server config.

## 6. Not yet implemented

- **OTP delivery.** `POST /v1/auth/send-otp` generates and stores a hashed code
  but has no SMS/email transport. Outside debug mode the code is written to the
  PHP error log only. Wire a provider into `AuthController::sendOtp()`.
- **Payments.** `MarketplaceController::purchase()` has no gateway. With
  `PAYMENTS_ENABLED=true` it returns 503 until one is implemented; the capture
  and signature-verification step goes in the marked block.

## 7. Running the tests

```bash
cd student_app

# Unit + widget tests (includes the palette contrast checks)
flutter test

# UI + readability tests: drives the real app against a running API.
# Credentials are passed in so none are committed.
flutter test integration_test/app_ui_test.dart -d linux \
  --dart-define=API_BASE_URL=http://127.0.0.1:8911/EXAMVERSE/api \
  --dart-define=TEST_STUDENT_PASSWORD='<student password>' \
  --dart-define=TEST_TEACHER_PASSWORD='<teacher password>'
```

The readability suite walks the rendered widget tree on 12 screens and fails
any text below 3:1 against the background actually painted behind it. Run it
after changing colours — a source-level scan cannot tell whether a given white
belongs on a card or on an accent fill.

## 8. Theme

The app uses a white ground with a dark-yellow accent. All colours live in
`AppConstants` (`student_app/lib/core/constants.dart`) and the matching admin
tokens are the `:root` variables in `admin/assets/style.css`. Keep the two in
step, and re-run the contrast tests after any change.
