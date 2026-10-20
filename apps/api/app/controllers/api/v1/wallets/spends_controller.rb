module Api
  module V1
    module Wallets
      # Spends during an active unlock; only the wallet's owner may spend.
      class SpendsController < BaseController
        include WalletAccess

        before_action -> { authorize_wallet!(:spend?) }
        rate_limit to: 10, within: 1.minute, by: -> { rate_limit_key }, with: -> { render_failure(:rate_limited) }

        def create
          result = ::Ledger::Spend.new.call(wallet: wallet, amount_cents: params[:amount_cents], key: params[:idempotency_key])
          render_result(result, status: :created) { |entry| LedgerEntrySerializer.new(entry, wallet: wallet) }
        end
      end
    end
  end
end
