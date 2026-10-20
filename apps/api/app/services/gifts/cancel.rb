module Gifts
  # The sender takes back a gift nobody has claimed yet: full refund, link dead.
  class Cancel
    def initialize(refund: Ledger::Refund.new)
      @refund = refund
    end

    def call(wallet:)
      wallet.with_lock { cancel(wallet) }
    end

    private

    def cancel(wallet)
      return Result.failure(:not_cancellable) unless wallet.pending?

      @refund.call(wallet: wallet, reason: "cancelled")
      wallet.update!(status: :cancelled, claim_token_digest: nil)
      Result.success(wallet)
    end
  end
end
