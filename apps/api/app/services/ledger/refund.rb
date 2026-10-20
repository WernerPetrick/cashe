module Ledger
  # Returns a wallet's whole remaining balance to its funder as one negative entry.
  # The caller must hold the wallet's row lock.
  class Refund
    def initialize(balances: WalletBalances.new)
      @balances = balances
    end

    def call(wallet:, reason:)
      cents = @balances.cents_for(wallet)
      return Result.success(nil) unless cents.positive?

      Result.success(LedgerEntry.create!(wallet: wallet, kind: :refund, amount_cents: -cents,
        idempotency_key: "refund/#{wallet.id}/#{reason}"))
    end
  end
end
