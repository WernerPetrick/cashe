module Ledger
  # Simulated top-up by the wallet's funder. Gifts can be topped up before they're claimed.
  class Deposit
    include AmountRules

    def initialize(post: Post.new, clock: Time)
      @post = post
      @clock = clock
    end

    def call(wallet:, amount_cents:, key:)
      error = input_error(amount_cents, key)
      return Result.failure(error) if error

      entry = LedgerEntry.new(wallet: wallet, kind: :deposit, amount_cents: amount_cents,
        idempotency_key: "deposit/#{wallet.id}/#{key}")
      @post.call(wallet: wallet, entry: entry) { |locked| :wallet_closed unless open?(locked) }
    end

    private

    def open?(wallet)
      (wallet.pending? || wallet.active?) && !expired?(wallet)
    end
  end
end
