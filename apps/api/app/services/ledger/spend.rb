module Ledger
  # Spends from a wallet during an active unlock. The entry records which unlock allowed it.
  class Spend
    include AmountRules

    def initialize(post: Post.new, clock: Time)
      @post = post
      @clock = clock
    end

    def call(wallet:, amount_cents:, key:)
      error = input_error(amount_cents, key)
      return Result.failure(error) if error

      entry = LedgerEntry.new(wallet: wallet, kind: :spend, amount_cents: -amount_cents,
        idempotency_key: "spend/#{wallet.id}/#{key}")
      @post.call(wallet: wallet, entry: entry) { |locked| refusal(locked, entry) }
    end

    private

    def refusal(wallet, entry)
      return :wallet_closed unless wallet.active? && !expired?(wallet)

      entry.unlock = wallet.unlocks.active_at(@clock.current).order(:unlocked_until).last
      :wallet_locked unless entry.unlock
    end
  end
end
