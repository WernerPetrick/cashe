# Privacy and policy review (Phase 3)

- Date: 2026-10-23
- Scope: the Rails API and the Flutter app, checked against the privacy rules and policy requirements in CLAUDE.md.

## Privacy rules

| Rule | Where it holds | Proof |
| --- | --- | --- |
| Raw coordinates are never persisted | `PresencePing` and `Coordinates` live only for the request. `presence_sessions` and `unlocks` hold timestamps only. The speed check keeps a distance to the place, not a position (ADR 0004). | `JumpCheckTest` "keeps only a distance, never coordinates" |
| Coordinates are never logged | `filter_parameters` covers `latitude`, `longitude`, `accuracy_m` and `near`, including the query string on the `Started GET` line. The geofence, distance and nearby-places queries run under `QuietSql`. `Coordinates#inspect` and `PresencePing#inspect` are redacted. | `never logs` tests for pings and place search; SQL-log tests for `Geofence` and `PlaceDistance` |
| Location is foreground only, on the unlock screen | Only `UnlockController` uses `LocationService`. The stream is cancelled when the screen is disposed. The app asks for "while in use" only. The place picker never reads the device's location (ADR 0003). | Unlock screen and controller tests |
| The funder never sees the recipient's location | Spends show the amount, time and place name (`LedgerEntrySerializer`). The spend window (`unlocked_until`) is shown to the owner only (`WalletPolicy#see_unlock?`). No endpoint exposes presence sessions. | "shows the spend window to the owner but never to the funder"; the happy-path integration test checks the funder's screens contain no coordinates |
| A claim token is a digest and works once | `ClaimToken` stores a SHA-256 digest, which is cleared on claim, cancel and expiry. `token` is a filtered parameter. | Gift-claim request tests |

## Policies

Every wallet action is checked in a `before_action` through `WalletPolicy`. A wallet the user has no part in returns 404, so its existence isn't revealed. Request tests cover each forbidden case:

- The funder can't ping for or spend a recipient's gift.
- The recipient can't top up or cancel a gift.
- A claimed gift or a goal can't be cancelled.
- A stranger can't see, ping, spend from, top up, cancel or read the history of a wallet.
- Children can't add places.
- The sender can't claim their own gift.
- Every endpoint refuses a missing or forged JWT (`AuthenticationRequiredTest`).

Rate limits are per signed-in user: pings 12 a minute, spends 10 and gift claims 10 (`RateLimitsTest`).

## Hardening added in Phase 3

- **Impossible jumps** are rejected as `impossible_jump` (ADR 0004).
- **A spoofed or jumping ping ends an open unlock**, not just the presence session.
- **Scheduled jobs** refund due gifts every 5 minutes and close presence sessions that stopped pinging every minute (`config/recurring.yml`).

## Known limits and recommendations

1. **Presence history is kept indefinitely.** Ended sessions record when the owner was at the place: timestamps only, and visible to no one through the API. Sessions without an unlock could be deleted after a set period; sessions with an unlock are referenced by spends. Deciding on retention changes the data rules, so it needs the developer's decision.
2. **`POST /places` and `POST /session` aren't rate-limited.** The risk is low, because both need a valid Appwrite JWT and Appwrite rate-limits sign-ins, but a limit per user (places) or per IP (session) would be cheap to add.
3. **A spoofer active before the unlock screen opens** gets past the speed check. Only the mock-location flag stops them (ADR 0004). Play Integrity and App Attest are post-hackathon.
4. **In production, Solid Cache keeps the last distance to the place in a database table for up to 45 seconds** (ADR 0004).
