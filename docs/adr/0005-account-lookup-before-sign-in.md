# 0005 — Account lookup before sign-in

- Status: accepted
- Date: 2026-10-29

## Context

Sign-in asks for the email first, then shows a password step. The password step has two forms: "Welcome back" (sign in) and "New to Cashe" (create your wallet). Appwrite's client SDK can't tell the app whether an email already has an account, so the step always opened as sign-in. A new user had to notice the "New to Cashe? Create your wallet" link to find the right form.

Rails holds the Appwrite server API key, and Appwrite's Users API can list users by email, so Rails can answer the question.

## Decision

- Add `POST /api/v1/account_lookups` with `{ "email": "…" }`. It returns `{ "exists": true | false }`. It is the only endpoint that needs no JWT, because it runs before sign-in.
- `AppwriteAuth::Directory` asks Appwrite's Users API for a user with that email (lowercased and trimmed). It is the only code that uses the server API key, which is read from `credentials.appwrite.api_key` and needs the `users.read` scope.
- The endpoint is rate-limited to 10 lookups a minute per IP. The email is already filtered from the logs.
- The app shows "Checking…" on Continue, then opens the password step as sign-up if the email is new, and as sign-in otherwise. If the lookup fails (offline, rate-limited, no API key, Appwrite down), it opens as sign-in, as before. Either form can still switch to the other with one tap.

## Consequences

- Anyone can check whether an email has a Cashe account. The rate limit slows bulk checks but doesn't stop them. Sign-up already revealed this (`account_exists`), so this makes the leak easier to use but doesn't create a new one. If that matters later, require a captcha or drop the lookup.
- Without the API key in credentials, the endpoint answers 503 `auth_unavailable` and the app behaves as it did before this change.
- The API key is a new secret for deployment (Phase 4). It stays in Rails credentials and never reaches the app.
