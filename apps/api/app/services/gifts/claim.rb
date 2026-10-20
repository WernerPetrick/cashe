module Gifts
  # Turns a claim token into ownership of a pending gift. The token then stops working.
  class Claim
    def initialize(clock: Time)
      @clock = clock
    end

    def call(user:, token:)
      Wallet.transaction do
        claim(Wallet.lock.find_by(claim_token_digest: ClaimToken.digest(token)), user)
      end
    end

    private

    def claim(wallet, user)
      return Result.failure(:invalid_claim) unless claimable?(wallet)
      return Result.failure(:own_gift) if wallet.funder_id == user.id

      wallet.update!(owner: user, claimed_at: @clock.current, status: :active, claim_token_digest: nil)
      Result.success(wallet)
    end

    def claimable?(wallet)
      wallet.present? && wallet.pending? && wallet.claim_expires_at > @clock.current
    end
  end
end
