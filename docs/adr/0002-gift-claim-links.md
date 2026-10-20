# 0002 — Gift recipients claim gifts through a one-time link

- Status: accepted
- Date: 2026-10-20

## Context

A gift wallet needs an owner, its recipient. The original plan linked a parent to child accounts, but gifts also go between friends ("a coffee on me"), where no account relationship exists. Looking recipients up by email or phone would let anyone check who has a Cashe account, and would still need an invite path for people who haven't signed up.

## Decision

- A sender creates a gift with no owner. Cashe returns a **one-time claim link** containing a random token (at least 128 bits). The sender shares it however they like.
- The recipient opens the link, signs in, and claims the gift (`POST /api/v1/gift_claims`). They become its owner and the token stops working.
- Only a SHA-256 digest of the token is stored. A claim succeeds once; later attempts fail without saying whether the token ever existed. Claims are rate-limited.
- **Unclaimed gifts:** the sender may cancel at any time before a claim (full refund). A gift still unclaimed **3 days** after creation is refunded automatically (the window is configurable). A refund is an append-only ledger entry that returns the balance to zero; money in Cashe is simulated, so "returned to the sender" means taken off the gift's balance.
- After a claim, the funder sees "Claimed by <display name>" and each spend with its place name, and never the recipient's location.
- A funder cannot claim their own gift.
- Gifts are not locked to a recipient's phone number or email; single use is the protection. Locking can be added later.
- Parent–child (managed child) accounts move to a later phase.

## Consequences

- `wallets.owner_id` is nullable for gifts until they're claimed, and required for goals (a check constraint enforces both).
- Wallets gain `claim_token_digest`, `claimed_at` and `claim_expires_at`, plus `status` values `pending`, `active`, `cancelled` and `expired`.
- New endpoints: `POST /gift_claims` and `POST /wallets/:id/cancellation`.
- The automatic refund of unclaimed gifts is built as a service in Phase 1. The Solid Queue job that runs it on schedule comes in Phase 3 with the other expiry jobs.
