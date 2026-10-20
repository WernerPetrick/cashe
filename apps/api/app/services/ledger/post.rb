module Ledger
  # Writes one entry with the wallet row locked (SELECT … FOR UPDATE). A repeated
  # idempotency key replays the original entry; a write that would leave the
  # balance negative is refused. The guard block runs under the lock and returns
  # an error code to refuse the write.
  class Post
    def initialize(balances: WalletBalances.new)
      @balances = balances
    end

    def call(wallet:, entry:, &guard)
      wallet.with_lock { post(wallet, entry, guard) }
    end

    private

    def post(wallet, entry, guard)
      original = LedgerEntry.find_by(idempotency_key: entry.idempotency_key)
      return replay(original, entry) if original

      error = guard&.call(wallet) || overdraft(wallet, entry)
      error ? Result.failure(error) : Result.success(entry.tap(&:save!))
    end

    def replay(original, entry)
      same = %i[wallet_id kind amount_cents].all? { |field| original[field] == entry[field] }
      same ? Result.success(original) : Result.failure(:idempotency_conflict)
    end

    def overdraft(wallet, entry)
      :insufficient_funds if (@balances.cents_for(wallet) + entry.amount_cents).negative?
    end
  end
end
