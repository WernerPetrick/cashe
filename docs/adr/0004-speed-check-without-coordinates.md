# 0004 — Speed check without storing coordinates

- Status: accepted
- Date: 2026-10-23

## Context

Phase 3 adds a check for impossible jumps: a phone that reports being 5 km away and then, 12 seconds later, inside the zone. The mock-location flag catches ordinary spoofing apps, but a rooted phone can hide that flag. A jump in position is the next signal.

A speed check needs something from the previous ping, and the privacy rules say raw coordinates are never persisted or logged. Rails also has no safe place to keep them:

- In production the cache is Solid Cache, a database table, so caching coordinates there would persist them.
- The `presence_sessions` table holds timestamps only, and a session only exists while the person is inside the zone. A jump *into* the zone starts a session, so there is no earlier ping in that session to compare against.

## Decision

- Each ping keeps one number from the previous ping: its **distance to the wallet's place**, rounded to the metre, with its accuracy and time. No coordinates are kept.
- PostGIS computes that distance (`ST_Distance` on the geography) in the same quiet query style as the geofence, so it never reaches the SQL log.
- The value lives in `Rails.cache`, keyed by user and wallet, and expires after `ping_gap_seconds` (45 s). Each ping overwrites it. It is never written to a table we own, and never logged or returned by the API.
- A ping is an **impossible jump** when the change in distance exceeds what is possible at `max_speed_mps` (default 70 m/s, about 250 km/h) over the time since the last ping, plus both pings' accuracy as slack:
  `|d₂ − d₁| > max_speed_mps × Δt + accuracy₁ + accuracy₂`
  The change in distance to a fixed point can never exceed the true distance moved, so this check never rejects an honest ping. It only catches movement towards or away from the place, which is the direction that matters for an unlock.
- The ping is rejected with reason `impossible_jump`, which is a new value of `rejected`. Like a mock location, it ends the presence session.
- **A mock location or an impossible jump also ends an active unlock**, by setting its `unlocked_until` to now. Today a spoofed ping during the spend window is rejected, but the unlock stays open and the next ping shows it unlocked again. The `unlocks` table isn't the ledger, so this doesn't touch the ledger rules.
- The app shows the jump as "Location rejected" with the message "Your location jumped too far, too fast. Stay put and try again."

## Consequences

- In production Solid Cache stores the distance in a database table for up to 45 seconds. It is a single number relative to a public place, not a position, but it is still derived from location and is stated here for the privacy review.
- Movement around the place at a constant distance isn't caught. That doesn't help a spoofer, who needs to get closer.
- The first ping after a 45-second gap has nothing to compare with, so a jump across a gap isn't caught. Dwell still has to be earned from that point on.
- Tests inject a memory store, because the test environment's cache is a null store.
- OpenAPI gains `impossible_jump` in the `reason` enum, and the Flutter `RejectionReason` enum gains `impossibleJump`.
