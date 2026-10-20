module Gifts
  # Refunds a gift that is due: unclaimed past its claim window, or claimed and past
  # the sender's expiry date. Safe to run repeatedly (the scheduled job lands in Phase 3).
  class Expire
    def initialize(refund: Ledger::Refund.new, clock: Time)
      @refund = refund
      @clock = clock
    end

    def call(wallet:)
      wallet.with_lock { expire(wallet) }
    end

    private

    def expire(wallet)
      return Result.failure(:not_due) unless due?(wallet, @clock.current)

      @refund.call(wallet: wallet, reason: "expired")
      wallet.update!(status: :expired, claim_token_digest: nil)
      Result.success(wallet)
    end

    def due?(wallet, now)
      return wallet.claim_expires_at <= now if wallet.pending?

      wallet.gift? && wallet.active? && wallet.expires_at.present? && wallet.expires_at <= now
    end
  end
end
