module Ledger
  # Input checks shared by deposits and spends.
  module AmountRules
    MAX_KEY_LENGTH = 100

    private

    def input_error(amount_cents, key)
      return :invalid_amount unless amount_cents.is_a?(Integer) && amount_cents.positive?

      :invalid_idempotency_key if key.to_s.strip.empty? || key.to_s.length > MAX_KEY_LENGTH
    end

    def expired?(wallet)
      wallet.expires_at.present? && wallet.expires_at <= @clock.current
    end
  end
end
